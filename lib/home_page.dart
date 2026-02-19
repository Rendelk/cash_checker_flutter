import 'package:flutter/material.dart';
import '../../data/models/account.dart';
import '../../data/repositories/wallet_repository.dart';

class HomePage extends StatefulWidget {
  final Locale locale;
  const HomePage({super.key, required this.locale});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = WalletRepository();
  List<Account> _accounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _repo.getAccounts();
    if (!mounted) return;
    setState(() {
      _accounts = data;
      _loading = false;
    });
  }

  Future<void> _addAccountDialog() async {
    final nameCtrl = TextEditingController();
    final balCtrl = TextEditingController(text: '0');
    String type = 'card';
    String currency = 'UAH';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новий рахунок'),
        content: StatefulBuilder(
          builder: (ctx, setD) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Назва')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: 'card', child: Text('Картка')),
                    DropdownMenuItem(value: 'cash', child: Text('Готівка')),
                  ],
                  onChanged: (v) => setD(() => type = v ?? 'card'),
                  decoration: const InputDecoration(labelText: 'Тип'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: currency,
                  items: const [
                    DropdownMenuItem(value: 'UAH', child: Text('UAH')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  ],
                  onChanged: (v) => setD(() => currency = v ?? 'UAH'),
                  decoration: const InputDecoration(labelText: 'Валюта'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: balCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Початковий баланс'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Зберегти')),
        ],
      ),
    );

    if (ok != true) return;

    final balance = double.tryParse(balCtrl.text.replaceAll(',', '.')) ?? 0;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    await _repo.addAccount(
      name: name,
      type: type,
      currencyCode: currency,
      balance: balance,
    );
    await _load();
  }

  Future<void> _deleteAccount(Account a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Видалити рахунок?'),
        content: Text('Рахунок "${a.name}" і всі його операції будуть видалені.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await _repo.deleteAccount(a.id);
    await _load();
  }

double get _totalUah => _accounts
      .where((a) => a.currencyCode == 'UAH')
      .fold(0, (p, a) => p + a.balance);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Загальний баланс', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                Text('${_totalUah.toStringAsFixed(2)} UAH',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Ваші рахунки', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: _addAccountDialog, icon: const Icon(Icons.add_circle)),
            ],
          ),
          const SizedBox(height: 8),
          if (_accounts.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Немає рахунків. Натисніть + щоб додати.'),
              ),
            )
          else
            ..._accounts.map((a) => Dismissible(
                  key: ValueKey(a.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    await _deleteAccount(a);
                    return false; // видаляємо самі через repo + reload
                  },
                  child: Card(
                    child: ListTile(
                      title: Text(a.name),
                      subtitle: Text('${a.type.toUpperCase()} • ${a.currencyCode}'),
                      trailing: Text(
                        '${a.balance.toStringAsFixed(2)} ${a.currencyCode}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
