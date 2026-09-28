"""End-to-end tests for fisherman phone sign-in and session handling.

Runs against the database configured in backend/.env (dev OTP mode) and
cleans up the accounts it creates.   Run:  python -m pytest tests -q
"""

import random

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import delete

from app.config import settings
from app.database import SessionLocal
from app.main import app
from app.models.otp_challenge import OTPChallenge
from app.models.user import User


client = TestClient(app)


@pytest.fixture(autouse=True)
def dev_otp_mode(monkeypatch):
    monkeypatch.setattr(settings, "otp_provider", "dev")
    monkeypatch.setattr(settings, "otp_resend_cooldown_seconds", 0)


@pytest.fixture
def phone():
    number = f"+9190{random.randint(10_000_000, 99_999_999)}"
    yield number
    with SessionLocal() as db:
        db.execute(delete(User).where(User.phone_number == number))
        db.execute(delete(OTPChallenge).where(OTPChallenge.phone_number == number))
        db.commit()


def _request_otp(phone: str) -> str:
    response = client.post(
        "/api/v1/auth/fisherman/request-otp", json={"phone_number": phone}
    )
    assert response.status_code == 200, response.text
    return response.json()["dev_otp"]


def _verify(phone: str, otp: str):
    return client.post(
        "/api/v1/auth/fisherman/verify-otp",
        json={"phone_number": phone, "otp": otp},
    )


def _register(phone: str) -> dict:
    onboarding = _verify(phone, _request_otp(phone)).json()["onboarding_token"]
    response = client.post(
        "/api/v1/auth/fisherman/complete-registration",
        json={
            "onboarding_token": onboarding,
            "full_name": "Auth Test",
            "preferred_language": "en",
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


def _me(access_token: str):
    return client.get(
        "/api/v1/auth/me", headers={"Authorization": f"Bearer {access_token}"}
    )


def _refresh(refresh_token: str):
    return client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})


def test_new_user_registers_and_gets_both_tokens(phone):
    body = _register(phone)
    assert body["access_token"] and body["refresh_token"]
    assert body["user"]["phone_number"] == phone
    assert _me(body["access_token"]).status_code == 200


def test_returning_user_signs_in_with_otp(phone):
    _register(phone)
    body = _verify(phone, _request_otp(phone)).json()
    assert body["is_new_user"] is False
    assert body["access_token"] and body["refresh_token"]


def test_wrong_otp_is_rejected_and_locks_after_five_attempts(phone):
    otp = _request_otp(phone)
    wrong = "000000" if otp != "000000" else "111111"
    for _ in range(5):
        assert _verify(phone, wrong).status_code == 400
    assert _verify(phone, otp).status_code == 429


def test_otp_cannot_be_reused(phone):
    otp = _request_otp(phone)
    assert _verify(phone, otp).status_code == 200
    assert _verify(phone, otp).status_code == 400


def test_refresh_rotates_tokens_and_keeps_user_signed_in(phone):
    first = _register(phone)
    refreshed = _refresh(first["refresh_token"])
    assert refreshed.status_code == 200
    body = refreshed.json()
    assert body["refresh_token"] != first["refresh_token"]
    assert _me(body["access_token"]).status_code == 200


def test_reusing_an_old_refresh_token_ends_the_session(phone):
    first = _register(phone)
    second = _refresh(first["refresh_token"]).json()
    # Replaying the already-used token looks like theft: everything is revoked.
    assert _refresh(first["refresh_token"]).status_code == 401
    assert _refresh(second["refresh_token"]).status_code == 401


def test_logout_revokes_the_session(phone):
    body = _register(phone)
    assert (
        client.post(
            "/api/v1/auth/logout", json={"refresh_token": body["refresh_token"]}
        ).status_code
        == 204
    )
    assert _refresh(body["refresh_token"]).status_code == 401


def test_inactive_account_cannot_sign_in(phone):
    _register(phone)
    with SessionLocal() as db:
        user = db.query(User).filter(User.phone_number == phone).one()
        user.is_active = False
        db.commit()
    assert _verify(phone, _request_otp(phone)).status_code == 403


def test_garbage_tokens_are_rejected():
    assert _me("not-a-token").status_code == 401
    assert _refresh("x" * 43).status_code == 401
