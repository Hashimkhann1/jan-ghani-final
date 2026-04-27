// =============================================================
// po_audit_log_helper.dart
// PO snapshot banao + human-readable diff generate karo
// Datasource mein import karke use karo
// =============================================================

import 'package:jan_ghani_final/features/warehouse/purchase_invoice/domain/purchase_order_model.dart';

class PoAuditHelper {

  // ── PO ka snapshot banao — old_data / new_data ke liye ───
  // Sirf woh fields jo audit ke liye important hain
  static Map<String, dynamic> snapshot({
    required String    supplierId,
    required String?   supplierName,
    required String    status,
    required double    subtotal,
    required double    discountAmount,
    required double    taxAmount,
    required double    totalAmount,
    required double    paidAmount,
    required double    remainingAmount,
    required DateTime? expectedDate,
    required List<PurchaseOrderItem> items,
  }) {
    return {
      'supplier_id':      supplierId,
      'supplier_name':    supplierName,
      'status':           status,
      'subtotal':         subtotal,
      'discount_amount':  discountAmount,
      'tax_amount':       taxAmount,
      'total_amount':     totalAmount,
      'paid_amount':      paidAmount,
      'remaining_amount': remainingAmount,
      'expected_date':    expectedDate?.toIso8601String(),
      'items': items.map((i) => {
        'product_id':       i.productId,
        'product_name':     i.productName,
        'sku':              i.sku,
        'quantity_ordered': i.quantityOrdered,
        'unit_cost':        i.unitCost,
        'total_cost':       i.totalCost,
        'sale_price':       i.salePrice,
        'discount_amount':  i.discountAmount,
        'discount_percent': i.discountPercent,
      }).toList(),
    };
  }

  // ── Old aur New data compare karke summary banao ──────────
  // Example output:
  // "paid_amount: Rs 500 → Rs 1000 | status: ordered → received | items: 2 → 3"
  static String buildSummary({
    required Map<String, dynamic> oldData,
    required Map<String, dynamic> newData,
  }) {
    final changes = <String>[];

    // ── Header fields check karo ──────────────────────────
    _compareField(changes, oldData, newData, 'supplier_name',    prefix: 'Supplier');
    _compareField(changes, oldData, newData, 'status',           prefix: 'Status');
    _compareAmountField(changes, oldData, newData, 'total_amount',    label: 'Total');
    _compareAmountField(changes, oldData, newData, 'paid_amount',     label: 'Paid');
    _compareAmountField(changes, oldData, newData, 'discount_amount', label: 'Discount');
    _compareAmountField(changes, oldData, newData, 'tax_amount',      label: 'Tax');
    _compareField(changes, oldData, newData, 'expected_date',    prefix: 'Delivery Date');

    // ── Items check karo ──────────────────────────────────
    final oldItems = (oldData['items'] as List?)?.length ?? 0;
    final newItems = (newData['items'] as List?)?.length ?? 0;
    if (oldItems != newItems) {
      changes.add('Items: $oldItems → $newItems');
    } else {
      // Same count — per-item changes check karo
      final oldList = (oldData['items'] as List?) ?? [];
      final newList = (newData['items'] as List?) ?? [];
      for (var idx = 0; idx < oldList.length; idx++) {
        if (idx >= newList.length) break;
        final old = oldList[idx] as Map<String, dynamic>;
        final nw  = newList[idx] as Map<String, dynamic>;
        final name = old['product_name'] ?? 'Item ${idx + 1}';

        if (_changed(old, nw, 'quantity_ordered')) {
          changes.add(
            '$name qty: ${old['quantity_ordered']} → ${nw['quantity_ordered']}',
          );
        }
        if (_changed(old, nw, 'unit_cost')) {
          changes.add(
            '$name cost: Rs ${old['unit_cost']} → Rs ${nw['unit_cost']}',
          );
        }
        if (_changed(old, nw, 'sale_price')) {
          changes.add(
            '$name sale price: Rs ${old['sale_price']} → Rs ${nw['sale_price']}',
          );
        }
      }
    }

    if (changes.isEmpty) return 'No significant changes';
    return changes.join(' | ');
  }

  // ── Helpers ───────────────────────────────────────────────

  static bool _changed(
      Map<String, dynamic> a, Map<String, dynamic> b, String key) {
    return a[key]?.toString() != b[key]?.toString();
  }

  static void _compareField(
      List<String> out,
      Map<String, dynamic> old,
      Map<String, dynamic> nw,
      String key, {
        required String prefix,
      }) {
    if (_changed(old, nw, key)) {
      out.add('$prefix: ${old[key] ?? '-'} → ${nw[key] ?? '-'}');
    }
  }

  static void _compareAmountField(
      List<String> out,
      Map<String, dynamic> old,
      Map<String, dynamic> nw,
      String key, {
        required String label,
      }) {
    if (_changed(old, nw, key)) {
      out.add('$label: Rs ${old[key] ?? 0} → Rs ${nw[key] ?? 0}');
    }
  }
}