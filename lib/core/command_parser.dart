class CommandParser {
  // Sort synonyms by length descending so we match "ochib yubor" before "och"
  static final Map<String, List<String>> _openAppSynonyms = {
    'uz': ['ochib yubor', 'ochib ber', 'kirsam', 'yoq', 'och', 'kir'],
    'ru': ['запусти', 'открой', 'войди в', 'включи'],
    'en': ['launch', 'start', 'open', 'run'],
  };

  static final Map<String, List<String>> _callSynonyms = {
    'uz': ['telefon qilib yubor', 'qo\'ng\'iroq qiling', 'qo\'ng\'iroq qil', 'qongiroq qil', 'telefon qiling', 'telefon qil', 'chaqir', 'ter'],
    'ru': ['позвони', 'набери', 'вызови', 'звонок'],
    'en': ['phone', 'call', 'dial'],
  };

  static final Map<String, List<String>> _smsSynonyms = {
    'uz': ['xabar yubor', 'xabar yoz', 'sms yubor', 'sms yoz', 'sms jo\'nat', 'xat yoz'],
    'ru': ['отправь смс', 'напиши сообщение', 'сообщение'],
    'en': ['send message', 'text', 'sms'],
  };

  static final Map<String, List<String>> _swipeSynonyms = {
    'uz': ['skrol qil', 'tepaga', 'pastga', 'o\'tkaz', 'o\'tka', 'sur'],
    'ru': ['пролистай', 'прокрути', 'свайп', 'вверх', 'вниз'],
    'en': ['scroll', 'swipe', 'down', 'up'],
  };

  static final Map<String, List<String>> _stopSwipeSynonyms = {
    'uz': ['to\'xtat', 'to\'xta', 'bas'],
    'ru': ['останови', 'хватит', 'стоп'],
    'en': ['pause', 'stop', 'halt'],
  };

  // Filler words that are truly unnecessary regardless of context.
  // Note: "qil", "ber", "yubor" are removed from here because they are part of intents (e.g. "telefon qil").
  // They will be handled explicitly if they remain dangling.
  static final List<String> _fillerWords = [
    'iltimos', 'endi', 'keyin', 'qani', 'sot', 'sotib', 'ol'
  ];

  static Map<String, dynamic> parse(String text, String localeCode) {
    String lowerText = text.toLowerCase().trim();

    // Normalize spaces
    lowerText = lowerText.replaceAll(RegExp(r'\s+'), ' ');

    // Remove safe filler words BEFORE intent matching
    for (String filler in _fillerWords) {
      lowerText = lowerText.replaceAll(RegExp(r'\b' + filler + r'\b'), '').trim();
      lowerText = lowerText.replaceAll(RegExp(r'\s+'), ' '); // re-normalize
    }

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

    // 3. Check for "SMS"
    String? smsKeyword = _findKeyword(lowerText, _smsSynonyms[localeCode] ?? []);
    if (smsKeyword != null) {
      String target = lowerText.replaceAll(RegExp(r'\b' + smsKeyword + r'\b'), '').trim();
      target = _cleanTargetName(target, localeCode);
      if (target.isNotEmpty) {
        // We will map SMS to an intent (maybe not implemented natively yet, but parser is ready)
        return {'action': 'sms', 'params': {'name': target}};
      }
    }

    // 4. Check for "Call"
    String? callKeyword = _findKeyword(lowerText, _callSynonyms[localeCode] ?? []);
    if (callKeyword != null) {
      // Remove exactly the keyword
      String target = lowerText.replaceAll(RegExp(r'\b' + callKeyword + r'\b'), '').trim();
      target = _cleanTargetName(target, localeCode);
      if (target.isNotEmpty) {
        return {'action': 'call', 'params': {'name': target}};
      }
    }

    // 5. Check for "Open App"
    String? openKeyword = _findKeyword(lowerText, _openAppSynonyms[localeCode] ?? []);
    if (openKeyword != null) {
      String target = lowerText.replaceAll(RegExp(r'\b' + openKeyword + r'\b'), '').trim();
      target = _cleanTargetName(target, localeCode);
      if (target.isNotEmpty) {
         return {'action': 'open_app', 'params': {'appName': target}};
      }
    }

    // Fallback
    return {'action': 'unknown', 'params': {}};
  }

  static bool _matchesIntent(String text, List<String> synonyms) {
    for (String synonym in synonyms) {
      if (text.contains(RegExp(r'\b' + synonym + r'\b'))) {
        return true;
      }
    }
    return false;
  }

  static String? _findKeyword(String text, List<String> synonyms) {
    for (String synonym in synonyms) {
      if (text.contains(RegExp(r'\b' + synonym + r'\b'))) {
        return synonym;
      }
    }
    return null;
  }

  static String _cleanTargetName(String name, String localeCode) {
    if (name.isEmpty) return name;

    String cleaned = name.trim();

    // 1. Clean dangling verbs from end (e.g., if someone says "Dilshodga qilib yubor", and 'qil' was missed)
    final List<String> danglingVerbs = ['qilib', 'qil', 'yubor', 'ber'];
    for (String verb in danglingVerbs) {
       cleaned = cleaned.replaceAll(RegExp(r'\b' + verb + r'\b$'), '').trim();
    }

    if (localeCode == 'uz') {
      // Remove Uzbek grammatical suffixes (accusative, dative, locative, ablative)
      // E.g., Dilshodga -> Dilshod, Telegramni -> Telegram
      List<String> words = cleaned.split(' ');
      if (words.isNotEmpty) {
        words[words.length - 1] = words[words.length - 1].replaceAll(RegExp(r"['`]?([nN]i|[gG]a|[dD]an|[dD]a|[qQ]a|[kK]a|[nN]ing)$"), "");
        cleaned = words.join(' ');
      }
    } else if (localeCode == 'ru') {
       // "в Telegram", "позвони Алексею" (Russian suffixes are harder, partial match will handle it)
       cleaned = cleaned.replaceAll(RegExp(r"^(в|на|к)\s+"), "");
    }

    return cleaned;
  }
}