import 'dart:ui';

class S {
  static const Map<String, Map<String, String>> _m = {
    'uk': {
      'app_title': 'CashChecker',
      'tab_home': 'Головна',
      'tab_history': 'Історія',
      'tab_calendar': 'Календар',
      'tab_add': 'Додати',
      'tab_debts': 'Борги',
      'home_title': 'Головна',
      'history_title': 'Історія',
      'calendar_title': 'Календар',
      'add_title': 'Додати операцію',
      'debts_title': 'Борги',
    },
    'en': {
      'app_title': 'CashChecker',
      'tab_home': 'Home',
      'tab_history': 'History',
      'tab_calendar': 'Calendar',
      'tab_add': 'Add',
      'tab_debts': 'Debts',
      'home_title': 'Home',
      'history_title': 'History',
      'calendar_title': 'Calendar',
      'add_title': 'Add transaction',
      'debts_title': 'Debts',
    },
  };

  static String of(Locale locale, String key) {
    return _m[locale.languageCode]?[key] ?? _m['en']![key] ?? key;
  }
}
