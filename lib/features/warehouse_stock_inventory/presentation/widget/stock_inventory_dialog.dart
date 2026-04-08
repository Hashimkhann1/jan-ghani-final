import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jan_ghani_final/features/warehouse_stock_inventory/presentation/widget/section_label_widget.dart';
import 'package:jan_ghani_final/features/warehouse_stock_inventory/presentation/widget/status_toggle_widget.dart';
import '../../data/model/warehouse_stock_inventory_model.dart';
import 'dialog_action_widget.dart';
import 'dialog_header_widget.dart';
import 'expiree_field_widget.dart';
import 'field_widget.dart';
import 'form_row_widget.dart';


class StockInventoryDialog extends StatefulWidget {
  final WarehouseStockInventory? inventory;

  const StockInventoryDialog({super.key, this.inventory});

  @override
  State<StockInventoryDialog> createState() => _StockInventoryDialogState();
}

class _StockInventoryDialogState extends State<StockInventoryDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _productNameCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _sellPriceCtrl;
  late final TextEditingController _purchasePriceCtrl;
  late final TextEditingController _wholePriceCtrl;
  late final TextEditingController _taxCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _minStockCtrl;
  late final TextEditingController _maxStockCtrl;

  DateTime? _expiryDate;
  bool _isActive = true;
  bool _isSaving = false;

  bool get isEditMode => widget.inventory != null;

  @override
  void initState() {
    super.initState();
    final inv = widget.inventory;
    _barcodeCtrl       = TextEditingController(text: inv?.barcode ?? '');
    _skuCtrl           = TextEditingController(text: inv?.sku ?? '');
    _productNameCtrl   = TextEditingController(text: inv?.productName ?? '');
    _nameCtrl          = TextEditingController(text: inv?.name ?? '');
    _descriptionCtrl   = TextEditingController(text: inv?.description ?? '');
    _categoryCtrl      = TextEditingController(text: inv?.category ?? '');
    _companyCtrl       = TextEditingController(text: inv?.companyName ?? '');
    _unitCtrl          = TextEditingController(text: inv?.unit ?? '');
    _sellPriceCtrl     = TextEditingController(text: inv?.sellPrice.toStringAsFixed(0) ?? '');
    _purchasePriceCtrl = TextEditingController(text: inv?.purchasePrice.toStringAsFixed(0) ?? '');
    _wholePriceCtrl    = TextEditingController(text: inv?.wholePrice.toStringAsFixed(0) ?? '');
    _taxCtrl           = TextEditingController(text: inv?.tax.toStringAsFixed(0) ?? '');
    _discountCtrl      = TextEditingController(text: inv?.discount.toStringAsFixed(0) ?? '');
    _minStockCtrl      = TextEditingController(text: inv?.minStock.toString() ?? '');
    _maxStockCtrl      = TextEditingController(text: inv?.maxStock.toString() ?? '');
    _expiryDate        = inv?.expiryDate;
    _isActive          = inv?.isActive ?? true;
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _skuCtrl.dispose();
    _productNameCtrl.dispose();
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _categoryCtrl.dispose();
    _companyCtrl.dispose();
    _unitCtrl.dispose();
    _sellPriceCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _wholePriceCtrl.dispose();
    _taxCtrl.dispose();
    _discountCtrl.dispose();
    _minStockCtrl.dispose();
    _maxStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final now = DateTime.now();

    final result = WarehouseStockInventory(
      id:            widget.inventory?.id ?? 0,
      productName:   _productNameCtrl.text.trim(),
      name:          _nameCtrl.text.trim(),
      sku:           _skuCtrl.text.trim(),
      barcode:       _barcodeCtrl.text.trim(),
      description:   _descriptionCtrl.text.trim(),
      category:      _categoryCtrl.text.trim(),
      unit:          _unitCtrl.text.trim(),
      sellPrice:     double.tryParse(_sellPriceCtrl.text.trim()) ?? 0,
      purchasePrice: double.tryParse(_purchasePriceCtrl.text.trim()) ?? 0,
      wholePrice:    double.tryParse(_wholePriceCtrl.text.trim()) ?? 0,
      tax:           double.tryParse(_taxCtrl.text.trim()) ?? 0,
      discount:      double.tryParse(_discountCtrl.text.trim()) ?? 0,
      minStock:      int.tryParse(_minStockCtrl.text.trim()) ?? 0,
      maxStock:      int.tryParse(_maxStockCtrl.text.trim()) ?? 0,
      companyName:   _companyCtrl.text.trim(),
      expiryDate:    _expiryDate,
      isActive:      _isActive,
      createdAt:     widget.inventory?.createdAt ?? now,
      updatedAt:     now,
    );

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isSaving = false);
    if (mounted) Navigator.pop(context, result);
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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

                      // ── Section: Basic Info ──
                      SectionLabel(label: "Basic Information", icon: Icons.info_outline_rounded),
                      const SizedBox(height: 12),

                      FormRow(children: [
                        Field(
                          label: "Product Name *",
                          controller: _productNameCtrl,
                          hint: "e.g. Panadol 500mg",
                          validator: _required,
                        ),
                      ]),
                      const SizedBox(height: 14),

                      Field(
                        label: "Description",
                        controller: _descriptionCtrl,
                        hint: "Brief product description...",
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),

                      FormRow(children: [
                        Field(
                          label: "Barcode *",
                          controller: _barcodeCtrl,
                          hint: "e.g. 8901234567890",
                          validator: _required,
                        ),
                        Field(
                          label: "SKU",
                          controller: _skuCtrl,
                          hint: "e.g. MED-PAN-500",
                        ),
                      ]),
                      const SizedBox(height: 14),

                      FormRow(children: [
                        Field(
                          label: "Category *",
                          controller: _categoryCtrl,
                          hint: "e.g. Medicine",
                          validator: _required,
                        ),
                        Field(
                          label: "Company *",
                          controller: _companyCtrl,
                          hint: "e.g. GSK",
                          validator: _required,
                        ),
                      ]),
                      const SizedBox(height: 14),

                      Field(
                        label: "Unit *",
                        controller: _unitCtrl,
                        hint: "e.g. Pcs, Box, Kg, Strip",
                        validator: _required,
                      ),

                      const SizedBox(height: 24),

                      // ── Section: Pricing ──
                      SectionLabel(label: "Pricing", icon: Icons.sell_rounded),
                      const SizedBox(height: 12),

                      FormRow(children: [
                        Field(
                          label: "Purchase Price (Rs.) *",
                          controller: _purchasePriceCtrl,
                          hint: "e.g. 180",
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          validator: _required,
                        ),
                        Field(
                          label: "Sale Price (Rs.) *",
                          controller: _sellPriceCtrl,
                          hint: "e.g. 250",
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          validator: _required,
                        ),
                      ]),
                      const SizedBox(height: 14),

                      FormRow(children: [
                        Field(
                          label: "Wholesale Price (Rs.)",
                          controller: _wholePriceCtrl,
                          hint: "e.g. 210",
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        ),
                        Field(
                          label: "Tax (%)",
                          controller: _taxCtrl,
                          hint: "e.g. 5",
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        ),
                      ]),
                      const SizedBox(height: 14),

                      // Discount — half width
                      SizedBox(
                        width: double.infinity,
                        child: FormRow(children: [
                          Field(
                            label: "Discount (%)",
                            controller: _discountCtrl,
                            hint: "e.g. 10",
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          ),
                          const SizedBox(), // empty second cell
                        ]),
                      ),

                      const SizedBox(height: 24),

                      // ── Section: Stock ──
                      SectionLabel(label: "Stock & Expiry", icon: Icons.inventory_2_rounded),
                      const SizedBox(height: 12),

                      FormRow(children: [
                        Field(
                          label: "Min Stock *",
                          controller: _minStockCtrl,
                          hint: "e.g. 10",
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: _required,
                        ),
                        Field(
                          label: "Max Stock *",
                          controller: _maxStockCtrl,
                          hint: "e.g. 500",
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: _required,
                        ),
                      ]),
                      const SizedBox(height: 14),

                      ExpiryField(date: _expiryDate, onTap: _pickExpiry),

                      const SizedBox(height: 24),

                      // ── Section: Status ──
                      SectionLabel(label: "Status", icon: Icons.toggle_on_rounded),
                      const SizedBox(height: 12),

                      StatusToggle(
                        isActive: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),

                      const SizedBox(height: 28),

                      // ── Actions ──
                      DialogActions(
                        isSaving: _isSaving,
                        isEditMode: isEditMode,
                        onCancel: () => Navigator.pop(context),
                        onSave: _onSave,
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


