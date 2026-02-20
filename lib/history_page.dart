import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'account.dart';
import 'app_strings.dart';
import 'transaction_record.dart';
import 'wallet_repository.dart';

class HistoryPage extends StatefulWidget {
  final Locale locale;
  const HistoryPage({super.key, required this.locale});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _repo = WalletRepository();

  List<Account> _accounts = [];
  List<TransactionRecord> _tx = [];

  String? _accountId;
  String? _type; // income|expense|null
  DateTime? _from;
  DateTime? _to;
  bool _loading = true;


  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accounts = await _repo.getAccounts();
    final tx = await _repo.getTransactions(
      accountId: _accountId,
      type: _type,
      from: _from,
      to: _to != null
          ? DateTime(_to!.year, _to!.month, _to!.day, 23, 59, 59, 999)
          : null,
    );
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _tx = tx;
      _loading = false;
    });
  }

  String _fmtDate(DateTime d) => DateFormat('dd.MM.yyyy').format(d);

  String _fmtDateTime(int ms) =>
      DateFormat('dd.MM.yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(ms));

  Future<void> _pickFrom() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => _from = d);
      _load();
    }
  }

  Future<void> _pickTo() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _to ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => _to = d);
      _load();
    }
  }

  Future<void> _deleteTx(TransactionRecord t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(S.of(widget.locale, 'delete_operation')),
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
    if (ok == true) {
      await _repo.deleteTransaction(t.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.of(widget.locale, 'operation_deleted'))));
      _load();
    }
  }

  double get _total {
    if (_tx.isEmpty) return 0;
    return _tx.fold(0.0, (p, e) => p + (e.type == 'expense' ? -e.amount : e.amount));
  }

  @override
  Widget build(BuildContext context) {
    final accountMap = {for (final a in _accounts) a.id: a};
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        S.of(widget.locale, 'history_title'),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              DropdownButtonFormField<String?>(
                                value: _accountId,
                                decoration:
                                    InputDecoration(labelText: S.of(widget.locale, 'account')),
                                items: [
                                  DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text(S.of(widget.locale, 'all_accounts')),
                                  ),
                                  ..._accounts.map(
                                    (a) => DropdownMenuItem<String?>(
                                      value: a.id,
                                      child: Text('${a.name} (${a.currencyCode})'),
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  setState(() => _accountId = v);
                                  _load();
                                },
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String?>(
                                value: _type,
                                decoration: InputDecoration(labelText: S.of(widget.locale, 'type')),
                                items: [
                                  DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text(S.of(widget.locale, 'all_types')),
                                  ),
                                  DropdownMenuItem<String?>(
                                    value: 'expense',
                                    child: Text(S.of(widget.locale, 'expense')),
                                  ),
                                  DropdownMenuItem<String?>(
                                    value: 'income',
                                    child: Text(S.of(widget.locale, 'income')),
                                  ),
                                ],
                                onChanged: (v) {
                                  setState(() => _type = v);
                                  _load();
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _pickFrom,
                                      child: Text(
                                        _from == null
                                            ? S.of(widget.locale, 'from')
                                            : '${S.of(widget.locale, 'from')}: ${_fmtDate(_from!)}',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _pickTo,
                                      child: Text(
                                        _to == null
                                            ? S.of(widget.locale, 'to')
                                            : '${S.of(widget.locale, 'to')}: ${_fmtDate(_to!)}',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _from = null;
                                      _to = null;
                                      _type = null;
                                      _accountId = null;
                                    });
                                    _load();
                                  },
                                  child: Text(S.of(widget.locale, 'reset')),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_tx.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text(S.of(widget.locale, 'no_transactions'))),
                        )
                      else
                        ..._tx.map((t) {
                          final acc = accountMap[t.accountId];
                          final sign = t.type == 'expense' ? '-' : '+';
                          final color = t.type == 'expense' ? Colors.red : Colors.green;
                          return Card(
                            child: ListTile(
                              title: Text(t.categoryRaw),
                              subtitle: Text(
                                '${acc?.name ?? '-'} • ${_fmtDateTime(t.createdAtMs)}'
                                '${t.note.isEmpty ? '' : '\n${t.note}'}',
                              ),
                              isThreeLine: t.note.isNotEmpty,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$sign${t.amount.toStringAsFixed(2)} ${t.currencyCode}',
                                    style: TextStyle(fontWeight: FontWeight.w700, color: color),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _deleteTx(t),
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          
                          S.of(widget.locale, 'total_operations'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        _total.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: _total < 0 ? Colors.red : Colors.green,
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