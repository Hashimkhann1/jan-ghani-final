import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/branch/branch_stock_inventory/presentation/provider/branch_stock_inventory_provider.dart';
import '../../data/datasource/branch_stock_remote_datasource.dart';
import '../../data/model/branch_stock_model.dart';

class EditStockDialog extends ConsumerStatefulWidget {
  final BranchStockModel product;
  const EditStockDialog({super.key, required this.product});

  @override
  ConsumerState<EditStockDialog> createState() => _EditStockDialogState();
}

class _EditStockDialogState extends ConsumerState<EditStockDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _skuCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _costPriceCtrl;
  late TextEditingController _salePriceCtrl;
  late TextEditingController _wholesalePriceCtrl;
  late TextEditingController _taxRateCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _minStockCtrl;
  late TextEditingController _maxStockCtrl;
  late TextEditingController _descriptionCtrl;
  late String _selectedUnit;

  static const _units = ['pcs', 'kg', 'g', 'ltr', 'ml', 'box', 'dozen', 'pair'];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl           = TextEditingController(text: p.name);
    _skuCtrl            = TextEditingController(text: p.sku);
    _barcodeCtrl        = TextEditingController(
        text: BranchStockDataSource().parseBarcode(p.barcode) ?? '');
    _costPriceCtrl      = TextEditingController(text: p.costPrice.toStringAsFixed(0));
    _salePriceCtrl      = TextEditingController(text: p.sellingPrice.toStringAsFixed(0));
    _wholesalePriceCtrl = TextEditingController(
        text: p.wholesalePrice?.toStringAsFixed(0) ?? '');
    _taxRateCtrl        = TextEditingController(text: p.taxRate.toStringAsFixed(1));
    _discountCtrl       = TextEditingController(text: p.discount.toStringAsFixed(1));
    _quantityCtrl       = TextEditingController(text: p.quantity.toStringAsFixed(0));
    _minStockCtrl       = TextEditingController(text: p.minStockLevel.toString());
    _maxStockCtrl       = TextEditingController(text: p.maxStockLevel.toString());
    _descriptionCtrl    = TextEditingController(text: p.description ?? '');
    _selectedUnit       = _units.contains(p.unitOfMeasure) ? p.unitOfMeasure : 'pcs';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _costPriceCtrl.dispose();
    _salePriceCtrl.dispose();
    _wholesalePriceCtrl.dispose();
    _taxRateCtrl.dispose();
    _discountCtrl.dispose();
    _quantityCtrl.dispose();
    _minStockCtrl.dispose();
    _maxStockCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = BranchStockInventory(
      id:             widget.product.id,
      storeId:        widget.product.storeId,
      productId:      widget.product.productId,
      barcode:        _barcodeCtrl.text.trim().isEmpty
          ? []
          : [_barcodeCtrl.text.trim()],
      sku:            _skuCtrl.text.trim(),
      productName:    _nameCtrl.text.trim(),
      purchasePrice:  double.tryParse(_costPriceCtrl.text)      ?? 0,
      salePrice:      double.tryParse(_salePriceCtrl.text)      ?? 0,
      wholesalePrice: double.tryParse(_wholesalePriceCtrl.text) ?? 0,
      stock:          double.tryParse(_quantityCtrl.text)       ?? 0,
      minStock:       double.tryParse(_minStockCtrl.text)       ?? 0,
      maxStock:       double.tryParse(_maxStockCtrl.text)       ?? 0,
      unit:           _selectedUnit,
    );

    final success = await ref
        .read(inventoryPageProvider.notifier)
        .updateProduct(updated);

    if (mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('${updated.productName} updated successfully'),
          backgroundColor: AppColor.success,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving =
    ref.watch(inventoryPageProvider.select((s) => s.isMutating));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Header ─────────────────────────────────────────
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.06),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(children: [
                const Icon(Icons.edit_outlined,
                    size: 20, color: AppColor.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Edit Product',
                      style: TextStyle(
                          fontSize:   16,
                          fontWeight: FontWeight.w700,
                          color:      AppColor.textPrimary)),
                ),
                IconButton(
                  onPressed:
                  isSaving ? null : () => Navigator.pop(context),
                  icon:  const Icon(Icons.close_rounded, size: 20),
                  style: IconButton.styleFrom(
                      foregroundColor: AppColor.textSecondary),
                ),
              ]),
            ),

            // ── Form Body ───────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      _SectionLabel('Basic Information'),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          flex: 3,
                          child: _Field(
                            label: 'Product Name *',
                            ctrl:  _nameCtrl,
                            validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Name required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            flex: 2,
                            child: _Field(label: 'SKU', ctrl: _skuCtrl)),
                        const SizedBox(width: 12),
                        Expanded(
                            flex: 2,
                            child: _Field(
                                label: 'Barcode', ctrl: _barcodeCtrl)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: _Field(
                            label:    'Description',
                            ctrl:     _descriptionCtrl,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 130,
                          child: _DropdownField(
                            label:     'Unit',
                            value:     _selectedUnit,
                            items:     _units,
                            onChanged: (v) =>
                                setState(() => _selectedUnit = v!),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 20),
                      const Divider(height: 1, color: AppColor.grey200),
                      const SizedBox(height: 20),

                      _SectionLabel('Pricing'),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: _Field(
                            label:    'Cost Price (Rs) *',
                            ctrl:     _costPriceCtrl,
                            isNumber: true,
                            validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Field(
                            label:    'Sale Price (Rs) *',
                            ctrl:     _salePriceCtrl,
                            isNumber: true,
                            validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Field(
                            label:    'Wholesale Price (Rs)',
                            ctrl:     _wholesalePriceCtrl,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Field(
                            label:    'Tax Rate (%)',
                            ctrl:     _taxRateCtrl,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Field(
                            label:    'Discount (%)',
                            ctrl:     _discountCtrl,
                            isNumber: true,
                          ),
                        ),
                      ]),

                      const SizedBox(height: 20),
                      const Divider(height: 1, color: AppColor.grey200),
                      const SizedBox(height: 20),

                      _SectionLabel('Stock'),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: _Field(
                            label:    'Quantity *',
                            ctrl:     _quantityCtrl,
                            isNumber: true,
                            validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Field(
                            label:  'Min Stock Level',
                            ctrl:   _minStockCtrl,
                            isNumber: true,
                            isInt:  true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Field(
                            label:  'Max Stock Level',
                            ctrl:   _maxStockCtrl,
                            isNumber: true,
                            isInt:  true,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppColor.grey200, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100,
                    child: OutlinedButton(
                      onPressed:
                      isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColor.textSecondary,
                        side: const BorderSide(color: AppColor.grey300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 150,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: isSaving
                          ? const SizedBox(
                          width:  16,
                          height: 16,
                          child:  CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(isSaving ? 'Saving...' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize:      13,
          fontWeight:    FontWeight.w700,
          color:         AppColor.textSecondary,
          letterSpacing: 0.4));
}

class _Field extends StatelessWidget {
  final String                     label;
  final TextEditingController      ctrl;
  final bool                       isNumber;
  final bool                       isInt;
  final int                        maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.ctrl,
    this.isNumber  = false,
    this.isInt     = false,
    this.maxLines  = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller:   ctrl,
    keyboardType: isNumber
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    inputFormatters: isInt
        ? [FilteringTextInputFormatter.digitsOnly]
        : isNumber
        ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
        : null,
    maxLines:    maxLines,
    validator:   validator,
    style:       const TextStyle(fontSize: 13),
    cursorHeight: 14,
    decoration: InputDecoration(
      labelText:  label,
      labelStyle: const TextStyle(
          fontSize: 12, color: AppColor.textSecondary),
      filled:    true,
      fillColor: AppColor.grey100,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
          const BorderSide(color: AppColor.primary, width: 1.2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
          const BorderSide(color: AppColor.error, width: 1)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
          const BorderSide(color: AppColor.error, width: 1.2)),
    ),
  );
}

class _DropdownField extends StatelessWidget {
  final String                label;
  final String                value;
  final List<String>          items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value:     value,
    onChanged: onChanged,
    style: const TextStyle(
        fontSize: 13, color: AppColor.textPrimary),
    decoration: InputDecoration(
      labelText:  label,
      labelStyle: const TextStyle(
          fontSize: 12, color: AppColor.textSecondary),
      filled:    true,
      fillColor: AppColor.grey100,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
          const BorderSide(color: AppColor.primary, width: 1.2)),
    ),
    items: items
        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
        .toList(),
  );
}