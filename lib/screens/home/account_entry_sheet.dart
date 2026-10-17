import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/account_store.dart';

Future<void> showAccountEntrySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    builder: (context) => const _AccountEntrySheet(),
  );
}

class _AccountEntrySheet extends StatefulWidget {
  const _AccountEntrySheet();

  @override
  State<_AccountEntrySheet> createState() => _AccountEntrySheetState();
}

class _AccountEntrySheetState extends State<_AccountEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _balanceController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(
      _balanceController.text.replaceAll(' ', '').replaceAll(',', '.'),
    );
    setState(() => _saving = true);
    await AccountStore.instance.add(
      AccountRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        subtitle: _subtitleController.text.trim().isEmpty
            ? 'Картка'
            : _subtitleController.text.trim(),
        balanceCents: (amount * 100).round(),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset + 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Додати картку',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Назва картки або банку',
                  hintText: 'Наприклад, monobank',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Вкажи назву'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subtitleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Опис картки (необов’язково)',
                  hintText: 'Чорна картка',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Поточна сума на картці',
                  suffixText: '₴',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = double.tryParse(
                    (value ?? '').replaceAll(' ', '').replaceAll(',', '.'),
                  );
                  if (amount == null || !amount.isFinite || amount < 0) {
                    return 'Вкажи суму картки';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Додати картку'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
