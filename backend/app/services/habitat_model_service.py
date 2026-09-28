from __future__ import annotations

from functools import lru_cache
import json
import math
from pathlib import Path
from typing import Any
import warnings

import joblib
import numpy as np
import sklearn

from app.schemas.habitat import (
    HabitatFeatureInput,
    HabitatModelHealthResponse,
    HabitatScoreResponse,
)


ORCA_ROOT = Path(__file__).resolve().parents[3]
MODEL_PATH = (
    ORCA_ROOT
    / "ml"
    / "artifacts"
    / "habitat_opportunity_v1.joblib"
)
METRICS_PATH = (
    ORCA_ROOT
    / "ml"
    / "artifacts"
    / "habitat_opportunity_v1_metrics.json"
)

EXPECTED_FEATURES = [
    "depth_m",
    "bathy_slope_m_per_km",
    "month_sin",
    "month_cos",
    "doy_sin",
    "doy_cos",
    "sst_c",
    "sst_anom_c",
    "sst_error_c",
    "sst_local_range_c",
    "chl_mg_m3",
    "log_chl",
    "chl_local_range",
    "wind_speed_ms",
    "eastward_wind_ms",
    "northward_wind_ms",
]

OPTIONAL_FEATURES = {
    "sst_anom_c",
    "sst_error_c",
    "sst_local_range_c",
    "log_chl",
    "chl_local_range",
    "eastward_wind_ms",
    "northward_wind_ms",
}


@lru_cache(maxsize=1)
def _load_artifact() -> dict[str, Any]:
    if not MODEL_PATH.exists():
        raise FileNotFoundError(
            f"ORCA habitat model not found: {MODEL_PATH}"
        )

    artifact = joblib.load(MODEL_PATH)

    if not isinstance(artifact, dict):
        raise RuntimeError(
            "Unexpected habitat model artifact format."
        )

    if "model" not in artifact or "features" not in artifact:
        raise RuntimeError(
            "Habitat artifact is missing model/features metadata."
        )

    saved_features = list(artifact["features"])

    if saved_features != EXPECTED_FEATURES:
        raise RuntimeError(
            "Habitat feature contract mismatch.\n"
            f"Expected: {EXPECTED_FEATURES}\n"
            f"Artifact: {saved_features}"
        )

    return artifact


def _load_test_metrics() -> dict[str, float]:
    if not METRICS_PATH.exists():
        return {}

    try:
        payload = json.loads(
            METRICS_PATH.read_text(
                encoding="utf-8"
            )
        )

        raw = payload.get(
            "independent_temporal_test_metrics",
            {},
        )

        return {
            str(key): float(value)
            for key, value in raw.items()
            if isinstance(value, (int, float))
        }
    except Exception:
        return {}


def get_habitat_model_health() -> HabitatModelHealthResponse:
    try:
        artifact = _load_artifact()

        return HabitatModelHealthResponse(
            status="ready",
            model_path=str(MODEL_PATH),
            model_name=artifact.get("model_name"),
            training_window=artifact.get(
                "training_window"
            ),
            test_window=artifact.get(
                "test_window"
            ),
            feature_count=len(
                artifact["features"]
            ),
            sklearn_runtime_version=(
                sklearn.__version__
            ),
            metrics=_load_test_metrics(),
            message=(
                "Model loaded. Scores are relative habitat-suitability "
                "signals, not official INCOIS PFZ probabilities."
            ),
        )

    except Exception as exc:
        return HabitatModelHealthResponse(
            status="not_ready",
            model_path=str(MODEL_PATH),
            sklearn_runtime_version=(
                sklearn.__version__
            ),
            message=str(exc),
        )


def _band(score: float) -> str:
    if score < 35:
        return "LOW"
    if score < 55:
        return "MODERATE"
    if score < 75:
        return "MODERATE_HIGH"
    return "HIGH"


def score_habitat(
    features: HabitatFeatureInput,
) -> HabitatScoreResponse:
    artifact = _load_artifact()
    model = artifact["model"]

    values = features.model_dump()

    if values.get("log_chl") is None:
        values["log_chl"] = math.log1p(
            values["chl_mg_m3"]
        )

    missing_optional = sorted(
        name
        for name in OPTIONAL_FEATURES
        if values.get(name) is None
    )

    row = []

    for feature_name in EXPECTED_FEATURES:
        value = values.get(feature_name)

        if value is None:
            row.append(np.nan)
        else:
            row.append(float(value))

    X = np.asarray(
        [row],
        dtype=float,
    )

    # The sklearn pipeline was fitted with DataFrame feature names.
    # The order here is validated against the saved artifact metadata.
    # Suppress only that harmless inference-time feature-name warning.
    with warnings.catch_warnings():
        warnings.filterwarnings(
            "ignore",
            message=(
                "X does not have valid feature names, "
                "but SimpleImputer was fitted with feature names"
            ),
            category=UserWarning,
        )
        relative_score = float(
            model.predict_proba(X)[0, 1]
        )

    score = round(
        relative_score * 100.0,
        1,
    )

    if len(missing_optional) == 0:
        data_quality = (
            "HIGH_FEATURE_COMPLETENESS"
        )
    elif len(missing_optional) <= 3:
        data_quality = (
            "MODERATE_FEATURE_COMPLETENESS"
        )
    else:
        data_quality = (
            "LOW_FEATURE_COMPLETENESS"
        )

    return HabitatScoreResponse(
        model_name=(
            "ORCA Fishing Habitat Opportunity Model"
        ),
        model_version="v1",
        score_0_100=score,
        band=_band(score),
        data_quality=data_quality,
        missing_optional_features=(
            missing_optional
        ),
        interpretation=(
            "Relative environmental habitat-suitability signal "
            "from the trained ORCA presence-background model."
        ),
        warning=(
            "Experimental decision-support evidence. Not an "
            "official INCOIS PFZ advisory, not a calibrated "
            "fish-presence probability, and not sufficient alone "
            "for voyage or safety decisions."
        ),
        evidence_sources=[
            "CMLRE / IndOBIS biological occurrence records",
            "INCOIS Oceansat-2 OCM chlorophyll-a (training)",
            "NOAA OISST v2.1 (training)",
            "INCOIS ASCAT wind (training)",
            "GEBCO 2026 bathymetry",
        ],
    )
