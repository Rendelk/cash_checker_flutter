import 'package:flutter/material.dart';

import 'account.dart';
import 'app_strings.dart';
import 'wallet_repository.dart';

class HomePage extends StatefulWidget {
  final Locale locale;
  const HomePage({super.key, required this.locale});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = WalletRepository();

  List<Account> _accounts = [];
  Map<String, double> _monthExpense = {};
  bool _loading = true;
  String _selectedCurrency = 'UAH';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accounts = await _repo.getAccounts();
    final monthExpense = await _repo.monthlyExpenseByCurrency();

    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _monthExpense = monthExpense;
      final currencies = _accounts.map((e) => e.currencyCode).toSet().toList();
      if (currencies.isNotEmpty && !currencies.contains(_selectedCurrency)) {
        _selectedCurrency = currencies.first;
      }
      _loading = false;
    });
  }

  double get _totalBalance {
    return _accounts
        .where((a) => a.currencyCode == _selectedCurrency)
        .fold(0.0, (p, a) => p + a.balance);
  }

  double get _totalMonthExpense => _monthExpense[_selectedCurrency] ?? 0.0;

  Future<bool?> _confirmDelete(Account a) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(S.of(widget.locale, 'delete_account')),
        content: Text(S.of(widget.locale, 'delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(widget.locale, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.of(widget.locale, 'delete')),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAccount(Account a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(S.of(widget.locale, 'clear_account')),
        content: Text(S.of(widget.locale, 'clear_account_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(widget.locale, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.of(widget.locale, 'clear')),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _repo.clearAccountTransactions(a.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(widget.locale, 'account_cleared'))),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final currencies = _accounts.map((e) => e.currencyCode).toSet().toList()..sort();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            S.of(widget.locale, 'home_title'),
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          if (currencies.isNotEmpty)
            Wrap(
              spacing: 8,
              children: currencies
                  .map(
                    (c) => ChoiceChip(
                      label: Text(c),
                      selected: _selectedCurrency == c,
                      onSelected: (_) => setState(() => _selectedCurrency = c),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: S.of(widget.locale, 'total_balance'),
                  value: '${_totalBalance.toStringAsFixed(2)} $_selectedCurrency',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  title: S.of(widget.locale, 'total_expense_month'),
                  value: '${_totalMonthExpense.toStringAsFixed(2)} $_selectedCurrency',
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          Text(
            S.of(widget.locale, 'your_accounts'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),

          if (_accounts.isEmpty)
            Text(S.of(widget.locale, 'no_accounts'))
          else
            ..._accounts.map((a) {
              return Dismissible(
                key: ValueKey(a.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade500,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                ),
                confirmDismiss: (_) => _confirmDelete(a),
                onDismissed: (_) async {
                  await _repo.deleteAccount(a.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.of(widget.locale, 'account_deleted'))),
                  );
                  _load();
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(a.name),
                    subtitle: Text('${a.type.toUpperCase()} • ${a.currencyCode}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'clear') {
                          await _clearAccount(a);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'clear',
                          child: Text(S.of(widget.locale, 'clear_account')),
                        ),
                      ],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${a.balance.toStringAsFixed(2)} ${a.currencyCode}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          const Icon(Icons.more_horiz, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryCard({
    required this.title,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}