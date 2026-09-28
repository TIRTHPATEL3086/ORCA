"""Refresh-token sessions: issue, rotate and revoke.

Raw refresh tokens are random 256-bit strings given to the app once; the
database only keeps their SHA-256 hash.
"""

import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from uuid import UUID, uuid4

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.config import settings
from app.models.refresh_token import RefreshToken
from app.models.user import User


class InvalidRefreshToken(Exception):
    """The refresh token is unknown, expired, revoked or reused."""


def _hash(raw_token: str) -> str:
    return hashlib.sha256(raw_token.encode()).hexdigest()


def issue_refresh_token(
    db: Session,
    user: User,
    family_id: UUID | None = None,
) -> str:
    raw_token = secrets.token_urlsafe(32)
    db.add(
        RefreshToken(
            user_id=user.id,
            family_id=family_id or uuid4(),
            token_hash=_hash(raw_token),
            expires_at=datetime.now(timezone.utc)
            + timedelta(days=settings.refresh_token_expire_days),
        )
    )
    return raw_token


def _revoke_family(db: Session, family_id: UUID, now: datetime) -> None:
    db.execute(
        update(RefreshToken)
        .where(
            RefreshToken.family_id == family_id,
            RefreshToken.revoked_at.is_(None),
        )
        .values(revoked_at=now)
    )


def rotate_refresh_token(db: Session, raw_token: str) -> tuple[User, str]:
    """Exchange a valid refresh token for a new one (the old one is revoked)."""
    now = datetime.now(timezone.utc)
    stored = db.scalar(
        select(RefreshToken).where(RefreshToken.token_hash == _hash(raw_token))
    )

    if stored is None:
        raise InvalidRefreshToken()

    if stored.revoked_at is not None:
        # A revoked token being presented again means it was copied:
        # end every session descended from the same sign-in.
        _revoke_family(db, stored.family_id, now)
        db.commit()
        raise InvalidRefreshToken()

    if stored.expires_at < now:
        raise InvalidRefreshToken()

    user = db.get(User, stored.user_id)
    if user is None or not user.is_active:
        raise InvalidRefreshToken()

    stored.revoked_at = now
    new_token = issue_refresh_token(db, user, family_id=stored.family_id)
    db.commit()
    return user, new_token


def revoke_refresh_token(db: Session, raw_token: str) -> None:
    """Sign out: revoke this device's session (unknown tokens are ignored)."""
    stored = db.scalar(
        select(RefreshToken).where(RefreshToken.token_hash == _hash(raw_token))
    )
    if stored is not None:
        _revoke_family(db, stored.family_id, datetime.now(timezone.utc))
        db.commit()
