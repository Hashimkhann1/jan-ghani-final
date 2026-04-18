import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/branch/expense/data/model/expense_model.dart';
import 'package:jan_ghani_final/features/branch/expense/presentation/provider/expense_provider.dart';

class AddExpenseDialog extends ConsumerStatefulWidget {
  final ExpenseModel? expense;
  const AddExpenseDialog({super.key, this.expense});

  @override
  ConsumerState<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<AddExpenseDialog> {
  final _formKey     = GlobalKey<FormState>();
  final _head        = TextEditingController();
  final _amount      = TextEditingController();
  final _description = TextEditingController();
  bool _isSaving     = false;

  // Common expense heads for quick select
  final _quickHeads = const [
    'Rent',
    'Electricity',
    'Salary',
    'Transport',
    'Maintenance',
    'Grocery',
    'Miscellaneous',
  ];

  bool get _isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    if (e != null) {
      _head.text        = e.expenseHead;
      _amount.text      = e.amount.toStringAsFixed(0);
      _description.text = e.description ?? '';
    }
  }

  @override
  void dispose() {
    _head.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(expenseProvider.notifier);

    try {
      if (_isEdit) {
        await notifier.updateExpense(widget.expense!.copyWith(
          expenseHead: _head.text.trim(),
          amount:      double.tryParse(_amount.text) ?? 0,
          description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        ));
      } else {
        await notifier.addExpense(
          expenseHead: _head.text.trim(),
          amount:      double.tryParse(_amount.text) ?? 0,
          description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize:       MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ───────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColor.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isEdit
                            ? Icons.edit_outlined
                            : Icons.add_card_outlined,
                        color: AppColor.error,
                        size:  20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'Edit Expense' : 'New Expense',
                          style: const TextStyle(
                              fontSize:   16,
                              fontWeight: FontWeight.w700),
                        ),
                        const Text(
                          'Expense ki details bharein',
                          style: TextStyle(
                              fontSize: 12,
                              color:    AppColor.textSecondary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon:  const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                          foregroundColor: AppColor.textSecondary),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(color: AppColor.grey200),
                const SizedBox(height: 16),

                // ── Expense Head ──────────────────────────
                const _Label('Expense Head *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller:   _head,
                  cursorHeight: 14,
                  style: const TextStyle(
                      fontSize: 14, color: AppColor.textPrimary),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'Expense head required hai'
                      : null,
                  decoration: InputDecoration(
                    hintText:  'e.g. Rent, Salary...',
                    hintStyle: const TextStyle(
                        color: AppColor.textHint, fontSize: 13),
                    filled:    true,
                    fillColor: AppColor.grey100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColor.grey200)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColor.grey200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColor.primary, width: 1.5)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        const BorderSide(color: AppColor.error)),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Quick Head Chips ──────────────────────
                if (!_isEdit) ...[
                  const _Label('Quick Select'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing:   8,
                    runSpacing: 6,
                    children: _quickHeads.map((h) => GestureDetector(
                      onTap: () => setState(() => _head.text = h),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _head.text == h
                              ? AppColor.primary
                              : AppColor.grey100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _head.text == h
                                ? AppColor.primary
                                : AppColor.grey300,
                          ),
                        ),
                        child: Text(h,
                            style: TextStyle(
                              fontSize:   12,
                              fontWeight: FontWeight.w500,
                              color: _head.text == h
                                  ? Colors.white
                                  : AppColor.textSecondary,
                            )),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Amount ────────────────────────────────
                const _Label('Amount (Rs) *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller:   _amount,
                  cursorHeight: 14,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  style: const TextStyle(
                      fontSize: 14, color: AppColor.textPrimary),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Amount required hai';
                    final parsed = double.tryParse(v);
                    if (parsed == null || parsed <= 0)
                      return 'Valid amount dalein';
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText:  '0',
                    hintStyle: const TextStyle(
                        color: AppColor.textHint, fontSize: 13),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, right: 8),
                      child: Text('Rs',
                          style: TextStyle(
                              fontSize:   14,
                              fontWeight: FontWeight.w600,
                              color:      AppColor.textSecondary)),
                    ),
                    prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                    filled:    true,
                    fillColor: AppColor.grey100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColor.grey200)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColor.grey200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColor.primary, width: 1.5)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        const BorderSide(color: AppColor.error)),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Description ───────────────────────────
                const _Label('Description (Optional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller:   _description,
                  maxLines:     3,
                  cursorHeight: 14,
                  style: const TextStyle(
                      fontSize: 14, color: AppColor.textPrimary),
                  decoration: InputDecoration(
                    hintText:  'Extra details...',
                    hintStyle: const TextStyle(
                        color: AppColor.textHint, fontSize: 13),
                    filled:    true,
                    fillColor: AppColor.grey100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColor.grey200)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColor.grey200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColor.primary, width: 1.5)),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Save Button ───────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:         AppColor.primary,
                      foregroundColor:         Colors.white,
                      disabledBackgroundColor:
                      AppColor.primary.withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                        width:  20,
                        height: 20,
                        child:  CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : Text(
                        _isEdit
                            ? 'Update Expense'
                            : 'Save Expense',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize:   15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize:      12,
          fontWeight:    FontWeight.w600,
          color:         AppColor.textSecondary,
          letterSpacing: 0.5));
}