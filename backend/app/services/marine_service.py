from __future__ import annotations

from datetime import datetime, timezone

from app.services.weather_sources import current_wind, get_json
from app.schemas.marine import (
    MarineConditionsResponse,
    MarineEvidence,
)


MARINE_ENDPOINT = "https://marine-api.open-meteo.com/v1/marine"
WEATHER_ENDPOINT = "https://api.open-meteo.com/v1/forecast"

INCOIS_OSF_URL = (
    "https://www.incois.gov.in/oceanservices/osfforecast.jsp"
)


def _number(
    data: dict,
    key: str,
) -> float | None:
    value = data.get(key)

    if value is None:
        return None

    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _prototype_screening(
    wave_height_m: float | None,
    wind_speed_ms: float | None,
    wind_gust_ms: float | None,
) -> tuple[str, str]:
    """
    Hackathon-only conservative screening.
    These thresholds are NOT an official safety standard.
    """

    if wave_height_m is None and wind_speed_ms is None:
        return (
            "UNKNOWN",
            "Insufficient live model values for screening.",
        )

    high = (
        (wave_height_m is not None and wave_height_m >= 2.5)
        or (wind_speed_ms is not None and wind_speed_ms >= 15.0)
        or (wind_gust_ms is not None and wind_gust_ms >= 18.0)
    )

    if high:
        return (
            "HIGH",
            "One or more prototype screening thresholds are high. "
            "Check official INCOIS/IMD advisories before departure.",
        )

    caution = (
        (wave_height_m is not None and wave_height_m >= 1.5)
        or (wind_speed_ms is not None and wind_speed_ms >= 10.0)
        or (wind_gust_ms is not None and wind_gust_ms >= 13.0)
    )

    if caution:
        return (
            "CAUTION",
            "Moderate wave/wind conditions detected by the prototype "
            "screening rules. Verify official advisories.",
        )

    return (
        "LOW",
        "Prototype screening did not cross the current caution "
        "thresholds. Official advisories still take priority.",
    )


def fetch_marine_conditions(
    latitude: float,
    longitude: float,
) -> MarineConditionsResponse:
    marine_params = {
        "latitude": latitude,
        "longitude": longitude,
        "current": (
            "wave_height,wave_direction,wave_period,"
            "swell_wave_height,sea_surface_temperature,"
            "ocean_current_velocity,ocean_current_direction,"
            "sea_level_height_msl"
        ),
        "velocity_unit": "ms",
        "timezone": "auto",
        "cell_selection": "sea",
    }

    marine = get_json(
        MARINE_ENDPOINT,
        marine_params,
    )

    try:
        wind = current_wind(latitude, longitude)
    except Exception:
        # Waves alone still support a screening; wind shows as unavailable.
        wind = None

    marine_current = marine.get("current") or {}

    wave_height = _number(
        marine_current,
        "wave_height",
    )
    wind_speed = wind.speed_ms if wind else None
    wind_gust = wind.gust_ms if wind else None

    screening_status, screening_reason = (
        _prototype_screening(
            wave_height,
            wind_speed,
            wind_gust,
        )
    )

    fetched_at = datetime.now(
        timezone.utc
    ).isoformat()

    evidence = [
        MarineEvidence(
            source="Open-Meteo Marine API",
            source_url=MARINE_ENDPOINT,
            model_time=marine_current.get("time"),
            fetched_at=fetched_at,
            freshness_label="Current model conditions",
            note=(
                "Development adapter for live marine variables. "
                "Open-Meteo documents limitations for coastal "
                "tide/current accuracy."
            ),
        ),
        MarineEvidence(
            source=wind.source if wind else "Wind data",
            source_url=wind.source_url if wind else WEATHER_ENDPOINT,
            model_time=wind.model_time if wind else None,
            fetched_at=fetched_at,
            freshness_label=(
                "Current model conditions" if wind else "Temporarily unavailable"
            ),
            note=(
                "10 m wind and gust (gust may be unavailable outside "
                "the source's coverage)."
                if wind
                else "Wind sources did not respond; screening used waves only."
            ),
        ),
        MarineEvidence(
            source="INCOIS Ocean State Forecast (official India reference)",
            source_url=INCOIS_OSF_URL,
            model_time=None,
            fetched_at=fetched_at,
            freshness_label="Reference source",
            note=(
                "ORCA production adapters should prioritize official "
                "INCOIS/IMD marine products and advisories."
            ),
        ),
    ]

    return MarineConditionsResponse(
        requested_latitude=latitude,
        requested_longitude=longitude,
        grid_latitude=_number(
            marine,
            "latitude",
        ),
        grid_longitude=_number(
            marine,
            "longitude",
        ),
        wave_height_m=wave_height,
        wave_direction_deg=_number(
            marine_current,
            "wave_direction",
        ),
        wave_period_s=_number(
            marine_current,
            "wave_period",
        ),
        swell_height_m=_number(
            marine_current,
            "swell_wave_height",
        ),
        sea_surface_temperature_c=_number(
            marine_current,
            "sea_surface_temperature",
        ),
        ocean_current_velocity_ms=_number(
            marine_current,
            "ocean_current_velocity",
        ),
        ocean_current_direction_deg=_number(
            marine_current,
            "ocean_current_direction",
        ),
        sea_level_height_msl_m=_number(
            marine_current,
            "sea_level_height_msl",
        ),
        wind_speed_ms=wind_speed,
        wind_direction_deg=wind.direction_deg if wind else None,
        wind_gust_ms=wind_gust,
        screening_status=screening_status,
        screening_reason=screening_reason,
        evidence=evidence,
    )
