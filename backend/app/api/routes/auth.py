from fastapi import APIRouter, Depends, HTTPException, status

from sqlalchemy.orm import Session
from datetime import datetime, timedelta, timezone
from app.config import settings
from app.core.fisher_id import generate_fisher_id
from app.core.phone import normalize_indian_phone
import jwt
from app.core.security import (
    create_access_token,
    create_fisher_onboarding_token,
    decode_fisher_onboarding_token,
    generate_otp,
    hash_otp,
    hash_password,
    verify_otp_hash,
    verify_password,
)
from sqlalchemy import select, update
from app.schemas.auth import (
        FishermanCompleteRegistrationRequest,
        FishermanOTPRequest,
        FishermanOTPVerifyRequest,
        LoginRequest,
        OTPRequestResponse,
        OTPVerifyResponse,
        RegisterRequest,
        TokenResponse,
        UserResponse,
)
from app.models.otp_challenge import OTPChallenge
from app.database import get_db
from app.models.fisherman_profile import FishermanProfile
from app.models.user import User
from app.schemas.auth import (
    LoginRequest,
    RegisterRequest,
    TokenResponse,
    UserResponse,
)
from app.api.dependencies import get_current_user
from app.services.sms_service import SmsDeliveryError, send_otp_sms, sends_real_sms

router = APIRouter(
    prefix="/api/v1/auth",
    tags=["Authentication"],
)


PUBLIC_REGISTRATION_ROLES = {
    "RESEARCHER",
}


@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
def register(
    data: RegisterRequest,
    db: Session = Depends(get_db),
):
    email = data.email.lower().strip()
    role = data.role.upper().strip()

    if role not in PUBLIC_REGISTRATION_ROLES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Public registration is available only "
                "for Researcher accounts."
            ),
        )

    existing_user = db.scalar(
        select(User).where(
            User.email == email
        )
    )

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists.",
        )

    user = User(
        full_name=data.full_name.strip(),
        email=email,
        password_hash=hash_password(data.password),
        role=role,
        auth_method="PASSWORD",
        preferred_language=data.preferred_language.lower(),
        is_active=True,
    )

    db.add(user)
    db.flush()

    if role == "FISHERMAN":
        fisherman_profile = FishermanProfile(
            user_id=user.id,
        )

        db.add(fisherman_profile)

    db.commit()
    db.refresh(user)

    return user


@router.post(
    "/login",
    response_model=TokenResponse,
)
def login(
    data: LoginRequest,
    db: Session = Depends(get_db),
):
    email = data.email.lower().strip()

    user = db.scalar(
        select(User).where(
            User.email == email
        )
    )

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
        )
    if user.auth_method != "PASSWORD":
        raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail="This account does not use password authentication.",
    )

    if user.password_hash is None:
        raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid email or password.",
    )

    if not verify_password(
        data.password,
        user.password_hash,
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account is inactive.",
        )

    access_token = create_access_token(
        user_id=user.id,
        role=user.role,
    )

    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user=user,
    )
@router.get(
    "/me",
    response_model=UserResponse,
)
def get_me(
    current_user: User = Depends(get_current_user),
):
    return current_user
@router.post(
    "/fisherman/request-otp",
    response_model=OTPRequestResponse,
)
def request_fisherman_otp(
    data: FishermanOTPRequest,
    db: Session = Depends(get_db),
):
    try:
        phone_number = normalize_indian_phone(
            data.phone_number
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        )

    now = datetime.now(timezone.utc)

    latest_challenge = db.scalar(
        select(OTPChallenge)
        .where(
            OTPChallenge.phone_number == phone_number
        )
        .order_by(
            OTPChallenge.created_at.desc()
        )
    )

    if latest_challenge is not None:
        cooldown_until = (
            latest_challenge.created_at
            + timedelta(
                seconds=settings.otp_resend_cooldown_seconds
            )
        )

        if now < cooldown_until:
            remaining = int(
                (
                    cooldown_until - now
                ).total_seconds()
            )

            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=(
                    f"Please wait {remaining} seconds "
                    "before requesting another OTP."
                ),
            )

    db.execute(
        update(OTPChallenge)
        .where(
            OTPChallenge.phone_number == phone_number,
            OTPChallenge.consumed.is_(False),
        )
        .values(consumed=True)
    )

    otp = generate_otp()

    challenge = OTPChallenge(
        phone_number=phone_number,
        otp_hash=hash_otp(
            phone_number,
            otp,
        ),
        expires_at=(
            now
            + timedelta(
                minutes=settings.otp_expire_minutes
            )
        ),
        attempts=0,
        consumed=False,
    )

    db.add(challenge)

    # Send before committing so a failed SMS leaves no unusable challenge.
    try:
        send_otp_sms(phone_number, otp)
    except SmsDeliveryError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not send the OTP SMS right now. Please try again shortly.",
        )

    db.commit()

    # Only in "dev" OTP mode is the code returned to the app for testing.
    development_otp = None if sends_real_sms() else otp

    return OTPRequestResponse(
        message=(
            "OTP sent by SMS." if sends_real_sms() else "OTP generated successfully."
        ),
        expires_in_seconds=(
            settings.otp_expire_minutes * 60
        ),
        dev_otp=development_otp,
    )
@router.post(
    "/fisherman/verify-otp",
    response_model=OTPVerifyResponse,
)
def verify_fisherman_otp(
    data: FishermanOTPVerifyRequest,
    db: Session = Depends(get_db),
):
    try:
        phone_number = normalize_indian_phone(
            data.phone_number
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        )

    challenge = db.scalar(
        select(OTPChallenge)
        .where(
            OTPChallenge.phone_number == phone_number,
            OTPChallenge.consumed.is_(False),
        )
        .order_by(
            OTPChallenge.created_at.desc()
        )
    )

    if challenge is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No active OTP challenge found.",
        )

    now = datetime.now(timezone.utc)

    if challenge.expires_at < now:
        challenge.consumed = True
        db.commit()

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="OTP has expired.",
        )

    if challenge.attempts >= 5:
        challenge.consumed = True
        db.commit()

        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many incorrect OTP attempts.",
        )

    valid_otp = verify_otp_hash(
        phone_number,
        data.otp,
        challenge.otp_hash,
    )

    if not valid_otp:
        challenge.attempts += 1
        db.commit()

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect OTP.",
        )

    challenge.consumed = True
    db.commit()

    existing_user = db.scalar(
        select(User).where(
            User.phone_number == phone_number
        )
    )

    if existing_user is not None:
        if existing_user.role != "FISHERMAN":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=(
                    "This phone number is not linked "
                    "to a Fisherman account."
                ),
            )

        access_token = create_access_token(
            user_id=existing_user.id,
            role=existing_user.role,
        )

        return OTPVerifyResponse(
            is_new_user=False,
            access_token=access_token,
            user=existing_user,
        )

    onboarding_token = (
        create_fisher_onboarding_token(
            phone_number
        )
    )

    return OTPVerifyResponse(
        is_new_user=True,
        onboarding_token=onboarding_token,
    )
@router.post(
    "/fisherman/complete-registration",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
)
def complete_fisherman_registration(
    data: FishermanCompleteRegistrationRequest,
    db: Session = Depends(get_db),
):
    try:
        payload = decode_fisher_onboarding_token(
            data.onboarding_token
        )

        phone_number = payload.get("sub")

        if phone_number is None:
            raise jwt.InvalidTokenError(
                "Missing phone number."
            )

    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=(
                "Invalid or expired onboarding token."
            ),
        )

    existing_user = db.scalar(
        select(User).where(
            User.phone_number == phone_number
        )
    )

    if existing_user is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "A Fisherman account already exists "
                "for this phone number."
            ),
        )

    user = User(
        full_name=data.full_name.strip(),
        phone_number=phone_number,
        phone_verified=True,
        role="FISHERMAN",
        auth_method="PHONE_OTP",
        preferred_language=(
            data.preferred_language.lower()
        ),
        is_active=True,
    )

    db.add(user)
    db.flush()

    user.fisher_id = generate_fisher_id(
        user.id
    )

    fisherman_profile = FishermanProfile(
        user_id=user.id,
        home_landing_centre=(
            data.home_landing_centre
        ),
        emergency_contact_name=(
            data.emergency_contact_name
        ),
        emergency_contact_phone=(
            data.emergency_contact_phone
        ),
    )

    db.add(fisherman_profile)

    db.commit()
    db.refresh(user)

    access_token = create_access_token(
        user_id=user.id,
        role=user.role,
    )

    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user=user,
    )