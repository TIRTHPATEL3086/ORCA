from __future__ import annotations

from typing import Any

from app.agents.habitat_agent import (
    run_habitat_agent,
)
from app.schemas.orca_agent import (
    OrcaAgentEvidence,
    OrcaAgentQueryRequest,
)
from app.services.gis_service import (
    check_boundary,
    plan_weather_aware_route,
)
from app.services.marine_service import (
    fetch_marine_conditions,
)


def _fmt(
    value: float | None,
    unit: str,
    decimals: int = 1,
) -> str:
    if value is None:
        return "Unavailable"

    return f"{value:.{decimals}f} {unit}"


def _role_code(
    role: str | None,
) -> str:
    return (
        role
        or "FISHERMAN"
    ).upper()


def execute_tools(
    request: OrcaAgentQueryRequest,
    planned_tools: list[str],
    audience_role: str = "FISHERMAN",
) -> tuple[
    dict[str, Any],
    list[str],
    list[OrcaAgentEvidence],
]:
    state: dict[str, Any] = {}
    executed: list[str] = []
    evidence: list[OrcaAgentEvidence] = []
    role = _role_code(audience_role)

    if "Boundary Agent" in planned_tools:
        boundary = check_boundary(
            request.latitude,
            request.longitude,
        )
        state["boundary"] = boundary
        executed.append("Boundary Agent")

        evidence.append(
            OrcaAgentEvidence(
                tool="Boundary Agent",
                label="Navigation surface",
                value=boundary.surface,
                source="ORCA GIS service",
                details={
                    "coast_distance_km":
                        boundary.coast_distance_km,
                    "demo_geofence_state":
                        boundary.status,
                    "territorial_sea": (
                        boundary.territorial_sea.status
                        if boundary.territorial_sea
                        else None
                    ),
                    "eez": (
                        boundary.eez.status
                        if boundary.eez
                        else None
                    ),
                },
            )
        )

    boundary = state.get("boundary")

    if (
        "Ocean & Weather Agent"
        in planned_tools
        and (
            boundary is None
            or boundary.surface == "WATER"
        )
    ):
        marine = fetch_marine_conditions(
            request.latitude,
            request.longitude,
        )
        state["marine"] = marine
        executed.append(
            "Ocean & Weather Agent"
        )

        evidence.extend(
            [
                OrcaAgentEvidence(
                    tool="Ocean & Weather Agent",
                    label="Wave height",
                    value=_fmt(
                        marine.wave_height_m,
                        "m",
                    ),
                    source="Open-Meteo Marine API",
                    freshness=(
                        marine.evidence[0].model_time
                        if marine.evidence
                        else None
                    ),
                ),
                OrcaAgentEvidence(
                    tool="Ocean & Weather Agent",
                    label="Wind speed",
                    value=_fmt(
                        marine.wind_speed_ms,
                        "m/s",
                    ),
                    source="Open-Meteo Weather API",
                ),
                OrcaAgentEvidence(
                    tool="Ocean & Weather Agent",
                    label="Ocean current",
                    value=_fmt(
                        marine.ocean_current_velocity_ms,
                        "m/s",
                        decimals=2,
                    ),
                    source="Open-Meteo Marine API",
                ),
            ]
        )

    if (
        "Habitat Intelligence Agent"
        in planned_tools
        and (
            boundary is None
            or boundary.surface == "WATER"
        )
    ):
        habitat = run_habitat_agent(
            request.latitude,
            request.longitude,
        )
        state["habitat"] = habitat
        executed.append(
            "Habitat Intelligence Agent"
        )

        if (
            habitat.status == "READY"
            and habitat.score is not None
        ):
            # Fishermen see a simple suitability band.
            # Researchers may see the numeric relative model score.
            if role == "RESEARCHER":
                display_value = (
                    f"{habitat.score.band} • "
                    f"{habitat.score.score_0_100:.1f}/100"
                )
            else:
                band_words = {
                    "LOW": "Less favourable",
                    "MODERATE": "Mixed",
                    "MODERATE_HIGH": "Promising",
                    "HIGH": "Strong habitat signal",
                }
                display_value = band_words.get(
                    habitat.score.band,
                    habitat.score.band,
                )

            evidence.append(
                OrcaAgentEvidence(
                    tool="Habitat Intelligence Agent",
                    label="Fishing habitat",
                    value=display_value,
                    source=(
                        "ORCA Habitat Opportunity Model v1"
                    ),
                    freshness=habitat.evaluated_at,
                    details={
                        "status": habitat.status,
                        "model_version":
                            habitat.score.model_version,
                        "data_quality":
                            habitat.score.data_quality,
                        "score_0_100": (
                            habitat.score.score_0_100
                            if role == "RESEARCHER"
                            else None
                        ),
                        "model_scope_warning":
                            habitat.model_scope_warning,
                        "source_shift_warning":
                            habitat.source_shift_warning,
                    },
                )
            )
        else:
            evidence.append(
                OrcaAgentEvidence(
                    tool="Habitat Intelligence Agent",
                    label="Fishing habitat",
                    value="Not available from fresh evidence",
                    source=(
                        "ORCA Habitat Opportunity Model v1"
                    ),
                    freshness=habitat.evaluated_at,
                    details={
                        "status": habitat.status,
                        "abstention_reasons":
                            habitat.abstention_reasons,
                        "model_scope_warning":
                            habitat.model_scope_warning,
                    },
                )
            )

        # Expose scientific provenance as evidence. The UI can keep
        # this collapsed for fishermen and expanded for researchers.
        for item in habitat.evidence:
            evidence.append(
                OrcaAgentEvidence(
                    tool="Habitat Intelligence Agent",
                    label=item.variable,
                    value=(
                        _fmt(
                            item.value,
                            item.unit or "",
                            decimals=2,
                        )
                        if item.value is not None
                        else "Unavailable"
                    ),
                    source=item.source,
                    freshness=item.observed_at,
                    details={
                        "status": item.status,
                        "age_hours": item.age_hours,
                        "note": item.note,
                    },
                )
            )

    if (
        "Route Agent" in planned_tools
        and request.destination_latitude
        is not None
        and request.destination_longitude
        is not None
        and request.cruising_speed_knots
        is not None
        and (
            boundary is None
            or boundary.surface == "WATER"
        )
    ):
        route = plan_weather_aware_route(
            request.latitude,
            request.longitude,
            request.destination_latitude,
            request.destination_longitude,
            request.cruising_speed_knots,
        )

        state["route"] = route
        executed.append("Route Agent")

        evidence.extend(
            [
                OrcaAgentEvidence(
                    tool="Route Agent",
                    label="Faster route",
                    value=(
                        f"{route.fastest.distance_nm:.1f} nm • "
                        f"{route.fastest.eta_minutes:.0f} min"
                    ),
                    source=route.data_source,
                    freshness=route.data_freshness,
                    details={
                        "exposure_score":
                            route.fastest.exposure_score,
                        "status":
                            route.fastest.route_status,
                    },
                ),
                OrcaAgentEvidence(
                    tool="Route Agent",
                    label="Lower-exposure route",
                    value=(
                        f"{route.lower_exposure.distance_nm:.1f} nm • "
                        f"{route.lower_exposure.eta_minutes:.0f} min"
                    ),
                    source=route.data_source,
                    freshness=route.data_freshness,
                    details={
                        "exposure_score":
                            route.lower_exposure.exposure_score,
                        "status":
                            route.lower_exposure.route_status,
                    },
                ),
            ]
        )

    if "PFZ Discovery Agent" in planned_tools:
        state["pfz"] = {
            "available": False,
            "source": (
                "INCOIS Potential Fishing Zone Advisory"
            ),
            "reason": (
                "The official PFZ advisory service is identified, "
                "but structured coordinate ingestion is not yet connected "
                "in this build. ORCA will not invent PFZ coordinates."
            ),
        }
        executed.append(
            "PFZ Discovery Agent"
        )

        evidence.append(
            OrcaAgentEvidence(
                tool="PFZ Discovery Agent",
                label="PFZ source",
                value=(
                    "Official INCOIS PFZ adapter pending"
                ),
                source=(
                    "INCOIS Potential Fishing Zone Advisory"
                ),
                details={
                    "coordinates_invented": False,
                },
            )
        )

    if "Risk Agent" in planned_tools:
        state["risk"] = True
        executed.append("Risk Agent")

    if (
        "Mission Feasibility Agent"
        in planned_tools
    ):
        state["mission_feasibility"] = True
        executed.append(
            "Mission Feasibility Agent"
        )

    if "Interaction Agent" in planned_tools:
        executed.append("Interaction Agent")

    return state, executed, evidence
