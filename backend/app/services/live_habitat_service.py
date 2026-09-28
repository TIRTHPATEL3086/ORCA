from __future__ import annotations

import csv
import io
import math
from datetime import datetime, timezone
from functools import lru_cache
from pathlib import Path
from typing import Any
from urllib.parse import quote

import numpy as np
import requests
from scipy.io import netcdf_file

from app.schemas.habitat import (
    HabitatFeatureInput,
    LiveHabitatResponse,
    RuntimeEvidence,
)
from app.services.habitat_model_service import score_habitat


ORCA_ROOT = Path(__file__).resolve().parents[3]

GEBCO_PATH = (
    ORCA_ROOT
    / "data"
    / "raw"
    / "bathymetry"
    / "gebco_2026_n25.0_s5.0_w65.0_e98.0.nc"
)

NOAA_OISST_NRT = (
    "https://coastwatch.pfeg.noaa.gov/erddap/griddap/"
    "ncdcOisst21NrtAgg.csv"
)

NOAA_VIIRS_CHL_NRT = (
    "https://coastwatch.pfeg.noaa.gov/erddap/griddap/"
    "nesdisVHNchlaDaily.csv"
)

OPEN_METEO = (
    "https://api.open-meteo.com/v1/forecast"
)

HTTP_TIMEOUT = 45

MAX_SST_AGE_HOURS = 120.0
MAX_CHL_AGE_HOURS = 168.0


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _parse_iso(value: str | None) -> datetime | None:
    if not value:
        return None

    try:
        parsed = datetime.fromisoformat(
            value.replace("Z", "+00:00")
        )

        if parsed.tzinfo is None:
            parsed = parsed.replace(
                tzinfo=timezone.utc
            )

        return parsed.astimezone(
            timezone.utc
        )
    except Exception:
        return None


def _age_hours(
    observed: datetime | None,
    now: datetime,
) -> float | None:
    if observed is None:
        return None

    return max(
        0.0,
        (now - observed).total_seconds()
        / 3600.0,
    )


def _get_text(url: str) -> str:
    response = requests.get(
        url,
        timeout=HTTP_TIMEOUT,
        headers={
            "User-Agent": (
                "ORCA-Hackathon-Marine-Intelligence/1.0"
            )
        },
    )
    response.raise_for_status()
    return response.text


def _erddap_rows(url: str) -> list[dict[str, str]]:
    text = _get_text(url)
    raw_rows = list(
        csv.reader(
            io.StringIO(text)
        )
    )

    if len(raw_rows) < 3:
        return []

    header = raw_rows[0]

    # ERDDAP .csv row 2 is the units row.
    data_rows = raw_rows[2:]

    result: list[dict[str, str]] = []

    for row in data_rows:
        if len(row) != len(header):
            continue

        result.append(
            dict(
                zip(
                    header,
                    row,
                    strict=True,
                )
            )
        )

    return result


def _float_or_none(value: Any) -> float | None:
    if value is None:
        return None

    text = str(value).strip()

    if text in {
        "",
        "NaN",
        "nan",
        "null",
        "None",
    }:
        return None

    try:
        number = float(text)
    except Exception:
        return None

    if not math.isfinite(number):
        return None

    return number


@lru_cache(maxsize=1)
def _gebco_arrays():
    if not GEBCO_PATH.exists():
        raise FileNotFoundError(
            f"GEBCO file missing: {GEBCO_PATH}"
        )

    with netcdf_file(
        str(GEBCO_PATH),
        "r",
        mmap=False,
    ) as nc:
        lat = np.asarray(
            nc.variables["lat"].data,
            dtype=float,
        ).copy()

        lon = np.asarray(
            nc.variables["lon"].data,
            dtype=float,
        ).copy()

        elevation = np.asarray(
            nc.variables["elevation"].data,
            dtype=float,
        ).copy()

    return lat, lon, elevation


def _gebco_features(
    latitude: float,
    longitude: float,
) -> tuple[float, float]:
    lat, lon, elevation = _gebco_arrays()

    i = int(
        np.abs(
            lat - latitude
        ).argmin()
    )
    j = int(
        np.abs(
            lon - longitude
        ).argmin()
    )

    z = float(
        elevation[i, j]
    )

    depth_m = max(
        0.0,
        -z,
    )

    i0 = max(
        0,
        i - 1,
    )
    i1 = min(
        len(lat) - 1,
        i + 1,
    )

    j0 = max(
        0,
        j - 1,
    )
    j1 = min(
        len(lon) - 1,
        j + 1,
    )

    dz_lat = float(
        elevation[i1, j]
        - elevation[i0, j]
    )

    dz_lon = float(
        elevation[i, j1]
        - elevation[i, j0]
    )

    dlat_km = max(
        0.01,
        abs(
            float(
                lat[i1]
                - lat[i0]
            )
        )
        * 111.32,
    )

    dlon_km = max(
        0.01,
        abs(
            float(
                lon[j1]
                - lon[j0]
            )
        )
        * 111.32
        * max(
            0.05,
            math.cos(
                math.radians(
                    latitude
                )
            ),
        ),
    )

    slope = math.sqrt(
        (dz_lat / dlat_km) ** 2
        + (dz_lon / dlon_km) ** 2
    )

    return depth_m, slope


def _fetch_latest_sst(
    latitude: float,
    longitude: float,
    now: datetime,
):
    query = (
        f"sst[(last)][(0.0)][({latitude})][({longitude})],"
        f"anom[(last)][(0.0)][({latitude})][({longitude})],"
        f"err[(last)][(0.0)][({latitude})][({longitude})]"
    )

    url = (
        NOAA_OISST_NRT
        + "?"
        + quote(
            query,
            safe="[](),:.-_",
        )
    )

    rows = _erddap_rows(
        url
    )

    if not rows:
        return None, []

    row = rows[0]

    observed = _parse_iso(
        row.get("time")
    )
    age = _age_hours(
        observed,
        now,
    )

    sst = _float_or_none(
        row.get("sst")
    )
    anomaly = _float_or_none(
        row.get("anom")
    )
    error = _float_or_none(
        row.get("err")
    )

    stale = (
        age is not None
        and age > MAX_SST_AGE_HOURS
    )

    evidence = [
        RuntimeEvidence(
            variable="sst",
            value=sst,
            unit="°C",
            source=(
                "NOAA OISST v2.1 Preliminary / NRT"
            ),
            observed_at=(
                observed.isoformat()
                if observed
                else None
            ),
            age_hours=age,
            status=(
                "STALE"
                if stale
                else (
                    "OK"
                    if sst is not None
                    else "MISSING"
                )
            ),
        ),
        RuntimeEvidence(
            variable="sst_anomaly",
            value=anomaly,
            unit="°C",
            source=(
                "NOAA OISST v2.1 Preliminary / NRT"
            ),
            observed_at=(
                observed.isoformat()
                if observed
                else None
            ),
            age_hours=age,
            status=(
                "STALE"
                if stale
                else (
                    "OK"
                    if anomaly is not None
                    else "MISSING"
                )
            ),
        ),
    ]

    if sst is None or stale:
        return None, evidence

    return {
        "sst_c": sst,
        "sst_anom_c": anomaly,
        "sst_error_c": error,
        "sst_local_range_c": None,
    }, evidence


def _fetch_latest_chl(
    latitude: float,
    longitude: float,
    now: datetime,
):
    # Query latest NRT S-NPP VIIRS daily chlorophyll.
    # If the exact pixel is cloud/missing, the Habitat Agent abstains.
    query = (
        f"chlor_a[(last)][(0.0)]"
        f"[({latitude})][({longitude})]"
    )

    url = (
        NOAA_VIIRS_CHL_NRT
        + "?"
        + quote(
            query,
            safe="[](),:.-_",
        )
    )

    rows = _erddap_rows(
        url
    )

    if not rows:
        evidence = [
            RuntimeEvidence(
                variable="chlorophyll_a",
                source=(
                    "NOAA S-NPP VIIRS NRT Daily Chlorophyll"
                ),
                status="MISSING",
                note=(
                    "No valid chlorophyll pixel was returned."
                ),
            )
        ]
        return None, evidence

    row = rows[0]

    observed = _parse_iso(
        row.get("time")
    )
    age = _age_hours(
        observed,
        now,
    )

    chl = _float_or_none(
        row.get("chlor_a")
    )

    if (
        chl is not None
        and not (
            0.001
            <= chl
            <= 100.0
        )
    ):
        chl = None

    stale = (
        age is not None
        and age > MAX_CHL_AGE_HOURS
    )

    evidence = [
        RuntimeEvidence(
            variable="chlorophyll_a",
            value=chl,
            unit="mg/m³",
            source=(
                "NOAA S-NPP VIIRS NRT Daily Chlorophyll"
            ),
            observed_at=(
                observed.isoformat()
                if observed
                else None
            ),
            age_hours=age,
            status=(
                "STALE"
                if stale
                else (
                    "OK"
                    if chl is not None
                    else "MISSING"
                )
            ),
            note=(
                "Runtime chlorophyll source differs from the "
                "Oceansat-2 OCM training source."
            ),
        )
    ]

    if chl is None or stale:
        return None, evidence

    return {
        "chl_mg_m3": chl,
        "log_chl": math.log1p(
            chl
        ),
        "chl_local_range": None,
    }, evidence


def _fetch_current_wind(
    latitude: float,
    longitude: float,
    now: datetime,
):
    response = requests.get(
        OPEN_METEO,
        params={
            "latitude": latitude,
            "longitude": longitude,
            "current": (
                "wind_speed_10m,"
                "wind_direction_10m"
            ),
            "wind_speed_unit": "ms",
            "timezone": "UTC",
        },
        timeout=HTTP_TIMEOUT,
        headers={
            "User-Agent": (
                "ORCA-Hackathon-Marine-Intelligence/1.0"
            )
        },
    )
    response.raise_for_status()

    payload = response.json()
    current = payload.get(
        "current",
        {},
    )

    speed = _float_or_none(
        current.get(
            "wind_speed_10m"
        )
    )
    direction = _float_or_none(
        current.get(
            "wind_direction_10m"
        )
    )

    observed = _parse_iso(
        current.get(
            "time"
        )
    )

    # Meteorological direction is where wind comes FROM.
    # Convert to eastward/northward vector toward which air moves.
    east = None
    north = None

    if (
        speed is not None
        and direction is not None
    ):
        radians = math.radians(
            direction
        )
        east = (
            -speed
            * math.sin(
                radians
            )
        )
        north = (
            -speed
            * math.cos(
                radians
            )
        )

    evidence = [
        RuntimeEvidence(
            variable="wind_speed",
            value=speed,
            unit="m/s",
            source="Open-Meteo Weather API",
            observed_at=(
                observed.isoformat()
                if observed
                else None
            ),
            age_hours=_age_hours(
                observed,
                now,
            ),
            status=(
                "OK"
                if speed is not None
                else "MISSING"
            ),
            note=(
                "Runtime wind source differs from the "
                "INCOIS ASCAT training source."
            ),
        )
    ]

    if speed is None:
        return None, evidence

    return {
        "wind_speed_ms": speed,
        "eastward_wind_ms": east,
        "northward_wind_ms": north,
    }, evidence


def evaluate_live_habitat(
    latitude: float,
    longitude: float,
) -> LiveHabitatResponse:
    now = _utc_now()
    evidence: list[
        RuntimeEvidence
    ] = []
    reasons: list[str] = []

    if not (
        5.0
        <= latitude
        <= 25.0
        and 65.0
        <= longitude
        <= 98.0
    ):
        reasons.append(
            "Coordinate is outside the v1 model/GEBCO India "
            "working domain (5–25°N, 65–98°E)."
        )

    try:
        depth, slope = _gebco_features(
            latitude,
            longitude,
        )
    except Exception as exc:
        depth = None
        slope = None
        reasons.append(
            f"GEBCO unavailable: {exc}"
        )

    if depth is not None:
        evidence.append(
            RuntimeEvidence(
                variable="depth",
                value=depth,
                unit="m",
                source="GEBCO 2026 regional subset",
                status="OK",
            )
        )

        if depth <= 0:
            reasons.append(
                "Coordinate does not resolve to ocean water in "
                "the GEBCO grid."
            )

    try:
        sst, sst_evidence = (
            _fetch_latest_sst(
                latitude,
                longitude,
                now,
            )
        )
        evidence.extend(
            sst_evidence
        )
    except Exception as exc:
        sst = None
        reasons.append(
            f"SST source unavailable: {exc}"
        )

    try:
        chl, chl_evidence = (
            _fetch_latest_chl(
                latitude,
                longitude,
                now,
            )
        )
        evidence.extend(
            chl_evidence
        )
    except Exception as exc:
        chl = None
        reasons.append(
            f"Chlorophyll source unavailable: {exc}"
        )

    try:
        wind, wind_evidence = (
            _fetch_current_wind(
                latitude,
                longitude,
                now,
            )
        )
        evidence.extend(
            wind_evidence
        )
    except Exception as exc:
        wind = None
        reasons.append(
            f"Wind source unavailable: {exc}"
        )

    if sst is None:
        reasons.append(
            "A fresh SST value is required for habitat inference."
        )

    if chl is None:
        reasons.append(
            "A fresh chlorophyll-a value is required for habitat inference."
        )

    if wind is None:
        reasons.append(
            "A current wind value is required for habitat inference."
        )

    if (
        depth is None
        or slope is None
    ):
        reasons.append(
            "Bathymetry features are required for habitat inference."
        )

    source_shift_warning = (
        "Runtime inference currently uses NOAA VIIRS NRT chlorophyll "
        "and Open-Meteo current wind, while v1 was trained with "
        "INCOIS Oceansat-2 OCM chlorophyll and INCOIS ASCAT wind. "
        "This sensor/source shift can affect calibration, so the score "
        "must remain experimental decision-support evidence."
    )

    model_scope_warning = (
        "ORCA Habitat Opportunity v1 is a presence-background habitat "
        "suitability model. It is not an official INCOIS PFZ model and "
        "does not by itself determine whether a fishing voyage is safe."
    )

    if reasons:
        return LiveHabitatResponse(
            status="ABSTAINED",
            latitude=latitude,
            longitude=longitude,
            evaluated_at=now.isoformat(),
            evidence=evidence,
            abstention_reasons=list(
                dict.fromkeys(
                    reasons
                )
            ),
            source_shift_warning=source_shift_warning,
            model_scope_warning=model_scope_warning,
        )

    dt = now
    month = dt.month
    doy = dt.timetuple().tm_yday

    features = HabitatFeatureInput(
        depth_m=float(depth),
        bathy_slope_m_per_km=float(slope),
        month_sin=math.sin(
            2
            * math.pi
            * month
            / 12.0
        ),
        month_cos=math.cos(
            2
            * math.pi
            * month
            / 12.0
        ),
        doy_sin=math.sin(
            2
            * math.pi
            * doy
            / 365.25
        ),
        doy_cos=math.cos(
            2
            * math.pi
            * doy
            / 365.25
        ),
        **sst,
        **chl,
        **wind,
    )

    score = score_habitat(
        features
    )

    return LiveHabitatResponse(
        status="READY",
        latitude=latitude,
        longitude=longitude,
        evaluated_at=now.isoformat(),
        score=score,
        features=features,
        evidence=evidence,
        abstention_reasons=[],
        source_shift_warning=source_shift_warning,
        model_scope_warning=model_scope_warning,
    )
