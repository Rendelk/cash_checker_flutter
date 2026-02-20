import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_strings.dart';
import 'planned_expense.dart';
import 'wallet_repository.dart';

class PlannedPage extends StatefulWidget {
  final Locale locale;
  const PlannedPage({super.key, required this.locale});

  @override
  State<PlannedPage> createState() => _PlannedPageState();
}

class _PlannedPageState extends State<PlannedPage> {
  final _repo = WalletRepository();
  bool _loading = true;
  List<PlannedExpense> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.getPlannedExpenses();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  String _fmtDate(int ms) =>
      DateFormat('dd.MM.yyyy').format(DateTime.fromMillisecondsSinceEpoch(ms));

  Future<void> _delete(String id) async {
    await _repo.deletePlannedExpense(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(widget.locale, 'planned_expenses')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(S.of(widget.locale, 'no_planned')))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final p = _items[i];
                    return Card(
                      child: ListTile(
                        title: Text(p.title),
                        subtitle: Text(
                          '${_fmtDate(p.plannedAtMs)}${p.note.isEmpty ? '' : ' • ${p.note}'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${p.amount.toStringAsFixed(2)} ${p.currencyCode}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            IconButton(
                              onPressed: () => _delete(p.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}