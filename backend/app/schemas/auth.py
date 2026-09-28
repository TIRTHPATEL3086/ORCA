from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class RegisterRequest(BaseModel):
    full_name: str = Field(
        min_length=2,
        max_length=120,
    )

    email: EmailStr

    password: str = Field(
        min_length=8,
        max_length=128,
    )

    role: str = Field(
        default="RESEARCHER",
    )

    preferred_language: str = Field(
        default="en",
        min_length=2,
        max_length=10,
    )


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class FishermanOTPRequest(BaseModel):
    phone_number: str = Field(
        min_length=8,
        max_length=20,
    )


class FishermanOTPVerifyRequest(BaseModel):
    phone_number: str

    otp: str = Field(
        min_length=6,
        max_length=6,
    )


class FishermanCompleteRegistrationRequest(BaseModel):
    onboarding_token: str

    full_name: str = Field(
        min_length=2,
        max_length=120,
    )

    preferred_language: str = Field(
        default="en",
        min_length=2,
        max_length=10,
    )

    home_landing_centre: str | None = Field(
        default=None,
        max_length=200,
    )

    emergency_contact_name: str | None = Field(
        default=None,
        max_length=120,
    )

    emergency_contact_phone: str | None = Field(
        default=None,
        max_length=30,
    )


class UserResponse(BaseModel):
    id: UUID
    full_name: str

    email: EmailStr | None = None
    phone_number: str | None = None

    fisher_id: str | None = None

    role: str
    auth_method: str

    preferred_language: str
    is_active: bool

    model_config = {
        "from_attributes": True
    }


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str | None = None
    token_type: str = "bearer"
    user: UserResponse


class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=20, max_length=200)


class OTPRequestResponse(BaseModel):
    message: str
    expires_in_seconds: int
    dev_otp: str | None = None


class OTPVerifyResponse(BaseModel):
    is_new_user: bool

    access_token: str | None = None
    refresh_token: str | None = None
    onboarding_token: str | None = None

    user: UserResponse | None = None