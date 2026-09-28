import 'package:flutter/material.dart';

import 'package:flutter_tts/flutter_tts.dart';

import 'package:geolocator/geolocator.dart';

import 'package:speech_to_text/speech_to_text.dart';



import '../../core/theme/app_theme.dart';

import '../../models/orca_agent_models.dart';

import '../../services/fisherman_service.dart';

import '../../services/orca_agent_service.dart';

import '../../services/orca_chat_history_service.dart';

import '../../services/session_service.dart';

import '../gis/boundary_guardian_screen.dart';

import '../gis/plan_trip_screen.dart';

import '../marine/sea_conditions_screen.dart';



class AskOrcaScreen extends StatefulWidget {

  const AskOrcaScreen({super.key});



  @override

  State<AskOrcaScreen> createState() => _AskOrcaScreenState();

}



class _AskOrcaScreenState extends State<AskOrcaScreen> {

  final controller = TextEditingController();

  final scrollController = ScrollController();

  final speech = SpeechToText();

  final tts = FlutterTts();



  List<OrcaChatMessageData> messages = [];

  Position? position;

  OrcaAgentResponseData? lastResponse;



  String language = 'en';

  bool loading = true;

  bool asking = false;

  bool listening = false;

  bool useDemoSeaPoint = false;

  String? error;

  bool voiceChecked = false;
  bool speechReady = false;
  bool ttsReady = false;
  String? speechLocaleId;
  String? ttsLocaleId;

static const demoLat = 20.65;

  static const demoLon = 69.75;



  static const localeMap = {

    'en': 'en-IN',

    'hi': 'hi-IN',

    'mr': 'mr-IN',

    'gu': 'gu-IN',

    'te': 'te-IN',

    'ta': 'ta-IN',

    'kn': 'kn-IN',

    'ml': 'ml-IN',

    'bn': 'bn-IN',

    'or': 'or-IN',

  };



  static const ui = {

    'en': {

      'title': 'Ask ORCA',

      'hint': 'Ask about sea, safety, PFZ or route...',

      'decision': 'Decision',

      'why': 'Why',

      'action': 'What to do',

      'evidence': 'Evidence',

      'tools': 'Agents used',

      'demo': 'Offshore demo point',

      'clear': 'Clear chat',

      'listening': 'Listening...',

      'speak': 'Read answer',

      'gps': 'Using real GPS',

    },

    'hi': {

      'title': 'ORCA से पूछें',

      'hint': 'समुद्र, सुरक्षा, PFZ या मार्ग के बारे में पूछें...',

      'decision': 'निर्णय',

      'why': 'क्यों',

      'action': 'क्या करें',

      'evidence': 'प्रमाण',

      'tools': 'उपयोग किए गए एजेंट',

      'demo': 'ऑफशोर डेमो बिंदु',

      'clear': 'चैट साफ़ करें',

      'listening': 'सुन रहा है...',

      'speak': 'उत्तर सुनें',

      'gps': 'वास्तविक GPS उपयोग हो रहा है',

    },

    'mr': {

      'title': 'ORCA ला विचारा',

      'hint': 'समुद्र, सुरक्षा, PFZ किंवा मार्गाबद्दल विचारा...',

      'decision': 'निर्णय',

      'why': 'का',

      'action': 'काय करावे',

      'evidence': 'पुरावे',

      'tools': 'वापरलेले एजंट',

      'demo': 'ऑफशोर डेमो पॉइंट',

      'clear': 'चॅट साफ करा',

      'listening': 'ऐकत आहे...',

      'speak': 'उत्तर ऐका',

      'gps': 'खरे GPS वापरत आहे',

    },

    'gu': {

      'title': 'ORCA ને પૂછો',

      'hint': 'સમુદ્ર, સુરક્ષા, PFZ અથવા માર્ગ વિશે પૂછો...',

      'decision': 'નિર્ણય',

      'why': 'શા માટે',

      'action': 'શું કરવું',

      'evidence': 'પુરાવો',

      'tools': 'વપરાયેલા એજન્ટ',

      'demo': 'ઓફશોર ડેમો પોઈન્ટ',

      'clear': 'ચેટ સાફ કરો',

      'listening': 'સાંભળી રહ્યું છે...',

      'speak': 'જવાબ સાંભળો',

      'gps': 'વાસ્તવિક GPS વપરાઈ રહ્યું છે',

    },

    'te': {

      'title': 'ORCA ను అడగండి',

      'hint': 'సముద్రం, భద్రత, PFZ లేదా మార్గం గురించి అడగండి...',

      'decision': 'నిర్ణయం',

      'why': 'ఎందుకు',

      'action': 'ఏం చేయాలి',

      'evidence': 'ఆధారాలు',

      'tools': 'ఉపయోగించిన ఏజెంట్లు',

      'demo': 'ఆఫ్‌షోర్ డెమో పాయింట్',

      'clear': 'చాట్ క్లియర్ చేయండి',

      'listening': 'వింటోంది...',

      'speak': 'జవాబు వినండి',

      'gps': 'నిజమైన GPS ఉపయోగిస్తోంది',

    },

    'ta': {

      'title': 'ORCA-விடம் கேளுங்கள்',

      'hint': 'கடல், பாதுகாப்பு, PFZ அல்லது வழி பற்றி கேளுங்கள்...',

      'decision': 'முடிவு',

      'why': 'ஏன்',

      'action': 'என்ன செய்ய வேண்டும்',

      'evidence': 'ஆதாரம்',

      'tools': 'பயன்பட்ட முகவர்கள்',

      'demo': 'ஆஃப்ஷோர் டெமோ புள்ளி',

      'clear': 'அரட்டை அழிக்கவும்',

      'listening': 'கேட்கிறது...',

      'speak': 'பதிலை கேளுங்கள்',

      'gps': 'உண்மையான GPS பயன்படுத்தப்படுகிறது',

    },

    'kn': {

      'title': 'ORCA ಅನ್ನು ಕೇಳಿ',

      'hint': 'ಸಮುದ್ರ, ಸುರಕ್ಷತೆ, PFZ ಅಥವಾ ಮಾರ್ಗದ ಬಗ್ಗೆ ಕೇಳಿ...',

      'decision': 'ನಿರ್ಣಯ',

      'why': 'ಏಕೆ',

      'action': 'ಏನು ಮಾಡಬೇಕು',

      'evidence': 'ಸಾಕ್ಷ್ಯ',

      'tools': 'ಬಳಸಿದ ಏಜೆಂಟ್‌ಗಳು',

      'demo': 'ಆಫ್‌ಶೋರ್ ಡೆಮೋ ಪಾಯಿಂಟ್',

      'clear': 'ಚಾಟ್ ತೆರವುಗೊಳಿಸಿ',

      'listening': 'ಕೇಳುತ್ತಿದೆ...',

      'speak': 'ಉತ್ತರ ಕೇಳಿ',

      'gps': 'ನಿಜವಾದ GPS ಬಳಸುತ್ತಿದೆ',

    },

    'ml': {

      'title': 'ORCAയോട് ചോദിക്കുക',

      'hint': 'കടൽ, സുരക്ഷ, PFZ അല്ലെങ്കിൽ റൂട്ട് ചോദിക്കുക...',

      'decision': 'തീരുമാനം',

      'why': 'എന്തുകൊണ്ട്',

      'action': 'എന്ത് ചെയ്യണം',

      'evidence': 'തെളിവ്',

      'tools': 'ഉപയോഗിച്ച ഏജന്റുകൾ',

      'demo': 'ഓഫ്‌ഷോർ ഡെമോ പോയിന്റ്',

      'clear': 'ചാറ്റ് മായ്ക്കുക',

      'listening': 'കേൾക്കുന്നു...',

      'speak': 'മറുപടി കേൾക്കുക',

      'gps': 'യഥാർത്ഥ GPS ഉപയോഗിക്കുന്നു',

    },

    'bn': {

      'title': 'ORCA-কে জিজ্ঞাসা করুন',

      'hint': 'সমুদ্র, নিরাপত্তা, PFZ বা রুট সম্পর্কে জিজ্ঞাসা করুন...',

      'decision': 'সিদ্ধান্ত',

      'why': 'কেন',

      'action': 'কী করবেন',

      'evidence': 'প্রমাণ',

      'tools': 'ব্যবহৃত এজেন্ট',

      'demo': 'অফশোর ডেমো পয়েন্ট',

      'clear': 'চ্যাট পরিষ্কার করুন',

      'listening': 'শুনছে...',

      'speak': 'উত্তর শুনুন',

      'gps': 'বাস্তব GPS ব্যবহার হচ্ছে',

    },

    'or': {

      'title': 'ORCA କୁ ପଚାରନ୍ତୁ',

      'hint': 'ସମୁଦ୍ର, ସୁରକ୍ଷା, PFZ କିମ୍ବା ମାର୍ଗ ବିଷୟରେ ପଚାରନ୍ତୁ...',

      'decision': 'ନିଷ୍ପତ୍ତି',

      'why': 'କାହିଁକି',

      'action': 'କଣ କରିବେ',

      'evidence': 'ପ୍ରମାଣ',

      'tools': 'ବ୍ୟବହୃତ ଏଜେଣ୍ଟ',

      'demo': 'ଅଫଶୋର ଡେମୋ ପଏଣ୍ଟ',

      'clear': 'ଚାଟ୍ ସଫା କରନ୍ତୁ',

      'listening': 'ଶୁଣୁଛି...',

      'speak': 'ଉତ୍ତର ଶୁଣନ୍ତୁ',

      'gps': 'ବାସ୍ତବ GPS ବ୍ୟବହାର ହେଉଛି',

    },

  };




  static const voiceUi = {
    'en': {
      'quick': 'Try asking',
      'voice_ready': 'Voice ready',
      'voice_partial': 'Voice partly available',
      'voice_checking': 'Checking voice...',
      'stt_missing': 'Speech recognition is not installed for this language.',
      'tts_missing': 'Spoken answers are not installed for this language.',
      'gps_required': 'GPS is unavailable. Turn on location or enable the labelled offshore demo point.',
      'gps_missing': 'GPS unavailable',
      'welcome': 'Speak naturally in your language. ORCA listens, checks specialist marine agents and speaks the answer back.',
    },
    'hi': {
      'quick': 'पूछकर देखें',
      'voice_ready': 'आवाज़ तैयार है',
      'voice_partial': 'आवाज़ आंशिक रूप से उपलब्ध है',
      'voice_checking': 'आवाज़ जाँच रहा है...',
      'stt_missing': 'इस भाषा के लिए बोलकर पूछने की सुविधा इंस्टॉल नहीं है।',
      'tts_missing': 'इस भाषा में बोलकर उत्तर देने की सुविधा इंस्टॉल नहीं है।',
      'gps_required': 'GPS उपलब्ध नहीं है। लोकेशन चालू करें या लेबल वाला ऑफशोर डेमो बिंदु चुनें।',
      'gps_missing': 'GPS उपलब्ध नहीं',
      'welcome': 'अपनी भाषा में बोलकर पूछें। ORCA समुद्री एजेंटों से जाँच कर उसी भाषा में उत्तर बोलेगा।',
    },
    'mr': {
      'quick': 'विचारून पाहा',
      'voice_ready': 'आवाज तयार आहे',
      'voice_partial': 'आवाज अंशतः उपलब्ध आहे',
      'voice_checking': 'आवाज तपासत आहे...',
      'stt_missing': 'या भाषेसाठी बोलून विचारण्याची सुविधा इन्स्टॉल नाही.',
      'tts_missing': 'या भाषेत बोलून उत्तर देण्याची सुविधा इन्स्टॉल नाही.',
      'gps_required': 'GPS उपलब्ध नाही. Location सुरू करा किंवा लेबल केलेला offshore demo point निवडा.',
      'gps_missing': 'GPS उपलब्ध नाही',
      'welcome': 'तुमच्या भाषेत बोला. ORCA समुद्री एजंट तपासून त्याच भाषेत उत्तर बोलेल.',
    },
    'gu': {
      'quick': 'પૂછીને જુઓ',
      'voice_ready': 'વોઇસ તૈયાર છે',
      'voice_partial': 'વોઇસ આંશિક ઉપલબ્ધ છે',
      'voice_checking': 'વોઇસ તપાસી રહ્યું છે...',
      'stt_missing': 'આ ભાષા માટે બોલીને પૂછવાની સુવિધા ઇન્સ્ટોલ નથી.',
      'tts_missing': 'આ ભાષામાં બોલીને જવાબ આપવાની સુવિધા ઇન્સ્ટોલ નથી.',
      'gps_required': 'GPS ઉપલબ્ધ નથી. Location ચાલુ કરો અથવા લેબલ કરેલું offshore demo point પસંદ કરો.',
      'gps_missing': 'GPS ઉપલબ્ધ નથી',
      'welcome': 'તમારી ભાષામાં બોલો. ORCA સમુદ્રી એજન્ટો તપાસીને એ જ ભાષામાં જવાબ બોલશે.',
    },
    'te': {
      'quick': 'అడిగి చూడండి',
      'voice_ready': 'వాయిస్ సిద్ధంగా ఉంది',
      'voice_partial': 'వాయిస్ కొంతవరకు అందుబాటులో ఉంది',
      'voice_checking': 'వాయిస్‌ను తనిఖీ చేస్తోంది...',
      'stt_missing': 'ఈ భాషలో మాట్లాడి అడిగే సదుపాయం ఇన్‌స్టాల్ కాలేదు.',
      'tts_missing': 'ఈ భాషలో మాట్లాడే సమాధానం ఇన్‌స్టాల్ కాలేదు.',
      'gps_required': 'GPS అందుబాటులో లేదు. Location ఆన్ చేయండి లేదా labelled offshore demo point ఎంచుకోండి.',
      'gps_missing': 'GPS అందుబాటులో లేదు',
      'welcome': 'మీ భాషలో మాట్లాడండి. ORCA సముద్ర ఏజెంట్లను తనిఖీ చేసి అదే భాషలో సమాధానం చెబుతుంది.',
    },
    'ta': {
      'quick': 'கேட்டு பாருங்கள்',
      'voice_ready': 'குரல் தயாராக உள்ளது',
      'voice_partial': 'குரல் பகுதியளவில் கிடைக்கிறது',
      'voice_checking': 'குரலைச் சரிபார்க்கிறது...',
      'stt_missing': 'இந்த மொழிக்கான பேச்சு அடையாளம் சாதனத்தில் நிறுவப்படவில்லை.',
      'tts_missing': 'இந்த மொழிக்கான பேசும் பதில் சாதனத்தில் நிறுவப்படவில்லை.',
      'gps_required': 'GPS கிடைக்கவில்லை. Location-ஐ இயக்கவும் அல்லது labelled offshore demo point-ஐ தேர்வு செய்யவும்.',
      'gps_missing': 'GPS கிடைக்கவில்லை',
      'welcome': 'உங்கள் மொழியில் பேசுங்கள். ORCA கடல் முகவர்களைச் சரிபார்த்து அதே மொழியில் பதில் பேசும்.',
    },
    'kn': {
      'quick': 'ಕೇಳಿ ನೋಡಿ',
      'voice_ready': 'ಧ್ವನಿ ಸಿದ್ಧವಾಗಿದೆ',
      'voice_partial': 'ಧ್ವನಿ ಭಾಗಶಃ ಲಭ್ಯವಿದೆ',
      'voice_checking': 'ಧ್ವನಿಯನ್ನು ಪರಿಶೀಲಿಸಲಾಗುತ್ತಿದೆ...',
      'stt_missing': 'ಈ ಭಾಷೆಯ ಮಾತು ಗುರುತಿಸುವಿಕೆ ಸಾಧನದಲ್ಲಿ ಇನ್‌ಸ್ಟಾಲ್ ಆಗಿಲ್ಲ.',
      'tts_missing': 'ಈ ಭಾಷೆಯ ಮಾತನಾಡುವ ಉತ್ತರ ಸಾಧನದಲ್ಲಿ ಇನ್‌ಸ್ಟಾಲ್ ಆಗಿಲ್ಲ.',
      'gps_required': 'GPS ಲಭ್ಯವಿಲ್ಲ. Location ಆನ್ ಮಾಡಿ ಅಥವಾ labelled offshore demo point ಆಯ್ಕೆಮಾಡಿ.',
      'gps_missing': 'GPS ಲಭ್ಯವಿಲ್ಲ',
      'welcome': 'ನಿಮ್ಮ ಭಾಷೆಯಲ್ಲಿ ಮಾತನಾಡಿ. ORCA ಸಮುದ್ರ ಏಜೆಂಟ್‌ಗಳನ್ನು ಪರಿಶೀಲಿಸಿ ಅದೇ ಭಾಷೆಯಲ್ಲಿ ಉತ್ತರಿಸುತ್ತದೆ.',
    },
    'ml': {
      'quick': 'ചോദിച്ച് നോക്കൂ',
      'voice_ready': 'വോയ്സ് തയ്യാറാണ്',
      'voice_partial': 'വോയ്സ് ഭാഗികമായി ലഭ്യമാണ്',
      'voice_checking': 'വോയ്സ് പരിശോധിക്കുന്നു...',
      'stt_missing': 'ഈ ഭാഷയ്ക്കുള്ള speech recognition ഇൻസ്റ്റാൾ ചെയ്തിട്ടില്ല.',
      'tts_missing': 'ഈ ഭാഷയ്ക്കുള്ള spoken answer ഇൻസ്റ്റാൾ ചെയ്തിട്ടില്ല.',
      'gps_required': 'GPS ലഭ്യമല്ല. Location ഓൺ ചെയ്യുക അല്ലെങ്കിൽ labelled offshore demo point തിരഞ്ഞെടുക്കുക.',
      'gps_missing': 'GPS ലഭ്യമല്ല',
      'welcome': 'നിങ്ങളുടെ ഭാഷയിൽ സംസാരിക്കുക. ORCA marine agents പരിശോധിച്ച് അതേ ഭാഷയിൽ മറുപടി പറയും.',
    },
    'bn': {
      'quick': 'জিজ্ঞাসা করে দেখুন',
      'voice_ready': 'ভয়েস প্রস্তুত',
      'voice_partial': 'ভয়েস আংশিকভাবে উপলব্ধ',
      'voice_checking': 'ভয়েস পরীক্ষা করা হচ্ছে...',
      'stt_missing': 'এই ভাষার speech recognition ইনস্টল করা নেই।',
      'tts_missing': 'এই ভাষায় spoken answer ইনস্টল করা নেই।',
      'gps_required': 'GPS পাওয়া যাচ্ছে না। Location চালু করুন অথবা labelled offshore demo point বেছে নিন।',
      'gps_missing': 'GPS পাওয়া যাচ্ছে না',
      'welcome': 'নিজের ভাষায় বলুন। ORCA সামুদ্রিক এজেন্ট যাচাই করে একই ভাষায় উত্তর বলবে।',
    },
    'or': {
      'quick': 'ପଚାରି ଦେଖନ୍ତୁ',
      'voice_ready': 'ଭଏସ୍ ପ୍ରସ୍ତୁତ',
      'voice_partial': 'ଭଏସ୍ ଆଂଶିକ ଭାବେ ଉପଲବ୍ଧ',
      'voice_checking': 'ଭଏସ୍ ଯାଞ୍ଚ ହେଉଛି...',
      'stt_missing': 'ଏହି ଭାଷାର speech recognition ଇନ୍‌ଷ୍ଟଲ୍ ନାହିଁ।',
      'tts_missing': 'ଏହି ଭାଷାର spoken answer ଇନ୍‌ଷ୍ଟଲ୍ ନାହିଁ।',
      'gps_required': 'GPS ଉପଲବ୍ଧ ନାହିଁ। Location ଚାଲୁ କରନ୍ତୁ କିମ୍ବା labelled offshore demo point ବାଛନ୍ତୁ।',
      'gps_missing': 'GPS ଉପଲବ୍ଧ ନାହିଁ',
      'welcome': 'ନିଜ ଭାଷାରେ କହନ୍ତୁ। ORCA marine agents ଯାଞ୍ଚ କରି ସେହି ଭାଷାରେ ଉତ୍ତର କହିବ।',
    },
  };

  static const quickQuestions = {
    'en': [
      'Where is the nearest fishing zone?',
      'Is it safe to go tomorrow morning?',
      'What are the sea conditions and tide here?',
      'Is the sea safe? Are there cyclone or lightning alerts?',
      'Is this a good fishing area?',
      'Show the safest route.',
      'Which restricted or boundary areas should I avoid?',
    ],
    'hi': [
      'सबसे नज़दीकी मछली क्षेत्र कहाँ है?',
      'क्या कल सुबह जाना सुरक्षित है?',
      'यहाँ समुद्र की स्थिति, लहरें और ज्वार क्या हैं?',
      'क्या समुद्र सुरक्षित है? कोई चक्रवात या बिजली चेतावनी है?',
      'क्या यह मछली के लिए अच्छा क्षेत्र है?',
      'सबसे सुरक्षित मार्ग दिखाएँ।',
      'कौन से प्रतिबंधित क्षेत्र और सीमा से बचना चाहिए?',
    ],
    'mr': [
      'सर्वात जवळचे मासेमारी क्षेत्र कुठे आहे?',
      'उद्या सकाळी जाणे सुरक्षित आहे का?',
      'इथली समुद्राची स्थिती, लाटा आणि भरती-ओहोटी कशी आहे?',
      'समुद्र सुरक्षित आहे का? चक्रीवादळ किंवा वीजेचा इशारा आहे का?',
      'हा भाग मासेमारीसाठी चांगला आहे का?',
      'सर्वात सुरक्षित मार्ग दाखवा.',
      'कोणते प्रतिबंधित भाग किंवा सीमा टाळाव्यात?',
    ],
    'gu': [
      'સૌથી નજીકનું માછીમારી ઝોન ક્યાં છે?',
      'કાલે સવારે જવું સુરક્ષિત છે?',
      'અહીં સમુદ્રની સ્થિતિ, મોજાં અને જ્વાર શું છે?',
      'સમુદ્ર સુરક્ષિત છે? કોઈ ચક્રવાત અથવા વીજળી ચેતવણી છે?',
      'શું આ માછલી માટે સારું વિસ્તાર છે?',
      'સૌથી સુરક્ષિત માર્ગ બતાવો.',
      'કયા પ્રતિબંધિત વિસ્તાર અથવા સીમાથી દૂર રહેવું?',
    ],
    'te': [
      'అత్యంత దగ్గరలో ఉన్న ఫిషింగ్ జోన్ ఎక్కడ ఉంది?',
      'రేపు ఉదయం వెళ్లడం సురక్షితమా?',
      'ఇక్కడ సముద్ర పరిస్థితి, అలలు మరియు టైడ్ ఎలా ఉన్నాయి?',
      'సముద్రం సురక్షితమా? తుఫాను లేదా మెరుపు హెచ్చరిక ఉందా?',
      'ఈ ప్రాంతం చేపలకు అనుకూలమా?',
      'అత్యంత సురక్షితమైన మార్గం చూపించండి.',
      'ఏ నిషేధిత ప్రాంతాలు లేదా సరిహద్దులను తప్పుకోవాలి?',
    ],
    'ta': [
      'அருகிலுள்ள மீன்பிடி பகுதி எங்கே?',
      'நாளை காலை கடலுக்கு செல்வது பாதுகாப்பானதா?',
      'இங்கே கடல் நிலை, அலை மற்றும் அலைச்சல் எப்படி உள்ளது?',
      'கடல் பாதுகாப்பானதா? புயல் அல்லது மின்னல் எச்சரிக்கை உள்ளதா?',
      'இந்த பகுதி மீன்பிடிக்க நல்லதா?',
      'பாதுகாப்பான வழியை காட்டுங்கள்.',
      'எந்த தடைப்பகுதி அல்லது எல்லையை தவிர்க்க வேண்டும்?',
    ],
    'kn': [
      'ಹತ್ತಿರದ ಮೀನುಗಾರಿಕೆ ವಲಯ ಎಲ್ಲಿದೆ?',
      'ನಾಳೆ ಬೆಳಿಗ್ಗೆ ಸಮುದ್ರಕ್ಕೆ ಹೋಗುವುದು ಸುರಕ್ಷಿತವೇ?',
      'ಇಲ್ಲಿನ ಸಮುದ್ರ ಸ್ಥಿತಿ, ಅಲೆ ಮತ್ತು ಜ್ವಾರ ಹೇಗಿದೆ?',
      'ಸಮುದ್ರ ಸುರಕ್ಷಿತವೇ? ಚಂಡಮಾರುತ ಅಥವಾ ಮಿಂಚಿನ ಎಚ್ಚರಿಕೆ ಇದೆಯೇ?',
      'ಈ ಪ್ರದೇಶ ಮೀನು ಸಿಗಲು ಅನುಕೂಲಕರವೇ?',
      'ಅತ್ಯಂತ ಸುರಕ್ಷಿತ ಮಾರ್ಗ ತೋರಿಸಿ.',
      'ಯಾವ ನಿರ್ಬಂಧಿತ ಪ್ರದೇಶ ಅಥವಾ ಗಡಿಯನ್ನು ತಪ್ಪಿಸಬೇಕು?',
    ],
    'ml': [
      'അടുത്ത മത്സ്യബന്ധന മേഖല എവിടെയാണ്?',
      'നാളെ രാവിലെ കടലിൽ പോകുന്നത് സുരക്ഷിതമാണോ?',
      'ഇവിടത്തെ കടൽ നില, തിരയും വേലിയേറ്റവും എങ്ങനെയാണ്?',
      'കടൽ സുരക്ഷിതമാണോ? ചുഴലിക്കാറ്റ് അല്ലെങ്കിൽ മിന്നൽ മുന്നറിയിപ്പ് ഉണ്ടോ?',
      'ഈ പ്രദേശം മത്സ്യം ലഭിക്കാൻ നല്ലതാണോ?',
      'ഏറ്റവും സുരക്ഷിതമായ റൂട്ട് കാണിക്കുക.',
      'ഏത് നിയന്ത്രിത മേഖലകളോ അതിർത്തികളോ ഒഴിവാക്കണം?',
    ],
    'bn': [
      'সবচেয়ে কাছের মাছ ধরার অঞ্চল কোথায়?',
      'আগামীকাল সকালে সমুদ্রে যাওয়া নিরাপদ কি?',
      'এখানে সমুদ্রের অবস্থা, ঢেউ ও জোয়ার কেমন?',
      'সমুদ্র নিরাপদ কি? ঘূর্ণিঝড় বা বজ্রপাতের সতর্কতা আছে?',
      'এই এলাকা মাছ পাওয়ার জন্য ভালো কি?',
      'সবচেয়ে নিরাপদ রুট দেখান।',
      'কোন নিষিদ্ধ অঞ্চল বা সীমা এড়াতে হবে?',
    ],
    'or': [
      'ସବୁଠାରୁ ନିକଟ ମାଛଧରା ଅଞ୍ଚଳ କେଉଁଠି?',
      'ଆସନ୍ତାକାଲି ସକାଳେ ସମୁଦ୍ରକୁ ଯିବା ସୁରକ୍ଷିତ କି?',
      'ଏଠାରେ ସମୁଦ୍ର ଅବସ୍ଥା, ତରଙ୍ଗ ଓ ଜ୍ୱାର କେମିତି?',
      'ସମୁଦ୍ର ସୁରକ୍ଷିତ କି? ବାତ୍ୟା କିମ୍ବା ବଜ୍ରପାତ ସତର୍କତା ଅଛି କି?',
      'ଏହି ଅଞ୍ଚଳ ମାଛ ପାଇଁ ଭଲ କି?',
      'ସବୁଠାରୁ ସୁରକ୍ଷିତ ମାର୍ଗ ଦେଖାନ୍ତୁ।',
      'କେଉଁ ନିଷିଦ୍ଧ ଅଞ୍ଚଳ କିମ୍ବା ସୀମାକୁ ଏଡ଼ାଇବା ଉଚିତ?',
    ],
  };

  String vtr(String key) =>
      voiceUi[language]?[key] ?? voiceUi['en']![key]!;

  String _normalizeLocale(String value) =>
      value.toLowerCase().replaceAll('_', '-');

  String _languageCodeFromLocale(String value) =>
      _normalizeLocale(value).split('-').first;

  String? _bestLocale(
    Iterable<String> installed,
    String desired,
  ) {
    final desiredNormalized = _normalizeLocale(desired);

    for (final item in installed) {
      if (_normalizeLocale(item) == desiredNormalized) {
        return item;
      }
    }

    final languageCode = _languageCodeFromLocale(desired);

    for (final item in installed) {
      if (_languageCodeFromLocale(item) == languageCode) {
        return item;
      }
    }

    return null;
  }

  String tr(String key) => ui[language]?[key] ?? ui['en']![key]!;



  @override

  void initState() {

    super.initState();

    _bootstrap();

  }



  @override

  void dispose() {

    controller.dispose();

    scrollController.dispose();

    speech.stop();

    tts.stop();

    super.dispose();

  }



  Future<Position?> _tryPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();

    if (!enabled) return null;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (
        permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _prepareVoice() async {
    String? resolvedSpeech;
    String? resolvedTts;

    try {
      final available = await speech.initialize();

      if (available) {
        final desired = localeMap[language] ?? 'en-IN';
        final locales = await speech.locales();

        resolvedSpeech = _bestLocale(
          locales.map((e) => e.localeId),
          desired,
        );
      }
    } catch (_) {
      resolvedSpeech = null;
    }

    try {
      final desired = localeMap[language] ?? 'en-IN';
      final dynamic rawLanguages = await tts.getLanguages;
      final installed = <String>[];

      if (rawLanguages is List) {
        installed.addAll(
          rawLanguages
              .where((e) => e != null)
              .map((e) => e.toString()),
        );
      }

      resolvedTts = _bestLocale(
        installed,
        desired,
      );

      if (resolvedTts == null) {
        final dynamic availability =
            await tts.isLanguageAvailable(desired);

        final supported =
            availability == true ||
            availability == 1 ||
            availability?.toString() == '1';

        if (supported) {
          resolvedTts = desired;
        }
      }
    } catch (_) {
      resolvedTts = null;
    }

    if (!mounted) return;

    setState(() {
      speechLocaleId = resolvedSpeech;
      ttsLocaleId = resolvedTts;
      speechReady = resolvedSpeech != null;
      ttsReady = resolvedTts != null;
      voiceChecked = true;
    });
  }

  Future<void> _bootstrap() async {
    try {
      final profile = await FishermanService.getProfile();

      language = profile.preferredLanguage.toLowerCase();

      await SessionService.setPreferredLanguage(language);
    } catch (_) {
      language = (await SessionService.getPreferredLanguage() ?? 'en')
          .toLowerCase();
    }

    messages = await OrcaChatHistoryService.load();
    position = await _tryPosition();

    if (mounted) {
      setState(() => loading = false);
      _scrollBottom();
    }

    await _prepareVoice();
  }

  double? get queryLat =>
      useDemoSeaPoint ? demoLat : position?.latitude;

  double? get queryLon =>
      useDemoSeaPoint ? demoLon : position?.longitude;

  Future<void> _ask() async {

    final text = controller.text.trim();



    if (text.length < 2 || asking) return;



        final latitude = queryLat;
    final longitude = queryLon;

    if (latitude == null || longitude == null) {
      _snack(vtr('gps_required'));
      return;
    }

final previous = List<OrcaChatMessageData>.from(messages);

    final userMessage = OrcaChatMessageData(

      role: 'user',

      content: text,

      createdAt: DateTime.now(),

    );



    setState(() {

      messages.add(userMessage);

      controller.clear();

      asking = true;

      error = null;

      lastResponse = null;

    });



    await OrcaChatHistoryService.save(messages);

    _scrollBottom();



    try {

      final result = await OrcaAgentService.query(

        message: text,

        latitude: latitude,

        longitude: longitude,

        preferredLanguage: language,

        history: previous,

      );



      final assistantText =

          '${result.shortAnswer}\n\n${result.laymanExplanation}\n\n${result.recommendation}';



      final assistantMessage = OrcaChatMessageData(

        role: 'assistant',

        content: assistantText,

        createdAt: DateTime.now(),

      );



      if (!mounted) return;



      setState(() {

        lastResponse = result;

        messages.add(assistantMessage);

      });



      await OrcaChatHistoryService.save(messages);

      await _speak(result.spokenText);

    } catch (e) {

      if (!mounted) return;

      setState(() => error = e.toString());

    } finally {

      if (mounted) {

        setState(() => asking = false);

        _scrollBottom();

      }

    }

  }



  Future<void> _listen() async {
    if (listening) {
      await speech.stop();

      if (mounted) {
        setState(() => listening = false);
      }

      return;
    }

    if (!voiceChecked) {
      await _prepareVoice();
    }

    final localeId = speechLocaleId;

    if (localeId == null) {
      _snack(vtr('stt_missing'));
      return;
    }

    setState(() => listening = true);

    await speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenMode: ListenMode.confirmation,
        partialResults: true,
      ),
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          controller.text = result.recognizedWords;
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );

          if (result.finalResult) {
            listening = false;
          }
        });

        if (
            result.finalResult &&
            result.recognizedWords.trim().length >= 2) {
          Future<void>.delayed(
            const Duration(milliseconds: 350),
            () async {
              if (
                  mounted &&
                  !asking &&
                  !listening &&
                  controller.text.trim().length >= 2) {
                await _ask();
              }
            },
          );
        }
      },
    );
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;

    if (!voiceChecked) {
      await _prepareVoice();
    }

    final locale = ttsLocaleId;

    if (locale == null) {
      _snack(vtr('tts_missing'));
      return;
    }

    try {
      await tts.stop();
      await tts.setLanguage(locale);
      await tts.setSpeechRate(0.46);
      await tts.speak(text);
    } catch (_) {
      _snack(vtr('tts_missing'));
    }
  }

  Future<void> _clear() async {

    await OrcaChatHistoryService.clear();



    if (!mounted) return;



    setState(() {

      messages = [];

      lastResponse = null;

      error = null;

    });

  }



  void _scrollBottom() {

    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (!scrollController.hasClients) return;



      scrollController.animateTo(

        scrollController.position.maxScrollExtent,

        duration: const Duration(milliseconds: 250),

        curve: Curves.easeOut,

      );

    });

  }



  void _snack(String text) {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)),

    );

  }



  Future<void> _openAction(OrcaAgentActionData action) async {

    Widget? screen;



    switch (action.id) {

      case 'open_plan_trip':

        screen = const PlanTripScreen();

        break;

      case 'open_boundary':

        screen = const BoundaryGuardianScreen();

        break;

      case 'open_sea_conditions':

        screen = const SeaConditionsScreen();

        break;

    }



    if (screen == null) return;



    await Navigator.of(context)

        .push(MaterialPageRoute(builder: (_) => screen!));

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF4F8FA),

      appBar: AppBar(

        title: Text(tr('title')),

        backgroundColor: Colors.transparent,

        elevation: 0,

        actions: [

          IconButton(

            tooltip: tr('clear'),

            onPressed: _clear,

            icon: const Icon(Icons.delete_outline_rounded),

          ),

        ],

      ),

      body: loading

          ? const Center(child: CircularProgressIndicator())

          : Column(

              children: [

                _locationBar(),

                Expanded(

                  child: ListView(

                    controller: scrollController,

                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),

                    children: [

                      if (messages.isEmpty) _welcome(),

                      ...messages.map(_bubble),

                      if (asking) _thinking(),

                      if (error != null) _error(error!),

                      if (lastResponse != null) ...[

                        const SizedBox(height: 10),

                        _structured(lastResponse!),

                      ],

                    ],

                  ),

                ),

                _composer(),

              ],

            ),

    );

  }



  Widget _locationBar() {

    return Container(

      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),

      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: const Color(0xFFE0E9ED)),

      ),

      child: Row(

        children: [

          Icon(
            useDemoSeaPoint
                ? Icons.science_rounded
                : position != null
                    ? Icons.my_location_rounded
                    : Icons.location_off_rounded,
            color: useDemoSeaPoint
                ? AppTheme.warning
                : position != null
                    ? AppTheme.oceanBlue
                    : AppTheme.warning,
          ),

          const SizedBox(width: 8),

          Expanded(

            child: Text(

              useDemoSeaPoint
                  ? tr('demo')
                  : position != null
                      ? tr('gps')
                      : vtr('gps_missing'),

              style: const TextStyle(

                color: AppTheme.navy,

                fontWeight: FontWeight.w700,

              ),

            ),

          ),

          Switch.adaptive(

            value: useDemoSeaPoint,

            onChanged: (value) async {
              setState(() {
                useDemoSeaPoint = value;
                lastResponse = null;
              });

              if (!value && position == null) {
                final refreshed = await _tryPosition();

                if (mounted) {
                  setState(() => position = refreshed);
                }
              }
            },

          ),

        ],

      ),

    );

  }



  Widget _welcome() {
    final prompts =
        quickQuestions[language] ?? quickQuestions['en']!;

    final voiceLabel = !voiceChecked
        ? vtr('voice_checking')
        : speechReady && ttsReady
            ? vtr('voice_ready')
            : vtr('voice_partial');

    final voiceColor = !voiceChecked
        ? AppTheme.oceanBlue
        : speechReady && ttsReady
            ? AppTheme.success
            : AppTheme.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.navy,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vtr('welcome'),
                style: const TextStyle(
                  color: Colors.white,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 13),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      speechReady && ttsReady
                          ? Icons.record_voice_over_rounded
                          : Icons.info_outline_rounded,
                      color: voiceColor,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        voiceLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(
          vtr('quick'),
          style: const TextStyle(
            color: AppTheme.navy,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: prompts
              .map(
                (prompt) => ActionChip(
                  avatar: const Icon(
                    Icons.mic_rounded,
                    size: 16,
                  ),
                  label: Text(prompt),
                  onPressed: asking
                      ? null
                      : () async {
                          controller.text = prompt;
                          controller.selection =
                              TextSelection.fromPosition(
                            TextPosition(
                              offset: controller.text.length,
                            ),
                          );
                          await _ask();
                        },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _bubble(OrcaChatMessageData message) {

    final user = message.role == 'user';



    return Align(

      alignment: user ? Alignment.centerRight : Alignment.centerLeft,

      child: Container(

        constraints: const BoxConstraints(maxWidth: 330),

        margin: const EdgeInsets.only(top: 10),

        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(

          color: user ? AppTheme.oceanBlue : Colors.white,

          borderRadius: BorderRadius.circular(19),

          border: user ? null : Border.all(color: const Color(0xFFE0E9ED)),

        ),

        child: Text(

          message.content,

          style: TextStyle(

            color: user ? Colors.white : AppTheme.navy,

            height: 1.45,

          ),

        ),

      ),

    );

  }



  Widget _thinking() {

    return const Padding(

      padding: EdgeInsets.only(top: 14),

      child: Row(

        children: [

          SizedBox(

            width: 22,

            height: 22,

            child: CircularProgressIndicator(strokeWidth: 2.5),

          ),

          SizedBox(width: 10),

          Text('ORCA agents are checking evidence...'),

        ],

      ),

    );

  }



  Widget _error(String value) {

    return Padding(

      padding: const EdgeInsets.only(top: 12),

      child: Text(value, style: const TextStyle(color: AppTheme.danger)),

    );

  }



  Widget _structured(OrcaAgentResponseData data) {

    return Container(

      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: const Color(0xFFE0E9ED)),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          _section(tr('decision'), data.shortAnswer),

          _section(tr('why'), data.laymanExplanation),

          _section(tr('action'), data.recommendation),

          const Divider(height: 24),

          Text(

            tr('tools'),

            style: const TextStyle(

              color: AppTheme.navy,

              fontWeight: FontWeight.w900,

            ),

          ),

          const SizedBox(height: 7),

          Wrap(

            spacing: 7,

            runSpacing: 7,

            children: data.executedTools

                .map((tool) => Chip(label: Text(tool)))

                .toList(),

          ),

          if (data.evidence.isNotEmpty) ...[

            const SizedBox(height: 12),

            Text(

              tr('evidence'),

              style: const TextStyle(

                color: AppTheme.navy,

                fontWeight: FontWeight.w900,

              ),

            ),

            const SizedBox(height: 6),

            ...data.evidence.map(

              (e) => Padding(

                padding: const EdgeInsets.only(bottom: 6),

                child: Text(

                  '${e.label}: ${e.value} • ${e.source}',

                  style: const TextStyle(

                    color: Color(0xFF667A82),

                    fontSize: 11.5,

                  ),

                ),

              ),

            ),

          ],

          const SizedBox(height: 8),

          Row(

            children: [

              OutlinedButton.icon(

                onPressed: () => _speak(data.spokenText),

                icon: const Icon(Icons.volume_up_rounded),

                label: Text(tr('speak')),

              ),

              const SizedBox(width: 8),

              Expanded(

                child: Wrap(

                  spacing: 6,

                  runSpacing: 6,

                  children: data.actions

                      .map(

                        (a) => TextButton(

                          onPressed: () => _openAction(a),

                          child: Text(a.label),

                        ),

                      )

                      .toList(),

                ),

              ),

            ],

          ),

        ],

      ),

    );

  }



  Widget _section(String title, String body) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 11),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(

            title,

            style: const TextStyle(

              color: AppTheme.oceanBlue,

              fontSize: 11,

              fontWeight: FontWeight.w900,

            ),

          ),

          const SizedBox(height: 3),

          Text(

            body,

            style: const TextStyle(

              color: AppTheme.navy,

              fontSize: 14.5,

              height: 1.45,

              fontWeight: FontWeight.w700,

            ),

          ),

        ],

      ),

    );

  }



  Widget _composer() {

    return Container(

      padding: EdgeInsets.fromLTRB(

        12,

        9,

        12,

        9 + MediaQuery.of(context).padding.bottom,

      ),

      color: Colors.white,

      child: Row(

        children: [

          IconButton.filledTonal(

            onPressed: _listen,

            icon: Icon(listening ? Icons.mic_rounded : Icons.mic_none_rounded),

          ),

          const SizedBox(width: 7),

          Expanded(

            child: TextField(

              controller: controller,

              minLines: 1,

              maxLines: 4,

              textInputAction: TextInputAction.send,

              onSubmitted: (_) => _ask(),

              decoration: InputDecoration(

                hintText: listening ? tr('listening') : tr('hint'),

                filled: true,

                fillColor: const Color(0xFFF4F8FA),

                border: OutlineInputBorder(

                  borderRadius: BorderRadius.circular(18),

                  borderSide: BorderSide.none,

                ),

              ),

            ),

          ),

          const SizedBox(width: 7),

          IconButton.filled(

            onPressed: asking ? null : _ask,

            icon: const Icon(Icons.arrow_upward_rounded),

          ),

        ],

      ),

    );

  }

}
