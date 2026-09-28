from fastapi import APIRouter, Depends, HTTPException, Query

from app.api.dependencies import get_current_user
from app.models.user import User
from app.schemas.habitat import (
    HabitatFeatureInput,
    HabitatModelHealthResponse,
    HabitatScoreResponse,
    LiveHabitatResponse,
)
from app.services.habitat_model_service import (
    get_habitat_model_health,
    score_habitat,
)
from app.services.live_habitat_service import (
    evaluate_live_habitat,
)


router = APIRouter(
    prefix="/api/v1/habitat",
    tags=["Habitat Intelligence"],
)


@router.get(
    "/model/health",
    response_model=HabitatModelHealthResponse,
)
def habitat_model_health(
    current_user: User = Depends(
        get_current_user
    ),
):
    del current_user
    return get_habitat_model_health()


@router.post(
    "/score",
    response_model=HabitatScoreResponse,
)
def habitat_score(
    data: HabitatFeatureInput,
    current_user: User = Depends(
        get_current_user
    ),
):
    del current_user

    try:
        return score_habitat(data)
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail=(
                "Habitat model inference is unavailable: "
                f"{exc}"
            ),
        ) from exc


@router.get(
    "/live",
    response_model=LiveHabitatResponse,
)
def live_habitat(
    latitude: float = Query(
        ge=5,
        le=25,
    ),
    longitude: float = Query(
        ge=65,
        le=98,
    ),
    current_user: User = Depends(
        get_current_user
    ),
):
    del current_user

    try:
        return evaluate_live_habitat(
            latitude,
            longitude,
        )
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail=(
                "Live habitat evaluation is unavailable: "
                f"{exc}"
            ),
        ) from exc
