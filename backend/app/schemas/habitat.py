from typing import Literal

from pydantic import BaseModel, Field


class HabitatFeatureInput(BaseModel):
    depth_m: float = Field(ge=0, le=12000)
    bathy_slope_m_per_km: float = Field(ge=0)

    month_sin: float = Field(ge=-1, le=1)
    month_cos: float = Field(ge=-1, le=1)
    doy_sin: float = Field(ge=-1, le=1)
    doy_cos: float = Field(ge=-1, le=1)

    sst_c: float
    sst_anom_c: float | None = None
    sst_error_c: float | None = None
    sst_local_range_c: float | None = None

    chl_mg_m3: float = Field(gt=0)
    log_chl: float | None = None
    chl_local_range: float | None = None

    wind_speed_ms: float = Field(ge=0)
    eastward_wind_ms: float | None = None
    northward_wind_ms: float | None = None


class HabitatScoreResponse(BaseModel):
    model_name: str
    model_version: str
    score_0_100: float
    band: Literal[
        "LOW",
        "MODERATE",
        "MODERATE_HIGH",
        "HIGH",
    ]
    data_quality: Literal[
        "HIGH_FEATURE_COMPLETENESS",
        "MODERATE_FEATURE_COMPLETENESS",
        "LOW_FEATURE_COMPLETENESS",
    ]
    missing_optional_features: list[str]
    interpretation: str
    warning: str
    evidence_sources: list[str]


class HabitatModelHealthResponse(BaseModel):
    status: Literal["ready", "not_ready"]
    model_path: str
    model_name: str | None = None
    training_window: str | None = None
    test_window: str | None = None
    feature_count: int | None = None
    sklearn_runtime_version: str
    metrics: dict[str, float] = Field(default_factory=dict)
    message: str


class RuntimeEvidence(BaseModel):
    variable: str
    value: float | None = None
    unit: str | None = None
    source: str
    observed_at: str | None = None
    age_hours: float | None = None
    status: Literal[
        "OK",
        "MISSING",
        "STALE",
        "FALLBACK",
    ] = "OK"
    note: str | None = None


class LiveHabitatResponse(BaseModel):
    status: Literal[
        "READY",
        "ABSTAINED",
    ]
    latitude: float
    longitude: float
    evaluated_at: str

    score: HabitatScoreResponse | None = None
    features: HabitatFeatureInput | None = None
    evidence: list[RuntimeEvidence] = Field(default_factory=list)

    abstention_reasons: list[str] = Field(default_factory=list)
    source_shift_warning: str
    model_scope_warning: str
