"""OTP delivery.

Providers (OTP_PROVIDER):
- "dev":      no SMS is sent; the code is returned to the app for testing.
- "sms_gate": the code is sent as a real SMS through SMS Gateway for Android
              (https://sms-gate.app), which uses an Android phone's own SIM.
"""

import logging

import requests

from app.config import settings


logger = logging.getLogger(__name__)


class SmsDeliveryError(Exception):
    """The OTP could not be handed to the SMS provider."""


def sends_real_sms() -> bool:
    return settings.otp_provider.lower() != "dev"


def otp_message(otp: str) -> str:
    return (
        f"{otp} is your ORCA verification code. "
        f"It expires in {settings.otp_expire_minutes} minutes. "
        "Do not share it with anyone."
    )


def send_otp_sms(phone_number: str, otp: str) -> None:
    provider = settings.otp_provider.lower()

    if provider == "dev":
        return

    if provider == "sms_gate":
        _send_via_sms_gate(phone_number, otp_message(otp))
        return

    raise SmsDeliveryError(f"Unknown OTP_PROVIDER: {settings.otp_provider}")


def _send_via_sms_gate(phone_number: str, text: str) -> None:
    if not settings.sms_gate_username or not settings.sms_gate_password:
        raise SmsDeliveryError("SMS gateway credentials are not configured.")

    try:
        response = requests.post(
            f"{settings.sms_gate_url.rstrip('/')}/messages",
            auth=(settings.sms_gate_username, settings.sms_gate_password),
            json={"textMessage": {"text": text}, "phoneNumbers": [phone_number]},
            timeout=15,
        )
    except requests.RequestException as exc:
        logger.exception("SMS gateway request failed")
        raise SmsDeliveryError("SMS gateway is unreachable.") from exc

    if response.status_code >= 300:
        logger.error(
            "SMS gateway rejected message: HTTP %s %s",
            response.status_code,
            response.text[:300],
        )
        raise SmsDeliveryError(f"SMS gateway returned HTTP {response.status_code}.")
