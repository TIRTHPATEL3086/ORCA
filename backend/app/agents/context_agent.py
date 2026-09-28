from app.agents.intent_agent import (
    classify_intent,
)
from app.schemas.orca_agent import (
    OrcaChatTurn,
)


def resolve_contextual_intent(
    message: str,
    history: list[OrcaChatTurn],
) -> tuple[str, bool]:
    current = classify_intent(message)

    if current != "UNKNOWN":
        return current, False

    recent_user_messages = [
        item.content
        for item in history
        if item.role == "user"
    ][-4:]

    for previous in reversed(
        recent_user_messages
    ):
        previous_intent = classify_intent(
            previous
        )

        if previous_intent != "UNKNOWN":
            return previous_intent, True

    return "HELP", False
