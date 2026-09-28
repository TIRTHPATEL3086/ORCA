from app.schemas.habitat import LiveHabitatResponse
from app.services.live_habitat_service import (
    evaluate_live_habitat,
)


def run_habitat_agent(
    latitude: float,
    longitude: float,
) -> LiveHabitatResponse:
    """
    Domain agent wrapper for ORCA's trained habitat model.

    The live service owns scientific feature acquisition, freshness
    checks and abstention. This agent does not manufacture missing
    observations or reinterpret the model as an official PFZ.
    """
    return evaluate_live_habitat(
        latitude,
        longitude,
    )
