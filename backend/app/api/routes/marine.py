import logging

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.api.dependencies import get_current_user
from app.models.user import User
from app.schemas.marine import MarineConditionsResponse
from app.services.marine_service import fetch_marine_conditions


logger = logging.getLogger(__name__)


router = APIRouter(
    prefix="/api/v1/marine",
    tags=["Marine Intelligence"],
)


@router.get(
    "/conditions",
    response_model=MarineConditionsResponse,
)
def get_conditions(
    latitude: float = Query(
        ge=-90,
        le=90,
    ),
    longitude: float = Query(
        ge=-180,
        le=180,
    ),
    current_user: User = Depends(get_current_user),
):
    del current_user

    try:
        return fetch_marine_conditions(
            latitude,
            longitude,
        )
    except Exception as exc:
        logger.exception("Live marine data fetch failed")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "Live marine data is temporarily unavailable. "
                "Retry shortly or use the last downloaded Mission Pack."
            ),
        ) from exc
