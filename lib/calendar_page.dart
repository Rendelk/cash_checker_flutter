import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_strings.dart';
import 'transaction_record.dart';
import 'wallet_repository.dart';

class CalendarPage extends StatefulWidget {
  final Locale locale;
  const CalendarPage({super.key, required this.locale});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _repo = WalletRepository();

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _from;
  DateTime? _to;
  String _currency = 'UAH';

  bool _loading = true;
  List<TransactionRecord> _monthTx = [];
  List<TransactionRecord> _rangeTx = [];
  Map<String, double> _byCategory = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime get _monthStart => DateTime(_month.year, _month.month, 1);
  DateTime get _monthEnd => DateTime(_month.year, _month.month + 1, 0, 23, 59, 59, 999);

  Future<void> _load() async {
    final monthTx = await _repo.getTransactions(
      type: 'expense',
      from: _monthStart,
      to: _monthEnd,
    );

    final from = _from ?? _monthStart;
    final to = _to ?? _monthEnd;
    final rangeTx = await _repo.getTransactions(
      type: 'expense',
      from: from,
      to: to,
    );

    final byCategory = await _repo.expenseByCategoryInRange(
      from: from,
      to: to,
      currencyCode: _currency,
    );

    if (!mounted) return;
    setState(() {
      _monthTx = monthTx;
      _rangeTx = rangeTx;
      _byCategory = byCategory;
      _loading = false;
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
      helpText: S.of(widget.locale, 'month'),
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month, 1));
      _load();
    }
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _from = picked);
      _load();
    }
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _to = DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 999));
      _load();
    }
  }

  String _fmtDate(DateTime d) => DateFormat('dd.MM.yyyy').format(d);

  String _monthLabel() {
    final localeCode = widget.locale.languageCode == 'uk' ? 'uk_UA' : 'en_US';
    return DateFormat('LLLL yyyy', localeCode).format(_month);
  }

  double get _monthTotal {
    return _monthTx
        .where((e) => e.currencyCode == _currency)
        .fold(0.0, (p, e) => p + e.amount);
  }

  double get _rangeTotal {
    return _rangeTx
        .where((e) => e.currencyCode == _currency)
        .fold(0.0, (p, e) => p + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    final currencies = <String>{'UAH', 'USD', 'EUR'}
      ..addAll(_monthTx.map((e) => e.currencyCode))
      ..addAll(_rangeTx.map((e) => e.currencyCode));

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                S.of(widget.locale, 'calendar_title'),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: Text(S.of(widget.locale, 'month')),
                  subtitle: Text(_monthLabel()),
                  trailing: IconButton(
                    onPressed: _pickMonth,
                    icon: const Icon(Icons.calendar_month),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: currencies
                    .map(
                      (c) => ChoiceChip(
                        label: Text(c),
                        selected: _currency == c,
                        onSelected: (_) {
                          setState(() => _currency = c);
                          _load();
                        },
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  title: Text(S.of(widget.locale, 'month_expenses')),
                  subtitle: Text(_monthLabel()),
                  trailing: Text(
                    '${_monthTotal.toStringAsFixed(2)} $_currency',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          S.of(widget.locale, 'select_range'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              S.of(widget.locale, 'range_total'),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${_rangeTotal.toStringAsFixed(2)} $_currency',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _from = null;
                              _to = null;
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

              const SizedBox(height: 10),
              Text(
                S.of(widget.locale, 'by_category'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),

              if (_byCategory.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(S.of(widget.locale, 'no_transactions')),
                )
              else
                ..._byCategory.entries.map(
                  (e) => Card(
                    child: ListTile(
                      title: Text(e.key.isEmpty ? '-' : e.key),
                      trailing: Text(
                        '${e.value.toStringAsFixed(2)} $_currency',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          );
  }
}