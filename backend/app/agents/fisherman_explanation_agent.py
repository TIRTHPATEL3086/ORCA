from __future__ import annotations

from typing import Any


SUPPORTED = {
    "en", "hi", "mr", "gu", "te",
    "ta", "kn", "ml", "bn", "or",
}


def _fmt(
    value: float | None,
    unit: str,
    decimals: int = 1,
) -> str:
    if value is None:
        return "—"
    return f"{value:.{decimals}f} {unit}"


def _eta(minutes: float | None) -> str:
    if minutes is None:
        return "—"

    total = max(0, round(minutes))
    hours = total // 60
    mins = total % 60

    if hours:
        return f"{hours}h {mins}m"

    return f"{mins}m"


# Keep the fisherman response deliberately short:
# Decision -> one reason -> one direct action.
#
# Researchers continue using the richer explanation_agent.
TEXT = {
    "en": {
        "land_d": "No — this is not a sea position.",
        "land_w": "ORCA cannot plan a fishing mission from a point on land.",
        "land_a": "Turn on vessel GPS or use the clearly labelled offshore demo point.",

        "sea_yes_d": "Yes — current checked sea conditions look suitable.",
        "sea_yes_w": "Waves are {wave} and wind is {wind}; no high-risk condition is detected here.",
        "sea_yes_a": "Open Plan Trip to compare the safer route before starting the mission.",

        "sea_caution_d": "No — do not continue with the current plan yet.",
        "sea_caution_w": "The current sea exposure needs caution: waves {wave}, wind {wind}.",
        "sea_caution_a": "Open Plan Trip and choose a lower-exposure route or wait for better conditions.",

        "sea_no_d": "No — do not proceed now.",
        "sea_no_w": "ORCA detected a high marine-risk condition at this location.",
        "sea_no_a": "Stay in safer waters and use Plan Trip only after conditions improve.",

        "boundary_clear_d": "Yes — you are currently inside the checked safe operating area.",
        "boundary_clear_w": "No immediate boundary or restricted-zone crossing is detected.",
        "boundary_clear_a": "Continue with Boundary Guardian active so ORCA can warn before a crossing.",

        "boundary_near_d": "Change course now — you are approaching a boundary.",
        "boundary_near_w": "Your present position is close enough that continuing the same course can create a crossing risk.",
        "boundary_near_a": "Open Boundary Guardian and follow the safer side of the boundary.",

        "boundary_inside_d": "No — move out of the restricted/boundary area.",
        "boundary_inside_w": "Your current position is inside a configured restricted or boundary-risk zone.",
        "boundary_inside_a": "Turn toward permitted waters now and keep Boundary Guardian open.",

        "route_need_d": "Choose where you want to go first.",
        "route_need_w": "A marine route needs a destination and vessel cruising speed.",
        "route_need_a": "Open Plan Trip, select the destination, then let ORCA calculate the route.",

        "route_ready_d": "Yes — your marine route is ready.",
        "route_ready_w": "ORCA compared route distance with marine exposure instead of treating the sea like a road.",
        "route_ready_a": "Use the lower-exposure option when conditions are worse; fastest ETA is {fast_eta}, safer-route ETA is {safe_eta}.",

        "pfz_d": "Do not choose a fishing zone from unverified coordinates.",
        "pfz_w": "The live official PFZ coordinate feed is not connected in this build, so ORCA will not invent a location.",
        "pfz_a": "Open Plan Trip for the labelled demo workflow; real mode will use verified PFZ points when the feed is connected.",

        "habitat_high_d": "Yes — this area shows a strong fishing-habitat signal.",
        "habitat_promising_d": "Yes — this area looks promising for fishing habitat.",
        "habitat_mixed_d": "Possible — conditions are mixed here.",
        "habitat_low_d": "No — this area currently looks less favourable.",
        "habitat_w": "ORCA combined sea temperature, chlorophyll, wind and seabed depth for this area.",
        "habitat_a": "Open Plan Trip to compare this area with a safer or more favourable option before starting.",

        "habitat_abstain_d": "Do not choose this area yet.",
        "habitat_abstain_w": "Fresh fish-location evidence is incomplete, so ORCA will not guess.",
        "habitat_abstain_a": "Open Plan Trip and choose another verified option; ORCA will rescore when fresh data is available.",

        "safety_yes_d": "Yes — you can proceed on the current evidence.",
        "safety_yes_w": "No high marine-risk or immediate boundary warning is detected at this position.",
        "safety_yes_a": "Open Plan Trip now; ORCA can still show a more efficient or lower-exposure route.",

        "safety_caution_d": "No — do not depart on the current plan.",
        "safety_caution_w": "ORCA detected moderate marine exposure or boundary proximity.",
        "safety_caution_a": "Use Plan Trip to switch to a lower-exposure route or delay departure.",

        "safety_no_d": "No — do not depart now.",
        "safety_no_w": "A high marine-risk or restricted-zone condition is present.",
        "safety_no_a": "Remain in safer waters and let ORCA recalculate when the risk reduces.",

        "help_d": "Tell ORCA what you want to do.",
        "help_w": "You can ask about safety, fishing areas, sea conditions, boundaries or routes.",
        "help_a": "Speak naturally or tap one of the quick questions.",
    },

    "hi": {
        "land_d": "नहीं — यह समुद्र की स्थिति नहीं है।",
        "land_w": "ORCA जमीन की लोकेशन से मछली पकड़ने की यात्रा योजना नहीं बना सकता।",
        "land_a": "नाव का GPS चालू करें या साफ़ तौर पर चिन्हित ऑफशोर डेमो पॉइंट चुनें।",
        "sea_yes_d": "हाँ — अभी जाँची गई समुद्री स्थिति जाने के लिए ठीक दिख रही है।",
        "sea_yes_w": "लहरें {wave} और हवा {wind} है; यहाँ कोई उच्च जोखिम नहीं मिला।",
        "sea_yes_a": "मिशन शुरू करने से पहले Plan Trip खोलकर सुरक्षित मार्ग चुनें।",
        "sea_caution_d": "नहीं — अभी इसी योजना पर आगे न बढ़ें।",
        "sea_caution_w": "समुद्री स्थिति सावधानी मांगती है: लहरें {wave}, हवा {wind}।",
        "sea_caution_a": "Plan Trip खोलें और कम जोखिम वाला मार्ग चुनें या स्थिति बेहतर होने तक रुकें।",
        "sea_no_d": "नहीं — अभी समुद्र में आगे न बढ़ें।",
        "sea_no_w": "ORCA ने इस स्थान पर उच्च समुद्री जोखिम पाया है।",
        "sea_no_a": "सुरक्षित पानी में रहें और स्थिति सुधरने पर ही Plan Trip से आगे बढ़ें।",
        "boundary_clear_d": "हाँ — अभी आप जाँचे गए सुरक्षित क्षेत्र में हैं।",
        "boundary_clear_w": "तुरंत कोई सीमा या प्रतिबंधित क्षेत्र पार होने का जोखिम नहीं मिला।",
        "boundary_clear_a": "Boundary Guardian चालू रखें ताकि सीमा से पहले चेतावनी मिल सके।",
        "boundary_near_d": "अभी दिशा बदलें — आप सीमा के पास जा रहे हैं।",
        "boundary_near_w": "इसी दिशा में चलते रहने पर सीमा पार होने का जोखिम है।",
        "boundary_near_a": "Boundary Guardian खोलें और सुरक्षित तरफ़ का मार्ग लें।",
        "boundary_inside_d": "नहीं — प्रतिबंधित/सीमा क्षेत्र से बाहर निकलें।",
        "boundary_inside_w": "आपकी वर्तमान लोकेशन एक जोखिम वाले सीमा क्षेत्र के अंदर है।",
        "boundary_inside_a": "अनुमत पानी की ओर मुड़ें और Boundary Guardian खुला रखें।",
        "route_need_d": "पहले बताइए आपको कहाँ जाना है।",
        "route_need_w": "समुद्री मार्ग के लिए गंतव्य और नाव की गति चाहिए।",
        "route_need_a": "Plan Trip खोलें, गंतव्य चुनें और ORCA को मार्ग बनाने दें।",
        "route_ready_d": "हाँ — आपका समुद्री मार्ग तैयार है।",
        "route_ready_w": "ORCA ने केवल दूरी नहीं, बल्कि समुद्री जोखिम भी देखकर मार्ग तुलना की है।",
        "route_ready_a": "खराब स्थिति में कम जोखिम वाला मार्ग चुनें; तेज ETA {fast_eta}, सुरक्षित ETA {safe_eta}।",
        "pfz_d": "असत्यापित लोकेशन से मछली पकड़ने का क्षेत्र न चुनें।",
        "pfz_w": "इस बिल्ड में लाइव आधिकारिक PFZ coordinates अभी जुड़े नहीं हैं; ORCA नकली लोकेशन नहीं देगा।",
        "pfz_a": "डेमो के लिए Plan Trip खोलें; लाइव मोड में सत्यापित PFZ जुड़ने पर वही इस्तेमाल होगा।",
        "habitat_high_d": "हाँ — इस क्षेत्र में मजबूत मछली-अनुकूल संकेत हैं।",
        "habitat_promising_d": "हाँ — यह क्षेत्र मछली पकड़ने के लिए आशाजनक दिख रहा है।",
        "habitat_mixed_d": "संभव है — यहाँ स्थिति मिश्रित है।",
        "habitat_low_d": "नहीं — यह क्षेत्र अभी कम अनुकूल दिख रहा है।",
        "habitat_w": "ORCA ने तापमान, क्लोरोफिल, हवा और समुद्र की गहराई को साथ देखा है।",
        "habitat_a": "मिशन शुरू करने से पहले Plan Trip में दूसरे सुरक्षित या बेहतर विकल्प से तुलना करें।",
        "habitat_abstain_d": "अभी इस क्षेत्र को न चुनें।",
        "habitat_abstain_w": "ताज़ा मछली-स्थान डेटा पूरा नहीं है, इसलिए ORCA अनुमान नहीं लगाएगा।",
        "habitat_abstain_a": "Plan Trip खोलकर दूसरा सत्यापित विकल्प चुनें; ताज़ा डेटा आने पर ORCA फिर जाँच करेगा।",
        "safety_yes_d": "हाँ — अभी उपलब्ध जानकारी के अनुसार आप आगे बढ़ सकते हैं।",
        "safety_yes_w": "इस स्थान पर उच्च समुद्री जोखिम या तुरंत सीमा चेतावनी नहीं मिली।",
        "safety_yes_a": "अब Plan Trip खोलें; ORCA अधिक सुरक्षित या बेहतर मार्ग भी दिखा सकता है।",
        "safety_caution_d": "नहीं — मौजूदा योजना पर अभी रवाना न हों।",
        "safety_caution_w": "ORCA ने मध्यम समुद्री जोखिम या सीमा की नज़दीकी पाई है।",
        "safety_caution_a": "Plan Trip से कम जोखिम वाला मार्ग चुनें या प्रस्थान देर से करें।",
        "safety_no_d": "नहीं — अभी रवाना न हों।",
        "safety_no_w": "उच्च समुद्री जोखिम या प्रतिबंधित क्षेत्र की स्थिति मौजूद है।",
        "safety_no_a": "सुरक्षित पानी में रहें और जोखिम कम होने पर ORCA से मार्ग दोबारा बनवाएँ।",
        "help_d": "ORCA को बताइए आपको क्या करना है।",
        "help_w": "आप सुरक्षा, मछली क्षेत्र, समुद्री स्थिति, सीमा या मार्ग पूछ सकते हैं।",
        "help_a": "अपनी भाषा में बोलें या नीचे दिए त्वरित प्रश्न पर टैप करें।",
    },

    "mr": {
        "land_d": "नाही — हे समुद्रातील स्थान नाही.",
        "land_w": "जमिनीवरील स्थानावरून ORCA मासेमारी मिशन आखू शकत नाही.",
        "land_a": "बोटीचा GPS सुरू करा किंवा स्पष्टपणे चिन्हांकित ऑफशोअर डेमो पॉइंट वापरा.",
        "sea_yes_d": "हो — सध्या तपासलेली समुद्रस्थिती जाण्यास योग्य दिसते.",
        "sea_yes_w": "लाटा {wave} आणि वारा {wind} आहे; येथे उच्च धोका आढळला नाही.",
        "sea_yes_a": "मिशन सुरू करण्यापूर्वी Plan Trip उघडून अधिक सुरक्षित मार्ग निवडा.",
        "sea_caution_d": "नाही — सध्याच्या योजनेने अजून पुढे जाऊ नका.",
        "sea_caution_w": "समुद्रस्थितीत सावधगिरी आवश्यक आहे: लाटा {wave}, वारा {wind}.",
        "sea_caution_a": "Plan Trip मधून कमी जोखमीचा मार्ग निवडा किंवा स्थिती सुधारण्याची वाट पहा.",
        "sea_no_d": "नाही — आत्ता पुढे जाऊ नका.",
        "sea_no_w": "ORCA ला या ठिकाणी उच्च समुद्री धोका आढळला आहे.",
        "sea_no_a": "सुरक्षित पाण्यात रहा आणि स्थिती सुधारल्यानंतरच Plan Trip वापरा.",
        "boundary_clear_d": "हो — सध्या तुम्ही तपासलेल्या सुरक्षित क्षेत्रात आहात.",
        "boundary_clear_w": "तत्काळ सीमा किंवा प्रतिबंधित क्षेत्र ओलांडण्याचा धोका दिसत नाही.",
        "boundary_clear_a": "Boundary Guardian सुरू ठेवा म्हणजे सीमा ओलांडण्यापूर्वी इशारा मिळेल.",
        "boundary_near_d": "आत्ताच दिशा बदला — तुम्ही सीमेकडे जात आहात.",
        "boundary_near_w": "हीच दिशा ठेवली तर सीमा ओलांडण्याचा धोका वाढू शकतो.",
        "boundary_near_a": "Boundary Guardian उघडा आणि सुरक्षित बाजूचा मार्ग घ्या.",
        "boundary_inside_d": "नाही — प्रतिबंधित/सीमा क्षेत्रातून बाहेर या.",
        "boundary_inside_w": "तुमचे सध्याचे स्थान जोखमीच्या सीमा क्षेत्रात आहे.",
        "boundary_inside_a": "परवानगी असलेल्या पाण्याकडे वळा आणि Boundary Guardian सुरू ठेवा.",
        "route_need_d": "प्रथम कुठे जायचे ते निवडा.",
        "route_need_w": "समुद्री मार्गासाठी गंतव्य आणि बोटीचा वेग आवश्यक आहे.",
        "route_need_a": "Plan Trip उघडा, गंतव्य निवडा आणि ORCA ला मार्ग मोजू द्या.",
        "route_ready_d": "हो — तुमचा समुद्री मार्ग तयार आहे.",
        "route_ready_w": "ORCA ने फक्त अंतर नाही तर समुद्री जोखीमही विचारात घेऊन मार्गांची तुलना केली.",
        "route_ready_a": "स्थिती खराब असल्यास कमी जोखमीचा मार्ग घ्या; जलद ETA {fast_eta}, सुरक्षित ETA {safe_eta}.",
        "pfz_d": "असत्यापित ठिकाणावरून मासेमारी क्षेत्र निवडू नका.",
        "pfz_w": "या बिल्डमध्ये अधिकृत लाइव्ह PFZ coordinates अजून जोडलेले नाहीत; ORCA खोटे ठिकाण देणार नाही.",
        "pfz_a": "डेमोसाठी Plan Trip उघडा; लाइव्ह मोडमध्ये पडताळलेले PFZ जोडल्यावर तेच वापरले जातील.",
        "habitat_high_d": "हो — या भागात मजबूत मासेमारी-अनुकूल संकेत आहेत.",
        "habitat_promising_d": "हो — हा भाग मासेमारीसाठी आशादायक दिसतो.",
        "habitat_mixed_d": "शक्यता आहे — इथली स्थिती मिश्र आहे.",
        "habitat_low_d": "नाही — हा भाग सध्या कमी अनुकूल दिसतो.",
        "habitat_w": "ORCA ने समुद्राचे तापमान, क्लोरोफिल, वारा आणि खोली एकत्र तपासली.",
        "habitat_a": "मिशन सुरू करण्यापूर्वी Plan Trip मध्ये दुसऱ्या सुरक्षित किंवा अधिक अनुकूल पर्यायाशी तुलना करा.",
        "habitat_abstain_d": "आत्ता हा भाग निवडू नका.",
        "habitat_abstain_w": "ताजे मासेमारी स्थान डेटा अपूर्ण आहे, त्यामुळे ORCA अंदाज लावणार नाही.",
        "habitat_abstain_a": "Plan Trip उघडून दुसरा पडताळलेला पर्याय निवडा; ताजा डेटा आल्यावर ORCA पुन्हा तपासेल.",
        "safety_yes_d": "हो — सध्याच्या उपलब्ध माहितीनुसार तुम्ही पुढे जाऊ शकता.",
        "safety_yes_w": "या ठिकाणी उच्च समुद्री धोका किंवा तत्काळ सीमा इशारा आढळला नाही.",
        "safety_yes_a": "आता Plan Trip उघडा; ORCA अधिक सुरक्षित किंवा कार्यक्षम मार्गही दाखवू शकतो.",
        "safety_caution_d": "नाही — सध्याच्या योजनेने अजून निघू नका.",
        "safety_caution_w": "ORCA ला मध्यम समुद्री धोका किंवा सीमा जवळ असल्याचे आढळले.",
        "safety_caution_a": "Plan Trip मधून कमी जोखमीचा मार्ग निवडा किंवा प्रस्थान उशिरा करा.",
        "safety_no_d": "नाही — आत्ता निघू नका.",
        "safety_no_w": "उच्च समुद्री धोका किंवा प्रतिबंधित क्षेत्राची स्थिती आहे.",
        "safety_no_a": "सुरक्षित पाण्यात रहा आणि धोका कमी झाल्यावर ORCA कडून मार्ग पुन्हा मोजा.",
        "help_d": "ORCA ला सांगा तुम्हाला काय करायचे आहे.",
        "help_w": "तुम्ही सुरक्षा, मासेमारी क्षेत्र, समुद्रस्थिती, सीमा किंवा मार्ग विचारू शकता.",
        "help_a": "तुमच्या भाषेत बोला किंवा खालील जलद प्रश्नावर टॅप करा.",
    },

    # For the remaining supported languages we keep the same concise
    # decision structure in the selected language. These strings are
    # intentionally short for voice playback.
    "gu": {
        "land_d": "ના — આ સમુદ્રનું સ્થાન નથી.",
        "land_w": "જમીન પરથી ORCA માછીમારી મિશન પ્લાન કરી શકતું નથી.",
        "land_a": "બોટનું GPS ચાલુ કરો અથવા સ્પષ્ટ offshore demo point વાપરો.",
        "sea_yes_d": "હા — હાલની તપાસેલી સમુદ્ર સ્થિતિ જવા માટે યોગ્ય લાગે છે.",
        "sea_yes_w": "મોજાં {wave} અને પવન {wind} છે; ઊંચો જોખમ મળ્યો નથી.",
        "sea_yes_a": "મિશન શરૂ કરતા પહેલા Plan Tripમાં વધુ સુરક્ષિત માર્ગ પસંદ કરો.",
        "sea_caution_d": "ના — હાલની યોજના પ્રમાણે હમણાં આગળ ન વધો.",
        "sea_caution_w": "સમુદ્ર સ્થિતિમાં સાવચેતી જરૂરી છે: મોજાં {wave}, પવન {wind}.",
        "sea_caution_a": "Plan Tripમાં ઓછા જોખમનો માર્ગ પસંદ કરો અથવા સ્થિતિ સુધરે ત્યાં સુધી રાહ જુઓ.",
        "sea_no_d": "ના — હમણાં આગળ ન વધો.",
        "sea_no_w": "ORCAએ અહીં ઊંચો સમુદ્રી જોખમ શોધ્યો છે.",
        "sea_no_a": "સુરક્ષિત પાણીમાં રહો અને સ્થિતિ સુધરે પછી જ Plan Trip વાપરો.",
        "boundary_clear_d": "હા — હાલમાં તમે તપાસેલા સુરક્ષિત વિસ્તારમાં છો.",
        "boundary_clear_w": "તાત્કાલિક boundary અથવા restricted-zone crossing મળ્યું નથી.",
        "boundary_clear_a": "Boundary Guardian ચાલુ રાખો જેથી crossing પહેલાં ચેતવણી મળે.",
        "boundary_near_d": "હમણાં દિશા બદલો — તમે boundary નજીક જઈ રહ્યા છો.",
        "boundary_near_w": "આ જ દિશામાં ચાલવાથી crossing નો જોખમ છે.",
        "boundary_near_a": "Boundary Guardian ખોલો અને સુરક્ષિત બાજુનો માર્ગ લો.",
        "boundary_inside_d": "ના — restricted/boundary વિસ્તારમાંથી બહાર આવો.",
        "boundary_inside_w": "તમારી હાલની સ્થિતિ જોખમી boundary વિસ્તારમાં છે.",
        "boundary_inside_a": "પરવાનગીવાળા પાણી તરફ વાળો અને Boundary Guardian ચાલુ રાખો.",
        "route_need_d": "પહેલા ક્યાં જવું છે તે પસંદ કરો.",
        "route_need_w": "સમુદ્રી માર્ગ માટે destination અને boat speed જોઈએ.",
        "route_need_a": "Plan Trip ખોલો, destination પસંદ કરો અને ORCAને route ગણવા દો.",
        "route_ready_d": "હા — તમારો સમુદ્રી route તૈયાર છે.",
        "route_ready_w": "ORCAએ distance સાથે marine exposure પણ સરખાવ્યું છે.",
        "route_ready_a": "ખરાબ સ્થિતિમાં lower-exposure route લો; fast ETA {fast_eta}, safer ETA {safe_eta}.",
        "pfz_d": "અચકાસેલ coordinates પરથી fishing zone પસંદ ન કરો.",
        "pfz_w": "લાઇવ official PFZ coordinates હજુ જોડાયેલા નથી; ORCA ખોટું location નહીં આપે.",
        "pfz_a": "Demo માટે Plan Trip ખોલો; live modeમાં verified PFZ જ વપરાશે.",
        "habitat_high_d": "હા — અહીં મજબૂત fishing-habitat signal છે.",
        "habitat_promising_d": "હા — આ વિસ્તાર માછીમારી માટે આશાસ્પદ લાગે છે.",
        "habitat_mixed_d": "શક્ય છે — અહીં conditions mixed છે.",
        "habitat_low_d": "ના — આ વિસ્તાર હાલ ઓછો અનુકૂળ લાગે છે.",
        "habitat_w": "ORCAએ temperature, chlorophyll, wind અને depth સાથે તપાસ્યા છે.",
        "habitat_a": "Mission પહેલા Plan Tripમાં બીજા વધુ સુરક્ષિત અથવા અનુકૂળ વિકલ્પ સાથે સરખાવો.",
        "habitat_abstain_d": "હમણાં આ વિસ્તાર પસંદ ન કરો.",
        "habitat_abstain_w": "તાજું fishing-location evidence પૂરતું નથી, તેથી ORCA અંદાજ નહીં કરે.",
        "habitat_abstain_a": "Plan Tripમાં બીજો verified વિકલ્પ પસંદ કરો; fresh data આવ્યા પછી ORCA ફરી તપાસશે.",
        "safety_yes_d": "હા — હાલની માહિતી મુજબ તમે આગળ વધી શકો છો.",
        "safety_yes_w": "અહીં ઊંચો marine risk અથવા તાત્કાલિક boundary warning નથી.",
        "safety_yes_a": "હવે Plan Trip ખોલો; ORCA વધુ સુરક્ષિત અથવા efficient route બતાવી શકે છે.",
        "safety_caution_d": "ના — હાલની યોજના પર હમણાં ન નીકળો.",
        "safety_caution_w": "ORCAએ moderate marine exposure અથવા boundary proximity શોધી છે.",
        "safety_caution_a": "Plan Tripમાંથી lower-exposure route લો અથવા departure મોડું કરો.",
        "safety_no_d": "ના — હમણાં ન નીકળો.",
        "safety_no_w": "ઊંચો marine risk અથવા restricted-zone condition છે.",
        "safety_no_a": "સુરક્ષિત પાણીમાં રહો અને જોખમ ઓછું થયા પછી route ફરી ગણાવો.",
        "help_d": "ORCAને કહો તમને શું કરવું છે.",
        "help_w": "તમે safety, fishing area, sea conditions, boundary અથવા route પૂછો.",
        "help_a": "તમારી ભાષામાં બોલો અથવા quick question પસંદ કરો.",
    },

    "te": {
        "land_d": "కాదు — ఇది సముద్రంలోని స్థానం కాదు.",
        "land_w": "భూమి మీద ఉన్న స్థానం నుంచి ORCA fishing missionను ప్లాన్ చేయలేదు.",
        "land_a": "బోటు GPS ఆన్ చేయండి లేదా స్పష్టంగా గుర్తించిన offshore demo point ఉపయోగించండి.",
        "sea_yes_d": "అవును — ప్రస్తుతం పరీక్షించిన సముద్ర పరిస్థితులు వెళ్లడానికి అనుకూలంగా ఉన్నాయి.",
        "sea_yes_w": "అలలు {wave}, గాలి {wind}; ఇక్కడ అధిక ప్రమాదం కనిపించలేదు.",
        "sea_yes_a": "మిషన్ ప్రారంభించే ముందు Plan Tripలో సురక్షిత మార్గాన్ని ఎంచుకోండి.",
        "sea_caution_d": "కాదు — ప్రస్తుత ప్లాన్‌తో ఇప్పుడే ముందుకు వెళ్లవద్దు.",
        "sea_caution_w": "సముద్ర పరిస్థితులకు జాగ్రత్త అవసరం: అలలు {wave}, గాలి {wind}.",
        "sea_caution_a": "Plan Tripలో తక్కువ exposure route ఎంచుకోండి లేదా పరిస్థితులు మెరుగయ్యే వరకు వేచి ఉండండి.",
        "sea_no_d": "కాదు — ఇప్పుడే ముందుకు వెళ్లవద్దు.",
        "sea_no_w": "ORCA ఈ స్థానంలో అధిక సముద్ర ప్రమాదాన్ని గుర్తించింది.",
        "sea_no_a": "సురక్షిత జలాల్లో ఉండండి; పరిస్థితులు మెరుగైన తర్వాత Plan Trip వాడండి.",
        "boundary_clear_d": "అవును — మీరు ప్రస్తుతం తనిఖీ చేసిన సురక్షిత ప్రాంతంలో ఉన్నారు.",
        "boundary_clear_w": "తక్షణ boundary లేదా restricted-zone crossing ప్రమాదం లేదు.",
        "boundary_clear_a": "crossingకు ముందు హెచ్చరిక కోసం Boundary Guardianను ఆన్‌లో ఉంచండి.",
        "boundary_near_d": "ఇప్పుడే దిశ మార్చండి — మీరు boundaryకు దగ్గరవుతున్నారు.",
        "boundary_near_w": "ఇదే దిశలో కొనసాగితే crossing ప్రమాదం పెరుగుతుంది.",
        "boundary_near_a": "Boundary Guardian తెరిచి సురక్షిత వైపు మార్గాన్ని ఎంచుకోండి.",
        "boundary_inside_d": "కాదు — restricted/boundary ప్రాంతం నుంచి బయటకు వెళ్లండి.",
        "boundary_inside_w": "మీ ప్రస్తుత స్థానం boundary-risk ప్రాంతంలో ఉంది.",
        "boundary_inside_a": "అనుమతించిన జలాల వైపు తిరిగి Boundary Guardianను ఆన్‌లో ఉంచండి.",
        "route_need_d": "ముందుగా ఎక్కడికి వెళ్లాలో ఎంచుకోండి.",
        "route_need_w": "సముద్ర మార్గానికి destination మరియు boat speed అవసరం.",
        "route_need_a": "Plan Trip తెరిచి destination ఎంచుకుని ORCAతో route లెక్కించండి.",
        "route_ready_d": "అవును — మీ సముద్ర మార్గం సిద్ధంగా ఉంది.",
        "route_ready_w": "ORCA distanceతో పాటు marine exposureను కూడా పోల్చింది.",
        "route_ready_a": "పరిస్థితులు కఠినంగా ఉంటే lower-exposure route వాడండి; fast ETA {fast_eta}, safer ETA {safe_eta}.",
        "pfz_d": "verify చేయని coordinates నుంచి fishing zone ఎంచుకోవద్దు.",
        "pfz_w": "live official PFZ coordinates ఇంకా కనెక్ట్ కాలేదు; ORCA locationను కల్పించదు.",
        "pfz_a": "Demo కోసం Plan Trip తెరవండి; live modeలో verified PFZ మాత్రమే వాడుతుంది.",
        "habitat_high_d": "అవును — ఈ ప్రాంతంలో బలమైన fishing-habitat signal ఉంది.",
        "habitat_promising_d": "అవును — ఈ ప్రాంతం fishingకు ఆశాజనకంగా ఉంది.",
        "habitat_mixed_d": "సాధ్యమే — ఇక్కడ పరిస్థితులు మిశ్రమంగా ఉన్నాయి.",
        "habitat_low_d": "కాదు — ఈ ప్రాంతం ప్రస్తుతం తక్కువ అనుకూలంగా ఉంది.",
        "habitat_w": "ORCA temperature, chlorophyll, wind మరియు depthను కలిపి పరిశీలించింది.",
        "habitat_a": "Missionకు ముందు Plan Tripలో మరో సురక్షిత లేదా అనుకూల optionతో పోల్చండి.",
        "habitat_abstain_d": "ఇప్పుడే ఈ ప్రాంతాన్ని ఎంచుకోవద్దు.",
        "habitat_abstain_w": "తాజా fishing-location evidence పూర్తి కాదు; ORCA ఊహించదు.",
        "habitat_abstain_a": "Plan Tripలో మరో verified option ఎంచుకోండి; fresh data వచ్చినప్పుడు ORCA మళ్లీ తనిఖీ చేస్తుంది.",
        "safety_yes_d": "అవును — ప్రస్తుతం ఉన్న ఆధారాల ప్రకారం మీరు వెళ్లవచ్చు.",
        "safety_yes_w": "ఈ స్థానంలో high marine risk లేదా immediate boundary warning లేదు.",
        "safety_yes_a": "ఇప్పుడు Plan Trip తెరవండి; ORCA మరింత సురక్షిత లేదా efficient route చూపుతుంది.",
        "safety_caution_d": "కాదు — ప్రస్తుత ప్లాన్‌తో ఇప్పుడే బయలుదేరవద్దు.",
        "safety_caution_w": "ORCA moderate marine exposure లేదా boundary proximity గుర్తించింది.",
        "safety_caution_a": "Plan Tripలో lower-exposure route ఎంచుకోండి లేదా departure ఆలస్యం చేయండి.",
        "safety_no_d": "కాదు — ఇప్పుడే బయలుదేరవద్దు.",
        "safety_no_w": "High marine risk లేదా restricted-zone condition ఉంది.",
        "safety_no_a": "సురక్షిత జలాల్లో ఉండి risk తగ్గిన తర్వాత route మళ్లీ లెక్కించండి.",
        "help_d": "మీరు ఏం చేయాలనుకుంటున్నారో ORCAకి చెప్పండి.",
        "help_w": "Safety, fishing area, sea conditions, boundary లేదా route గురించి అడగండి.",
        "help_a": "మీ భాషలో మాట్లాడండి లేదా quick questionపై ట్యాప్ చేయండి.",
    },
}


# For ta/kn/ml/bn/or we provide concise native decision-first core text.
# Dynamic values remain simple and numeric.
TEXT.update({
    "ta": {
        **TEXT["en"],
        "sea_yes_d": "ஆம் — தற்போது சரிபார்த்த கடல் நிலை செல்ல ஏற்றதாக உள்ளது.",
        "sea_caution_d": "இல்லை — தற்போதைய திட்டத்தில் இப்போது செல்ல வேண்டாம்.",
        "sea_no_d": "இல்லை — இப்போது கடலுக்கு செல்ல வேண்டாம்.",
        "safety_yes_d": "ஆம் — தற்போதைய தகவல்படி நீங்கள் செல்லலாம்.",
        "safety_caution_d": "இல்லை — தற்போதைய திட்டத்தில் புறப்பட வேண்டாம்.",
        "safety_no_d": "இல்லை — இப்போது புறப்பட வேண்டாம்.",
        "boundary_clear_d": "ஆம் — நீங்கள் தற்போது சரிபார்த்த பாதுகாப்பான பகுதியில் உள்ளீர்கள்.",
        "boundary_near_d": "இப்போது திசை மாற்றுங்கள் — நீங்கள் எல்லைக்கு அருகில் செல்கிறீர்கள்.",
        "boundary_inside_d": "இல்லை — கட்டுப்படுத்தப்பட்ட பகுதியிலிருந்து வெளியே செல்லுங்கள்.",
        "route_need_d": "முதலில் செல்ல வேண்டிய இடத்தைத் தேர்ந்தெடுக்கவும்.",
        "route_ready_d": "ஆம் — உங்கள் கடல் வழி தயாராக உள்ளது.",
        "habitat_high_d": "ஆம் — இந்த பகுதியில் வலுவான மீன்பிடி habitat signal உள்ளது.",
        "habitat_promising_d": "ஆம் — இந்த பகுதி மீன்பிடிக்கு நம்பிக்கையளிக்கிறது.",
        "habitat_mixed_d": "சாத்தியம் — இங்கு நிலை கலந்துள்ளது.",
        "habitat_low_d": "இல்லை — இந்த பகுதி தற்போது குறைவாக ஏற்றுள்ளது.",
        "habitat_abstain_d": "இப்போது இந்த பகுதியைத் தேர்ந்தெடுக்க வேண்டாம்.",
        "help_d": "நீங்கள் என்ன செய்ய விரும்புகிறீர்கள் என்பதை ORCA-விடம் சொல்லுங்கள்.",
    },
    "kn": {
        **TEXT["en"],
        "sea_yes_d": "ಹೌದು — ಈಗ ಪರಿಶೀಲಿಸಿದ ಸಮುದ್ರ ಪರಿಸ್ಥಿತಿ ಹೋಗಲು ಸೂಕ್ತವಾಗಿದೆ.",
        "sea_caution_d": "ಇಲ್ಲ — ಈಗಿನ ಯೋಜನೆಯಂತೆ ಹೊರಡಬೇಡಿ.",
        "sea_no_d": "ಇಲ್ಲ — ಈಗ ಸಮುದ್ರಕ್ಕೆ ಹೋಗಬೇಡಿ.",
        "safety_yes_d": "ಹೌದು — ಈಗಿನ ಮಾಹಿತಿಯಂತೆ ನೀವು ಮುಂದುವರಿಯಬಹುದು.",
        "safety_caution_d": "ಇಲ್ಲ — ಈಗಿನ ಯೋಜನೆಯಂತೆ ಹೊರಡಬೇಡಿ.",
        "safety_no_d": "ಇಲ್ಲ — ಈಗ ಹೊರಡಬೇಡಿ.",
        "boundary_clear_d": "ಹೌದು — ನೀವು ಈಗ ಪರಿಶೀಲಿಸಿದ ಸುರಕ್ಷಿತ ಪ್ರದೇಶದಲ್ಲಿದ್ದೀರಿ.",
        "boundary_near_d": "ಈಗಲೇ ದಿಕ್ಕು ಬದಲಿಸಿ — ನೀವು ಗಡಿಯತ್ತ ಸಾಗುತ್ತಿದ್ದೀರಿ.",
        "boundary_inside_d": "ಇಲ್ಲ — ನಿರ್ಬಂಧಿತ ಪ್ರದೇಶದಿಂದ ಹೊರಬನ್ನಿ.",
        "route_need_d": "ಮೊದಲು ಗಮ್ಯಸ್ಥಾನವನ್ನು ಆಯ್ಕೆ ಮಾಡಿ.",
        "route_ready_d": "ಹೌದು — ನಿಮ್ಮ ಸಮುದ್ರ ಮಾರ್ಗ ಸಿದ್ಧವಾಗಿದೆ.",
        "habitat_high_d": "ಹೌದು — ಇಲ್ಲಿ ಬಲವಾದ ಮೀನುಗಾರಿಕೆ habitat signal ಇದೆ.",
        "habitat_promising_d": "ಹೌದು — ಈ ಪ್ರದೇಶ ಮೀನುಗಾರಿಕೆಗೆ ಆಶಾದಾಯಕವಾಗಿದೆ.",
        "habitat_mixed_d": "ಸಾಧ್ಯ — ಇಲ್ಲಿ ಪರಿಸ್ಥಿತಿ ಮಿಶ್ರವಾಗಿದೆ.",
        "habitat_low_d": "ಇಲ್ಲ — ಈ ಪ್ರದೇಶ ಈಗ ಕಡಿಮೆ ಅನುಕೂಲಕರವಾಗಿದೆ.",
        "habitat_abstain_d": "ಈಗ ಈ ಪ್ರದೇಶವನ್ನು ಆಯ್ಕೆ ಮಾಡಬೇಡಿ.",
        "help_d": "ನೀವು ಏನು ಮಾಡಲು ಬಯಸುತ್ತೀರಿ ಎಂದು ORCAಗೆ ಹೇಳಿ.",
    },
    "ml": {
        **TEXT["en"],
        "sea_yes_d": "അതെ — ഇപ്പോൾ പരിശോധിച്ച കടൽസ്ഥിതി പോകാൻ അനുയോജ്യമാണ്.",
        "sea_caution_d": "ഇല്ല — നിലവിലെ പദ്ധതിപ്രകാരം ഇപ്പോൾ പോകരുത്.",
        "sea_no_d": "ഇല്ല — ഇപ്പോൾ കടലിലേക്ക് പോകരുത്.",
        "safety_yes_d": "അതെ — നിലവിലെ വിവരമനുസരിച്ച് നിങ്ങൾക്ക് മുന്നോട്ട് പോകാം.",
        "safety_caution_d": "ഇല്ല — നിലവിലെ പദ്ധതിയിൽ ഇപ്പോൾ പുറപ്പെടരുത്.",
        "safety_no_d": "ഇല്ല — ഇപ്പോൾ പുറപ്പെടരുത്.",
        "boundary_clear_d": "അതെ — നിങ്ങൾ ഇപ്പോൾ പരിശോധിച്ച സുരക്ഷിത മേഖലയിലാണ്.",
        "boundary_near_d": "ഇപ്പോൾ ദിശ മാറ്റുക — നിങ്ങൾ അതിർത്തിയിലേക്ക് അടുക്കുന്നു.",
        "boundary_inside_d": "ഇല്ല — നിയന്ത്രിത മേഖലയിൽ നിന്ന് പുറത്തുകടക്കുക.",
        "route_need_d": "ആദ്യം പോകേണ്ട സ്ഥലം തിരഞ്ഞെടുക്കുക.",
        "route_ready_d": "അതെ — നിങ്ങളുടെ കടൽപാത തയ്യാറാണ്.",
        "habitat_high_d": "അതെ — ഇവിടെ ശക്തമായ മത്സ്യബന്ധന habitat signal ഉണ്ട്.",
        "habitat_promising_d": "അതെ — ഈ പ്രദേശം മത്സ്യബന്ധനത്തിന് പ്രതീക്ഷ നൽകുന്നു.",
        "habitat_mixed_d": "സാധ്യതയുണ്ട് — ഇവിടെ സാഹചര്യങ്ങൾ മിശ്രമാണ്.",
        "habitat_low_d": "ഇല്ല — ഈ പ്രദേശം ഇപ്പോൾ കുറച്ച് അനുയോജ്യമാണ്.",
        "habitat_abstain_d": "ഇപ്പോൾ ഈ പ്രദേശം തിരഞ്ഞെടുക്കരുത്.",
        "help_d": "നിങ്ങൾ എന്ത് ചെയ്യണമെന്ന് ORCAയോട് പറയുക.",
    },
    "bn": {
        **TEXT["en"],
        "sea_yes_d": "হ্যাঁ — এখন যাচাই করা সমুদ্রের অবস্থা যাওয়ার জন্য উপযুক্ত।",
        "sea_caution_d": "না — বর্তমান পরিকল্পনা অনুযায়ী এখন এগোবেন না।",
        "sea_no_d": "না — এখন সমুদ্রে যাবেন না।",
        "safety_yes_d": "হ্যাঁ — বর্তমান তথ্য অনুযায়ী আপনি এগোতে পারেন।",
        "safety_caution_d": "না — বর্তমান পরিকল্পনায় এখন রওনা দেবেন না।",
        "safety_no_d": "না — এখন রওনা দেবেন না।",
        "boundary_clear_d": "হ্যাঁ — আপনি বর্তমানে যাচাই করা নিরাপদ এলাকায় আছেন।",
        "boundary_near_d": "এখনই দিক বদলান — আপনি সীমার কাছে যাচ্ছেন।",
        "boundary_inside_d": "না — সীমাবদ্ধ এলাকা থেকে বেরিয়ে আসুন।",
        "route_need_d": "আগে গন্তব্য নির্বাচন করুন।",
        "route_ready_d": "হ্যাঁ — আপনার সামুদ্রিক রুট প্রস্তুত।",
        "habitat_high_d": "হ্যাঁ — এখানে শক্তিশালী মাছ ধরার habitat signal আছে।",
        "habitat_promising_d": "হ্যাঁ — এই এলাকা মাছ ধরার জন্য আশাব্যঞ্জক।",
        "habitat_mixed_d": "সম্ভব — এখানে পরিস্থিতি মিশ্র।",
        "habitat_low_d": "না — এই এলাকা এখন কম অনুকূল।",
        "habitat_abstain_d": "এখন এই এলাকা নির্বাচন করবেন না।",
        "help_d": "আপনি কী করতে চান ORCA-কে বলুন।",
    },
    "or": {
        **TEXT["en"],
        "sea_yes_d": "ହଁ — ବର୍ତ୍ତମାନ ଯାଞ୍ଚ ହୋଇଥିବା ସମୁଦ୍ର ଅବସ୍ଥା ଯିବା ପାଇଁ ଉପଯୁକ୍ତ।",
        "sea_caution_d": "ନା — ବର୍ତ୍ତମାନର ଯୋଜନାରେ ଏବେ ଆଗକୁ ଯାଆନ୍ତୁ ନାହିଁ।",
        "sea_no_d": "ନା — ଏବେ ସମୁଦ୍ରକୁ ଯାଆନ୍ତୁ ନାହିଁ।",
        "safety_yes_d": "ହଁ — ବର୍ତ୍ତମାନ ତଥ୍ୟ ଅନୁସାରେ ଆପଣ ଆଗକୁ ଯାଇପାରିବେ।",
        "safety_caution_d": "ନା — ବର୍ତ୍ତମାନର ଯୋଜନାରେ ଏବେ ବାହାରନ୍ତୁ ନାହିଁ।",
        "safety_no_d": "ନା — ଏବେ ବାହାରନ୍ତୁ ନାହିଁ।",
        "boundary_clear_d": "ହଁ — ଆପଣ ବର୍ତ୍ତମାନ ଯାଞ୍ଚ ହୋଇଥିବା ସୁରକ୍ଷିତ ଅଞ୍ଚଳରେ ଅଛନ୍ତି।",
        "boundary_near_d": "ଏବେ ଦିଗ ବଦଳାନ୍ତୁ — ଆପଣ ସୀମା ନିକଟକୁ ଯାଉଛନ୍ତି।",
        "boundary_inside_d": "ନା — ନିଷିଦ୍ଧ ଅଞ୍ଚଳରୁ ବାହାରନ୍ତୁ।",
        "route_need_d": "ପ୍ରଥମେ ଗନ୍ତବ୍ୟ ସ୍ଥାନ ବାଛନ୍ତୁ।",
        "route_ready_d": "ହଁ — ଆପଣଙ୍କ ସମୁଦ୍ର ମାର୍ଗ ପ୍ରସ୍ତୁତ।",
        "habitat_high_d": "ହଁ — ଏଠାରେ ଶକ୍ତିଶାଳୀ fishing habitat signal ଅଛି।",
        "habitat_promising_d": "ହଁ — ଏହି ଅଞ୍ଚଳ ମାଛଧରା ପାଇଁ ଆଶାଜନକ।",
        "habitat_mixed_d": "ସମ୍ଭବ — ଏଠାରେ ଅବସ୍ଥା ମିଶ୍ର।",
        "habitat_low_d": "ନା — ଏହି ଅଞ୍ଚଳ ବର୍ତ୍ତମାନ କମ୍ ଉପଯୁକ୍ତ।",
        "habitat_abstain_d": "ଏବେ ଏହି ଅଞ୍ଚଳ ବାଛନ୍ତୁ ନାହିଁ।",
        "help_d": "ଆପଣ କଣ କରିବାକୁ ଚାହୁଁଛନ୍ତି ORCAକୁ କହନ୍ତୁ।",
    },
})


def _t(
    language: str,
    key: str,
    **kwargs,
) -> str:
    lang = (
        language
        if language in SUPPORTED
        else "en"
    )

    table = TEXT.get(
        lang,
        TEXT["en"],
    )

    template = table.get(
        key,
        TEXT["en"][key],
    )

    return template.format(
        **kwargs
    )


def build_fisherman_explanation(
    intent: str,
    language: str,
    state: dict[str, Any],
) -> tuple[
    str,
    str,
    str,
    str,
    str,
]:
    boundary = state.get("boundary")
    marine = state.get("marine")
    route = state.get("route")
    habitat = state.get("habitat")

    if (
        boundary is not None
        and boundary.surface == "LAND"
    ):
        return (
            "DO_NOT_PROCEED",
            "INFO",
            _t(language, "land_d"),
            _t(language, "land_w"),
            _t(language, "land_a"),
        )

    if intent == "SEA_CONDITIONS":
        status = (
            marine.screening_status
            if marine is not None
            else "UNKNOWN"
        )

        wave = _fmt(
            marine.wave_height_m
            if marine is not None
            else None,
            "m",
        )

        wind = _fmt(
            marine.wind_speed_ms
            if marine is not None
            else None,
            "m/s",
        )

        if status == "HIGH":
            return (
                "DO_NOT_PROCEED",
                "HIGH",
                _t(language, "sea_no_d"),
                _t(language, "sea_no_w"),
                _t(language, "sea_no_a"),
            )

        if status == "CAUTION":
            return (
                "CHANGE_PLAN",
                "CAUTION",
                _t(language, "sea_caution_d"),
                _t(
                    language,
                    "sea_caution_w",
                    wave=wave,
                    wind=wind,
                ),
                _t(language, "sea_caution_a"),
            )

        return (
            "PROCEED",
            "LOW",
            _t(language, "sea_yes_d"),
            _t(
                language,
                "sea_yes_w",
                wave=wave,
                wind=wind,
            ),
            _t(language, "sea_yes_a"),
        )

    if intent == "BOUNDARY":
        status = (
            boundary.status
            if boundary is not None
            else "CLEAR"
        )

        if status == "INSIDE":
            return (
                "DO_NOT_PROCEED",
                "HIGH",
                _t(language, "boundary_inside_d"),
                _t(language, "boundary_inside_w"),
                _t(language, "boundary_inside_a"),
            )

        if status == "NEAR":
            return (
                "CHANGE_COURSE",
                "CAUTION",
                _t(language, "boundary_near_d"),
                _t(language, "boundary_near_w"),
                _t(language, "boundary_near_a"),
            )

        return (
            "PROCEED",
            "LOW",
            _t(language, "boundary_clear_d"),
            _t(language, "boundary_clear_w"),
            _t(language, "boundary_clear_a"),
        )

    if intent == "SAFETY":
        boundary_status = (
            boundary.status
            if boundary is not None
            else "CLEAR"
        )

        marine_status = (
            marine.screening_status
            if marine is not None
            else "UNKNOWN"
        )

        if (
            boundary_status == "INSIDE"
            or marine_status == "HIGH"
        ):
            return (
                "DO_NOT_DEPART",
                "HIGH",
                _t(language, "safety_no_d"),
                _t(language, "safety_no_w"),
                _t(language, "safety_no_a"),
            )

        if (
            boundary_status == "NEAR"
            or marine_status == "CAUTION"
        ):
            return (
                "CHANGE_PLAN",
                "CAUTION",
                _t(language, "safety_caution_d"),
                _t(language, "safety_caution_w"),
                _t(language, "safety_caution_a"),
            )

        return (
            "PROCEED",
            "LOW",
            _t(language, "safety_yes_d"),
            _t(language, "safety_yes_w"),
            _t(language, "safety_yes_a"),
        )

    if intent == "ROUTE":
        if route is None:
            return (
                "NEED_DESTINATION",
                "INFO",
                _t(language, "route_need_d"),
                _t(language, "route_need_w"),
                _t(language, "route_need_a"),
            )

        return (
            "ROUTES_READY",
            "INFO",
            _t(language, "route_ready_d"),
            _t(language, "route_ready_w"),
            _t(
                language,
                "route_ready_a",
                fast_eta=_eta(
                    route.fastest.eta_minutes
                ),
                safe_eta=_eta(
                    route.lower_exposure.eta_minutes
                ),
            ),
        )

    if intent == "PFZ":
        return (
            "PFZ_DATA_REQUIRED",
            "INFO",
            _t(language, "pfz_d"),
            _t(language, "pfz_w"),
            _t(language, "pfz_a"),
        )

    if intent == "HABITAT":
        if (
            habitat is None
            or habitat.status != "READY"
            or habitat.score is None
        ):
            return (
                "HABITAT_ABSTAINED",
                "INFO",
                _t(language, "habitat_abstain_d"),
                _t(language, "habitat_abstain_w"),
                _t(language, "habitat_abstain_a"),
            )

        band = habitat.score.band

        if band == "HIGH":
            key = "habitat_high_d"
            decision = "PROCEED_TO_COMPARE"
        elif band == "MODERATE_HIGH":
            key = "habitat_promising_d"
            decision = "PROCEED_TO_COMPARE"
        elif band == "MODERATE":
            key = "habitat_mixed_d"
            decision = "COMPARE_OPTIONS"
        else:
            key = "habitat_low_d"
            decision = "CHOOSE_ANOTHER_AREA"

        return (
            decision,
            "INFO",
            _t(language, key),
            _t(language, "habitat_w"),
            _t(language, "habitat_a"),
        )

    return (
        "INFO",
        "INFO",
        _t(language, "help_d"),
        _t(language, "help_w"),
        _t(language, "help_a"),
    )
