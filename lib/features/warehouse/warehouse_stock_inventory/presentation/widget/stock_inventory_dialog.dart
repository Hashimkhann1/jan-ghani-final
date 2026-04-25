// =============================================================
// stock_inventory_dialog.dart
// UPDATED: Single barcode field → multiple barcode chips
// =============================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/category/data/model/category_model.dart';
import 'package:jan_ghani_final/features/warehouse/category/presentation/provider/category_provider.dart';
import 'package:jan_ghani_final/features/warehouse/category/presentation/widget/add_category_dialog.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/data/model/product_model.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/presentation/provider/product_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/presentation/widget/section_label_widget.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/presentation/widget/status_toggle_widget.dart';
import 'dialog_action_widget.dart';
import 'dialog_header_widget.dart';
import 'expiree_field_widget.dart';
import 'field_widget.dart';
import 'form_row_widget.dart';

class StockInventoryDialog extends ConsumerStatefulWidget {
  final ProductModel? product;

  const StockInventoryDialog({super.key, this.product});

  @override
  ConsumerState<StockInventoryDialog> createState() =>
      _StockInventoryDialogState();
}

class _StockInventoryDialogState
    extends ConsumerState<StockInventoryDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _skuCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descriptionCtrl;
  String _selectedUnit = 'pcs';
  late final TextEditingController purchasePriceCtrl;
  late final TextEditingController _sellPriceCtrl;
  late final TextEditingController _wholePriceCtrl;
  late final TextEditingController _taxCtrl;
  late final TextEditingController _minStockCtrl;
  late final TextEditingController _maxStockCtrl;
  late final TextEditingController _reorderCtrl;
  late final TextEditingController _initialQtyCtrl;

  // ── Barcode list state ────────────────────────────────────
  late List<String> _barcodes;
  final TextEditingController _barcodeInputCtrl = TextEditingController();

  String? _selectedCategoryId;
  bool    _isActive      = true;
  bool    _isTrackStock  = true;
  bool    _isSaving      = false;

  bool get isEditMode => widget.product != null;

  // ── Auto generators ───────────────────────────────────────
  static String _generateSku() {
    final rand = Random();
    final digits = List.generate(8, (_) => rand.nextInt(10)).join();
    return 'JG-$digits';
  }

  static String _generateBarcode() {
    final rand = Random();
    final digits = List.generate(12, (_) => rand.nextInt(10)).join();
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(digits[i]) * (i.isEven ? 1 : 3);
    }
    final check = (10 - (sum % 10)) % 10;
    return '$digits$check';
  }

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    _skuCtrl         = TextEditingController(text: p?.sku ?? _generateSku());
    _nameCtrl        = TextEditingController(text: p?.name ?? '');
    _descriptionCtrl = TextEditingController(text: p?.description ?? '');
    _selectedUnit    = p?.unitOfMeasure ?? 'pcs';
    purchasePriceCtrl   = TextEditingController(
        text: p != null ? p.purchasePrice.toStringAsFixed(0) : '');
    _sellPriceCtrl   = TextEditingController(
        text: p != null ? p.sellingPrice.toStringAsFixed(0) : '');
    _wholePriceCtrl  = TextEditingController(
        text: p?.wholesalePrice?.toStringAsFixed(0) ?? '');
    _taxCtrl         = TextEditingController(
        text: p != null ? p.taxRate.toStringAsFixed(0) : '0');
    _minStockCtrl    = TextEditingController(
        text: p?.minStockLevel.toString() ?? '0');
    _maxStockCtrl    = TextEditingController(
        text: p?.maxStockLevel?.toString() ?? '');
    _reorderCtrl     = TextEditingController(
        text: p?.reorderPoint.toString() ?? '0');
    _initialQtyCtrl  = TextEditingController(
        text: p != null ? p.quantity.toStringAsFixed(0) : '0');

    // ── Barcodes init ─────────────────────────────────────
    _barcodes           = List<String>.from(p?.barcodes ?? []);
    // Agar new product aur list empty hai to ek auto barcode add karo
    if (!isEditMode && _barcodes.isEmpty) {
      _barcodes.add(_generateBarcode());
    }

    _selectedCategoryId = p?.categoryId;
    _isActive           = p?.isActive ?? true;
    _isTrackStock       = p?.isTrackStock ?? true;
  }

  @override
  void dispose() {
    _skuCtrl.dispose();
    _barcodeInputCtrl.dispose();
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    purchasePriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _wholePriceCtrl.dispose();
    _taxCtrl.dispose();
    _minStockCtrl.dispose();
    _maxStockCtrl.dispose();
    _reorderCtrl.dispose();
    _initialQtyCtrl.dispose();
    super.dispose();
  }

  // ── Barcode helpers ───────────────────────────────────────
  void _addBarcode() {
    final val = _barcodeInputCtrl.text.trim();
    if (val.isEmpty) return;
    if (_barcodes.contains(val)) {
      // Duplicate — highlight karo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeh barcode pehle se exist karta hai'),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _barcodes.add(val);
      _barcodeInputCtrl.clear();
    });
  }

  void _removeBarcode(int index) {
    setState(() => _barcodes.removeAt(index));
  }

  void _addGeneratedBarcode() {
    final generated = _generateBarcode();
    setState(() => _barcodes.add(generated));
  }

  // ── Save ─────────────────────────────────────────────────
  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(productProvider.notifier);

    try {
      if (isEditMode) {
        final newQty =
            double.tryParse(_initialQtyCtrl.text) ?? widget.product!.quantity;
        await notifier.updateProduct(
          widget.product!.copyWith(
            sku:            _skuCtrl.text.trim(),
            barcodes:       _barcodes,
            name:           _nameCtrl.text.trim(),
            description:    _descriptionCtrl.text.trim().isEmpty
                ? null : _descriptionCtrl.text.trim(),
            categoryId:     _selectedCategoryId,
            unitOfMeasure:  _selectedUnit,
            purchasePrice:      double.tryParse(purchasePriceCtrl.text) ?? 0,
            sellingPrice:   double.tryParse(_sellPriceCtrl.text) ?? 0,
            wholesalePrice: _wholePriceCtrl.text.trim().isEmpty
                ? null : double.tryParse(_wholePriceCtrl.text),
            taxRate:        double.tryParse(_taxCtrl.text) ?? 0,
            minStockLevel:  int.tryParse(_minStockCtrl.text) ?? 0,
            maxStockLevel:  _maxStockCtrl.text.trim().isEmpty
                ? null : int.tryParse(_maxStockCtrl.text),
            reorderPoint:   int.tryParse(_reorderCtrl.text) ?? 0,
            isActive:       _isActive,
            isTrackStock:   _isTrackStock,
          ),
          newQty: newQty,
        );
      } else {
        await notifier.addProduct(
          sku:            _skuCtrl.text.trim(),
          name:           _nameCtrl.text.trim(),
          barcodes:       _barcodes,
          description:    _descriptionCtrl.text.trim().isEmpty
              ? null : _descriptionCtrl.text.trim(),
          categoryId:     _selectedCategoryId,
          unitOfMeasure:  _selectedUnit,
          purchasePrice:      double.tryParse(purchasePriceCtrl.text) ?? 0,
          sellingPrice:   double.tryParse(_sellPriceCtrl.text) ?? 0,
          wholesalePrice: _wholePriceCtrl.text.trim().isEmpty
              ? null : double.tryParse(_wholePriceCtrl.text),
          taxRate:        double.tryParse(_taxCtrl.text) ?? 0,
          minStockLevel:  int.tryParse(_minStockCtrl.text) ?? 0,
          maxStockLevel:  _maxStockCtrl.text.trim().isEmpty
              ? null : int.tryParse(_maxStockCtrl.text),
          reorderPoint:   int.tryParse(_reorderCtrl.text) ?? 0,
          isActive:       _isActive,
          isTrackStock:   _isTrackStock,
          initialQty:     double.tryParse(_initialQtyCtrl.text) ?? 0,
        );
      }

      final hasError = ref.read(productProvider).errorMessage != null;
      if (!hasError && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required hai' : null;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(
        categoryProvider.select((s) => s.allCategories
            .where((c) => c.isActive && c.deletedAt == null)
            .toList()));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogHeader(isEditMode: isEditMode),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Basic Info ────────────────────────
                      SectionLabel(
                          label: "Basic Information",
                          icon:  Icons.info_outline_rounded),
                      const SizedBox(height: 12),

                      Field(
                        label:      "Product Name *",
                        controller: _nameCtrl,
                        hint:       "e.g. Surf Excel 1kg",
                        validator:  _required,
                      ),
                      const SizedBox(height: 14),

                      Field(
                        label:      "Description",
                        controller: _descriptionCtrl,
                        hint:       "Product description...",
                        maxLines:   2,
                      ),
                      const SizedBox(height: 14),

                      // SKU only (barcode alag section mein hai)
                      _AutoGenField(
                        label:      "SKU *",
                        controller: _skuCtrl,
                        hint:       "e.g. JG-12345678",
                        validator:  _required,
                        onRefresh:  isEditMode
                            ? null
                            : () => setState(
                                () => _skuCtrl.text = _generateSku()),
                      ),
                      const SizedBox(height: 14),

                      FormRow(children: [
                        _CategoryDropdown(
                          categories:         categories,
                          selectedCategoryId: _selectedCategoryId,
                          onChanged: (id) =>
                              setState(() => _selectedCategoryId = id),
                        ),
                        _UnitDropdown(
                          selectedUnit: _selectedUnit,
                          onChanged:    (v) =>
                              setState(() => _selectedUnit = v ?? 'pcs'),
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // ── Barcodes Section ──────────────────
                      SectionLabel(
                          label: "Barcodes",
                          icon:  Icons.qr_code_rounded),
                      const SizedBox(height: 12),

                      _BarcodesSection(
                        barcodes:      _barcodes,
                        inputCtrl:     _barcodeInputCtrl,
                        onAdd:         _addBarcode,
                        onRemove:      _removeBarcode,
                        onGenerate:    _addGeneratedBarcode,
                      ),

                      const SizedBox(height: 24),

                      // ── Pricing ───────────────────────────
                      SectionLabel(
                          label: "Pricing",
                          icon:  Icons.sell_rounded),
                      const SizedBox(height: 12),

                      FormRow(children: [
                        Field(
                          label:     "Purchase Price (Rs.) *",
                          controller: purchasePriceCtrl,
                          hint:      "e.g. 180",
                          keyboardType: const TextInputType
                              .numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter
                              .allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          validator: _required,
                        ),
                        Field(
                          label:     "Sale Price (Rs.) *",
                          controller: _sellPriceCtrl,
                          hint:      "e.g. 220",
                          keyboardType: const TextInputType
                              .numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter
                              .allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          validator: _required,
                        ),
                      ]),
                      const SizedBox(height: 14),

                      FormRow(children: [
                        Field(
                          label:      "Wholesale Price (Rs.)",
                          controller: _wholePriceCtrl,
                          hint:       "e.g. 200",
                          keyboardType: const TextInputType
                              .numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter
                              .allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        ),
                        Field(
                          label:      "Tax (%)",
                          controller: _taxCtrl,
                          hint:       "e.g. 5",
                          keyboardType: const TextInputType
                              .numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter
                              .allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // ── Stock ─────────────────────────────
                      SectionLabel(
                          label: "Stock Levels",
                          icon:  Icons.inventory_2_rounded),
                      const SizedBox(height: 12),

                      FormRow(children: [
                        Field(
                          label:     "Min Stock *",
                          controller: _minStockCtrl,
                          hint:      "e.g. 10",
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly],
                          validator: _required,
                        ),
                        Field(
                          label:      "Max Stock",
                          controller: _maxStockCtrl,
                          hint:       "e.g. 500",
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly],
                        ),
                      ]),
                      const SizedBox(height: 14),

                      FormRow(children: [
                        Field(
                          label:     "Reorder Point *",
                          controller: _reorderCtrl,
                          hint:      "e.g. 15",
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly],
                          validator: _required,
                        ),
                        Field(
                          label:     isEditMode
                              ? "Update Stock *" : "Initial Stock *",
                          controller: _initialQtyCtrl,
                          hint:      "e.g. 100",
                          keyboardType: const TextInputType
                              .numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter
                              .allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          validator: _required,
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // ── Status ────────────────────────────
                      // SectionLabel(
                      //     label: "Status",
                      //     icon:  Icons.toggle_on_rounded),
                      // const SizedBox(height: 12),

                      // StatusToggle(
                      //   isActive:  _isActive,
                      //   onChanged: (v) => setState(() => _isActive = v),
                      // ),
                      // const SizedBox(height: 10),

                      // _TrackStockToggle(
                      //   isTrackStock: _isTrackStock,
                      //   onChanged:
                      //       (v) => setState(() => _isTrackStock = v),
                      // ),

                      const SizedBox(height: 28),

                      DialogActions(
                        isSaving:   _isSaving,
                        isEditMode: isEditMode,
                        onCancel:   () => Navigator.pop(context),
                        onSave:     _onSave,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// BARCODES SECTION WIDGET
// =============================================================
class _BarcodesSection extends StatelessWidget {
  final List<String>           barcodes;
  final TextEditingController  inputCtrl;
  final VoidCallback           onAdd;
  final void Function(int)     onRemove;
  final VoidCallback           onGenerate;

  const _BarcodesSection({
    required this.barcodes,
    required this.inputCtrl,
    required this.onAdd,
    required this.onRemove,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Existing barcode chips ────────────────────
          if (barcodes.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: barcodes.asMap().entries.map((entry) {
                final i   = entry.key;
                final bc  = entry.value;
                final isPrimary = i == 0;
                return _BarcodeChip(
                  barcode:   bc,
                  isPrimary: isPrimary,
                  onRemove:  () => onRemove(i),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // ── Input row ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: inputCtrl,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF1A1D23)),
                  decoration: InputDecoration(
                    hintText: 'Barcode type karo ya scan karo...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: Color(0xFFD1D5DB)),
                    prefixIcon: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 18,
                        color: Color(0xFF9CA3AF)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    filled:    true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: Color(0xFFE5E7EB))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF6366F1), width: 1.5)),
                  ),
                  onFieldSubmitted: (_) => onAdd(),
                ),
              ),
              const SizedBox(width: 8),

              // Add button
              Tooltip(
                message: 'Barcode add karo',
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_rounded,
                        size: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Auto-generate button
              Tooltip(
                message: 'Auto barcode generate karo',
                child: InkWell(
                  onTap: onGenerate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF6366F1).withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        size: 18, color: Color(0xFF6366F1)),
                  ),
                ),
              ),
            ],
          ),

          // ── Helper text ───────────────────────────────
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 12, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text(
                barcodes.isEmpty
                    ? 'Pehla barcode primary hoga'
                    : '${barcodes.length} barcode(s) — pehla primary hai',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Single Barcode Chip ───────────────────────────────────────
class _BarcodeChip extends StatelessWidget {
  final String      barcode;
  final bool        isPrimary;
  final VoidCallback onRemove;

  const _BarcodeChip({
    required this.barcode,
    required this.isPrimary,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary
            ? const Color(0xFFEEF2FF)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPrimary
              ? const Color(0xFF6366F1).withOpacity(0.4)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.qr_code_rounded,
            size:  13,
            color: isPrimary
                ? const Color(0xFF6366F1)
                : const Color(0xFF6C7280),
          ),
          const SizedBox(width: 6),
          Text(
            barcode,
            style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w600,
              color:      isPrimary
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF374151),
            ),
          ),
          if (isPrimary) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PRIMARY',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ],
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size:  14,
              color: isPrimary
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// CATEGORY DROPDOWN (unchanged)
// =============================================================
class _CategoryDropdown extends StatelessWidget {
  final List<CategoryModel>   categories;
  final String?               selectedCategoryId;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {

    final validIds = categories.map((c) => c.id).toSet();
    final safeValue = (selectedCategoryId != null && validIds.contains(selectedCategoryId))
        ? selectedCategoryId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label + New Category Button ──────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Category',
                style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                    color:      Color(0xFF374151))),
            GestureDetector(
              onTap: () => AddCategoryDialog.show(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_circle_outline_rounded,
                      size: 13, color: Color(0xFF6366F1)),
                  SizedBox(width: 3),
                  Text('New Category',
                      style: TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                          color:      Color(0xFF6366F1))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value:      safeValue,
          isExpanded: true,
          decoration: InputDecoration(
            hintText:  'Select category',
            hintStyle: const TextStyle(
                fontSize: 13, color: Color(0xFFD1D5DB)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            filled:    true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFF6366F1), width: 1.5)),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('No Category',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF9CA3AF))),
            ),
            ...categories.map((c) => DropdownMenuItem(
              value: c.id,
              child: Text(c.name,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF1A1D23))),
            )),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// =============================================================
// UNIT DROPDOWN (unchanged)
// =============================================================
class _UnitDropdown extends StatelessWidget {
  final String                selectedUnit;
  final ValueChanged<String?> onChanged;

  const _UnitDropdown({
    required this.selectedUnit,
    required this.onChanged,
  });

  static const List<Map<String, String>> _units = [
    {'value': 'pcs',    'label': 'Pieces (pcs)'},
    {'value': 'kg',     'label': 'Kilogram (kg)'},
    {'value': 'g',      'label': 'Gram (g)'},
    {'value': 'liter',  'label': 'Liter'},
    {'value': 'ml',     'label': 'Milliliter (ml)'},
    {'value': 'box',    'label': 'Box'},
    {'value': 'pack',   'label': 'Pack'},
    {'value': 'dozen',  'label': 'Dozen'},
    {'value': 'meter',  'label': 'Meter'},
    {'value': 'bottle', 'label': 'Bottle'},
    {'value': 'carton', 'label': 'Carton'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Unit of Measure *',
            style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      Color(0xFF374151))),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value:      selectedUnit,
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            filled:    true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFF6366F1), width: 1.5)),
          ),
          items: _units.map((u) => DropdownMenuItem(
            value: u['value'],
            child: Text(u['label']!,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF1A1D23))),
          )).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// =============================================================
// TRACK STOCK TOGGLE (unchanged)
// =============================================================
class _TrackStockToggle extends StatelessWidget {
  final bool             isTrackStock;
  final ValueChanged<bool> onChanged;

  const _TrackStockToggle({
    required this.isTrackStock,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isTrackStock
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTrackStock
              ? const Color(0xFF22C55E).withOpacity(0.3)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.track_changes_rounded,
              size:  20,
              color: isTrackStock
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTrackStock
                      ? "Stock Track Ho Raha Hai"
                      : "Stock Track Nahi Ho Raha",
                  style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w600,
                      color:      isTrackStock
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF6C7280)),
                ),
                Text(
                  isTrackStock
                      ? "Inventory automatically update hogi"
                      : "Yeh product inventory mein count nahi hoga",
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF6C7280)),
                ),
              ],
            ),
          ),
          Switch(
            value:       isTrackStock,
            onChanged:   onChanged,
            activeColor: const Color(0xFF22C55E),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// AUTO GEN FIELD (unchanged)
// =============================================================
class _AutoGenField extends StatelessWidget {
  final String                    label;
  final String                    hint;
  final TextEditingController     controller;
  final String? Function(String?)? validator;
  final VoidCallback?             onRefresh;

  const _AutoGenField({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      Color(0xFF374151))),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                validator:  validator,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF1A1D23)),
                decoration: InputDecoration(
                  hintText:  hint,
                  hintStyle: const TextStyle(
                      fontSize: 13, color: Color(0xFFD1D5DB)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  filled:    true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF6366F1), width: 1.5)),
                  errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                      const BorderSide(color: Color(0xFFEF4444))),
                ),
              ),
            ),
            if (onRefresh != null) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: 'Regenerate',
                child: InkWell(
                  onTap:        onRefresh,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF6366F1).withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        size: 18, color: Color(0xFF6366F1)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}


// // =============================================================
// // stock_inventory_dialog.dart
// // Add/Edit Product Dialog with category dropdown
// // =============================================================
//
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import 'package:jan_ghani_final/features/warehouse_stock_inventory/presentation/widget/section_label_widget.dart';
// import 'package:jan_ghani_final/features/warehouse_stock_inventory/presentation/widget/status_toggle_widget.dart';
// import 'package:jan_ghani_final/features/warehouse_stock_inventory/data/model/product_model.dart';
// import 'package:jan_ghani_final/features/warehouse_stock_inventory/presentation/provider/product_provider.dart';
// import 'package:jan_ghani_final/features/category/presentation/provider/category_provider.dart';
// import 'package:jan_ghani_final/features/category/data/model/category_model.dart';
// import 'package:jan_ghani_final/core/color/app_color.dart';
// import 'dialog_action_widget.dart';
// import 'dialog_header_widget.dart';
// import 'expiree_field_widget.dart';
// import 'field_widget.dart';
// import 'form_row_widget.dart';
//
// class StockInventoryDialog extends ConsumerStatefulWidget {
//   final ProductModel? product;
//
//   const StockInventoryDialog({super.key, this.product});
//
//   @override
//   ConsumerState<StockInventoryDialog> createState() =>
//       _StockInventoryDialogState();
// }
//
// class _StockInventoryDialogState
//     extends ConsumerState<StockInventoryDialog> {
//   final _formKey = GlobalKey<FormState>();
//
//   // Controllers
//   late final TextEditingController _skuCtrl;
//   late final TextEditingController _barcodeCtrl;
//   late final TextEditingController _nameCtrl;
//   late final TextEditingController _descriptionCtrl;
//   String _selectedUnit = 'pcs';
//   late final TextEditingController purchasePriceCtrl;
//   late final TextEditingController _sellPriceCtrl;
//   late final TextEditingController _wholePriceCtrl;
//   late final TextEditingController _taxCtrl;
//   late final TextEditingController _minStockCtrl;
//   late final TextEditingController _maxStockCtrl;
//   late final TextEditingController _reorderCtrl;
//   late final TextEditingController _initialQtyCtrl;
//
//   String? _selectedCategoryId;
//   bool    _isActive      = true;
//   bool    _isTrackStock  = true;
//   bool    _isSaving      = false;
//
//   bool get isEditMode => widget.product != null;
//
//   // ── Auto generators ───────────────────────────────────────
//   static String _generateSku() {
//     final rand = Random();
//     final digits = List.generate(8, (_) => rand.nextInt(10)).join();
//     return 'JG-$digits';
//   }
//
//   static String _generateBarcode() {
//     final rand = Random();
//     // 13 digit EAN-13 style
//     final digits = List.generate(12, (_) => rand.nextInt(10)).join();
//     // Last digit checksum (simple)
//     int sum = 0;
//     for (int i = 0; i < 12; i++) {
//       sum += int.parse(digits[i]) * (i.isEven ? 1 : 3);
//     }
//     final check = (10 - (sum % 10)) % 10;
//     return '$digits$check';
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     final p = widget.product;
//     _skuCtrl        = TextEditingController(text: p?.sku ?? _generateSku());
//     _barcodeCtrl    = TextEditingController(text: p?.barcode ?? _generateBarcode());
//     _nameCtrl       = TextEditingController(text: p?.name ?? '');
//     _descriptionCtrl= TextEditingController(text: p?.description ?? '');
//     _selectedUnit   = p?.unitOfMeasure ?? 'pcs';
//     purchasePriceCtrl  = TextEditingController(
//         text: p != null ? p.costPrice.toStringAsFixed(0) : '');
//     _sellPriceCtrl  = TextEditingController(
//         text: p != null ? p.sellingPrice.toStringAsFixed(0) : '');
//     _wholePriceCtrl = TextEditingController(
//         text: p?.wholesalePrice?.toStringAsFixed(0) ?? '');
//     _taxCtrl        = TextEditingController(
//         text: p != null ? p.taxRate.toStringAsFixed(0) : '0');
//     _minStockCtrl   = TextEditingController(
//         text: p?.minStockLevel.toString() ?? '0');
//     _maxStockCtrl   = TextEditingController(
//         text: p?.maxStockLevel?.toString() ?? '');
//     _reorderCtrl    = TextEditingController(
//         text: p?.reorderPoint.toString() ?? '0');
//     _initialQtyCtrl = TextEditingController(
//         text: p != null ? p.quantity.toStringAsFixed(0) : '0');
//
//     _selectedCategoryId = p?.categoryId;
//     _isActive           = p?.isActive ?? true;
//     _isTrackStock       = p?.isTrackStock ?? true;
//   }
//
//   @override
//   void dispose() {
//     _skuCtrl.dispose();
//     _barcodeCtrl.dispose();
//     _nameCtrl.dispose();
//     _descriptionCtrl.dispose();
//
//     purchasePriceCtrl.dispose();
//     _sellPriceCtrl.dispose();
//     _wholePriceCtrl.dispose();
//     _taxCtrl.dispose();
//     _minStockCtrl.dispose();
//     _maxStockCtrl.dispose();
//     _reorderCtrl.dispose();
//     _initialQtyCtrl.dispose();
//     super.dispose();
//   }
//
//   Future<void> _onSave() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _isSaving = true);
//
//     final notifier = ref.read(productProvider.notifier);
//
//     try {
//       if (isEditMode) {
//         final newQty = double.tryParse(_initialQtyCtrl.text) ?? widget.product!.quantity;
//         await notifier.updateProduct(widget.product!.copyWith(
//           sku:            _skuCtrl.text.trim(),
//           barcode:        _barcodeCtrl.text.trim().isEmpty
//               ? null : _barcodeCtrl.text.trim(),
//           name:           _nameCtrl.text.trim(),
//           description:    _descriptionCtrl.text.trim().isEmpty
//               ? null : _descriptionCtrl.text.trim(),
//           categoryId:     _selectedCategoryId,
//           unitOfMeasure:  _selectedUnit,
//           costPrice:      double.tryParse(purchasePriceCtrl.text) ?? 0,
//           sellingPrice:   double.tryParse(_sellPriceCtrl.text) ?? 0,
//           wholesalePrice: _wholePriceCtrl.text.trim().isEmpty
//               ? null : double.tryParse(_wholePriceCtrl.text),
//           taxRate:        double.tryParse(_taxCtrl.text) ?? 0,
//           minStockLevel:  int.tryParse(_minStockCtrl.text) ?? 0,
//           maxStockLevel:  _maxStockCtrl.text.trim().isEmpty
//               ? null : int.tryParse(_maxStockCtrl.text),
//           reorderPoint:   int.tryParse(_reorderCtrl.text) ?? 0,
//           isActive:       _isActive,
//           isTrackStock:   _isTrackStock,
//         ), newQty: newQty);
//       } else {
//         await notifier.addProduct(
//           sku:            _skuCtrl.text.trim(),
//           name:           _nameCtrl.text.trim(),
//           barcode:        _barcodeCtrl.text.trim().isEmpty
//               ? null : _barcodeCtrl.text.trim(),
//           description:    _descriptionCtrl.text.trim().isEmpty
//               ? null : _descriptionCtrl.text.trim(),
//           categoryId:     _selectedCategoryId,
//           unitOfMeasure:  _selectedUnit,
//           costPrice:      double.tryParse(purchasePriceCtrl.text) ?? 0,
//           sellingPrice:   double.tryParse(_sellPriceCtrl.text) ?? 0,
//           wholesalePrice: _wholePriceCtrl.text.trim().isEmpty
//               ? null : double.tryParse(_wholePriceCtrl.text),
//           taxRate:        double.tryParse(_taxCtrl.text) ?? 0,
//           minStockLevel:  int.tryParse(_minStockCtrl.text) ?? 0,
//           maxStockLevel:  _maxStockCtrl.text.trim().isEmpty
//               ? null : int.tryParse(_maxStockCtrl.text),
//           reorderPoint:   int.tryParse(_reorderCtrl.text) ?? 0,
//           isActive:       _isActive,
//           isTrackStock:   _isTrackStock,
//           initialQty:     double.tryParse(_initialQtyCtrl.text) ?? 0,
//         );
//       }
//
//       final hasError = ref.read(productProvider).errorMessage != null;
//       if (!hasError && mounted) Navigator.of(context).pop();
//     } finally {
//       if (mounted) setState(() => _isSaving = false);
//     }
//   }
//
//   String? _required(String? v) =>
//       (v == null || v.trim().isEmpty) ? 'Required hai' : null;
//
//   @override
//   Widget build(BuildContext context) {
//     final categories = ref.watch(
//         categoryProvider.select((s) => s.allCategories
//             .where((c) => c.isActive && c.deletedAt == null)
//             .toList()));
//
//     return Dialog(
//       shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20)),
//       insetPadding: const EdgeInsets.symmetric(
//           horizontal: 24, vertical: 32),
//       child: ConstrainedBox(
//         constraints: const BoxConstraints(maxWidth: 620),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             DialogHeader(isEditMode: isEditMode),
//             Flexible(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//
//                       // ── Basic Info ────────────────────────
//                       SectionLabel(
//                           label: "Basic Information",
//                           icon:  Icons.info_outline_rounded),
//                       const SizedBox(height: 12),
//
//                       Field(
//                         label:     "Product Name *",
//                         controller: _nameCtrl,
//                         hint:      "e.g. Surf Excel 1kg",
//                         validator: _required,
//                       ),
//                       const SizedBox(height: 14),
//
//                       Field(
//                         label:      "Description",
//                         controller: _descriptionCtrl,
//                         hint:       "Product description...",
//                         maxLines:   2,
//                       ),
//                       const SizedBox(height: 14),
//
//                       FormRow(children: [
//                         _AutoGenField(
//                           label:      "SKU *",
//                           controller: _skuCtrl,
//                           hint:       "e.g. JG-12345678",
//                           validator:  _required,
//                           onRefresh:  isEditMode ? null : () => setState(() {
//                             _skuCtrl.text = _generateSku();
//                           }),
//                         ),
//                         _AutoGenField(
//                           label:      "Barcode",
//                           controller: _barcodeCtrl,
//                           hint:       "e.g. 1234567890123",
//                           onRefresh:  isEditMode ? null : () => setState(() {
//                             _barcodeCtrl.text = _generateBarcode();
//                           }),
//                         ),
//                       ]),
//                       const SizedBox(height: 14),
//
//                       FormRow(children: [
//                         // ── Category Dropdown ──────────────
//                         _CategoryDropdown(
//                           categories:         categories,
//                           selectedCategoryId: _selectedCategoryId,
//                           onChanged: (id) =>
//                               setState(() => _selectedCategoryId = id),
//                         ),
//                         _UnitDropdown(
//                           selectedUnit: _selectedUnit,
//                           onChanged:    (v) =>
//                               setState(() => _selectedUnit = v ?? 'pcs'),
//                         ),
//                       ]),
//
//                       const SizedBox(height: 24),
//
//                       // ── Pricing ───────────────────────────
//                       SectionLabel(
//                           label: "Pricing",
//                           icon:  Icons.sell_rounded),
//                       const SizedBox(height: 12),
//
//                       FormRow(children: [
//                         Field(
//                           label:     "Cost Price (Rs.) *",
//                           controller: purchasePriceCtrl,
//                           hint:      "e.g. 180",
//                           keyboardType: const TextInputType
//                               .numberWithOptions(decimal: true),
//                           inputFormatters: [FilteringTextInputFormatter
//                               .allow(RegExp(r'^\d+\.?\d{0,2}'))],
//                           validator: _required,
//                         ),
//                         Field(
//                           label:     "Sale Price (Rs.) *",
//                           controller: _sellPriceCtrl,
//                           hint:      "e.g. 220",
//                           keyboardType: const TextInputType
//                               .numberWithOptions(decimal: true),
//                           inputFormatters: [FilteringTextInputFormatter
//                               .allow(RegExp(r'^\d+\.?\d{0,2}'))],
//                           validator: _required,
//                         ),
//                       ]),
//                       const SizedBox(height: 14),
//
//                       FormRow(children: [
//                         Field(
//                           label:      "Wholesale Price (Rs.)",
//                           controller: _wholePriceCtrl,
//                           hint:       "e.g. 200",
//                           keyboardType: const TextInputType
//                               .numberWithOptions(decimal: true),
//                           inputFormatters: [FilteringTextInputFormatter
//                               .allow(RegExp(r'^\d+\.?\d{0,2}'))],
//                         ),
//                         Field(
//                           label:      "Tax (%)",
//                           controller: _taxCtrl,
//                           hint:       "e.g. 5",
//                           keyboardType: const TextInputType
//                               .numberWithOptions(decimal: true),
//                           inputFormatters: [FilteringTextInputFormatter
//                               .allow(RegExp(r'^\d+\.?\d{0,2}'))],
//                         ),
//                       ]),
//
//                       const SizedBox(height: 24),
//
//                       // ── Stock ─────────────────────────────
//                       SectionLabel(
//                           label: "Stock Levels",
//                           icon:  Icons.inventory_2_rounded),
//                       const SizedBox(height: 12),
//
//                       FormRow(children: [
//                         Field(
//                           label:     "Min Stock *",
//                           controller: _minStockCtrl,
//                           hint:      "e.g. 10",
//                           keyboardType: TextInputType.number,
//                           inputFormatters: [
//                             FilteringTextInputFormatter.digitsOnly],
//                           validator: _required,
//                         ),
//                         Field(
//                           label:      "Max Stock",
//                           controller: _maxStockCtrl,
//                           hint:       "e.g. 500",
//                           keyboardType: TextInputType.number,
//                           inputFormatters: [
//                             FilteringTextInputFormatter.digitsOnly],
//                         ),
//                       ]),
//                       const SizedBox(height: 14),
//
//                       FormRow(children: [
//                         Field(
//                           label:     "Reorder Point *",
//                           controller: _reorderCtrl,
//                           hint:      "e.g. 15",
//                           keyboardType: TextInputType.number,
//                           inputFormatters: [
//                             FilteringTextInputFormatter.digitsOnly],
//                           validator: _required,
//                         ),
//                         Field(
//                           label:     isEditMode
//                               ? "Update Stock *"
//                               : "Initial Stock *",
//                           controller: _initialQtyCtrl,
//                           hint:      "e.g. 100",
//                           keyboardType: const TextInputType
//                               .numberWithOptions(decimal: true),
//                           inputFormatters: [
//                             FilteringTextInputFormatter
//                                 .allow(RegExp(r'^\d+\.?\d{0,2}'))],
//                           validator: _required,
//                         ),
//                       ]),
//
//                       const SizedBox(height: 24),
//
//                       // ── Status ────────────────────────────
//                       SectionLabel(
//                           label: "Status",
//                           icon:  Icons.toggle_on_rounded),
//                       const SizedBox(height: 12),
//
//                       StatusToggle(
//                         isActive:  _isActive,
//                         onChanged: (v) =>
//                             setState(() => _isActive = v),
//                       ),
//                       const SizedBox(height: 10),
//
//                       // Track stock toggle
//                       _TrackStockToggle(
//                         isTrackStock: _isTrackStock,
//                         onChanged:    (v) =>
//                             setState(() => _isTrackStock = v),
//                       ),
//
//                       const SizedBox(height: 28),
//
//                       // ── Actions ───────────────────────────
//                       DialogActions(
//                         isSaving:   _isSaving,
//                         isEditMode: isEditMode,
//                         onCancel:   () => Navigator.pop(context),
//                         onSave:     _onSave,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// // CATEGORY DROPDOWN
// // ─────────────────────────────────────────────────────────────
// class _CategoryDropdown extends StatelessWidget {
//   final List<CategoryModel>    categories;
//   final String?                selectedCategoryId;
//   final ValueChanged<String?>  onChanged;
//
//   const _CategoryDropdown({
//     required this.categories,
//     required this.selectedCategoryId,
//     required this.onChanged,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Category',
//           style: TextStyle(
//               fontSize:   12,
//               fontWeight: FontWeight.w600,
//               color:      Color(0xFF374151)),
//         ),
//         const SizedBox(height: 6),
//         DropdownButtonFormField<String>(
//           value:       selectedCategoryId,
//           isExpanded:  true,
//           decoration: InputDecoration(
//             hintText:  'Select category',
//             hintStyle: const TextStyle(
//                 fontSize: 13, color: Color(0xFFD1D5DB)),
//             contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 14, vertical: 12),
//             filled:    true,
//             fillColor: const Color(0xFFF9FAFB),
//             border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide:
//                 const BorderSide(color: Color(0xFFE5E7EB))),
//             enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide:
//                 const BorderSide(color: Color(0xFFE5E7EB))),
//             focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: const BorderSide(
//                     color: Color(0xFF6366F1), width: 1.5)),
//           ),
//           items: [
//             const DropdownMenuItem(
//               value: null,
//               child: Text('No Category',
//                   style: TextStyle(
//                       fontSize: 13, color: Color(0xFF9CA3AF))),
//             ),
//             ...categories.map((c) => DropdownMenuItem(
//               value: c.id,
//               child: Text(c.name,
//                   style: const TextStyle(
//                       fontSize: 13, color: Color(0xFF1A1D23))),
//             )),
//           ],
//           onChanged: onChanged,
//         ),
//       ],
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// // TRACK STOCK TOGGLE
// // ─────────────────────────────────────────────────────────────
// class _TrackStockToggle extends StatelessWidget {
//   final bool isTrackStock;
//   final ValueChanged<bool> onChanged;
//
//   const _TrackStockToggle({
//     required this.isTrackStock,
//     required this.onChanged,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       padding: const EdgeInsets.symmetric(
//           horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color:        isTrackStock
//             ? const Color(0xFFF0FDF4)
//             : const Color(0xFFF9FAFB),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isTrackStock
//               ? const Color(0xFF22C55E).withOpacity(0.3)
//               : const Color(0xFFE5E7EB),
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             Icons.track_changes_rounded,
//             size:  20,
//             color: isTrackStock
//                 ? const Color(0xFF22C55E)
//                 : const Color(0xFF9CA3AF),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   isTrackStock
//                       ? "Stock Track Ho Raha Hai"
//                       : "Stock Track Nahi Ho Raha",
//                   style: TextStyle(
//                     fontSize:   13,
//                     fontWeight: FontWeight.w600,
//                     color:      isTrackStock
//                         ? const Color(0xFF22C55E)
//                         : const Color(0xFF6C7280),
//                   ),
//                 ),
//                 Text(
//                   isTrackStock
//                       ? "Inventory automatically update hogi"
//                       : "Yeh product inventory mein count nahi hoga",
//                   style: const TextStyle(
//                       fontSize: 11,
//                       color:    Color(0xFF6C7280)),
//                 ),
//               ],
//             ),
//           ),
//           Switch(
//             value:       isTrackStock,
//             onChanged:   onChanged,
//             activeColor: const Color(0xFF22C55E),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// // UNIT DROPDOWN
// // ─────────────────────────────────────────────────────────────
// class _UnitDropdown extends StatelessWidget {
//   final String                selectedUnit;
//   final ValueChanged<String?> onChanged;
//
//   const _UnitDropdown({
//     required this.selectedUnit,
//     required this.onChanged,
//   });
//
//   static const List<Map<String, String>> _units = [
//     {'value': 'pcs',    'label': 'Pieces (pcs)'},
//     {'value': 'kg',     'label': 'Kilogram (kg)'},
//     {'value': 'g',      'label': 'Gram (g)'},
//     {'value': 'liter',  'label': 'Liter'},
//     {'value': 'ml',     'label': 'Milliliter (ml)'},
//     {'value': 'box',    'label': 'Box'},
//     {'value': 'pack',   'label': 'Pack'},
//     {'value': 'dozen',  'label': 'Dozen'},
//     {'value': 'meter',  'label': 'Meter'},
//     {'value': 'bottle', 'label': 'Bottle'},
//     {'value': 'carton', 'label': 'Carton'},
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Unit of Measure *',
//           style: TextStyle(
//               fontSize:   12,
//               fontWeight: FontWeight.w600,
//               color:      Color(0xFF374151)),
//         ),
//         const SizedBox(height: 6),
//         DropdownButtonFormField<String>(
//           value:      selectedUnit,
//           isExpanded: true,
//           decoration: InputDecoration(
//             contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 14, vertical: 12),
//             filled:    true,
//             fillColor: const Color(0xFFF9FAFB),
//             border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide:
//                 const BorderSide(color: Color(0xFFE5E7EB))),
//             enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide:
//                 const BorderSide(color: Color(0xFFE5E7EB))),
//             focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: const BorderSide(
//                     color: Color(0xFF6366F1), width: 1.5)),
//           ),
//           items: _units.map((u) => DropdownMenuItem(
//             value: u['value'],
//             child: Text(u['label']!,
//                 style: const TextStyle(
//                     fontSize: 13, color: Color(0xFF1A1D23))),
//           )).toList(),
//           onChanged: onChanged,
//         ),
//       ],
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// // AUTO GEN FIELD — refresh button ke saath
// // ─────────────────────────────────────────────────────────────
// class _AutoGenField extends StatelessWidget {
//   final String                    label;
//   final String                    hint;
//   final TextEditingController     controller;
//   final String? Function(String?)? validator;
//   final VoidCallback?             onRefresh;
//
//   const _AutoGenField({
//     required this.label,
//     required this.hint,
//     required this.controller,
//     this.validator,
//     this.onRefresh,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label,
//             style: const TextStyle(
//                 fontSize:   12,
//                 fontWeight: FontWeight.w600,
//                 color:      Color(0xFF374151))),
//         const SizedBox(height: 6),
//         Row(
//           children: [
//             Expanded(
//               child: TextFormField(
//                 controller: controller,
//                 validator:  validator,
//                 style: const TextStyle(
//                     fontSize: 13, color: Color(0xFF1A1D23)),
//                 decoration: InputDecoration(
//                   hintText:  hint,
//                   hintStyle: const TextStyle(
//                       fontSize: 13, color: Color(0xFFD1D5DB)),
//                   contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 14, vertical: 12),
//                   filled:    true,
//                   fillColor: const Color(0xFFF9FAFB),
//                   border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: const BorderSide(
//                           color: Color(0xFFE5E7EB))),
//                   enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: const BorderSide(
//                           color: Color(0xFFE5E7EB))),
//                   focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: const BorderSide(
//                           color: Color(0xFF6366F1), width: 1.5)),
//                   errorBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: const BorderSide(
//                           color: Color(0xFFEF4444))),
//                 ),
//               ),
//             ),
//             if (onRefresh != null) ...[
//               const SizedBox(width: 6),
//               Tooltip(
//                 message: 'Regenerate',
//                 child: InkWell(
//                   onTap:        onRefresh,
//                   borderRadius: BorderRadius.circular(8),
//                   child: Container(
//                     padding: const EdgeInsets.all(11),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFEEF2FF),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(
//                           color: const Color(0xFF6366F1)
//                               .withOpacity(0.3)),
//                     ),
//                     child: const Icon(Icons.refresh_rounded,
//                         size: 18, color: Color(0xFF6366F1)),
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ],
//     );
//   }
// }