import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_strings.dart';
import 'debt_item.dart';
import 'wallet_repository.dart';

class DebtsPage extends StatefulWidget {
  final Locale locale;
  const DebtsPage({super.key, required this.locale});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  final _repo = WalletRepository();

  bool _loading = true;
  List<DebtItem> _debts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final debts = await _repo.getDebts();
    if (!mounted) return;
    setState(() {
      _debts = debts;
      _loading = false;
    });
  }

  String _fmtDate(int ms) {
    return DateFormat('dd.MM.yyyy').format(DateTime.fromMillisecondsSinceEpoch(ms));
  }

  Future<void> _openAddDebt() async {
    final personCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    String direction = 'lent';
    String currency = 'UAH';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(S.of(widget.locale, 'add_debt')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: personCtrl,
                  decoration: InputDecoration(labelText: S.of(widget.locale, 'person_name')),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: direction,
                  decoration: InputDecoration(labelText: S.of(widget.locale, 'direction')),
                  items: [
                    DropdownMenuItem(value: 'lent', child: Text(S.of(widget.locale, 'i_lent'))),
                    DropdownMenuItem(value: 'borrowed', child: Text(S.of(widget.locale, 'i_borrowed'))),
                  ],
                  onChanged: (v) => setLocal(() => direction = v ?? 'lent'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: currency,
                  decoration: InputDecoration(labelText: S.of(widget.locale, 'currency')),
                  items: const [
                    DropdownMenuItem(value: 'UAH', child: Text('UAH')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  ],
                  onChanged: (v) => setLocal(() => currency = v ?? 'UAH'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: S.of(widget.locale, 'amount')),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(labelText: S.of(widget.locale, 'note')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(S.of(widget.locale, 'cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(S.of(widget.locale, 'save')),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final person = personCtrl.text.trim();
    final parsedAmount = double.tryParse(amountCtrl.text.replaceAll(',', '.').trim());
    if (person.isEmpty || parsedAmount == null ||  parsedAmount <= 0) return;
    await _repo.addDebt(
      personName: person,
      direction: direction,
      currencyCode: currency,
      amount: parsedAmount,
      note: noteCtrl.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(widget.locale, 'debt_added'))),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                S.of(widget.locale, 'debts_title'),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
              ),
            ),
            FilledButton.icon(
              onPressed: _openAddDebt,
              icon: const Icon(Icons.add),
              label: Text(S.of(widget.locale, 'add_debt')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_debts.isEmpty)
          Text(S.of(widget.locale, 'no_debts'))
        else
          ..._debts.map((d) {
            final isLent = d.direction == 'lent';

            return Card(
              child: ListTile(
  minVerticalPadding: 12,
  title: Text(
    d.personName,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  ),
  subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 4),
      Text(
        isLent ? S.of(widget.locale, 'i_lent') : S.of(widget.locale, 'i_borrowed'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        '${S.of(widget.locale, 'remaining')}: ${d.remaining.toStringAsFixed(2)} ${d.currencyCode}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        _fmtDate(d.createdAtMs),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: Text(
              '${d.amount.toStringAsFixed(2)} ${d.currencyCode}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            onSelected: (v) async {
              if (v == 'del') {
                await _repo.deleteDebt(d.id);
                _load();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'del',
                child: Text(S.of(widget.locale, 'delete')),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
),
            );
          }),
      ],
    );
  }
}