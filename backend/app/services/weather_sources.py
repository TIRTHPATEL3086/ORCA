"""Resilient access to free weather/ocean model APIs.

Open-Meteo's free tier is rate-limited per IP address. Cloud hosts share
outbound IPs between many apps, so requests from ORCA's server can receive
HTTP 429 even at low volume. This module:

- caches responses per ~1 km cell for a short time (fewer upstream calls),
- falls back to MET Norway's free Locationforecast API for wind,
- serves the last good reading (clearly timestamped) if every source is
  briefly unavailable.
"""

from __future__ import annotations

import threading
import time
from dataclasses import dataclass

import requests


OPEN_METEO_MARINE = "https://marine-api.open-meteo.com/v1/marine"
OPEN_METEO_WEATHER = "https://api.open-meteo.com/v1/forecast"
MET_NORWAY = "https://api.met.no/weatherapi/locationforecast/2.0/compact"

# MET Norway's terms require an identifying User-Agent with contact info.
USER_AGENT = "ORCA-MarineIntelligence/1.0 (+https://github.com/TIRTHPATEL3086/ORCA)"

FRESH_SECONDS = 20 * 60
STALE_SECONDS = 3 * 60 * 60
TIMEOUT_SECONDS = 15

_cache: dict[str, tuple[float, object]] = {}
_lock = threading.Lock()


def _cache_key(url: str, params: dict) -> str:
    return url + "?" + "&".join(f"{k}={params[k]}" for k in sorted(params))


def get_json(url: str, params: dict) -> object:
    """GET JSON with a short cache; serves stale data if the source fails."""
    key = _cache_key(url, params)
    now = time.monotonic()

    with _lock:
        cached = _cache.get(key)
    if cached and now - cached[0] < FRESH_SECONDS:
        return cached[1]

    try:
        response = requests.get(
            url,
            params=params,
            headers={"User-Agent": USER_AGENT, "Accept": "application/json"},
            timeout=TIMEOUT_SECONDS,
        )
        response.raise_for_status()
        data = response.json()
    except Exception:
        if cached and now - cached[0] < STALE_SECONDS:
            return cached[1]
        raise

    with _lock:
        _cache[key] = (now, data)
        if len(_cache) > 5000:
            oldest = sorted(_cache.items(), key=lambda item: item[1][0])[:1000]
            for old_key, _ in oldest:
                _cache.pop(old_key, None)
    return data


def _cell(value: float) -> float:
    # ~1 km cells: nearby requests share one upstream call.
    return round(value, 2)


@dataclass(frozen=True)
class WindReading:
    speed_ms: float | None
    direction_deg: float | None
    gust_ms: float | None
    model_time: str | None
    source: str
    source_url: str


def _num(value) -> float | None:
    try:
        return None if value is None else float(value)
    except (TypeError, ValueError):
        return None


def _open_meteo_wind(lat: float, lon: float) -> WindReading:
    data = get_json(
        OPEN_METEO_WEATHER,
        {
            "latitude": _cell(lat),
            "longitude": _cell(lon),
            "current": "wind_speed_10m,wind_direction_10m,wind_gusts_10m",
            "wind_speed_unit": "ms",
            "timezone": "UTC",
            "cell_selection": "sea",
        },
    )
    current = (data or {}).get("current") or {}
    return WindReading(
        speed_ms=_num(current.get("wind_speed_10m")),
        direction_deg=_num(current.get("wind_direction_10m")),
        gust_ms=_num(current.get("wind_gusts_10m")),
        model_time=current.get("time"),
        source="Open-Meteo Weather API",
        source_url=OPEN_METEO_WEATHER,
    )


def _met_norway_wind(lat: float, lon: float) -> WindReading:
    data = get_json(MET_NORWAY, {"lat": _cell(lat), "lon": _cell(lon)})
    series = ((data or {}).get("properties") or {}).get("timeseries") or []
    if not series:
        raise ValueError("MET Norway returned no forecast data.")
    first = series[0]
    details = ((first.get("data") or {}).get("instant") or {}).get("details") or {}
    return WindReading(
        speed_ms=_num(details.get("wind_speed")),
        direction_deg=_num(details.get("wind_from_direction")),
        # Gusts are only published for the Nordic region.
        gust_ms=_num(details.get("wind_speed_of_gust")),
        model_time=first.get("time"),
        source="MET Norway Locationforecast",
        source_url=MET_NORWAY,
    )


def current_wind(lat: float, lon: float) -> WindReading:
    """10 m wind from Open-Meteo, falling back to MET Norway."""
    try:
        return _open_meteo_wind(lat, lon)
    except Exception as primary_error:
        try:
            return _met_norway_wind(lat, lon)
        except Exception:
            raise primary_error
