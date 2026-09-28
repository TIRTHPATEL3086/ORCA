from app.agents.context_agent import (
    resolve_contextual_intent,
)
from app.agents.explanation_agent import (
    build_explanation,
)
from app.agents.language_agent import (
    detect_language,
    normalize_language,
)
from app.agents.planner_agent import (
    plan_tools,
)
from app.agents.tool_registry import (
    execute_tools,
)
from app.schemas.orca_agent import (
    OrcaAgentAction,
    OrcaAgentQueryRequest,
    OrcaAgentQueryResponse,
)


SUPPORTED_LANGUAGES = {
    "en", "hi", "mr", "gu", "te",
    "ta", "kn", "ml", "bn", "or",
}


def _actions_for_intent(
    intent: str,
) -> list[OrcaAgentAction]:
    actions = [
        OrcaAgentAction(
            id="open_sea_conditions",
            label="Sea Conditions",
        ),
        OrcaAgentAction(
            id="open_boundary",
            label="Boundary Guardian",
        ),
    ]

    if intent in {
        "ROUTE",
        "PFZ",
    }:
        actions.insert(
            0,
            OrcaAgentAction(
                id="open_plan_trip",
                label="Plan Trip",
            ),
        )

    if intent == "HABITAT":
        actions.insert(
            0,
            OrcaAgentAction(
                id="open_plan_trip",
                label="Plan Trip",
            ),
        )

    return actions


def run_orca_agent(
    request: OrcaAgentQueryRequest,
    audience_role: str = "FISHERMAN",
) -> OrcaAgentQueryResponse:
    detected_language = detect_language(
        request.message,
        request.preferred_language,
    )

    preferred = normalize_language(
        request.preferred_language
    )

    role = (
        audience_role
        or "FISHERMAN"
    ).upper()

    # Fisherman UX follows the explicitly selected app language.
    # Researchers may receive the language detected from their query.
    if role == "FISHERMAN":
        response_language = (
            preferred
            if preferred in SUPPORTED_LANGUAGES
            else "en"
        )
    else:
        response_language = (
            detected_language
            if detected_language
            in SUPPORTED_LANGUAGES
            else preferred
        )

    intent, context_used = (
        resolve_contextual_intent(
            request.message,
            request.history,
        )
    )

    has_destination = (
        request.destination_latitude
        is not None
        and request.destination_longitude
        is not None
        and request.cruising_speed_knots
        is not None
    )

    planned_tools = plan_tools(
        intent,
        has_destination,
    )

    state, executed, evidence = (
        execute_tools(
            request,
            planned_tools,
            audience_role=role,
        )
    )

    (
        decision,
        safety_state,
        short_answer,
        layman_explanation,
        recommendation,
    ) = build_explanation(
        intent,
        response_language,
        state,
        audience_role=role,
    )

    return OrcaAgentQueryResponse(
        intent=intent,
        detected_language=detected_language,
        response_language=response_language,
        decision=decision,
        safety_state=safety_state,
        short_answer=short_answer,
        layman_explanation=layman_explanation,
        recommendation=recommendation,
        planned_tools=planned_tools,
        executed_tools=executed,
        evidence=evidence,
        actions=_actions_for_intent(
            intent,
        ),
        context_used=context_used,
    )
