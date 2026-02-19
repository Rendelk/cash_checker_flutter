import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_strings.dart';
import 'features/add/add_page.dart';
import 'features/calendar/calendar_page.dart';
import 'features/debts/debts_page.dart';
import 'features/history/history_page.dart';
import 'features/home/home_page.dart';

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
          title: Text(S.of(_locale, 'app_title')),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.language),
              onSelected: (value) => setState(() => _locale = Locale(value)),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'uk',
                  child: Row(children: [
                    if (_locale.languageCode == 'uk') const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                    const Text('Українська'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'en',
                  child: Row(children: [
                    if (_locale.languageCode == 'en') const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                    const Text('English'),
                  ]),
                ),
              ],
            ),
          ],
        ),
        body: switch (_tab) {
          AppTab.home => HomePage(locale: _locale),
          AppTab.history => HistoryPage(locale: _locale),
          AppTab.calendar => CalendarPage(locale: _locale),
          AppTab.add => AddPage(locale: _locale),
          AppTab.debts => DebtsPage(locale: _locale),
        },
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (i) => setState(() => _tab = AppTab.values[i]),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home), label: S.of(_locale, 'tab_home')),
            NavigationDestination(icon: const Icon(Icons.history), label: S.of(_locale, 'tab_history')),
            NavigationDestination(icon: const Icon(Icons.calendar_month), label: S.of(_locale, 'tab_calendar')),
            NavigationDestination(icon: const Icon(Icons.add_circle), label: S.of(_locale, 'tab_add')),
            NavigationDestination(icon: const Icon(Icons.receipt_long), label: S.of(_locale, 'tab_debts')),
          ],
        ),
      ),
    );
  }
}
