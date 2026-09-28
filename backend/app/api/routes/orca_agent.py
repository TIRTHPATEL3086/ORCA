import logging

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.dependencies import get_current_user
from app.core.upstream import describe_upstream_error
from app.models.user import User
from app.schemas.orca_agent import (
    OrcaAgentQueryRequest,
    OrcaAgentQueryResponse,
)
from app.services.orca_agent_service import run_orca_agent


logger = logging.getLogger(__name__)


router = APIRouter(
    prefix="/api/v1/orca",
    tags=["ORCA Agent"],
)


def _user_role_code(
    current_user: User,
) -> str:
    raw = getattr(
        current_user,
        "role",
        "FISHERMAN",
    )

    value = getattr(
        raw,
        "value",
        raw,
    )

    return str(
        value
        or "FISHERMAN"
    ).upper()


@router.post(
    "/query",
    response_model=OrcaAgentQueryResponse,
)
def query_orca(
    data: OrcaAgentQueryRequest,
    current_user: User = Depends(get_current_user),
):
    try:
        return run_orca_agent(
            data,
            audience_role=_user_role_code(
                current_user
            ),
        )
    except Exception as exc:
        logger.exception("ORCA agent query failed")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "ORCA could not complete this answer right now. "
                f"Please try again shortly. ({describe_upstream_error(exc)})"
            ),
        ) from exc
