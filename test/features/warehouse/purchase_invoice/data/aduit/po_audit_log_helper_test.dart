// =============================================================
// po_audit_log_helper_test.dart
// =============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/data/audit/po_audit_log_helper.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/domain/purchase_order_model.dart';

void main() {

  // ── Snapshot helper ───────────────────────────────────────
  Map<String, dynamic> makeSnapshot({
    String  supplierId     = 'sup-1',
    String? supplierName   = 'Ali Traders',
    String  status         = 'received',
    double  totalAmount    = 1000,
    double  paidAmount     = 0,
    double  remainingAmount = 1000,
    double  discountAmount = 0,
    List<PurchaseOrderItem> items = const [],
  }) {
    return PoAuditHelper.snapshot(
      supplierId:     supplierId,
      supplierName:   supplierName,
      status:         status,
      subtotal:       totalAmount,
      discountAmount: discountAmount,
      taxAmount:      0,
      totalAmount:    totalAmount,
      paidAmount:     paidAmount,
      remainingAmount: remainingAmount,
      expectedDate:   DateTime(2026, 4, 27),
      items:          items,
    );
  }

  PurchaseOrderItem makeItem({
    String productId   = 'p-1',
    String productName = 'Pepsi',
    String sku         = 'SKU-001',
    double qty         = 10,
    double unitCost    = 100,
    double? salePrice  = 130,
  }) {
    return PurchaseOrderItem(
      id:               'item-1',
      poId:             'po-1',
      tenantId:         'wh-1',
      productId:        productId,
      productName:      productName,
      sku:              sku,
      quantityOrdered:  qty,
      quantityReceived: 0,
      unitCost:         unitCost,
      totalCost:        qty * unitCost,
      salePrice:        salePrice,
    );
  }

  // ═══════════════════════════════════════════════════════════
  group('PoAuditHelper.snapshot', () {

    test('snapshot contains all required keys', () {
      final snap = makeSnapshot();
      expect(snap.containsKey('supplier_id'),      isTrue);
      expect(snap.containsKey('supplier_name'),    isTrue);
      expect(snap.containsKey('status'),           isTrue);
      expect(snap.containsKey('total_amount'),     isTrue);
      expect(snap.containsKey('paid_amount'),      isTrue);
      expect(snap.containsKey('remaining_amount'), isTrue);
      expect(snap.containsKey('items'),            isTrue);
    });

    test('snapshot items contain product fields', () {
      final snap = makeSnapshot(items: [makeItem()]);
      final items = snap['items'] as List;
      expect(items, hasLength(1));
      expect(items.first['product_name'], equals('Pepsi'));
      expect(items.first['quantity_ordered'], equals(10.0));
      expect(items.first['unit_cost'], equals(100.0));
    });

    test('snapshot values match input', () {
      final snap = makeSnapshot(
          paidAmount: 500, totalAmount: 1000, remainingAmount: 500);
      expect(snap['paid_amount'],      equals(500.0));
      expect(snap['total_amount'],     equals(1000.0));
      expect(snap['remaining_amount'], equals(500.0));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('PoAuditHelper.buildSummary — no changes', () {

    test('identical snapshots → No significant changes', () {
      final snap = makeSnapshot(paidAmount: 500);
      final summary = PoAuditHelper.buildSummary(
          oldData: snap, newData: snap);
      expect(summary, equals('No significant changes'));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('PoAuditHelper.buildSummary — paid amount change', () {

    test('paid amount increase detected', () {
      final old = makeSnapshot(paidAmount: 0,   remainingAmount: 1000);
      final nw  = makeSnapshot(paidAmount: 645, remainingAmount: 355);
      final summary = PoAuditHelper.buildSummary(
          oldData: old, newData: nw);
      expect(summary, contains('Paid'));
      expect(summary, contains('0'));
      expect(summary, contains('645'));
    });

    test('paid amount decrease detected', () {
      final old = makeSnapshot(paidAmount: 1000, remainingAmount: 0);
      final nw  = makeSnapshot(paidAmount: 800,  remainingAmount: 200);
      final summary = PoAuditHelper.buildSummary(
          oldData: old, newData: nw);
      expect(summary, contains('Paid'));
      expect(summary, contains('1000'));
      expect(summary, contains('800'));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('PoAuditHelper.buildSummary — qty change', () {

    test('qty increase detected', () {
      final oldItem = makeItem(qty: 10);
      final newItem = makeItem(qty: 12);
      final old = makeSnapshot(items: [oldItem], totalAmount: 1000);
      final nw  = makeSnapshot(items: [newItem], totalAmount: 1200);

      final summary = PoAuditHelper.buildSummary(
          oldData: old, newData: nw);
      expect(summary, contains('Pepsi'));
      expect(summary, contains('10'));
      expect(summary, contains('12'));
    });

    test('qty decrease detected', () {
      final oldItem = makeItem(qty: 10);
      final newItem = makeItem(qty: 6);
      final old = makeSnapshot(items: [oldItem]);
      final nw  = makeSnapshot(items: [newItem]);

      final summary = PoAuditHelper.buildSummary(
          oldData: old, newData: nw);
      expect(summary, contains('10'));
      expect(summary, contains('6'));
    });

    test('item count change detected', () {
      final old = makeSnapshot(items: [makeItem()]);
      final nw  = makeSnapshot(items: [makeItem(), makeItem(
          productId: 'p-2', productName: 'Lemon Max')]);

      final summary = PoAuditHelper.buildSummary(
          oldData: old, newData: nw);
      expect(summary, contains('Items'));
      expect(summary, contains('1'));
      expect(summary, contains('2'));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('PoAuditHelper.buildSummary — price change', () {

    test('unit cost change detected', () {
      final oldItem = makeItem(unitCost: 100);
      final newItem = makeItem(unitCost: 120);
      final old = makeSnapshot(items: [oldItem]);
      final nw  = makeSnapshot(items: [newItem]);

      final summary = PoAuditHelper.buildSummary(
          oldData: old, newData: nw);
      expect(summary, contains('100'));
      expect(summary, contains('120'));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('PoAuditHelper.buildSummary — status change', () {

    test('status change detected', () {
      final old = makeSnapshot(status: 'ordered');
      final nw  = makeSnapshot(status: 'received');

      final summary = PoAuditHelper.buildSummary(
          oldData: old, newData: nw);
      expect(summary, contains('ordered'));
      expect(summary, contains('received'));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('PoAuditHelper.buildSummary — supplier change', () {

    test('supplier name change detected', () {
      final old = makeSnapshot(supplierName: 'Ali Traders');
      final nw  = makeSnapshot(supplierName: 'M Hashim');

      final summary = PoAuditHelper.buildSummary(
          oldData: old, newData: nw);
      expect(summary, contains('Ali Traders'));
      expect(summary, contains('M Hashim'));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('PoAuditHelper.buildSummary — multiple changes', () {

    test('multiple changes separated by |', () {
      final old = makeSnapshot(
          paidAmount: 0, totalAmount: 1000, remainingAmount: 1000,
          items: [makeItem(qty: 10)]);
      final nw = makeSnapshot(
          paidAmount: 500, totalAmount: 1200, remainingAmount: 700,
          items: [makeItem(qty: 12)]);

      final summary = PoAuditHelper.buildSummary(
          oldData: old, newData: nw);
      // Multiple changes hone chahiye
      expect(summary.contains('|'), isTrue);
    });
  });
}