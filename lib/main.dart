import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const CashCheckerApp());
}

enum AppTab { home, history, calendar, add, debts }

class CashCheckerApp extends StatefulWidget {
  const CashCheckerApp({super.key});

  @override
  State<CashCheckerApp> createState() => _CashCheckerAppState();
}

class _CashCheckerAppState extends State<CashCheckerApp> {
  Locale _locale = const Locale('uk');
  AppTab _tab = AppTab.home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [Locale('uk'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: Scaffold(
        appBar: AppBar(
          title: Text(T.of(_locale, 'app_title')),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.language),
              onSelected: (value) => setState(() => _locale = Locale(value)),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'uk',
                  child: Row(
                    children: [
                      if (_locale.languageCode == 'uk') const Icon(Icons.check, size: 18),
                      const SizedBox(width: 8),
                      const Text('Українська'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'en',
                  child: Row(
                    children: [
                      if (_locale.languageCode == 'en') const Icon(Icons.check, size: 18),
                      const SizedBox(width: 8),
                      const Text('English'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _buildPage(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (i) => setState(() => _tab = AppTab.values[i]),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home), label: T.of(_locale, 'tab_home')),
            NavigationDestination(icon: const Icon(Icons.history), label: T.of(_locale, 'tab_history')),
            NavigationDestination(icon: const Icon(Icons.calendar_month), label: T.of(_locale, 'tab_calendar')),
            NavigationDestination(icon: const Icon(Icons.add_circle), label: T.of(_locale, 'tab_add')),
            NavigationDestination(icon: const Icon(Icons.receipt_long), label: T.of(_locale, 'tab_debts')),
          ],
        ),
      ),
    );
  }

  Widget _buildPage() {
    switch (_tab) {
      case AppTab.home:
        return _Page(title: T.of(_locale, 'home_title'));
      case AppTab.history:
        return _Page(title: T.of(_locale, 'history_title'));
      case AppTab.calendar:
        return _Page(title: T.of(_locale, 'calendar_title'));
      case AppTab.add:
        return _Page(title: T.of(_locale, 'add_title'));
      case AppTab.debts:
        return _Page(title: T.of(_locale, 'debts_title'));
    }
  }
}

class _Page extends StatelessWidget {
  final String title;
  const _Page({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
    );
  }
}

class T {
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
