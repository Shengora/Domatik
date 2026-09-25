class CommandParser {
  static final Map<String, List<String>> _openAppSynonyms = {
    'uz': ['och', 'kir', 'ochib ber', 'ochib yubor', 'kirsam', 'yoq'],
    'ru': ['открой', 'запусти', 'войди в', 'включи'],
    'en': ['open', 'start', 'launch', 'run'],
  };

  static final Map<String, List<String>> _callSynonyms = {
    'uz': ['telefon qil', 'qo\'ng\'iroq qil', 'qongiroq qil', 'telefon qilib yubor', 'chaqir', 'ter', 'telefon qiling', 'qo\'ng\'iroq qiling'],
    'ru': ['позвони', 'набери', 'вызови', 'звонок'],
    'en': ['call', 'dial', 'phone'],
  };

  static final Map<String, List<String>> _swipeSynonyms = {
    'uz': ['tepaga', 'pastga', 'o\'tka', 'sur', 'o\'tkaz', 'skrol qil'],
    'ru': ['вверх', 'вниз', 'свайп', 'пролистай', 'прокрути'],
    'en': ['up', 'down', 'swipe', 'scroll'],
  };

  static final Map<String, List<String>> _stopSwipeSynonyms = {
    'uz': ['to\'xtat', 'to\'xta', 'bas'],
    'ru': ['стоп', 'хватит', 'останови'],
    'en': ['stop', 'halt', 'pause'],
  };

  static final List<String> _fillerWords = [
    'iltimos', 'endi', 'keyin', 'qani', 'qilib', 'yubor', 'chiq', 'qil', 'ber', 'sot', 'sotib', 'ol'
  ];

  static Map<String, dynamic> parse(String text, String localeCode) {
    String lowerText = text.toLowerCase().trim();

    // Remove filler words safely (only if they are standalone words)
    for (String filler in _fillerWords) {
      lowerText = lowerText.replaceAll(RegExp(r'\b' + filler + r'\b'), '').trim();
    }

    // Normalize spaces
    lowerText = lowerText.replaceAll(RegExp(r'\s+'), ' ');

    // 1. Check for "Stop Swipe"
    if (_matchesIntent(lowerText, _stopSwipeSynonyms[localeCode] ?? [])) {
      return {'action': 'stop_swipe', 'params': {}};
    }

    // 2. Check for "Swipe"
    if (_matchesIntent(lowerText, _swipeSynonyms[localeCode] ?? [])) {
      String direction = 'up';
      if (lowerText.contains('past') || lowerText.contains('вниз') || lowerText.contains('down')) {
        direction = 'down';
      }
      return {'action': 'swipe', 'params': {'direction': direction, 'count': 1}};
    }

    // 3. Check for "Call"
    String? callKeyword = _findKeyword(lowerText, _callSynonyms[localeCode] ?? []);
    if (callKeyword != null) {
      String target = lowerText.replaceAll(callKeyword, '').trim();
      target = _cleanTargetName(target, localeCode);
      if (target.isNotEmpty) {
        return {'action': 'call', 'params': {'name': target}};
      }
    }

    // 4. Check for "Open App"
    String? openKeyword = _findKeyword(lowerText, _openAppSynonyms[localeCode] ?? []);
    if (openKeyword != null) {
      String target = lowerText.replaceAll(openKeyword, '').trim();
      target = _cleanTargetName(target, localeCode);
      if (target.isNotEmpty) {
         return {'action': 'open_app', 'params': {'appName': target}};
      }
    }

    // Fallback: Default to open app if it's just one word and we're not sure,
    // or return unknown. Based on requirements, better to be strict and return unknown.
    return {'action': 'unknown', 'params': {}};
  }

  static bool _matchesIntent(String text, List<String> synonyms) {
    for (String synonym in synonyms) {
      if (text.contains(synonym)) {
        return true;
      }
    }
    return false;
  }

  static String? _findKeyword(String text, List<String> synonyms) {
    for (String synonym in synonyms) {
      if (text.contains(synonym)) {
        return synonym;
      }
    }
    return null;
  }

  static String _cleanTargetName(String name, String localeCode) {
    if (name.isEmpty) return name;

    String cleaned = name.trim();

    if (localeCode == 'uz') {
      // Remove Uzbek grammatical suffixes (accusative, dative, locative, ablative)
      // using regex to match them at the end of the word.
      // E.g., Dilshodga -> Dilshod, Telegramni -> Telegram, Chrome'ni -> Chrome, Whatsapp'ga -> Whatsapp

      cleaned = cleaned.replaceAll(RegExp(r"['`]?([nN]i|[gG]a|[dD]an|[dD]a|[qQ]a|[kK]a|[nN]ing)$"), "");

      // Secondary pass if there are multiple words (e.g. "Dilshod Aliyevga")
      List<String> words = cleaned.split(' ');
      if (words.isNotEmpty) {
        words[words.length - 1] = words[words.length - 1].replaceAll(RegExp(r"['`]?([nN]i|[gG]a|[dD]an|[dD]a|[qQ]a|[kK]a|[nN]ing)$"), "");
        cleaned = words.join(' ');
      }
    } else if (localeCode == 'ru') {
       // Russian morphological endings are harder with simple regex, but we can do basic trimming
       // like "в Telegram" -> "Telegram" or "позвони Алексею" -> "Алексею" (Contact search will use partial match anyway).
       cleaned = cleaned.replaceAll(RegExp(r"^(в|на|к)\s+"), "");
    }

    // Capitalize first letter of each word to help with contact/app searching
    // (though Kotlin native side will also use ignoreCase)
    return cleaned;
  }
}