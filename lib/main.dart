import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'add_page.dart';
import 'app_strings.dart';
import 'calendar_page.dart';
import 'debts_page.dart';
import 'history_page.dart';
import 'home_page.dart';
import 'wallet_repository.dart';

void main() {
  runApp(const CashCheckerApp());
}

class CashCheckerApp extends StatefulWidget {
  const CashCheckerApp({super.key});

  @override
  State<CashCheckerApp> createState() => _CashCheckerAppState();
}

class _CashCheckerAppState extends State<CashCheckerApp> {
  final _repo = WalletRepository();

  Locale _locale = const Locale('uk');
  int _tabIndex = 0;
  bool _ready = false;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final seen = await _repo.isOnboardingSeen();
    if (!mounted) return;
    setState(() {
      _showOnboarding = !seen;
      _ready = true;
    });
  }

  Future<void> _finishOnboarding() async {
    await _repo.setOnboardingSeen(true);
    if (!mounted) return;
    setState(() => _showOnboarding = false);
  }

  Widget _buildCurrentTab() {
    switch (_tabIndex) {
      case 0:
        return HomePage(locale: _locale);
      case 1:
        return HistoryPage(locale: _locale);
      case 2:
        return CalendarPage(locale: _locale);
      case 3:
        return AddPage(locale: _locale);
      case 4:
        return DebtsPage(locale: _locale);
      default:
        return HomePage(locale: _locale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [Locale('uk'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: !_ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _showOnboarding
              ? _OnboardingView(
                  locale: _locale,
                  onChangeLocale: (l) => setState(() => _locale = l),
                  onFinish: _finishOnboarding,
                )
              : Scaffold(
                  appBar: AppBar(
                    title: Text(S.of(_locale, 'app_title')),
                    actions: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.language),
                        onSelected: (v) => setState(() => _locale = Locale(v)),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'uk', child: Text('Українська')),
                          PopupMenuItem(value: 'en', child: Text('English')),
                        ],
                      ),
                    ],
                  ),
                  body: _buildCurrentTab(),
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: _tabIndex,
                    onDestinationSelected: (v) => setState(() => _tabIndex = v),
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.home),
                        label: S.of(_locale, 'tab_home'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.history),
                        label: S.of(_locale, 'tab_history'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.calendar_month),
                        label: S.of(_locale, 'tab_calendar'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.add_circle),
                        label: S.of(_locale, 'tab_add'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.receipt_long),
                        label: S.of(_locale, 'tab_debts'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  final Locale locale;
  final ValueChanged<Locale> onChangeLocale;
  final VoidCallback onFinish;

  const _OnboardingView({
    required this.locale,
    required this.onChangeLocale,
    required this.onFinish,
  });

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final _controller = PageController();
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      (
        S.of(widget.locale, 'onboarding_title_1'),
        S.of(widget.locale, 'onboarding_body_1'),
        Icons.account_balance_wallet_outlined
      ),
      (
        S.of(widget.locale, 'onboarding_title_2'),
        S.of(widget.locale, 'onboarding_body_2'),
        Icons.pie_chart_outline
      ),
      (
        S.of(widget.locale, 'onboarding_title_3'),
        S.of(widget.locale, 'onboarding_body_3'),
        Icons.calendar_month_outlined
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(widget.locale, 'app_title')),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (v) => widget.onChangeLocale(Locale(v)),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'uk', child: Text('Українська')),
              PopupMenuItem(value: 'en', child: Text('English')),
            ],
          ),
          TextButton(
            onPressed: widget.onFinish,
            child: Text(S.of(widget.locale, 'skip')),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) {
                final p = pages[i];
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(p.$3, size: 96),
                      const SizedBox(height: 24),
                      Text(
                        p.$1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p.$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              children: [
                ...List.generate(
                  pages.length,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page ? Colors.black : Colors.black26,
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () async {
                    if (_page == pages.length - 1) {
                      widget.onFinish();
                    } else {
                      await _controller.nextPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(
                    _page == pages.length - 1
                        ? S.of(widget.locale, 'start')
                        : S.of(widget.locale, 'next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
