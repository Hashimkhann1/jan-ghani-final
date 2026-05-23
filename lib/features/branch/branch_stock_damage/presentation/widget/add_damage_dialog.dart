// lib/features/branch/branch_stock_damage/presentation/widget/add_damage_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../branch_stock_inventory/presentation/provider/branch_stock_inventory_provider.dart';
import '../../data/model/branch_stock_damage_model.dart';
import '../provider/branch_stock_damage_provider.dart';

// ═══════════════════════════════════════════════════════════════════
// ADD DAMAGE DIALOG
// ═══════════════════════════════════════════════════════════════════
class AddDamageDialog extends ConsumerStatefulWidget {
  const AddDamageDialog({super.key});

  @override
  ConsumerState<AddDamageDialog> createState() => _AddDamageDialogState();
}

class _AddDamageDialogState extends ConsumerState<AddDamageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  BranchStockModel? _selectedProduct;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final p   = _selectedProduct!;
    final qty = double.parse(_qtyCtrl.text.trim()); // ✅ double.parse

    final ok = await ref.read(branchStockDamageProvider.notifier).addDamage(
      productId:     p.productId,
      productName:   p.name,
      salePrice:     p.sellingPrice,
      purchasePrice: p.costPrice,
      stockDamage:   qty,               // ✅ double
    );

    if (mounted && ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isMutating = ref.watch(branchStockDamageProvider).isMutating;
    final products   = ref.watch(branchStockProvider).allProducts;

    final dropdownItems = products.map((p) {
      final stockStr = p.isOutOfStock
          ? 'Out of Stock'
          : 'Stock: ${p.quantity.toStringAsFixed(2)}';
      return DropdownItem<BranchStockModel>(
        value: p,
        label: '${p.name}  [$stockStr]',
      );
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────────────
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: AppColor.error, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Add Damage Record',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    onPressed: isMutating ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    style: IconButton.styleFrom(foregroundColor: AppColor.textSecondary),
                  ),
                ]),

                const SizedBox(height: 20),

                // ── Product Dropdown ─────────────────────────────
                const _Label('Product Select Karein *'),
                const SizedBox(height: 6),
                FormField<BranchStockModel>(
                  validator: (_) => _selectedProduct == null ? 'Product select karein' : null,
                  builder: (fieldState) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSearchableDropdown<BranchStockModel>(
                        items:     dropdownItems,
                        value:     _selectedProduct,
                        hint:      'Product search karein...',
                        fullWidth: true,
                        onChanged: (p) {
                          setState(() { _selectedProduct = p; _qtyCtrl.clear(); });
                          fieldState.didChange(p);
                        },
                        validator: (_) => _selectedProduct == null
                            ? 'Product select karein' : null,
                      ),
                      if (fieldState.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(fieldState.errorText!,
                              style: const TextStyle(fontSize: 11, color: AppColor.error)),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Product info card ─────────────────────────────
                if (_selectedProduct != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColor.grey100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow('Purchase Price',
                                'Rs ${_selectedProduct!.costPrice.toStringAsFixed(2)}'),
                            const SizedBox(height: 4),
                            _InfoRow('Sale Price',
                                'Rs ${_selectedProduct!.sellingPrice.toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Available Stock',
                              style: TextStyle(fontSize: 11, color: AppColor.textSecondary)),
                          Text(
                            _selectedProduct!.quantity.toStringAsFixed(2),  // ✅ 2 decimal
                            style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800,
                              color: _selectedProduct!.isOutOfStock
                                  ? AppColor.error
                                  : _selectedProduct!.isLowStock
                                  ? AppColor.warning
                                  : AppColor.success,
                            ),
                          ),
                          Text(_selectedProduct!.unitOfMeasure,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColor.textSecondary)),
                        ],
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Quantity ──────────────────────────────────────
                const _Label('Damaged Quantity *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller:      _qtyCtrl,
                  keyboardType:    const TextInputType.numberWithOptions(decimal: true),
                  style:           const TextStyle(fontSize: 13),
                  cursorHeight:    14,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // ✅ decimal allow
                  ],
                  enabled:  _selectedProduct != null,
                  decoration: _inputDecor(
                    _selectedProduct != null
                        ? 'Max: ${_selectedProduct!.quantity.toStringAsFixed(2)}'
                        : 'Pehle product select karein',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Quantity enter karein';
                    final qty = double.tryParse(v.trim()); // ✅ double.tryParse
                    if (qty == null || qty <= 0) return 'Valid quantity enter karein';
                    if (_selectedProduct != null && qty > _selectedProduct!.quantity) {
                      return 'Max: ${_selectedProduct!.quantity.toStringAsFixed(2)}';
                    }
                    return null;
                  },
                ),

                // ── Total Loss Preview ────────────────────────────
                if (_selectedProduct != null && _qtyCtrl.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Builder(builder: (_) {
                    final qty  = double.tryParse(_qtyCtrl.text.trim()) ?? 0.0; // ✅ double
                    final loss = _selectedProduct!.costPrice * qty;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColor.error.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColor.error.withOpacity(0.25)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.trending_down_rounded,
                            size: 16, color: AppColor.error),
                        const SizedBox(width: 8),
                        Text('Total Loss: Rs ${loss.toStringAsFixed(2)}', // ✅ 2 decimal
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: AppColor.error)),
                      ]),
                    );
                  }),
                ],

                const SizedBox(height: 16),
                _WarningBanner('Submit karne par stock automatically reduce ho jayega'),
                const SizedBox(height: 20),

                _DialogButtons(
                  isMutating:   isMutating,
                  confirmLabel: 'Add Damage',
                  onCancel:     () => Navigator.of(context).pop(),
                  onConfirm:    _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EDIT DAMAGE DIALOG
// ═══════════════════════════════════════════════════════════════════
class EditDamageDialog extends ConsumerStatefulWidget {
  final BranchStockDamageModel record;
  const EditDamageDialog({super.key, required this.record});

  @override
  ConsumerState<EditDamageDialog> createState() => _EditDamageDialogState();
}

class _EditDamageDialogState extends ConsumerState<EditDamageDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    // ✅ stockDamage double hai, toStringAsFixed(2) se init
    _qtyCtrl = TextEditingController(
        text: widget.record.stockDamage.toStringAsFixed(
            widget.record.stockDamage % 1 == 0 ? 0 : 2));
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref.read(branchStockDamageProvider.notifier).updateDamage(
      original:       widget.record,
      newStockDamage: double.parse(_qtyCtrl.text.trim()), // ✅ double.parse
    );

    if (mounted && ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isMutating = ref.watch(branchStockDamageProvider).isMutating;
    final newQty     = double.tryParse(_qtyCtrl.text.trim()) ?? widget.record.stockDamage; // ✅ double
    final newLoss    = widget.record.purchasePrice * newQty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────────────
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: AppColor.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Edit Damage Record',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    onPressed: isMutating ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    style: IconButton.styleFrom(foregroundColor: AppColor.textSecondary),
                  ),
                ]),

                const SizedBox(height: 20),

                // ── Product Info (read-only) ──────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColor.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.record.productName,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Row(children: [
                        _InfoRow('Purchase Price', widget.record.purchasePriceLabel),
                        const SizedBox(width: 16),
                        _InfoRow('Sale Price', widget.record.salePriceLabel),
                      ]),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Qty field ─────────────────────────────────────
                const _Label('Damaged Quantity *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller:      _qtyCtrl,
                  keyboardType:    const TextInputType.numberWithOptions(decimal: true),
                  style:           const TextStyle(fontSize: 13),
                  cursorHeight:    14,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // ✅ decimal
                  ],
                  decoration: _inputDecor('Quantity enter karein'),
                  onChanged:  (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Quantity enter karein';
                    final qty = double.tryParse(v.trim()); // ✅ double
                    if (qty == null || qty <= 0) return 'Valid quantity enter karein';
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // ── Old → New preview ─────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColor.error.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColor.error.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(children: [
                        const Text('Old Qty',
                            style: TextStyle(fontSize: 11, color: AppColor.textSecondary)),
                        Text(
                          widget.record.stockDamage % 1 == 0
                              ? widget.record.stockDamage.toStringAsFixed(0)
                              : widget.record.stockDamage.toStringAsFixed(2), // ✅ double display
                          style: const TextStyle(fontSize: 18,
                              fontWeight: FontWeight.w700, color: AppColor.textSecondary),
                        ),
                      ]),
                    ),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 16, color: AppColor.textSecondary),
                    Expanded(
                      child: Column(children: [
                        const Text('New Qty',
                            style: TextStyle(fontSize: 11, color: AppColor.textSecondary)),
                        Text(
                          newQty % 1 == 0
                              ? newQty.toStringAsFixed(0)
                              : newQty.toStringAsFixed(2), // ✅ double display
                          style: const TextStyle(fontSize: 18,
                              fontWeight: FontWeight.w700, color: AppColor.error),
                        ),
                      ]),
                    ),
                    const VerticalDivider(),
                    Expanded(
                      child: Column(children: [
                        const Text('New Loss',
                            style: TextStyle(fontSize: 11, color: AppColor.textSecondary)),
                        Text('Rs ${newLoss.toStringAsFixed(2)}', // ✅ 2 decimal
                            style: const TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w700, color: AppColor.error)),
                      ]),
                    ),
                  ]),
                ),

                const SizedBox(height: 12),
                _WarningBanner('Stock automatically adjust ho jayega'),
                const SizedBox(height: 20),

                _DialogButtons(
                  isMutating:   isMutating,
                  confirmLabel: 'Update',
                  onCancel:     () => Navigator.of(context).pop(),
                  onConfirm:    _submit,
                  confirmColor: AppColor.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DELETE DAMAGE DIALOG
// ═══════════════════════════════════════════════════════════════════
class DeleteDamageDialog extends ConsumerWidget {
  final BranchStockDamageModel record;
  const DeleteDamageDialog({super.key, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMutating = ref.watch(branchStockDamageProvider).isMutating;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppColor.error.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColor.error, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Delete Damage Record',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                '"${record.productName}" ka record delete karna chahte hain?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColor.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColor.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColor.success.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.undo_rounded, size: 14, color: AppColor.success),
                  const SizedBox(width: 6),
                  Text(
                    // ✅ double display — trailing zeros hata do
                    '${record.stockDamage % 1 == 0 ? record.stockDamage.toStringAsFixed(0) : record.stockDamage.toStringAsFixed(2)} units stock restore ho jayega',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.success),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              _DialogButtons(
                isMutating:   isMutating,
                confirmLabel: 'Delete & Restore',
                onCancel:     () => Navigator.of(context).pop(),
                onConfirm: () async {
                  final ok = await ref
                      .read(branchStockDamageProvider.notifier)
                      .deleteDamage(record);
                  if (context.mounted && ok) Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED HELPERS
// ═══════════════════════════════════════════════════════════════════
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: AppColor.textSecondary));
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(children: [
    Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColor.textSecondary)),
    Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
  ]);
}

class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner(this.message);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColor.warning.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColor.warning.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, size: 15, color: AppColor.warning),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: const TextStyle(fontSize: 12, color: AppColor.warning))),
    ]),
  );
}

class _DialogButtons extends StatelessWidget {
  final bool         isMutating;
  final String       confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final Color        confirmColor;

  const _DialogButtons({
    required this.isMutating,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.confirmColor = AppColor.error,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(
      child: OutlinedButton(
        onPressed: isMutating ? null : onCancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColor.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Cancel'),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: ElevatedButton(
        onPressed: isMutating ? null : onConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: confirmColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isMutating
            ? const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(confirmLabel),
      ),
    ),
  ]);
}

InputDecoration _inputDecor(String hint) => InputDecoration(
  hintText:  hint,
  hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 13),
  filled:    true,
  fillColor: AppColor.grey100,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
  focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColor.primary, width: 1.2)),
  errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColor.error, width: 1.2)),
  focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColor.error, width: 1.2)),
);