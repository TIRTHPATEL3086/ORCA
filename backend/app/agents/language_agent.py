SUPPORTED_LANGUAGES = {
    "en", "hi", "mr", "gu", "te", "ta", "kn", "ml", "bn", "or"
}


def normalize_language(value: str | None) -> str:
    if not value:
        return "en"

    code = value.strip().lower()

    aliases = {
        "english": "en",
        "hindi": "hi",
        "marathi": "mr",
        "gujarati": "gu",
        "telugu": "te",
        "tamil": "ta",
        "kannada": "kn",
        "malayalam": "ml",
        "bengali": "bn",
        "odia": "or",
        "oriya": "or",
    }

    return aliases.get(code, code)


def detect_language(
    text: str,
    preferred_language: str,
) -> str:
    preferred = normalize_language(
        preferred_language
    )

    try:
        import langid

        detected, confidence = langid.classify(
            text
        )

        if (
            detected in SUPPORTED_LANGUAGES
            and confidence > -40
        ):
            return detected
    except Exception:
        pass

    if preferred in SUPPORTED_LANGUAGES:
        return preferred

    return "en"
