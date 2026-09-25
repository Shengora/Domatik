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
    'uz': ['deb yoz', 'xabar yubor', 'xabar yoz', 'sms yubor', 'sms yoz', 'sms jo\'nat', 'xat yoz'],
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

  static final Map<String, List<String>> _wifiSynonyms = {
    'uz': ['wi-fi ni', 'wi-fini', 'wifini', 'wifi ni', 'wi-fi', 'wifi', 'vayfay'],
    'ru': ['wi-fi', 'вай-фай', 'wifi'],
    'en': ['wi-fi', 'wifi'],
  };

  static final Map<String, List<String>> _bluetoothSynonyms = {
    'uz': ['bluetooth ni', 'bluetoothni', 'bluetooth', 'blyutuzni', 'blyutuz'],
    'ru': ['bluetooth', 'блютуз'],
    'en': ['bluetooth'],
  };

  static final Map<String, List<String>> _flashlightSynonyms = {
    'uz': ['chiroqni', 'chiroq', 'fonar'],
    'ru': ['фонарик', 'фонарь', 'свет'],
    'en': ['flashlight', 'torch', 'light'],
  };

  static final Map<String, List<String>> _volumeSynonyms = {
    'uz': ['ovozini', 'ovozni', 'ovoz'],
    'ru': ['звук', 'громкость'],
    'en': ['volume', 'sound'],
  };

  static final Map<String, List<String>> _brightnessSynonyms = {
    'uz': ['yorug\'likni', 'yorug\'lik', 'yorqinlikni', 'yorqinlik', 'ekran nurini', 'nurni'],
    'ru': ['яркость', 'свет экрана'],
    'en': ['brightness', 'screen light'],
  };

  static final Map<String, List<String>> _alarmSynonyms = {
    'uz': ['da uyg\'ot', 'uyg\'ot'],
    'ru': ['разбуди в', 'разбуди', 'будильник на'],
    'en': ['wake me up at', 'wake me at', 'set alarm for'],
  };

  static final Map<String, List<String>> _timerSynonyms = {
    'uz': ['daqiqalik taymer', 'taymer qo\'y', 'taymer'],
    'ru': ['таймер на', 'поставь таймер'],
    'en': ['timer for', 'set timer'],
  };

  static final Map<String, List<String>> _webSearchSynonyms = {
    'uz': ['google da qidir', 'googleda qidir', 'internetdan top', 'qidir', 'top'],
    'ru': ['найди в гугле', 'найди в интернете', 'поиск', 'найди'],
    'en': ['search google for', 'search for', 'find online', 'search'],
  };

  static final List<String> _turnOnSynonyms = ['yoq', 'qo\'y', 'включи', 'включить', 'turn on', 'enable'];
  static final List<String> _turnOffSynonyms = ['o\'chir', 'o\'chirib', 'выключи', 'выключить', 'turn off', 'disable'];
  static final List<String> _increaseSynonyms = ['oshir', 'ko\'paytir', 'balandlat', 'увеличь', 'повысь', 'increase', 'raise', 'up'];
  static final List<String> _decreaseSynonyms = ['pasaytir', 'kamaytir', 'уменьши', 'снизь', 'decrease', 'lower', 'down'];

  // Filler words that are truly unnecessary regardless of context.
  // Note: "qil", "ber", "yubor", "deb", "ga" are handled situationally to preserve semantics.
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

    // Check for "Web Search"
    String? searchKeyword = _findKeyword(lowerText, _webSearchSynonyms[localeCode] ?? []);
    if (searchKeyword != null) {
      String query = lowerText.replaceAll(RegExp(r'\b' + searchKeyword + r'\b'), '').trim();
      // specifically remove "google'da" variations
      query = query.replaceAll(RegExp(r"google(\s*)?['`]?(da)?", caseSensitive: false), "").trim();
      // clean suffix
      if (localeCode == 'uz') {
        query = query.replaceAll(RegExp(r"['`]?ni$"), "").trim();
      }
      if (query.isNotEmpty) {
        return {'action': 'web_search', 'params': {'query': query}};
      }
    }

    // Check for "System Control: Wi-Fi"
    if (_matchesIntent(lowerText, _wifiSynonyms[localeCode] ?? [])) {
      bool turnOn = _matchesIntent(lowerText, _turnOnSynonyms);
      return {'action': 'control_wifi', 'params': {'turnOn': turnOn}};
    }

    // Check for "System Control: Bluetooth"
    if (_matchesIntent(lowerText, _bluetoothSynonyms[localeCode] ?? [])) {
      bool turnOn = _matchesIntent(lowerText, _turnOnSynonyms);
      return {'action': 'control_bluetooth', 'params': {'turnOn': turnOn}};
    }

    // Check for "System Control: Flashlight"
    if (_matchesIntent(lowerText, _flashlightSynonyms[localeCode] ?? [])) {
      bool turnOn = _matchesIntent(lowerText, _turnOnSynonyms);
      return {'action': 'control_flashlight', 'params': {'turnOn': turnOn}};
    }

    // Check for "System Control: Volume"
    if (_matchesIntent(lowerText, _volumeSynonyms[localeCode] ?? [])) {
      bool increase = _matchesIntent(lowerText, _increaseSynonyms);
      bool decrease = _matchesIntent(lowerText, _decreaseSynonyms);

      String stream = "music";
      if (lowerText.contains("qo'ng'iroq") || lowerText.contains("звонок") || lowerText.contains("ring")) stream = "ring";
      if (lowerText.contains("budilnik") || lowerText.contains("будильник") || lowerText.contains("alarm")) stream = "alarm";

      int? level;
      final digitMatch = RegExp(r'\d+').firstMatch(lowerText);
      if (digitMatch != null) {
        level = int.tryParse(digitMatch.group(0)!);
      }

      String direction = increase ? "up" : (decrease ? "down" : "set");
      if (direction == "set" && level == null) direction = "up"; // fallback default

      return {'action': 'control_volume', 'params': {'stream': stream, 'direction': direction, 'level': level}};
    }

    // Check for "System Control: Brightness"
    if (_matchesIntent(lowerText, _brightnessSynonyms[localeCode] ?? [])) {
      bool increase = _matchesIntent(lowerText, _increaseSynonyms);
      bool decrease = _matchesIntent(lowerText, _decreaseSynonyms);

      int? level;
      final digitMatch = RegExp(r'\d+').firstMatch(lowerText);
      if (digitMatch != null) {
        level = int.tryParse(digitMatch.group(0)!);
      }

      String direction = increase ? "up" : (decrease ? "down" : "set");
      if (direction == "set" && level == null) direction = "up";

      return {'action': 'control_brightness', 'params': {'direction': direction, 'level': level}};
    }

    // Check for "Alarm"
    String? alarmKeyword = _findKeyword(lowerText, _alarmSynonyms[localeCode] ?? []);
    if (alarmKeyword != null) {
       int hour = 0;
       int minute = 0;
       bool foundTime = false;
       final timeMatch = RegExp(r'(\d{1,2})[\s:.]?(\d{2})?').firstMatch(lowerText);
       if (timeMatch != null) {
          hour = int.parse(timeMatch.group(1)!);
          minute = timeMatch.group(2) != null ? int.parse(timeMatch.group(2)!) : 0;
          foundTime = true;
       } else {
          // parse word numbers for uzbek (basic: yetti, sakkiz etc.)
          Map<String, int> wordsMap = {
            'bir': 1, 'ikki': 2, 'uch': 3, 'to\'rt': 4, 'besh': 5, 'olti': 6, 'yetti': 7, 'sakkiz': 8, 'to\'qqiz': 9, 'o\'n': 10, 'o\'n bir': 11, 'o\'n ikki': 12
          };
          for (var entry in wordsMap.entries) {
            if (lowerText.contains(entry.key)) {
               hour = entry.value;
               foundTime = true;
               break;
            }
          }
       }

       if (foundTime) {
          if (lowerText.contains("yarim") || lowerText.contains("половина")) minute = 30;
          return {'action': 'set_alarm', 'params': {'hour': hour, 'minute': minute}};
       }
       return {'action': 'unknown_time', 'params': {}};
    }

    // Check for "Timer"
    String? timerKeyword = _findKeyword(lowerText, _timerSynonyms[localeCode] ?? []);
    if (timerKeyword != null) {
       final digitMatch = RegExp(r'\d+').firstMatch(lowerText);
       if (digitMatch != null) {
          int minutes = int.parse(digitMatch.group(0)!);
          return {'action': 'set_timer', 'params': {'minutes': minutes}};
       }
       return {'action': 'unknown_time', 'params': {}};
    }

    // Check for "SMS"
    // Templates: "[ism]ga [matn] deb yoz", "[ism]ga sms yubor: [matn]"
    String? smsKeyword = _findKeyword(lowerText, _smsSynonyms[localeCode] ?? []);
    if (smsKeyword != null) {
      // Find the keyword position to split Name vs Message.
      // Usually format is "[Name]ga sms yoz [Message]" or "[Name]ga [Message] deb sms yoz"

      String targetName = "";
      String message = "";

      if (localeCode == 'uz') {
         // Naive extraction for "ismga xabar yoz matn" or "ismga matn deb xabar yubor"
         if (lowerText.contains('deb')) {
            var parts = lowerText.split('deb');
            message = parts[0].trim();
            targetName = message.split(' ').first; // take first word as name
            message = message.substring(targetName.length).trim(); // rest is message
         } else {
            var parts = lowerText.split(smsKeyword);
            targetName = parts[0].trim();
            message = parts.length > 1 ? parts[1].trim() : "";
         }
      } else {
         var parts = lowerText.split(smsKeyword);
         targetName = parts[0].trim();
         message = parts.length > 1 ? parts[1].trim() : "";
      }

      targetName = _cleanTargetName(targetName, localeCode);
      if (targetName.isNotEmpty) {
        return {'action': 'sms', 'params': {'name': targetName, 'message': message}};
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