ROUTE_WORDS = {
    "route", "trip", "destination", "navigate", "navigation", "sail",
    "go north", "go south", "go east", "go west", "kilometre", "kilometer", "km",
    "मार्ग", "यात्रा", "रस्ता", "प्रवास", "दिशा",
    "માર્ગ", "પ્રવાસ", "દિશા",
    "మార్గం", "ప్రయాణం", "దిశ",
    "வழி", "பயணம்", "திசை",
    "ಮಾರ್ಗ", "ಪ್ರಯಾಣ", "ದಿಕ್ಕು",
    "റൂട്ട്", "യാത്ര", "ദിശ",
    "রুট", "যাত্রা", "দিক",
    "ମାର୍ଗ", "ଯାତ୍ରା", "ଦିଗ",
}

PFZ_WORDS = {
    "pfz", "potential fishing zone", "fishing zone", "fish zone",
    "where should i fish", "where can i fish", "nearest fishing zone",
    "मत्स्य क्षेत्र", "मछली क्षेत्र", "फिशिंग ज़ोन",
    "मासेमारी क्षेत्र", "मच्छी क्षेत्र",
    "માછીમારી ઝોન", "માછલી ઝોન",
    "ఫిషింగ్ జోన్", "చేపల ప్రాంతం",
    "மீன்பிடி பகுதி",
    "ಮೀನುಗಾರಿಕೆ ವಲಯ",
    "മത്സ്യബന്ധന മേഖല",
    "মাছ ধরার অঞ্চল",
    "ମାଛଧରା ଅଞ୍ଚଳ",
}

# Habitat intent is deliberately separate from official PFZ.
# This captures "is this water promising?" rather than "where is the PFZ?".
HABITAT_WORDS = {
    "fish habitat", "fishing habitat", "habitat opportunity",
    "good fishing area", "good fishing spot", "promising fishing area",
    "good place to fish", "productive water", "productive waters",
    "fish availability", "fishing opportunity",
    "chlorophyll", "chlorophyll-a", "chl", "sst and chlorophyll",
    "favourable sst", "favorable sst", "thermal front",
    "ocean productivity", "productive zone",
    "मछली के लिए अच्छा", "मछली मिलने", "क्लोरोफिल",
    "मासेमारीसाठी चांगले", "मासे मिळण्य", "क्लोरोफिल",
    "માછલી માટે સારું", "ક્લોરોફિલ",
    "చేపలకు అనుకూలం", "క్లోరోఫిల్",
    "மீன் கிடைக்கும்", "குளோரோபில்",
    "ಮೀನು ಸಿಗುವ", "ಕ್ಲೋರೊಫಿಲ್",
    "മത്സ്യം ലഭിക്കുന്ന", "ക്ലോറോഫിൽ",
    "মাছ পাওয়ার", "ক্লোরোফিল",
    "ମାଛ ମିଳିବ", "କ୍ଲୋରୋଫିଲ",
}

BOUNDARY_WORDS = {
    "boundary", "border", "eez", "territorial", "coast", "coastline",
    "restricted", "zone", "international waters",
    "सीमा", "किनारा", "तट", "प्रतिबंधित",
    "सिमा", "किनारा", "प्रतिबंधित",
    "સીમા", "કિનારો", "પ્રતિબંધિત",
    "సరిహద్దు", "తీరం", "నిషేధిత",
    "எல்லை", "கடற்கரை",
    "ಗಡಿ", "ಕರಾವಳಿ",
    "അതിർത്തി", "തീരം",
    "সীমা", "উপকূল",
    "ସୀମା", "ତଟ",
}

CONDITION_WORDS = {
    "wave", "waves", "wind", "weather", "sea", "current", "swell",
    "temperature", "conditions", "condition", "tide",
    "लहर", "लहरें", "हवा", "मौसम", "समुद्र", "करंट", "ज्वार",
    "लाटा", "वारा", "हवामान", "समुद्र", "प्रवाह",
    "મોજાં", "પવન", "હવામાન", "સમુદ્ર", "પ્રવાહ",
    "అలలు", "గాలి", "వాతావరణం", "సముద్రం", "ప్రవాహం",
    "அலை", "காற்று", "வானிலை", "கடல்",
    "ಅಲೆ", "ಗಾಳಿ", "ಹವಾಮಾನ", "ಸಮುದ್ರ",
    "തിര", "കാറ്റ്", "കാലാവസ്ഥ", "കടൽ",
    "ঢেউ", "বাতাস", "আবহাওয়া", "সমুদ্র",
    "ତରଙ୍ଗ", "ପବନ", "ପାଣିପାଗ", "ସମୁଦ୍ର",
}

SAFETY_WORDS = {
    "safe", "safety", "danger", "dangerous", "risk", "risky",
    "go now", "leave now", "can i go", "should i go", "venture",
    "सुरक्षित", "खतरा", "जोखिम", "जा सकता", "जाऊ",
    "धोका", "जोखीम",
    "સુરક્ષિત", "જોખમ", "જઈ શકું",
    "సురక్షితం", "ప్రమాదం", "వెళ్లవచ్చా",
    "பாதுகாப்பு", "ஆபத்து",
    "ಸುರಕ್ಷಿತ", "ಅಪಾಯ",
    "സുരക്ഷിത", "അപകടം",
    "নিরাপদ", "ঝুঁকি",
    "ସୁରକ୍ଷିତ", "ବିପଦ",
}


def _contains_any(
    text: str,
    phrases: set[str],
) -> bool:
    return any(
        phrase in text
        for phrase in phrases
    )


def classify_intent(
    message: str,
) -> str:
    text = message.casefold()

    # PFZ stays first so "nearest PFZ with high chlorophyll"
    # is still treated as an official-PFZ request.
    if _contains_any(text, PFZ_WORDS):
        return "PFZ"

    if _contains_any(text, HABITAT_WORDS):
        return "HABITAT"

    if _contains_any(text, ROUTE_WORDS):
        return "ROUTE"

    if _contains_any(text, SAFETY_WORDS):
        return "SAFETY"

    if (
        _contains_any(text, BOUNDARY_WORDS)
        and _contains_any(
            text,
            CONDITION_WORDS,
        )
    ):
        return "SAFETY"

    if _contains_any(text, BOUNDARY_WORDS):
        return "BOUNDARY"

    if _contains_any(
        text,
        CONDITION_WORDS,
    ):
        return "SEA_CONDITIONS"

    return "UNKNOWN"
