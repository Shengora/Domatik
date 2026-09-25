class CommandParser {
  // Returns a Map representing {"action": "...", "params": {...}}
  static Map<String, dynamic> parse(String text) {
    text = text.toLowerCase().trim();

    // 0. To'xtatish buyrug'i
    final stopRegex = RegExp(r'^(?:to\'xta|yetadi|stop|стоп|хватит)$');
    if (stopRegex.hasMatch(text)) {
      return {"action": "stop_swipe", "params": {}};
    }

    // 1. Ilova ochish (App open)
    final openRegexUz = RegExp(r'^(.+?)\s+och(?:ib yubor)?$');
    final openRegexEn = RegExp(r'^open\s+(.+)$');
    final openRegexRu = RegExp(r'^(?:открой|открыть)\s+(.+)$');

    if (openRegexUz.hasMatch(text)) {
      final match = openRegexUz.firstMatch(text);
      return {"action": "open_app", "params": {"appName": match?.group(1)?.trim()}};
    } else if (openRegexEn.hasMatch(text)) {
      final match = openRegexEn.firstMatch(text);
      return {"action": "open_app", "params": {"appName": match?.group(1)?.trim()}};
    } else if (openRegexRu.hasMatch(text)) {
      final match = openRegexRu.firstMatch(text);
      return {"action": "open_app", "params": {"appName": match?.group(1)?.trim()}};
    }

    // 2. Qo'ng'iroq qilish (Call)
    final callRegexUz = RegExp(r"^(.+?)ga\s+(?:qo'ng'iroq|telefon)\s+qil$");
    final callRegexEn = RegExp(r'^call\s+(.+)$');
    final callRegexRu = RegExp(r'^позвони\s+(.+)$');

    if (callRegexUz.hasMatch(text)) {
      final match = callRegexUz.firstMatch(text);
      return {"action": "call", "params": {"name": match?.group(1)?.trim()}};
    } else if (callRegexEn.hasMatch(text)) {
      final match = callRegexEn.firstMatch(text);
      return {"action": "call", "params": {"name": match?.group(1)?.trim()}};
    } else if (callRegexRu.hasMatch(text)) {
      final match = callRegexRu.firstMatch(text);
      return {"action": "call", "params": {"name": match?.group(1)?.trim()}};
    }

    // 3. Swipe (pastga sur, tepaga sur) + takrorlash (masalan "10 ta sur" yoki "10 marta sur")
    final swipeDownRegex = RegExp(r'^(?:pastga sur|keyingi|swipe up|свайп вниз|вниз)(?:\s+(\d+)\s*(?:ta|marta|раз|times)?)?$');
    final swipeDownPrefixRegex = RegExp(r'^(\d+)\s*(?:ta|marta|раз|times)\s*(?:pastga sur|keyingi|swipe up|свайп вниз|вниз)$');

    final swipeUpRegex = RegExp(r'^(?:tepaga sur|oldingisi|swipe down|свайп вверх|вверх)(?:\s+(\d+)\s*(?:ta|marta|раз|times)?)?$');
    final swipeUpPrefixRegex = RegExp(r'^(\d+)\s*(?:ta|marta|раз|times)\s*(?:tepaga sur|oldingisi|swipe down|свайп вверх|вверх)$');

    if (swipeDownRegex.hasMatch(text)) {
      final match = swipeDownRegex.firstMatch(text);
      int count = int.tryParse(match?.group(1) ?? '1') ?? 1;
      return {"action": "swipe", "params": {"direction": "up", "count": count}};
    } else if (swipeDownPrefixRegex.hasMatch(text)) {
      final match = swipeDownPrefixRegex.firstMatch(text);
      int count = int.tryParse(match?.group(1) ?? '1') ?? 1;
      return {"action": "swipe", "params": {"direction": "up", "count": count}};
    }

    if (swipeUpRegex.hasMatch(text)) {
      final match = swipeUpRegex.firstMatch(text);
      int count = int.tryParse(match?.group(1) ?? '1') ?? 1;
      return {"action": "swipe", "params": {"direction": "down", "count": count}};
    } else if (swipeUpPrefixRegex.hasMatch(text)) {
      final match = swipeUpPrefixRegex.firstMatch(text);
      int count = int.tryParse(match?.group(1) ?? '1') ?? 1;
      return {"action": "swipe", "params": {"direction": "down", "count": count}};
    }

    return {"action": "unknown", "params": {}};
  }
}
