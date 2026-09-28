from typing import Any, Literal

from pydantic import BaseModel, Field


class OrcaChatTurn(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=2000)


class OrcaAgentQueryRequest(BaseModel):
    message: str = Field(min_length=2, max_length=1000)
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)

    preferred_language: str = Field(
        default="en",
        min_length=2,
        max_length=10,
    )

    history: list[OrcaChatTurn] = Field(
        default_factory=list,
        max_length=20,
    )

    destination_latitude: float | None = Field(
        default=None,
        ge=-90,
        le=90,
    )
    destination_longitude: float | None = Field(
        default=None,
        ge=-180,
        le=180,
    )
    cruising_speed_knots: float | None = Field(
        default=None,
        gt=0,
        le=80,
    )


class OrcaAgentEvidence(BaseModel):
    tool: str
    label: str
    value: str
    source: str
    freshness: str | None = None
    details: dict[str, Any] = Field(
        default_factory=dict,
    )


class OrcaAgentAction(BaseModel):
    id: str
    label: str


class OrcaAgentQueryResponse(BaseModel):
    intent: str
    detected_language: str
    response_language: str

    decision: str
    safety_state: str

    short_answer: str
    layman_explanation: str
    recommendation: str

    planned_tools: list[str]
    executed_tools: list[str]

    evidence: list[OrcaAgentEvidence]
    actions: list[OrcaAgentAction]

    context_used: bool = False

    orchestration_note: str = (
        "ORCA uses specialized agents to select deterministic marine/GIS tools. "
        "The language layer explains verified tool outputs; it does not invent "
        "scientific or safety-critical values."
    )
