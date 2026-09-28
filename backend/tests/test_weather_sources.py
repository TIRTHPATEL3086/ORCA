"""Weather source resilience: Open-Meteo rate limits (HTTP 429) must not
break Sea Conditions. Upstream services are simulated; no network is used.
"""

import pytest
import requests

from app.services import weather_sources
from app.services.marine_service import fetch_marine_conditions


class FakeResponse:
    def __init__(self, status: int, payload: dict | None = None, url: str = ""):
        self.status_code = status
        self._payload = payload or {}
        self.url = url

    def json(self):
        return self._payload

    def raise_for_status(self):
        if self.status_code >= 400:
            raise requests.HTTPError(f"HTTP {self.status_code}", response=self)


MARINE = {
    "latitude": 20.79,
    "longitude": 70.21,
    "current": {"time": "2026-09-29T06:00", "wave_height": 1.2, "wave_period": 9.0},
}
OPEN_METEO_WIND = {
    "current": {
        "time": "2026-09-29T06:00",
        "wind_speed_10m": 6.0,
        "wind_direction_10m": 250.0,
        "wind_gusts_10m": 9.0,
    }
}
MET_NORWAY = {
    "properties": {
        "timeseries": [
            {
                "time": "2026-09-29T06:00:00Z",
                "data": {"instant": {"details": {"wind_speed": 5.5, "wind_from_direction": 240.0}}},
            }
        ]
    }
}


@pytest.fixture
def upstream(monkeypatch):
    """Controls what each simulated upstream service returns."""
    state = {"open_meteo_weather": 200, "met_norway": 200, "marine": 200, "calls": []}

    def fake_get(url, params=None, headers=None, timeout=None):
        state["calls"].append(url)
        if url == weather_sources.OPEN_METEO_MARINE:
            return FakeResponse(state["marine"], MARINE, url)
        if url == weather_sources.OPEN_METEO_WEATHER:
            return FakeResponse(state["open_meteo_weather"], OPEN_METEO_WIND, url)
        if url == weather_sources.MET_NORWAY:
            assert "ORCA" in headers["User-Agent"]
            return FakeResponse(state["met_norway"], MET_NORWAY, url)
        raise AssertionError(f"unexpected URL {url}")

    monkeypatch.setattr(weather_sources.requests, "get", fake_get)
    weather_sources._cache.clear()
    yield state
    weather_sources._cache.clear()


def test_normal_day_uses_open_meteo(upstream):
    result = fetch_marine_conditions(20.8, 70.2)
    assert result.wave_height_m == 1.2
    assert result.wind_speed_ms == 6.0 and result.wind_gust_ms == 9.0
    assert result.evidence[1].source == "Open-Meteo Weather API"


def test_open_meteo_rate_limited_falls_back_to_met_norway(upstream):
    upstream["open_meteo_weather"] = 429
    result = fetch_marine_conditions(20.8, 70.2)
    assert result.wind_speed_ms == 5.5
    assert result.wind_direction_deg == 240.0
    assert result.wind_gust_ms is None
    assert result.evidence[1].source == "MET Norway Locationforecast"
    assert result.screening_status in {"LOW", "CAUTION", "HIGH"}


def test_all_wind_sources_down_still_returns_wave_screening(upstream):
    upstream["open_meteo_weather"] = 429
    upstream["met_norway"] = 503
    result = fetch_marine_conditions(20.8, 70.2)
    assert result.wave_height_m == 1.2
    assert result.wind_speed_ms is None
    assert result.screening_status != "UNKNOWN"
    assert result.evidence[1].freshness_label == "Temporarily unavailable"


def test_repeat_requests_are_served_from_cache(upstream):
    fetch_marine_conditions(20.8, 70.2)
    first_calls = len(upstream["calls"])
    fetch_marine_conditions(20.801, 70.199)  # same ~1 km cell for wind
    assert len(upstream["calls"]) - first_calls <= 1  # marine only


def test_stale_reading_used_when_source_briefly_fails(upstream, monkeypatch):
    fetch_marine_conditions(20.8, 70.2)
    # Age every cache entry past "fresh" but within the stale window.
    for key, (stamp, data) in list(weather_sources._cache.items()):
        weather_sources._cache[key] = (stamp - weather_sources.FRESH_SECONDS - 1, data)
    upstream["marine"] = 429
    upstream["open_meteo_weather"] = 429
    upstream["met_norway"] = 503
    result = fetch_marine_conditions(20.8, 70.2)
    assert result.wave_height_m == 1.2 and result.wind_speed_ms == 6.0


def test_marine_source_down_without_cache_reports_error(upstream):
    upstream["marine"] = 429
    with pytest.raises(requests.HTTPError):
        fetch_marine_conditions(20.8, 70.2)
