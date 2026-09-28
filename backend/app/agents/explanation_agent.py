from __future__ import annotations



from typing import Any





TEXT = {

    "en": {

        "conditions_short": "Current sea conditions are {state}.",

        "conditions_why": (

            "Waves are {wave}, wind is {wind}, and ocean current is {current}. "

            "These values come from ORCA's live marine/weather tools."

        ),

        "conditions_action": (

            "Check the detailed Sea Conditions screen and official INCOIS/IMD "

            "advisories before departure."

        ),

        "boundary_short": "Your current maritime-boundary state is {state}.",

        "boundary_why": (

            "You are on water. Approximate coast distance is {coast}. "

            "Territorial-sea reference is {territorial}; EEZ reference is {eez}; "

            "demo restricted-zone state is {zone}."

        ),

        "boundary_action": "Open Boundary Guardian for the map and source details.",

        "safety_low_short": "Current conditions look acceptable with caution.",

        "safety_low_why": (

            "ORCA did not detect a high marine-condition or demo-geofence warning "

            "at this point. Waves are {wave} and wind is {wind}."

        ),

        "safety_low_action": (

            "This is not a guaranteed 'safe' declaration. Check official advisories "

            "and reassess before departure."

        ),

        "safety_caution_short": "Use caution before departing.",

        "safety_caution_why": (

            "ORCA detected moderate marine exposure or boundary proximity. "

            "Current screening state is {state}."

        ),

        "safety_caution_action": (

            "Review Sea Conditions and Boundary Guardian before deciding to depart."

        ),

        "safety_high_short": "Departure is not recommended from the current evidence.",

        "safety_high_why": (

            "ORCA detected a high marine-condition or geofence warning. "

            "Current screening state is {state}."

        ),

        "safety_high_action": (

            "Do not rely on ORCA alone. Follow official INCOIS/IMD/local authority guidance."

        ),

        "land_short": "This location is on land, not a marine operating point.",

        "land_why": "ORCA cannot evaluate a sea mission from an inland position.",

        "land_action": "Use your vessel position on water or enable the labelled offshore demo point.",

        "route_short": "I can plan the marine route once a destination is selected.",

        "route_why": (

            "A route needs a real water destination and vessel speed. ORCA will then "

            "compare faster and lower-exposure paths using waves, wind, current and geofences."

        ),

        "route_action": "Open Plan Trip and choose a destination or PFZ candidate.",

        "route_ready_short": "Two weather-aware marine route options are ready.",

        "route_ready_why": (

            "Faster route ETA: {fast_eta}. Lower-exposure route ETA: {low_eta}. "

            "Both are water-only paths using the current marine grid."

        ),

        "route_ready_action": "Open Plan Trip to compare the routes and start mission tracking.",

        "pfz_short": "PFZ recommendation is not yet available from a structured official feed.",

        "pfz_why": (

            "ORCA has identified INCOIS as the authoritative PFZ source, but this build "

            "does not yet have reliable PFZ coordinates. ORCA will not fabricate fishing zones."

        ),

        "pfz_action": (

            "Use the official INCOIS PFZ advisory until the structured PFZ adapter is connected."

        ),

        "help_short": "Ask ORCA about sea conditions, safety, boundaries, PFZs or route planning.",

        "help_why": "ORCA chooses specialist tools and explains their verified outputs.",

        "help_action": "Try one of the suggested questions below.",

    },

    "hi": {

        "conditions_short": "वर्तमान समुद्री स्थिति {state} है।",

        "conditions_why": "लहरें {wave}, हवा {wind} और समुद्री धारा {current} है। ये आंकड़े ORCA के लाइव समुद्री/मौसम टूल से आते हैं।",

        "conditions_action": "रवाना होने से पहले Sea Conditions और आधिकारिक INCOIS/IMD सलाह देखें।",

        "boundary_short": "वर्तमान समुद्री सीमा स्थिति {state} है।",

        "boundary_why": "आप पानी पर हैं। तट की अनुमानित दूरी {coast} है। प्रादेशिक समुद्र: {territorial}; EEZ: {eez}; डेमो प्रतिबंधित क्षेत्र: {zone}।",

        "boundary_action": "मानचित्र और स्रोत देखने के लिए Boundary Guardian खोलें।",

        "safety_low_short": "अभी की स्थिति सावधानी के साथ स्वीकार्य लगती है।",

        "safety_low_why": "ORCA को इस स्थान पर कोई उच्च समुद्री या डेमो-जियोफेंस चेतावनी नहीं मिली। लहरें {wave} और हवा {wind} है।",

        "safety_low_action": "इसे पूर्ण सुरक्षित घोषणा न मानें। रवाना होने से पहले आधिकारिक सलाह देखें।",

        "safety_caution_short": "रवाना होने से पहले सावधानी रखें।",

        "safety_caution_why": "ORCA ने मध्यम समुद्री जोखिम या सीमा निकटता पाई। वर्तमान स्थिति {state} है।",

        "safety_caution_action": "निर्णय से पहले Sea Conditions और Boundary Guardian देखें।",

        "safety_high_short": "मौजूदा प्रमाण के आधार पर अभी रवाना होना उचित नहीं है।",

        "safety_high_why": "ORCA ने उच्च समुद्री जोखिम या जियोफेंस चेतावनी पाई। वर्तमान स्थिति {state} है।",

        "safety_high_action": "आधिकारिक INCOIS/IMD और स्थानीय प्राधिकरण की सलाह का पालन करें।",

        "land_short": "यह स्थान जमीन पर है, समुद्री संचालन बिंदु नहीं।",

        "land_why": "ORCA जमीन की स्थिति से समुद्री मिशन का मूल्यांकन नहीं कर सकता।",

        "land_action": "पानी पर नाव की स्थिति उपयोग करें या लेबल वाला ऑफशोर डेमो बिंदु चुनें।",

        "route_short": "गंतव्य चुनते ही मैं समुद्री मार्ग बना सकता हूँ।",

        "route_why": "मार्ग के लिए पानी पर वास्तविक गंतव्य और नाव की गति चाहिए। ORCA लहर, हवा, धारा और जियोफेंस के आधार पर मार्गों की तुलना करेगा।",

        "route_action": "Plan Trip खोलें और गंतव्य या PFZ उम्मीदवार चुनें।",

        "route_ready_short": "दो मौसम-आधारित समुद्री मार्ग तैयार हैं।",

        "route_ready_why": "तेज मार्ग ETA {fast_eta}। कम-एक्सपोजर मार्ग ETA {low_eta}।",

        "route_ready_action": "मार्ग तुलना और मिशन ट्रैकिंग के लिए Plan Trip खोलें।",

        "pfz_short": "संरचित आधिकारिक फीड से PFZ सिफारिश अभी उपलब्ध नहीं है।",

        "pfz_why": "ORCA ने INCOIS को आधिकारिक PFZ स्रोत माना है, लेकिन विश्वसनीय PFZ निर्देशांक अभी जुड़े नहीं हैं। ORCA नकली क्षेत्र नहीं बनाएगा।",

        "pfz_action": "संरचित PFZ एडाप्टर जुड़ने तक आधिकारिक INCOIS PFZ सलाह उपयोग करें।",

        "help_short": "समुद्री स्थिति, सुरक्षा, सीमा, PFZ या मार्ग के बारे में पूछें।",

        "help_why": "ORCA विशेषज्ञ टूल चुनता है और सत्यापित परिणाम समझाता है।",

        "help_action": "नीचे दिए सुझाए प्रश्नों में से एक पूछें।",

    },

    "mr": {

        "conditions_short": "सध्याची समुद्री स्थिती {state} आहे.",

        "conditions_why": "लाटा {wave}, वारा {wind} आणि समुद्री प्रवाह {current} आहे. ही माहिती ORCA च्या लाइव्ह marine/weather tools मधून येते.",

        "conditions_action": "निघण्यापूर्वी Sea Conditions आणि अधिकृत INCOIS/IMD सूचना तपासा.",

        "boundary_short": "सध्याची समुद्री सीमा स्थिती {state} आहे.",

        "boundary_why": "तुम्ही पाण्यावर आहात. किनाऱ्याचे अंदाजे अंतर {coast} आहे. प्रादेशिक समुद्र: {territorial}; EEZ: {eez}; डेमो प्रतिबंधित क्षेत्र: {zone}.",

        "boundary_action": "नकाशा आणि स्रोतासाठी Boundary Guardian उघडा.",

        "safety_low_short": "सध्याची स्थिती सावधगिरीने स्वीकारण्यासारखी दिसते.",

        "safety_low_why": "ORCA ला उच्च समुद्री धोका किंवा डेमो-जिओफेन्स चेतावणी आढळली नाही. लाटा {wave} आणि वारा {wind} आहे.",

        "safety_low_action": "हे पूर्ण सुरक्षिततेचे प्रमाणपत्र नाही. निघण्यापूर्वी अधिकृत सूचना तपासा.",

        "safety_caution_short": "निघण्यापूर्वी सावधगिरी बाळगा.",

        "safety_caution_why": "ORCA ने मध्यम समुद्री exposure किंवा सीमा जवळीक ओळखली. स्थिती {state} आहे.",

        "safety_caution_action": "निर्णयापूर्वी Sea Conditions आणि Boundary Guardian तपासा.",

        "safety_high_short": "सध्याच्या पुराव्यानुसार आत्ता निघणे शिफारसीय नाही.",

        "safety_high_why": "ORCA ने उच्च समुद्री स्थिती किंवा जिओफेन्स चेतावणी ओळखली. स्थिती {state} आहे.",

        "safety_high_action": "अधिकृत INCOIS/IMD आणि स्थानिक प्राधिकरणांच्या सूचनांचे पालन करा.",

        "land_short": "हे स्थान जमिनीवर आहे; समुद्री ऑपरेशन पॉइंट नाही.",

        "land_why": "ORCA जमिनीवरील स्थानावरून समुद्री मिशनचे मूल्यांकन करू शकत नाही.",

        "land_action": "पाण्यावरचे बोटीचे स्थान वापरा किंवा लेबल केलेला ऑफशोर डेमो पॉइंट वापरा.",

        "route_short": "गंतव्य निवडल्यानंतर मी समुद्री मार्ग तयार करू शकतो.",

        "route_why": "मार्गासाठी पाण्यावरचे खरे गंतव्य आणि बोटीचा वेग आवश्यक आहे. ORCA लाटा, वारा, प्रवाह आणि जिओफेन्स वापरेल.",

        "route_action": "Plan Trip उघडा आणि गंतव्य किंवा PFZ उमेदवार निवडा.",

        "route_ready_short": "दोन weather-aware समुद्री मार्ग तयार आहेत.",

        "route_ready_why": "जलद मार्ग ETA {fast_eta}. कमी-exposure मार्ग ETA {low_eta}.",

        "route_ready_action": "मार्ग तुलना आणि मिशन ट्रॅकिंगसाठी Plan Trip उघडा.",

        "pfz_short": "संरचित अधिकृत फीडमधून PFZ शिफारस अजून उपलब्ध नाही.",

        "pfz_why": "ORCA ने INCOIS हा अधिकृत PFZ स्रोत ओळखला आहे, पण विश्वसनीय PFZ coordinates अजून जोडलेले नाहीत. ORCA बनावट झोन तयार करणार नाही.",

        "pfz_action": "संरचित PFZ adapter जोडला जाईपर्यंत अधिकृत INCOIS PFZ advisory वापरा.",

        "help_short": "समुद्री स्थिती, सुरक्षा, सीमा, PFZ किंवा मार्गाबद्दल विचारा.",

        "help_why": "ORCA विशेषज्ञ tools निवडतो आणि पडताळलेले outputs समजावतो.",

        "help_action": "खालील सुचवलेल्या प्रश्नांपैकी एक विचारा.",

    },

    "gu": {

        "conditions_short": "હાલની સમુદ્રી સ્થિતિ {state} છે.",

        "conditions_why": "મોજાં {wave}, પવન {wind} અને સમુદ્રી પ્રવાહ {current} છે. આ માહિતી ORCAના લાઇવ marine/weather toolsમાંથી આવે છે.",

        "conditions_action": "રવાના થતા પહેલાં Sea Conditions અને અધિકૃત INCOIS/IMD સલાહ જુઓ.",

        "boundary_short": "હાલની સમુદ્રી સીમા સ્થિતિ {state} છે.",

        "boundary_why": "તમે પાણી પર છો. કિનારાની અંદાજિત દૂરી {coast} છે. Territorial sea: {territorial}; EEZ: {eez}; demo restricted zone: {zone}.",

        "boundary_action": "નકશો અને સ્રોત માટે Boundary Guardian ખોલો.",

        "safety_low_short": "હાલની સ્થિતિ સાવચેતી સાથે સ્વીકાર્ય લાગે છે.",

        "safety_low_why": "ORCAને ઉચ્ચ સમુદ્રી જોખમ અથવા demo geofence ચેતવણી મળી નથી. મોજાં {wave} અને પવન {wind} છે.",

        "safety_low_action": "આ સંપૂર્ણ સુરક્ષાની ખાતરી નથી. રવાના થતા પહેલાં અધિકૃત સલાહ તપાસો.",

        "safety_caution_short": "રવાના થતાં પહેલાં સાવચેતી રાખો.",

        "safety_caution_why": "ORCAએ મધ્યમ સમુદ્રી exposure અથવા boundary proximity શોધી. સ્થિતિ {state} છે.",

        "safety_caution_action": "નિર્ણય પહેલાં Sea Conditions અને Boundary Guardian તપાસો.",

        "safety_high_short": "હાલના પુરાવા મુજબ અત્યારે રવાના થવું ભલામણ કરાતું નથી.",

        "safety_high_why": "ORCAએ ઊંચી સમુદ્રી સ્થિતિ અથવા geofence ચેતવણી શોધી. સ્થિતિ {state} છે.",

        "safety_high_action": "અધિકૃત INCOIS/IMD અને સ્થાનિક સત્તાની સલાહ અનુસરો.",

        "land_short": "આ સ્થાન જમીન પર છે; સમુદ્રી ઓપરેશન પોઈન્ટ નથી.",

        "land_why": "ORCA જમીન પરથી સમુદ્રી મિશનનું મૂલ્યાંકન કરી શકતું નથી.",

        "land_action": "પાણી પરની બોટની સ્થિતિ અથવા લેબલ કરેલું offshore demo point વાપરો.",

        "route_short": "ગંતવ્ય પસંદ કર્યા પછી હું સમુદ્રી માર્ગ બનાવી શકું.",

        "route_why": "માર્ગ માટે પાણી પરનું વાસ્તવિક ગંતવ્ય અને બોટની ગતિ જોઈએ. ORCA મોજાં, પવન, પ્રવાહ અને geofence વાપરે છે.",

        "route_action": "Plan Trip ખોલો અને ગંતવ્ય અથવા PFZ candidate પસંદ કરો.",

        "route_ready_short": "બે weather-aware સમુદ્રી માર્ગ તૈયાર છે.",

        "route_ready_why": "ઝડપી માર્ગ ETA {fast_eta}. ઓછા-exposure માર્ગ ETA {low_eta}.",

        "route_ready_action": "માર્ગ સરખામણી અને mission tracking માટે Plan Trip ખોલો.",

        "pfz_short": "Structured official feedમાંથી PFZ recommendation હજી ઉપલબ્ધ નથી.",

        "pfz_why": "ORCAએ INCOISને authoritative PFZ source તરીકે ઓળખ્યું છે, પણ વિશ્વસનીય PFZ coordinates હજી જોડાયા નથી. ORCA ખોટા zone બનાવશે નહીં.",

        "pfz_action": "Structured PFZ adapter જોડાય ત્યાં સુધી official INCOIS PFZ advisory વાપરો.",

        "help_short": "સમુદ્રી સ્થિતિ, સુરક્ષા, સીમા, PFZ અથવા માર્ગ વિશે પૂછો.",

        "help_why": "ORCA specialist tools પસંદ કરીને verified outputs સમજાવે છે.",

        "help_action": "નીચેના સૂચિત પ્રશ્નોમાંથી એક પૂછો.",

    },

    "te": {

        "conditions_short": "ప్రస్తుత సముద్ర పరిస్థితి {state}.",

        "conditions_why": "అలలు {wave}, గాలి {wind}, సముద్ర ప్రవాహం {current}. ఇవి ORCA live marine/weather tools నుంచి వస్తాయి.",

        "conditions_action": "బయలుదేరే ముందు Sea Conditions మరియు అధికారిక INCOIS/IMD సూచనలు చూడండి.",

        "boundary_short": "ప్రస్తుత సముద్ర సరిహద్దు స్థితి {state}.",

        "boundary_why": "మీరు నీటిపై ఉన్నారు. తీరానికి అంచనా దూరం {coast}. Territorial sea: {territorial}; EEZ: {eez}; demo restricted zone: {zone}.",

        "boundary_action": "మ్యాప్ మరియు మూలాల కోసం Boundary Guardian తెరవండి.",

        "safety_low_short": "ప్రస్తుత పరిస్థితులు జాగ్రత్తతో ఆమోదయోగ్యంగా కనిపిస్తున్నాయి.",

        "safety_low_why": "ORCA అధిక సముద్ర ప్రమాదం లేదా demo geofence హెచ్చరికను గుర్తించలేదు. అలలు {wave}, గాలి {wind}.",

        "safety_low_action": "ఇది పూర్తి భద్రత హామీ కాదు. బయలుదేరే ముందు అధికారిక సూచనలు చూడండి.",

        "safety_caution_short": "బయలుదేరే ముందు జాగ్రత్త అవసరం.",

        "safety_caution_why": "ORCA మధ్యస్థ సముద్ర exposure లేదా boundary proximity గుర్తించింది. స్థితి {state}.",

        "safety_caution_action": "నిర్ణయం ముందు Sea Conditions మరియు Boundary Guardian చూడండి.",

        "safety_high_short": "ప్రస్తుత ఆధారాల ప్రకారం ఇప్పుడు బయలుదేరడం సిఫార్సు చేయబడదు.",

        "safety_high_why": "ORCA అధిక సముద్ర పరిస్థితి లేదా geofence హెచ్చరికను గుర్తించింది. స్థితి {state}.",

        "safety_high_action": "అధికారిక INCOIS/IMD మరియు స్థానిక అధికార సూచనలు పాటించండి.",

        "land_short": "ఈ స్థానం భూమిపై ఉంది; సముద్ర ఆపరేషన్ పాయింట్ కాదు.",

        "land_why": "ORCA భూమి స్థానంనుంచి సముద్ర మిషన్‌ను అంచనా వేయలేడు.",

        "land_action": "నీటిపై బోటు స్థానం లేదా labelled offshore demo point ఉపయోగించండి.",

        "route_short": "గమ్యం ఎంచుకున్న తర్వాత నేను సముద్ర మార్గం రూపొందించగలను.",

        "route_why": "మార్గానికి నీటిపై నిజమైన గమ్యం మరియు బోటు వేగం అవసరం. ORCA అలలు, గాలి, ప్రవాహం, geofenceలను ఉపయోగిస్తుంది.",

        "route_action": "Plan Trip తెరిచి గమ్యం లేదా PFZ candidate ఎంచుకోండి.",

        "route_ready_short": "రెండు weather-aware సముద్ర మార్గాలు సిద్ధంగా ఉన్నాయి.",

        "route_ready_why": "వేగవంతమైన మార్గ ETA {fast_eta}. తక్కువ-exposure మార్గ ETA {low_eta}.",

        "route_ready_action": "మార్గాలను పోల్చి mission tracking ప్రారంభించడానికి Plan Trip తెరవండి.",

        "pfz_short": "Structured official feed నుంచి PFZ recommendation ఇంకా అందుబాటులో లేదు.",

        "pfz_why": "ORCA INCOISను authoritative PFZ sourceగా గుర్తించింది, కానీ నమ్మదగిన PFZ coordinates ఇంకా కనెక్ట్ కాలేదు. ORCA కల్పిత zones ఇవ్వదు.",

        "pfz_action": "Structured PFZ adapter వచ్చే వరకు official INCOIS PFZ advisory ఉపయోగించండి.",

        "help_short": "సముద్ర పరిస్థితులు, భద్రత, సరిహద్దు, PFZ లేదా మార్గం గురించి అడగండి.",

        "help_why": "ORCA specialist tools ఎంచుకుని verified outputsను వివరిస్తుంది.",

        "help_action": "క్రింది సూచించిన ప్రశ్నల్లో ఒకటి అడగండి.",

    },

}





# For Tamil/Kannada/Malayalam/Bengali/Odia, the fisherman UI is fully

# localized in Flutter. Until these safety-critical backend templates receive

# native review, we use concise English scientific text instead of producing

# unreviewed translations.

for _code in ("ta", "kn", "ml", "bn", "or"):

    TEXT[_code] = TEXT["en"]





def _fmt(

    value: float | None,

    unit: str,

    decimals: int = 1,

) -> str:

    if value is None:

        return "Unavailable"



    return f"{value:.{decimals}f} {unit}"





def _eta(minutes: float) -> str:

    total = round(minutes)

    hours = total // 60

    mins = total % 60



    if hours:

        return f"{hours}h {mins}m"



    return f"{mins}m"





def _fill(

    language: str,

    key: str,

    **kwargs,

) -> str:

    table = TEXT.get(

        language,

        TEXT["en"],

    )

    template = table.get(

        key,

        TEXT["en"][key],

    )

    return template.format(**kwargs)







HABITAT_TEXT = {
    "en": {
        "ready_short": "This area shows a {band} fishing-habitat signal.",
        "ready_why": (
            "ORCA checked sea temperature, chlorophyll, wind and seabed depth together. "
            "This is a habitat signal, not a PFZ or safety clearance."
        ),
        "ready_action": (
            "Use it together with PFZ information, Sea Safety and Plan Trip before choosing where to fish."
        ),
        "abstain_short": "ORCA cannot judge fishing habitat reliably here right now.",
        "abstain_action": (
            "Use the latest official PFZ advisory and retry when fresh satellite data is available."
        ),
    },
    "hi": {
        "ready_short": "इस क्षेत्र में मछली आवास के संकेत {band} हैं।",
        "ready_why": (
            "ORCA ने समुद्री तापमान, क्लोरोफिल, हवा और समुद्र की गहराई को साथ में देखा है। "
            "यह PFZ या सुरक्षा मंजूरी नहीं है।"
        ),
        "ready_action": (
            "मछली पकड़ने की जगह चुनने से पहले इसे PFZ, Sea Safety और Plan Trip के साथ देखें।"
        ),
        "abstain_short": "अभी ORCA इस जगह के मछली आवास का भरोसेमंद आकलन नहीं कर सकता।",
        "abstain_action": (
            "ताज़ा आधिकारिक PFZ सलाह देखें और नया सैटेलाइट डेटा मिलने पर फिर कोशिश करें।"
        ),
    },
    "mr": {
        "ready_short": "या भागात मासेमारीसाठी {band} अधिवास संकेत दिसत आहेत.",
        "ready_why": (
            "ORCA ने समुद्राचे तापमान, क्लोरोफिल, वारा आणि समुद्रतळाची खोली एकत्र तपासली. "
            "हा PFZ किंवा सुरक्षिततेचा परवाना नाही."
        ),
        "ready_action": (
            "मासेमारीचे ठिकाण निवडण्यापूर्वी PFZ, Sea Safety आणि Plan Trip सोबत हा संकेत वापरा."
        ),
        "abstain_short": (
            "सध्या ORCA या ठिकाणच्या मासेमारी अधिवासाचे विश्वासार्ह मूल्यांकन करू शकत नाही."
        ),
        "abstain_action": (
            "नवीन satellite data मिळेपर्यंत अधिकृत PFZ advisory वापरा आणि नंतर पुन्हा तपासा."
        ),
    },
    "gu": {
        "ready_short": "આ વિસ્તારમાં માછીમારી માટે {band} habitat signal છે.",
        "ready_why": (
            "ORCAએ સમુદ્ર તાપમાન, chlorophyll, પવન અને સમુદ્રની ઊંડાઈ સાથે તપાસ્યા છે. "
            "આ PFZ અથવા safety clearance નથી."
        ),
        "ready_action": (
            "માછીમારી સ્થાન પસંદ કરતા પહેલા PFZ, Sea Safety અને Plan Trip સાથે આ signal વાપરો."
        ),
        "abstain_short": "હાલ ORCA અહીં માછીમારી habitatનું વિશ્વસનીય મૂલ્યાંકન કરી શકતું નથી.",
        "abstain_action": (
            "તાજી official PFZ advisory વાપરો અને નવું satellite data મળે ત્યારે ફરી તપાસો."
        ),
    },
    "te": {
        "ready_short": "ఈ ప్రాంతంలో చేపల habitat signal {band}గా ఉంది.",
        "ready_why": (
            "ORCA సముద్ర ఉష్ణోగ్రత, chlorophyll, గాలి మరియు సముద్ర లోతును కలిసి పరిశీలించింది. "
            "ఇది PFZ లేదా safety clearance కాదు."
        ),
        "ready_action": (
            "చేపల ప్రాంతం ఎంచుకునే ముందు PFZ, Sea Safety మరియు Plan Tripతో కలిసి ఈ signalను ఉపయోగించండి."
        ),
        "abstain_short": (
            "ప్రస్తుతం ORCA ఈ ప్రాంతంలో చేపల habitatను నమ్మదగిన విధంగా అంచనా వేయలేకపోతోంది."
        ),
        "abstain_action": (
            "తాజా official PFZ advisory ఉపయోగించి, కొత్త satellite data వచ్చిన తర్వాత మళ్లీ ప్రయత్నించండి."
        ),
    },
}

RESEARCH_HABITAT_TEXT = {
    "ready_short": (
        "Habitat Opportunity v1 produced a {band} relative suitability signal ({score}/100)."
    ),
    "ready_why": (
        "Inference used SST, chlorophyll-a, wind and bathymetric features. "
        "Review the evidence values, timestamps, source-shift warning and model scope."
    ),
    "ready_action": (
        "Treat this as presence-background environmental suitability evidence, not official PFZ probability."
    ),
    "abstain_short": (
        "Habitat Opportunity v1 abstained because required fresh evidence is incomplete."
    ),
    "abstain_action": (
        "Inspect source freshness and missing variables before repeating the analysis."
    ),
}


def _habitat_copy(
    language: str,
    key: str,
    **kwargs,
) -> str:
    table = HABITAT_TEXT.get(
        language,
        HABITAT_TEXT["en"],
    )
    template = table.get(
        key,
        HABITAT_TEXT["en"][key],
    )
    return template.format(**kwargs)


def _habitat_band_for_fisherman(
    raw_band: str,
    language: str,
) -> str:
    labels = {
        "en": {
            "LOW": "less favourable",
            "MODERATE": "mixed",
            "MODERATE_HIGH": "promising",
            "HIGH": "strong",
        },
        "hi": {
            "LOW": "कम अनुकूल",
            "MODERATE": "मिश्रित",
            "MODERATE_HIGH": "अच्छे",
            "HIGH": "मजबूत",
        },
        "mr": {
            "LOW": "कमी अनुकूल",
            "MODERATE": "मिश्र",
            "MODERATE_HIGH": "आशादायक",
            "HIGH": "मजबूत",
        },
        "gu": {
            "LOW": "ઓછું અનુકૂળ",
            "MODERATE": "મિશ્ર",
            "MODERATE_HIGH": "આશાસ્પદ",
            "HIGH": "મજબૂત",
        },
        "te": {
            "LOW": "తక్కువ అనుకూల",
            "MODERATE": "మిశ్రమ",
            "MODERATE_HIGH": "ఆశాజనక",
            "HIGH": "బలమైన",
        },
    }
    return labels.get(
        language,
        labels["en"],
    ).get(
        raw_band,
        raw_band,
    )

def build_explanation(

    intent: str,

    language: str,

    state: dict[str, Any],

    audience_role: str = "FISHERMAN",

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

    pfz = state.get("pfz")

    habitat = state.get("habitat")



    if (

        boundary is not None

        and boundary.surface == "LAND"

    ):

        return (

            "INFO",

            "INFO",

            _fill(language, "land_short"),

            _fill(language, "land_why"),

            _fill(language, "land_action"),

        )



    if intent == "HABITAT":

        if (
            habitat is not None
            and habitat.status == "READY"
            and habitat.score is not None
        ):

            if audience_role.upper() == "RESEARCHER":
                return (
                    "HABITAT_SIGNAL_AVAILABLE",
                    "INFO",
                    RESEARCH_HABITAT_TEXT[
                        "ready_short"
                    ].format(
                        band=habitat.score.band,
                        score=f"{habitat.score.score_0_100:.1f}",
                    ),
                    RESEARCH_HABITAT_TEXT[
                        "ready_why"
                    ],
                    RESEARCH_HABITAT_TEXT[
                        "ready_action"
                    ],
                )

            band = _habitat_band_for_fisherman(
                habitat.score.band,
                language,
            )

            return (
                "HABITAT_SIGNAL_AVAILABLE",
                "INFO",
                _habitat_copy(
                    language,
                    "ready_short",
                    band=band,
                ),
                _habitat_copy(
                    language,
                    "ready_why",
                ),
                _habitat_copy(
                    language,
                    "ready_action",
                ),
            )

        reasons = (
            habitat.abstention_reasons
            if habitat is not None
            else ["Fresh habitat evidence is unavailable."]
        )

        reason = (
            reasons[0]
            if reasons
            else "Fresh habitat evidence is unavailable."
        )

        if audience_role.upper() == "RESEARCHER":
            return (
                "HABITAT_ABSTAINED",
                "INFO",
                RESEARCH_HABITAT_TEXT[
                    "abstain_short"
                ],
                reason,
                RESEARCH_HABITAT_TEXT[
                    "abstain_action"
                ],
            )

        return (
            "HABITAT_ABSTAINED",
            "INFO",
            _habitat_copy(
                language,
                "abstain_short",
            ),
            reason,
            _habitat_copy(
                language,
                "abstain_action",
            ),
        )


    if intent == "SEA_CONDITIONS" and marine is not None:

        status = marine.screening_status



        return (

            status,

            status,

            _fill(

                language,

                "conditions_short",

                state=status,

            ),

            _fill(

                language,

                "conditions_why",

                wave=_fmt(

                    marine.wave_height_m,

                    "m",

                ),

                wind=_fmt(

                    marine.wind_speed_ms,

                    "m/s",

                ),

                current=_fmt(

                    marine.ocean_current_velocity_ms,

                    "m/s",

                    2,

                ),

            ),

            _fill(

                language,

                "conditions_action",

            ),

        )



    if intent == "BOUNDARY" and boundary is not None:

        territorial = (

            boundary.territorial_sea.status

            if boundary.territorial_sea

            else "Unavailable"

        )

        eez = (

            boundary.eez.status

            if boundary.eez

            else "Unavailable"

        )

        coast = (

            f"{boundary.coast_distance_km:.1f} km"

            if boundary.coast_distance_km

            is not None

            else "Unavailable"

        )



        decision = (

            "CAUTION"

            if boundary.status == "NEAR"

            else (

                "DO_NOT_PROCEED"

                if boundary.status

                == "INSIDE"

                else "INFO"

            )

        )



        safety_state = (

            "HIGH"

            if decision == "DO_NOT_PROCEED"

            else (

                "CAUTION"

                if decision == "CAUTION"

                else "INFO"

            )

        )



        return (

            decision,

            safety_state,

            _fill(

                language,

                "boundary_short",

                state=boundary.status,

            ),

            _fill(

                language,

                "boundary_why",

                coast=coast,

                territorial=territorial,

                eez=eez,

                zone=boundary.status,

            ),

            _fill(

                language,

                "boundary_action",

            ),

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

            decision = "DO_NOT_DEPART"

            safety_state = "HIGH"

            prefix = "safety_high"

        elif (

            boundary_status == "NEAR"

            or marine_status

            == "CAUTION"

        ):

            decision = "CAUTION"

            safety_state = "CAUTION"

            prefix = "safety_caution"

        else:

            decision = (

                "CURRENTLY_ACCEPTABLE"

            )

            safety_state = "LOW"

            prefix = "safety_low"



        return (

            decision,

            safety_state,

            _fill(

                language,

                f"{prefix}_short",

            ),

            _fill(

                language,

                f"{prefix}_why",

                state=marine_status,

                wave=_fmt(

                    marine.wave_height_m

                    if marine

                    else None,

                    "m",

                ),

                wind=_fmt(

                    marine.wind_speed_ms

                    if marine

                    else None,

                    "m/s",

                ),

            ),

            _fill(

                language,

                f"{prefix}_action",

            ),

        )



    if intent == "ROUTE":

        if route is None:

            return (

                "NEED_DESTINATION",

                "INFO",

                _fill(

                    language,

                    "route_short",

                ),

                _fill(

                    language,

                    "route_why",

                ),

                _fill(

                    language,

                    "route_action",

                ),

            )



        route_state = (

            "HIGH"

            if (

                route.fastest.route_status

                == "HIGH"

                or route.lower_exposure.route_status

                == "HIGH"

            )

            else (

                "CAUTION"

                if (

                    route.fastest.route_status

                    == "CAUTION"

                    or route.lower_exposure.route_status

                    == "CAUTION"

                )

                else "LOW"

            )

        )



        return (

            "ROUTES_READY",

            route_state,

            _fill(

                language,

                "route_ready_short",

            ),

            _fill(

                language,

                "route_ready_why",

                fast_eta=_eta(

                    route.fastest.eta_minutes

                ),

                low_eta=_eta(

                    route.lower_exposure.eta_minutes

                ),

            ),

            _fill(

                language,

                "route_ready_action",

            ),

        )



    if intent == "PFZ":

        return (

            "PFZ_DATA_REQUIRED",

            "INFO",

            _fill(language, "pfz_short"),

            _fill(language, "pfz_why"),

            _fill(language, "pfz_action"),

        )



    return (

        "INFO",

        "INFO",

        _fill(language, "help_short"),

        _fill(language, "help_why"),

        _fill(language, "help_action"),

    )
