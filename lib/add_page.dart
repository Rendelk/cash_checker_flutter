import 'package:flutter/material.dart';

import 'account.dart';
import 'app_strings.dart';
import 'category_item.dart';
import 'planned_page.dart';
import 'wallet_repository.dart';

class AddPage extends StatefulWidget {
  final Locale locale;
  const AddPage({super.key, required this.locale});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final _repo = WalletRepository();

  final _accName = TextEditingController();
  final _accBalance = TextEditingController(text: '0');

  final _txAmount = TextEditingController();
  final _txNote = TextEditingController();

  final _plannedTitle = TextEditingController();
  final _plannedAmount = TextEditingController();
  final _plannedNote = TextEditingController();

  final _newCategory = TextEditingController();

  List<Account> _accounts = [];
  List<CategoryItem> _categories = [];

  String _txType = 'expense';
  String? _selectedAccountId;
  String? _selectedCategoryName;
  DateTime _txDate = DateTime.now();

  String _accType = 'card';
  String _accCurrency = 'UAH';

  String _plannedCurrency = 'UAH';
  DateTime _plannedDate = DateTime.now();

  int _mode = 0; // 0 tx, 1 account, 2 planned, 3 categories
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _accName.dispose();
    _accBalance.dispose();
    _txAmount.dispose();
    _txNote.dispose();
    _plannedTitle.dispose();
    _plannedAmount.dispose();
    _plannedNote.dispose();
    _newCategory.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final accounts = await _repo.getAccounts();
    final categories = await _repo.getCategories(_txType);

    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _categories = categories;
      _selectedAccountId ??= accounts.isNotEmpty ? accounts.first.id : null;
      _selectedCategoryName ??= categories.isNotEmpty ? categories.first.name : null;
      _loading = false;
    });
  }

  Future<void> _reloadCategories() async {
    final categories = await _repo.getCategories(_txType);
    if (!mounted) return;
    setState(() {
      _categories = categories;
      if (_categories.isEmpty) {
        _selectedCategoryName = null;
      } else if (!_categories.any((e) => e.name == _selectedCategoryName)) {
        _selectedCategoryName = _categories.first.name;
      }
    });
  }

  void _hideKeyboard() => FocusScope.of(context).unfocus();

  String _fmtDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  Future<void> _pickTxDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _txDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _txDate = picked);
  }

  Future<void> _pickPlannedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plannedDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _plannedDate = picked);
  }

  Future<void> _saveAccount() async {
    final name = _accName.text.trim();
    final amount = double.tryParse(_accBalance.text.replaceAll(',', '.'));
    if (name.isEmpty || amount == null) {
      _snack(S.of(widget.locale, 'field_required'));
      return;
    }

    setState(() => _saving = true);
    await _repo.addAccount(
      name: name,
      type: _accType,
      currencyCode: _accCurrency,
      balance: amount,
      accentHex: '#20232A',
    );
    _accName.clear();
    _accBalance.text = '0';
    await _load();
    if (!mounted) return;
    setState(() => _saving = false);
    _snack(S.of(widget.locale, 'account_added'));
  }
  Future<void> _saveTransaction() async {
  if (_selectedAccountId == null) {
    _snack(S.of(widget.locale, 'field_required'));
    return;
  }

  final parsedAmount = double.tryParse(
    _txAmount.text.replaceAll(',', '.').trim(),
  );

  if (parsedAmount == null || parsedAmount <= 0 || _selectedCategoryName == null) {
    _snack(S.of(widget.locale, 'invalid_amount'));
    return;
  }

  final account = _accounts.firstWhere((a) => a.id == _selectedAccountId);

  setState(() => _saving = true);
  await _repo.addTransaction(
    accountId: account.id,
    type: _txType,
    categoryRaw: _selectedCategoryName!,
    currencyCode: account.currencyCode,
    amount: parsedAmount,
    note: _txNote.text.trim(),
    createdAt: _txDate,
  );

  _txAmount.clear();
  _txNote.clear();
  _txDate = DateTime.now();

  if (!mounted) return;
  setState(() => _saving = false);
  _snack(S.of(widget.locale, 'transaction_added'));
}

  Future<void> _savePlanned() async {
  final title = _plannedTitle.text.trim();
  final parsedAmount = double.tryParse(
    _plannedAmount.text.replaceAll(',', '.').trim(),
  );

  if (title.isEmpty || parsedAmount == null || parsedAmount <= 0) {
    _snack(S.of(widget.locale, 'invalid_amount'));
    return;
  }

  setState(() => _saving = true);

  await _repo.addPlannedExpense(
    title: title,
    currencyCode: _plannedCurrency,
    amount: parsedAmount,
    plannedAt: _plannedDate,
    note: _plannedNote.text.trim(),
  );

  _plannedTitle.clear();
  _plannedAmount.clear();
  _plannedNote.clear();
  _plannedDate = DateTime.now();

  if (!mounted) return;
  setState(() => _saving = false);
  _snack(S.of(widget.locale, 'planned_added'));
}

  Future<void> _addCategory() async {
    final name = _newCategory.text.trim();
    if (name.isEmpty) return;
    await _repo.addCategory(name: name, type: _txType);
    _newCategory.clear();
    await _reloadCategories();
    _snack(S.of(widget.locale, 'category_added'));
  }

  Future<void> _deleteCategory(CategoryItem c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(S.of(widget.locale, 'delete_category')),
        content: Text(S.of(widget.locale, 'delete_category_confirm')),
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
      await _repo.deleteCategory(c.id);
      await _reloadCategories();
      _snack(S.of(widget.locale, 'category_deleted'));
    }
  }

  void _snack(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return GestureDetector(
      onTap: _hideKeyboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(S.of(widget.locale, 'add_transaction'))),
                ButtonSegment(value: 1, label: Text(S.of(widget.locale, 'add_account'))),
                ButtonSegment(value: 2, label: Text(S.of(widget.locale, 'planned_expenses'))),
                ButtonSegment(value: 3, label: Text(S.of(widget.locale, 'manage_categories'))),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _hideKeyboard,
                icon: const Icon(Icons.keyboard_hide),
                label: Text(S.of(widget.locale, 'hide_keyboard')),
              ),
            ),
            const SizedBox(height: 8),
            if (_mode == 0) _buildAddTransaction(),
            if (_mode == 1) _buildAddAccount(),
            if (_mode == 2) _buildAddPlanned(),
            if (_mode == 3) _buildManageCategories(),
          ],
        ),
      ),
    );
  }
  Widget _buildAddTransaction() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _txType,
              decoration: InputDecoration(labelText: S.of(widget.locale, 'type')),
              items: [
                DropdownMenuItem(value: 'expense', child: Text(S.of(widget.locale, 'expense'))),
                DropdownMenuItem(value: 'income', child: Text(S.of(widget.locale, 'income'))),
              ],
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _txType = v);
                await _reloadCategories();
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedAccountId,
              decoration: InputDecoration(labelText: S.of(widget.locale, 'account')),
              items: _accounts
                  .map((a) => DropdownMenuItem(
                        value: a.id,
                        child: Text('${a.name} (${a.currencyCode})'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedAccountId = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCategoryName,
              decoration: InputDecoration(labelText: S.of(widget.locale, 'category')),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategoryName = v),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _txAmount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: S.of(widget.locale, 'amount')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _txNote,
              decoration: InputDecoration(labelText: S.of(widget.locale, 'note')),
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(S.of(widget.locale, 'date')),
              subtitle: Text(_fmtDate(_txDate)),
              trailing: IconButton(
                onPressed: _pickTxDate,
                icon: const Icon(Icons.calendar_month),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _saveTransaction,
              child: Text(S.of(widget.locale, 'save')),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAddAccount() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _accName,
              decoration: InputDecoration(labelText: S.of(widget.locale, 'name')),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _accType,
              decoration: InputDecoration(labelText: S.of(widget.locale, 'type')),
              items: const [
                DropdownMenuItem(value: 'card', child: Text('card')),
                DropdownMenuItem(value: 'cash', child: Text('cash')),
                DropdownMenuItem(value: 'wallet', child: Text('wallet')),
              ],
              onChanged: (v) => setState(() => _accType = v ?? 'card'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _accCurrency,
              decoration: InputDecoration(labelText: S.of(widget.locale, 'currency')),
              items: const [
                DropdownMenuItem(value: 'UAH', child: Text('UAH')),
                DropdownMenuItem(value: 'USD', child: Text('USD')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR')),
              ],
              onChanged: (v) => setState(() => _accCurrency = v ?? 'UAH'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _accBalance,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: S.of(widget.locale, 'initial_balance')),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _saveAccount,
              child: Text(S.of(widget.locale, 'save')),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAddPlanned() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    S.of(widget.locale, 'add_planned_expense'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlannedPage(locale: widget.locale),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list),
                  label: Text(S.of(widget.locale, 'planned_expenses')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _plannedTitle,
              decoration: InputDecoration(labelText: S.of(widget.locale, 'planned_name')),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _plannedCurrency,
              decoration: InputDecoration(labelText: S.of(widget.locale, 'currency')),
              items: const [
                DropdownMenuItem(value: 'UAH', child: Text('UAH')),
                DropdownMenuItem(value: 'USD', child: Text('USD')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR')),
              ],
              onChanged: (v) => setState(() => _plannedCurrency = v ?? 'UAH'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _plannedAmount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: S.of(widget.locale, 'planned_amount')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _plannedNote,
              decoration: InputDecoration(labelText: S.of(widget.locale, 'note')),
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(S.of(widget.locale, 'planned_date')),
              subtitle: Text(_fmtDate(_plannedDate)),
              trailing: IconButton(
                onPressed: _pickPlannedDate,
                icon: const Icon(Icons.calendar_month),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _savePlanned,
              child: Text(S.of(widget.locale, 'save')),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildManageCategories() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _txType,
              decoration: InputDecoration(labelText: S.of(widget.locale, 'type')),
              items: [
                DropdownMenuItem(value: 'expense', child: Text(S.of(widget.locale, 'expense'))),
                DropdownMenuItem(value: 'income', child: Text(S.of(widget.locale, 'income'))),
              ],
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _txType = v);
                await _reloadCategories();
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCategory,
                    decoration: InputDecoration(labelText: S.of(widget.locale, 'new_category')),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addCategory,
                  child: Text(S.of(widget.locale, 'save')),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_categories.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(S.of(widget.locale, 'no_categories')),
              )
            else
              ..._categories.map(
                (c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteCategory(c),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}