// =============================================================
// new_po_form_item.dart
// NewPurchaseOrderScreen ke liye ek product row ka model
// Controllers yahan hain taake state mein manage ho sakein
// =============================================================

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class NewPoFormItem {
  final String  id;
  final String? productId;
  String        productName;
  String?       sku;

  final TextEditingController qtyCtrl;
  final TextEditingController unitCostCtrl;
  final TextEditingController salePriceCtrl;

  NewPoFormItem({
    String?      id,
    this.productId,
    this.productName = '',
    this.sku,
    String qty        = '',
    String unitCost   = '',
    String salePrice  = '',
  })  : id            = id ?? const Uuid().v4(),
        qtyCtrl       = TextEditingController(text: qty),
        unitCostCtrl  = TextEditingController(text: unitCost),
        salePriceCtrl = TextEditingController(text: salePrice);

  void dispose() {
    qtyCtrl.dispose();
    unitCostCtrl.dispose();
    salePriceCtrl.dispose();
  }

  // ── Computed helpers ──────────────────────────────────────

  double get qty       => double.tryParse(qtyCtrl.text)       ?? 0;
  double get unitCost  => double.tryParse(unitCostCtrl.text)  ?? 0;
  double get salePrice => double.tryParse(salePriceCtrl.text) ?? 0;
  double get totalCost => qty * unitCost;

  double? get marginPercent =>
      salePrice > 0 && unitCost > 0
          ? ((salePrice - unitCost) / unitCost) * 100
          : null;

  bool get isValid =>
      productName.trim().isNotEmpty && qty > 0 && unitCost > 0;
}