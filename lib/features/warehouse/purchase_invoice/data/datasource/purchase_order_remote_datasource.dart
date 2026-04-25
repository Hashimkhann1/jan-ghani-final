// =============================================================
// purchase_order_remote_datasource.dart
// UPDATED: discount_amount per-item — DB insert, fetch, mapping
// =============================================================

// =============================================================
// purchase_order_remote_datasource.dart
// UPDATED: discount_amount + discount_percent per-item
// =============================================================

import 'package:jan_ghani_final/features/warehouse/purchase_invoice/domain/purchase_order_model.dart';
import 'package:postgres/postgres.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/provider/purchase_order_provider.dart';

class PurchaseOrderRemoteDataSource {
  Future<Connection> get _db => DatabaseService.getConnection();

  // ── GET ALL ───────────────────────────────────────────────
  Future<List<PurchaseOrderModel>> getAll(String warehouseId) async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        SELECT
          po.id,
          po.warehouse_id          AS tenant_id,
          po.po_number,
          po.supplier_id,
          s.name                   AS supplier_name,
          s.company_name           AS supplier_company,
          s.phone                  AS supplier_phone,
          s.address                AS supplier_address,
          s.tax_id                 AS supplier_tax_id,
          s.payment_terms          AS supplier_payment_terms,
          po.destination_location_id,
          l.name                   AS destination_name,
          po.status,
          po.order_date,
          po.expected_date,
          po.received_date,
          po.subtotal,
          po.discount_amount,
          po.tax_amount,
          po.total_amount,
          po.paid_amount,
          po.notes,
          u.full_name              AS created_by_name,
          po.created_at,
          po.updated_at
        FROM purchase_orders po
        LEFT JOIN suppliers s  ON s.id  = po.supplier_id
        LEFT JOIN locations l  ON l.id  = po.destination_location_id
        LEFT JOIN warehouse_users u      ON u.id  = po.created_by
        WHERE po.warehouse_id = @warehouseId
          AND po.deleted_at   IS NULL
        ORDER BY po.created_at DESC
      '''),
      parameters: {'warehouseId': warehouseId},
    );

    final orders = <PurchaseOrderModel>[];
    for (final row in result) {
      final m    = row.toColumnMap();
      final poId = m['id'].toString();
      final items = await _getItems(conn, poId);
      orders.add(_mapToModel(m, items));
    }
    return orders;
  }

  // ── GET BY ID ─────────────────────────────────────────────
  Future<PurchaseOrderModel?> getById(String id) async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        SELECT
          po.id,
          po.warehouse_id          AS tenant_id,
          po.po_number,
          po.supplier_id,
          s.name                   AS supplier_name,
          s.company_name           AS supplier_company,
          s.phone                  AS supplier_phone,
          s.address                AS supplier_address,
          s.tax_id                 AS supplier_tax_id,
          s.payment_terms          AS supplier_payment_terms,
          po.destination_location_id,
          l.name                   AS destination_name,
          po.status,
          po.order_date,
          po.expected_date,
          po.received_date,
          po.subtotal,
          po.discount_amount,
          po.tax_amount,
          po.total_amount,
          po.paid_amount,
          po.notes,
          u.full_name              AS created_by_name,
          po.created_at,
          po.updated_at
        FROM purchase_orders po
        LEFT JOIN suppliers s  ON s.id  = po.supplier_id
        LEFT JOIN locations l  ON l.id  = po.destination_location_id
        LEFT JOIN warehouse_users u      ON u.id  = po.created_by
        WHERE po.id = @id
          AND po.deleted_at IS NULL
        LIMIT 1
      '''),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;
    final m     = result.first.toColumnMap();
    final items = await _getItems(conn, id);
    return _mapToModel(m, items);
  }

  // ── CREATE PO ─────────────────────────────────────────────
  Future<PurchaseOrderModel> create({
    required String                  warehouseId,
    required String                  poNumber,
    String?                          destinationLocationId,
    String?                          supplierId,
    String?                          status,
    DateTime?                        expectedDate,
    double                           subtotal        = 0,
    double                           discountAmount  = 0,
    double                           taxAmount       = 0,
    double                           totalAmount     = 0,
    double                           paidAmount      = 0,
    double                           remainingAmount = 0,
    String?                          notes,
    String?                          createdBy,
    String?                          createdByName,
    required List<PurchaseOrderItem> items,
  }) async {
    final conn = await _db;

    final poResult = await conn.execute(
      Sql.named('''
        INSERT INTO purchase_orders (
          warehouse_id, po_number, supplier_id,
          destination_location_id, status,
          expected_date, subtotal, discount_amount,
          tax_amount, total_amount, paid_amount,
          remaining_amount, notes, created_by, created_by_name
        ) VALUES (
          @warehouseId, @poNumber, @supplierId,
          @destinationLocationId, @status,
          @expectedDate, @subtotal, @discountAmount,
          @taxAmount, @totalAmount, @paidAmount,
          @remainingAmount, @notes, @createdBy, @createdByName
        )
        RETURNING id
      '''),
      parameters: {
        'warehouseId':           warehouseId,
        'poNumber':              poNumber,
        'supplierId':            supplierId,
        'destinationLocationId': destinationLocationId,
        'status':                status ?? 'draft',
        'expectedDate':          expectedDate,
        'subtotal':              subtotal,
        'discountAmount':        discountAmount,
        'taxAmount':             taxAmount,
        'totalAmount':           totalAmount,
        'paidAmount':            paidAmount,
        'remainingAmount':       remainingAmount,
        'notes':                 notes,
        'createdBy':             createdBy,
        'createdByName':         createdByName,
      },
    );

    final newPoId = poResult.first.toColumnMap()['id'].toString();

    for (final item in items) {
      await conn.execute(
        Sql.named('''
          INSERT INTO purchase_order_items (
            po_id, warehouse_id, product_id, product_name,
            sku, quantity_ordered, quantity_received,
            unit_cost, total_cost, sale_price,
            discount_amount, discount_percent
          ) VALUES (
            @poId, @warehouseId, @productId, @productName,
            @sku, @quantityOrdered, 0,
            @unitCost, @totalCost, @salePrice,
            @discountAmount, @discountPercent
          )
        '''),
        parameters: {
          'poId':            newPoId,
          'warehouseId':     warehouseId,
          'productId':       item.productId,
          'productName':     item.productName,
          'sku':             item.sku,
          'quantityOrdered': item.quantityOrdered,
          'unitCost':        item.unitCost,
          'totalCost':       item.totalCost,
          'salePrice':       item.salePrice,
          'discountAmount':  item.discountAmount,
          'discountPercent': item.discountPercent,
        },
      );
    }

    await _handleReceivedInventory(conn, newPoId, warehouseId, status ?? 'draft', items);

    if ((status ?? 'draft') == 'received') {
      await _handleSupplierLedger(conn, newPoId, warehouseId, supplierId, poNumber, remainingAmount, createdBy);
    }

    return (await getById(newPoId))!;
  }

  // ── UPDATE PO — edit mode ke liye ─────────────────────────
  Future<PurchaseOrderModel> updatePO({
    required String                  poId,
    required String                  warehouseId,
    required String                  oldStatus,
    String?                          supplierId,
    String?                          status,
    DateTime?                        expectedDate,
    double                           subtotal        = 0,
    double                           discountAmount  = 0,
    double                           taxAmount       = 0,
    double                           totalAmount     = 0,
    double                           paidAmount      = 0,
    double                           remainingAmount = 0,
    String?                          notes,
    String?                          updatedBy,
    String?                          updatedByName,
    required List<PurchaseOrderItem> items,
  }) async {
    final conn = await _db;

    await conn.execute(
      Sql.named('''
        UPDATE purchase_orders SET
          supplier_id      = @supplierId,
          status           = @status,
          expected_date    = @expectedDate,
          subtotal         = @subtotal,
          discount_amount  = @discountAmount,
          tax_amount       = @taxAmount,
          total_amount     = @totalAmount,
          paid_amount      = @paidAmount,
          remaining_amount = @remainingAmount,
          notes            = @notes,
          updated_at       = NOW()
        WHERE id           = @poId
          AND warehouse_id = @warehouseId
      '''),
      parameters: {
        'poId':            poId,
        'warehouseId':     warehouseId,
        'supplierId':      supplierId,
        'status':          status ?? oldStatus,
        'expectedDate':    expectedDate,
        'subtotal':        subtotal,
        'discountAmount':  discountAmount,
        'taxAmount':       taxAmount,
        'totalAmount':     totalAmount,
        'paidAmount':      paidAmount,
        'remainingAmount': remainingAmount,
        'notes':           notes,
      },
    );

    await conn.execute(
      Sql.named('DELETE FROM purchase_order_items WHERE po_id = @poId'),
      parameters: {'poId': poId},
    );

    for (final item in items) {
      await conn.execute(
        Sql.named('''
          INSERT INTO purchase_order_items (
            po_id, warehouse_id, product_id, product_name,
            sku, quantity_ordered, quantity_received,
            unit_cost, total_cost, sale_price,
            discount_amount, discount_percent
          ) VALUES (
            @poId, @warehouseId, @productId, @productName,
            @sku, @quantityOrdered, @quantityReceived,
            @unitCost, @totalCost, @salePrice,
            @discountAmount, @discountPercent
          )
        '''),
        parameters: {
          'poId':             poId,
          'warehouseId':      warehouseId,
          'productId':        item.productId,
          'productName':      item.productName,
          'sku':              item.sku,
          'quantityOrdered':  item.quantityOrdered,
          'quantityReceived': item.quantityReceived,
          'unitCost':         item.unitCost,
          'totalCost':        item.totalCost,
          'salePrice':        item.salePrice,
          'discountAmount':   item.discountAmount,
          'discountPercent':  item.discountPercent,
        },
      );
    }

    final newStatus = status ?? oldStatus;
    final becomingReceived = newStatus == 'received' && oldStatus != 'received';

    if (becomingReceived) {
      await _handleReceivedInventory(conn, poId, warehouseId, newStatus, items);

      if (supplierId != null && supplierId.isNotEmpty) {
        await conn.execute(
          Sql.named('''
            DELETE FROM supplier_ledger
            WHERE po_id      = @poId
              AND entry_type = 'purchase'
          '''),
          parameters: {'poId': poId},
        );

        final balResult = await conn.execute(
          Sql.named('''
            SELECT outstanding_balance FROM suppliers
            WHERE id = @supplierId
          '''),
          parameters: {'supplierId': supplierId},
        );
        final currentBalance = balResult.isNotEmpty
            ? _toDouble(balResult.first.toColumnMap()['outstanding_balance'])
            : 0.0;
        final newBalance = currentBalance + remainingAmount;

        final poRow = await conn.execute(
          Sql.named('SELECT po_number FROM purchase_orders WHERE id = @poId'),
          parameters: {'poId': poId},
        );
        final poNumber = poRow.isNotEmpty
            ? poRow.first.toColumnMap()['po_number']
            : poId;

        await conn.execute(
          Sql.named('''
            INSERT INTO supplier_ledger (
              warehouse_id, supplier_id, po_id,
              entry_type, amount, balance_before,
              balance_after, notes, created_by
            ) VALUES (
              @warehouseId, @supplierId, @poId,
              'purchase', @amount, @balanceBefore,
              @balanceAfter, @notes, @createdBy
            )
          '''),
          parameters: {
            'warehouseId':   warehouseId,
            'supplierId':    supplierId,
            'poId':          poId,
            'amount':        remainingAmount,
            'balanceBefore': currentBalance,
            'balanceAfter':  newBalance,
            'notes':         'PO $poNumber — received ho gaya',
            'createdBy':     updatedBy,
          },
        );
      }
    }

    return (await getById(poId))!;
  }

  // ── UPDATE STATUS ─────────────────────────────────────────
  Future<void> updateStatus(String poId, String newStatus) async {
    final conn = await _db;
    await conn.execute(
      Sql.named('''
        UPDATE purchase_orders
        SET status = @status, updated_at = NOW()
        WHERE id   = @id
      '''),
      parameters: {'id': poId, 'status': newStatus},
    );
  }

  // ── SOFT DELETE ───────────────────────────────────────────
  Future<void> delete(String poId) async {
    final conn = await _db;
    await conn.execute(
      Sql.named('UPDATE purchase_orders SET deleted_at = NOW() WHERE id = @id'),
      parameters: {'id': poId},
    );
  }

  // ── STATS ─────────────────────────────────────────────────
  Future<PurchaseOrderStats> getStats(String warehouseId) async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        SELECT
          COUNT(*)                                        AS total_pos,
          COUNT(*) FILTER (
            WHERE status IN ('draft','ordered','partial')
          )                                               AS pending_count,
          COUNT(*) FILTER (
            WHERE status = 'received'
          )                                               AS received_count,
          COALESCE(SUM(total_amount) FILTER (
            WHERE DATE_TRUNC('month', order_date)
                  = DATE_TRUNC('month', NOW())
          ), 0)                                           AS this_month_total,
          COALESCE(SUM(total_amount - paid_amount) FILTER (
            WHERE status NOT IN ('cancelled','received')
          ), 0)                                           AS total_outstanding
        FROM purchase_orders
        WHERE warehouse_id = @warehouseId
          AND deleted_at IS NULL
      '''),
      parameters: {'warehouseId': warehouseId},
    );

    final m = result.first.toColumnMap();
    return PurchaseOrderStats(
      totalPOs:         _toInt(m['total_pos']),
      pendingCount:     _toInt(m['pending_count']),
      receivedCount:    _toInt(m['received_count']),
      thisMonthTotal:   _toDouble(m['this_month_total']),
      totalOutstanding: _toDouble(m['total_outstanding']),
    );
  }

  // ── PRIVATE: inventory update jab received ho ─────────────
  Future<void> _handleReceivedInventory(
      Connection conn,
      String     poId,
      String     warehouseId,
      String     status,
      List<PurchaseOrderItem> items,
      ) async {
    if (status != 'received') return;

    for (final item in items) {
      if (item.productId == null) continue;

      final oldQtyResult = await conn.execute(
        Sql.named('''
          SELECT COALESCE(i.quantity, 0) AS qty,
                 p.purchase_price
          FROM warehouse_inventory i
          JOIN warehouse_products p ON p.id = i.product_id
          WHERE i.product_id   = @productId
            AND i.warehouse_id = @warehouseId
          LIMIT 1
        '''),
        parameters: {
          'productId':   item.productId,
          'warehouseId': warehouseId,
        },
      );

      final oldQty  = oldQtyResult.isNotEmpty
          ? _toDouble(oldQtyResult.first.toColumnMap()['qty'])
          : 0.0;
      final oldCost = oldQtyResult.isNotEmpty
          ? _toDouble(oldQtyResult.first.toColumnMap()['purchase_price'])
          : item.unitCost;

      await conn.execute(
        Sql.named('''
          INSERT INTO warehouse_inventory (warehouse_id, product_id, quantity)
          VALUES (@warehouseId, @productId, @qty)
          ON CONFLICT (warehouse_id, product_id)
          DO UPDATE SET
            quantity         = warehouse_inventory.quantity + EXCLUDED.quantity,
            last_movement_at = NOW(),
            updated_at       = NOW(),
            is_synced        = false
        '''),
        parameters: {
          'warehouseId': warehouseId,
          'productId':   item.productId,
          'qty':         item.quantityOrdered,
        },
      );

      final newQty   = item.quantityOrdered;
      final totalQty = oldQty + newQty;
      final avgCost  = totalQty > 0
          ? ((oldQty * oldCost) + (newQty * item.unitCost)) / totalQty
          : item.unitCost;

      await conn.execute(
        Sql.named('''
          UPDATE warehouse_products SET
            purchase_price = @avgCost,
            selling_price  = COALESCE(@salePrice, selling_price),
            updated_at     = NOW(),
            is_synced      = false
          WHERE id           = @productId
            AND warehouse_id = @warehouseId
        '''),
        parameters: {
          'productId':   item.productId,
          'warehouseId': warehouseId,
          'avgCost':     double.parse(avgCost.toStringAsFixed(2)),
          'salePrice':   item.salePrice,
        },
      );
    }
  }

  // ── PRIVATE: supplier ledger entry ────────────────────────
  Future<void> _handleSupplierLedger(
      Connection conn,
      String     poId,
      String     warehouseId,
      String?    supplierId,
      String     poNumber,
      double     remainingAmount,
      String?    createdBy,
      ) async {
    if (supplierId == null || supplierId.isEmpty) return;

    final balResult = await conn.execute(
      Sql.named('''
        SELECT outstanding_balance FROM suppliers
        WHERE id = @supplierId
      '''),
      parameters: {'supplierId': supplierId},
    );
    final currentBalance = balResult.isNotEmpty
        ? _toDouble(balResult.first.toColumnMap()['outstanding_balance'])
        : 0.0;
    final newBalance = currentBalance + remainingAmount;

    await conn.execute(
      Sql.named('''
        INSERT INTO supplier_ledger (
          warehouse_id, supplier_id, po_id,
          entry_type, amount, balance_before,
          balance_after, notes, created_by
        ) VALUES (
          @warehouseId, @supplierId, @poId,
          'purchase', @amount, @balanceBefore,
          @balanceAfter, @notes, @createdBy
        )
      '''),
      parameters: {
        'warehouseId':   warehouseId,
        'supplierId':    supplierId,
        'poId':          poId,
        'amount':        remainingAmount,
        'balanceBefore': currentBalance,
        'balanceAfter':  newBalance,
        'notes':         'PO $poNumber se purchase',
        'createdBy':     createdBy,
      },
    );
  }

  // ── PRIVATE: items fetch ───────────────────────────────────
  Future<List<PurchaseOrderItem>> _getItems(
      Connection conn, String poId) async {
    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, po_id, warehouse_id AS tenant_id,
          product_id, product_name, sku,
          quantity_ordered, quantity_received,
          unit_cost, total_cost, sale_price,
          COALESCE(discount_amount, 0)  AS discount_amount,
          COALESCE(discount_percent, 0) AS discount_percent
        FROM purchase_order_items
        WHERE po_id = @poId
        ORDER BY id
      '''),
      parameters: {'poId': poId},
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return PurchaseOrderItem(
        id:               m['id'].toString(),
        poId:             m['po_id'].toString(),
        tenantId:         m['tenant_id'].toString(),
        productId:        m['product_id']?.toString(),
        productName:      m['product_name'].toString(),
        sku:              m['sku']?.toString(),
        quantityOrdered:  _toDouble(m['quantity_ordered']),
        quantityReceived: _toDouble(m['quantity_received']),
        unitCost:         _toDouble(m['unit_cost']),
        totalCost:        _toDouble(m['total_cost']),
        salePrice: m['sale_price'] != null
            ? _toDouble(m['sale_price'])
            : null,
        discountAmount:  _toDouble(m['discount_amount']),
        discountPercent: _toDouble(m['discount_percent']),
      );
    }).toList();
  }

  // ── PRIVATE: row → model ──────────────────────────────────
  PurchaseOrderModel _mapToModel(
      Map<String, dynamic> m, List<PurchaseOrderItem> items) {
    return PurchaseOrderModel(
      id:                    m['id'].toString(),
      tenantId:              m['tenant_id'].toString(),
      poNumber:              m['po_number'].toString(),
      supplierId:            m['supplier_id']?.toString(),
      supplierName:          m['supplier_name']?.toString(),
      supplierCompany:       m['supplier_company']?.toString(),
      supplierPhone:         m['supplier_phone']?.toString(),
      supplierAddress:       m['supplier_address']?.toString(),
      supplierTaxId:         m['supplier_tax_id']?.toString(),
      supplierPaymentTerms:  m['supplier_payment_terms'] != null
          ? _toInt(m['supplier_payment_terms'])
          : null,
      destinationLocationId: m['destination_location_id'].toString(),
      destinationName:       m['destination_name']?.toString(),
      status:                m['status'].toString(),
      orderDate: m['order_date'] is DateTime
          ? m['order_date'] as DateTime
          : DateTime.parse(m['order_date'].toString()),
      expectedDate: m['expected_date'] != null
          ? (m['expected_date'] is DateTime
          ? m['expected_date'] as DateTime
          : DateTime.parse(m['expected_date'].toString()))
          : null,
      receivedDate: m['received_date'] != null
          ? (m['received_date'] is DateTime
          ? m['received_date'] as DateTime
          : DateTime.parse(m['received_date'].toString()))
          : null,
      subtotal:       _toDouble(m['subtotal']),
      discountAmount: _toDouble(m['discount_amount']),
      taxAmount:      _toDouble(m['tax_amount']),
      totalAmount:    _toDouble(m['total_amount']),
      paidAmount:     _toDouble(m['paid_amount']),
      notes:          m['notes']?.toString(),
      createdByName:  m['created_by_name']?.toString(),
      createdAt: m['created_at'] is DateTime
          ? m['created_at'] as DateTime
          : DateTime.parse(m['created_at'].toString()),
      updatedAt: m['updated_at'] is DateTime
          ? m['updated_at'] as DateTime
          : DateTime.parse(m['updated_at'].toString()),
      items: items,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}



// // =============================================================
// // purchase_order_remote_datasource.dart
// // UPDATED: updatePO() function add kiya — edit mode ke liye
// // =============================================================
//
// import 'package:jan_ghani_final/features/warehouse/purchase_invoice/domain/purchase_order_model.dart';
// import 'package:postgres/postgres.dart';
// import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
// import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/provider/purchase_order_provider.dart';
//
// class PurchaseOrderRemoteDataSource {
//   Future<Connection> get _db => DatabaseService.getConnection();
//
//   // ── GET ALL ───────────────────────────────────────────────
//   Future<List<PurchaseOrderModel>> getAll(String warehouseId) async {
//     final conn = await _db;
//
//     final result = await conn.execute(
//       Sql.named('''
//         SELECT
//           po.id,
//           po.warehouse_id          AS tenant_id,
//           po.po_number,
//           po.supplier_id,
//           s.name                   AS supplier_name,
//           s.company_name           AS supplier_company,
//           s.phone                  AS supplier_phone,
//           s.address                AS supplier_address,
//           s.tax_id                 AS supplier_tax_id,
//           s.payment_terms          AS supplier_payment_terms,
//           po.destination_location_id,
//           l.name                   AS destination_name,
//           po.status,
//           po.order_date,
//           po.expected_date,
//           po.received_date,
//           po.subtotal,
//           po.discount_amount,
//           po.tax_amount,
//           po.total_amount,
//           po.paid_amount,
//           po.notes,
//           u.full_name              AS created_by_name,
//           po.created_at,
//           po.updated_at
//         FROM purchase_orders po
//         LEFT JOIN suppliers s  ON s.id  = po.supplier_id
//         LEFT JOIN locations l  ON l.id  = po.destination_location_id
//         LEFT JOIN warehouse_users u      ON u.id  = po.created_by
//         WHERE po.warehouse_id = @warehouseId
//           AND po.deleted_at   IS NULL
//         ORDER BY po.created_at DESC
//       '''),
//       parameters: {'warehouseId': warehouseId},
//     );
//
//     final orders = <PurchaseOrderModel>[];
//     for (final row in result) {
//       final m    = row.toColumnMap();
//       final poId = m['id'].toString();
//       final items = await _getItems(conn, poId);
//       orders.add(_mapToModel(m, items));
//     }
//     return orders;
//   }
//
//   // ── GET BY ID ─────────────────────────────────────────────
//   Future<PurchaseOrderModel?> getById(String id) async {
//     final conn = await _db;
//
//     final result = await conn.execute(
//       Sql.named('''
//         SELECT
//           po.id,
//           po.warehouse_id          AS tenant_id,
//           po.po_number,
//           po.supplier_id,
//           s.name                   AS supplier_name,
//           s.company_name           AS supplier_company,
//           s.phone                  AS supplier_phone,
//           s.address                AS supplier_address,
//           s.tax_id                 AS supplier_tax_id,
//           s.payment_terms          AS supplier_payment_terms,
//           po.destination_location_id,
//           l.name                   AS destination_name,
//           po.status,
//           po.order_date,
//           po.expected_date,
//           po.received_date,
//           po.subtotal,
//           po.discount_amount,
//           po.tax_amount,
//           po.total_amount,
//           po.paid_amount,
//           po.notes,
//           u.full_name              AS created_by_name,
//           po.created_at,
//           po.updated_at
//         FROM purchase_orders po
//         LEFT JOIN suppliers s  ON s.id  = po.supplier_id
//         LEFT JOIN locations l  ON l.id  = po.destination_location_id
//         LEFT JOIN warehouse_users u      ON u.id  = po.created_by
//         WHERE po.id = @id
//           AND po.deleted_at IS NULL
//         LIMIT 1
//       '''),
//       parameters: {'id': id},
//     );
//
//     if (result.isEmpty) return null;
//     final m     = result.first.toColumnMap();
//     final items = await _getItems(conn, id);
//     return _mapToModel(m, items);
//   }
//
//   // ── CREATE PO ─────────────────────────────────────────────
//   Future<PurchaseOrderModel> create({
//     required String                  warehouseId,
//     required String                  poNumber,
//     String?                          destinationLocationId,
//     String?                          supplierId,
//     String?                          status,
//     DateTime?                        expectedDate,
//     double                           subtotal        = 0,
//     double                           discountAmount  = 0,
//     double                           taxAmount       = 0,
//     double                           totalAmount     = 0,
//     double                           paidAmount      = 0,
//     double                           remainingAmount = 0,
//     String?                          notes,
//     String?                          createdBy,
//     String?                          createdByName,
//     required List<PurchaseOrderItem> items,
//   }) async {
//     final conn = await _db;
//
//     final poResult = await conn.execute(
//       Sql.named('''
//         INSERT INTO purchase_orders (
//           warehouse_id, po_number, supplier_id,
//           destination_location_id, status,
//           expected_date, subtotal, discount_amount,
//           tax_amount, total_amount, paid_amount,
//           remaining_amount, notes, created_by, created_by_name
//         ) VALUES (
//           @warehouseId, @poNumber, @supplierId,
//           @destinationLocationId, @status,
//           @expectedDate, @subtotal, @discountAmount,
//           @taxAmount, @totalAmount, @paidAmount,
//           @remainingAmount, @notes, @createdBy, @createdByName
//         )
//         RETURNING id
//       '''),
//       parameters: {
//         'warehouseId':           warehouseId,
//         'poNumber':              poNumber,
//         'supplierId':            supplierId,
//         'destinationLocationId': destinationLocationId,
//         'status':                status ?? 'draft',
//         'expectedDate':          expectedDate,
//         'subtotal':              subtotal,
//         'discountAmount':        discountAmount,
//         'taxAmount':             taxAmount,
//         'totalAmount':           totalAmount,
//         'paidAmount':            paidAmount,
//         'remainingAmount':       remainingAmount,
//         'notes':                 notes,
//         'createdBy':             createdBy,
//         'createdByName':         createdByName,
//       },
//     );
//
//     final newPoId = poResult.first.toColumnMap()['id'].toString();
//
//     for (final item in items) {
//       await conn.execute(
//         Sql.named('''
//           INSERT INTO purchase_order_items (
//             po_id, warehouse_id, product_id, product_name,
//             sku, quantity_ordered, quantity_received,
//             unit_cost, total_cost, sale_price
//           ) VALUES (
//             @poId, @warehouseId, @productId, @productName,
//             @sku, @quantityOrdered, 0,
//             @unitCost, @totalCost, @salePrice
//           )
//         '''),
//         parameters: {
//           'poId':            newPoId,
//           'warehouseId':     warehouseId,
//           'productId':       item.productId,
//           'productName':     item.productName,
//           'sku':             item.sku,
//           'quantityOrdered': item.quantityOrdered,
//           'unitCost':        item.unitCost,
//           'totalCost':       item.totalCost,
//           'salePrice':       item.salePrice,
//         },
//       );
//     }
//
//     await _handleReceivedInventory(conn, newPoId, warehouseId, status ?? 'draft', items);
//
//     if ((status ?? 'draft') == 'received') {
//       await _handleSupplierLedger(conn, newPoId, warehouseId, supplierId, poNumber, remainingAmount, createdBy);
//     }
//
//     return (await getById(newPoId))!;
//   }
//
//   // ── UPDATE PO — edit mode ke liye ─────────────────────────
//   Future<PurchaseOrderModel> updatePO({
//     required String                  poId,
//     required String                  warehouseId,
//     required String                  oldStatus,
//     String?                          supplierId,
//     String?                          status,
//     DateTime?                        expectedDate,
//     double                           subtotal        = 0,
//     double                           discountAmount  = 0,
//     double                           taxAmount       = 0,
//     double                           totalAmount     = 0,
//     double                           paidAmount      = 0,
//     double                           remainingAmount = 0,
//     String?                          notes,
//     String?                          updatedBy,
//     String?                          updatedByName,
//     required List<PurchaseOrderItem> items,
//   }) async {
//     final conn = await _db;
//
//     await conn.execute(
//       Sql.named('''
//         UPDATE purchase_orders SET
//           supplier_id      = @supplierId,
//           status           = @status,
//           expected_date    = @expectedDate,
//           subtotal         = @subtotal,
//           discount_amount  = @discountAmount,
//           tax_amount       = @taxAmount,
//           total_amount     = @totalAmount,
//           paid_amount      = @paidAmount,
//           remaining_amount = @remainingAmount,
//           notes            = @notes,
//           updated_at       = NOW()
//         WHERE id           = @poId
//           AND warehouse_id = @warehouseId
//       '''),
//       parameters: {
//         'poId':            poId,
//         'warehouseId':     warehouseId,
//         'supplierId':      supplierId,
//         'status':          status ?? oldStatus,
//         'expectedDate':    expectedDate,
//         'subtotal':        subtotal,
//         'discountAmount':  discountAmount,
//         'taxAmount':       taxAmount,
//         'totalAmount':     totalAmount,
//         'paidAmount':      paidAmount,
//         'remainingAmount': remainingAmount,
//         'notes':           notes,
//       },
//     );
//
//     await conn.execute(
//       Sql.named('DELETE FROM purchase_order_items WHERE po_id = @poId'),
//       parameters: {'poId': poId},
//     );
//
//     for (final item in items) {
//       await conn.execute(
//         Sql.named('''
//           INSERT INTO purchase_order_items (
//             po_id, warehouse_id, product_id, product_name,
//             sku, quantity_ordered, quantity_received,
//             unit_cost, total_cost, sale_price
//           ) VALUES (
//             @poId, @warehouseId, @productId, @productName,
//             @sku, @quantityOrdered, @quantityReceived,
//             @unitCost, @totalCost, @salePrice
//           )
//         '''),
//         parameters: {
//           'poId':             poId,
//           'warehouseId':      warehouseId,
//           'productId':        item.productId,
//           'productName':      item.productName,
//           'sku':              item.sku,
//           'quantityOrdered':  item.quantityOrdered,
//           'quantityReceived': item.quantityReceived,
//           'unitCost':         item.unitCost,
//           'totalCost':        item.totalCost,
//           'salePrice':        item.salePrice,
//         },
//       );
//     }
//
//     final newStatus = status ?? oldStatus;
//     final becomingReceived = newStatus == 'received' && oldStatus != 'received';
//
//     if (becomingReceived) {
//       await _handleReceivedInventory(conn, poId, warehouseId, newStatus, items);
//
//       if (supplierId != null && supplierId.isNotEmpty) {
//         await conn.execute(
//           Sql.named('''
//             DELETE FROM supplier_ledger
//             WHERE po_id      = @poId
//               AND entry_type = 'purchase'
//           '''),
//           parameters: {'poId': poId},
//         );
//
//         final balResult = await conn.execute(
//           Sql.named('''
//             SELECT outstanding_balance FROM suppliers
//             WHERE id = @supplierId
//           '''),
//           parameters: {'supplierId': supplierId},
//         );
//         final currentBalance = balResult.isNotEmpty
//             ? _toDouble(balResult.first.toColumnMap()['outstanding_balance'])
//             : 0.0;
//         final newBalance = currentBalance + remainingAmount;
//
//         final poRow = await conn.execute(
//           Sql.named('SELECT po_number FROM purchase_orders WHERE id = @poId'),
//           parameters: {'poId': poId},
//         );
//         final poNumber = poRow.isNotEmpty
//             ? poRow.first.toColumnMap()['po_number']
//             : poId;
//
//         await conn.execute(
//           Sql.named('''
//             INSERT INTO supplier_ledger (
//               warehouse_id, supplier_id, po_id,
//               entry_type, amount, balance_before,
//               balance_after, notes, created_by
//             ) VALUES (
//               @warehouseId, @supplierId, @poId,
//               'purchase', @amount, @balanceBefore,
//               @balanceAfter, @notes, @createdBy
//             )
//           '''),
//           parameters: {
//             'warehouseId':   warehouseId,
//             'supplierId':    supplierId,
//             'poId':          poId,
//             'amount':        remainingAmount,
//             'balanceBefore': currentBalance,
//             'balanceAfter':  newBalance,
//             'notes':         'PO $poNumber — received ho gaya',
//             'createdBy':     updatedBy,
//           },
//         );
//       }
//     }
//
//     return (await getById(poId))!;
//   }
//
//   // ── UPDATE STATUS ─────────────────────────────────────────
//   Future<void> updateStatus(String poId, String newStatus) async {
//     final conn = await _db;
//     await conn.execute(
//       Sql.named('''
//         UPDATE purchase_orders
//         SET status = @status, updated_at = NOW()
//         WHERE id   = @id
//       '''),
//       parameters: {'id': poId, 'status': newStatus},
//     );
//   }
//
//   // ── SOFT DELETE ───────────────────────────────────────────
//   Future<void> delete(String poId) async {
//     final conn = await _db;
//     await conn.execute(
//       Sql.named('UPDATE purchase_orders SET deleted_at = NOW() WHERE id = @id'),
//       parameters: {'id': poId},
//     );
//   }
//
//   // ── STATS ─────────────────────────────────────────────────
//   Future<PurchaseOrderStats> getStats(String warehouseId) async {
//     final conn = await _db;
//
//     final result = await conn.execute(
//       Sql.named('''
//         SELECT
//           COUNT(*)                                        AS total_pos,
//           COUNT(*) FILTER (
//             WHERE status IN ('draft','ordered','partial')
//           )                                               AS pending_count,
//           COUNT(*) FILTER (
//             WHERE status = 'received'
//           )                                               AS received_count,
//           COALESCE(SUM(total_amount) FILTER (
//             WHERE DATE_TRUNC('month', order_date)
//                   = DATE_TRUNC('month', NOW())
//           ), 0)                                           AS this_month_total,
//           COALESCE(SUM(total_amount - paid_amount) FILTER (
//             WHERE status NOT IN ('cancelled','received')
//           ), 0)                                           AS total_outstanding
//         FROM purchase_orders
//         WHERE warehouse_id = @warehouseId
//           AND deleted_at IS NULL
//       '''),
//       parameters: {'warehouseId': warehouseId},
//     );
//
//     final m = result.first.toColumnMap();
//     return PurchaseOrderStats(
//       totalPOs:         _toInt(m['total_pos']),
//       pendingCount:     _toInt(m['pending_count']),
//       receivedCount:    _toInt(m['received_count']),
//       thisMonthTotal:   _toDouble(m['this_month_total']),
//       totalOutstanding: _toDouble(m['total_outstanding']),
//     );
//   }
//
//   // ── PRIVATE: inventory update jab received ho ─────────────
//   Future<void> _handleReceivedInventory(
//       Connection conn,
//       String     poId,
//       String     warehouseId,
//       String     status,
//       List<PurchaseOrderItem> items,
//       ) async {
//     if (status != 'received') return;
//
//     for (final item in items) {
//       if (item.productId == null) continue;
//
//       final oldQtyResult = await conn.execute(
//         Sql.named('''
//           SELECT COALESCE(i.quantity, 0) AS qty,
//                  p.purchase_price
//           FROM warehouse_inventory i
//           JOIN warehouse_products p ON p.id = i.product_id
//           WHERE i.product_id   = @productId
//             AND i.warehouse_id = @warehouseId
//           LIMIT 1
//         '''),
//         parameters: {
//           'productId':   item.productId,
//           'warehouseId': warehouseId,
//         },
//       );
//
//       final oldQty  = oldQtyResult.isNotEmpty
//           ? _toDouble(oldQtyResult.first.toColumnMap()['qty'])
//           : 0.0;
//       final oldCost = oldQtyResult.isNotEmpty
//           ? _toDouble(oldQtyResult.first.toColumnMap()['purchase_price'])
//           : item.unitCost;
//
//       await conn.execute(
//         Sql.named('''
//           INSERT INTO warehouse_inventory (warehouse_id, product_id, quantity)
//           VALUES (@warehouseId, @productId, @qty)
//           ON CONFLICT (warehouse_id, product_id)
//           DO UPDATE SET
//             quantity         = warehouse_inventory.quantity + EXCLUDED.quantity,
//             last_movement_at = NOW(),
//             updated_at       = NOW()
//         '''),
//         parameters: {
//           'warehouseId': warehouseId,
//           'productId':   item.productId,
//           'qty':         item.quantityOrdered,
//         },
//       );
//
//       final newQty   = item.quantityOrdered;
//       final totalQty = oldQty + newQty;
//       final avgCost  = totalQty > 0
//           ? ((oldQty * oldCost) + (newQty * item.unitCost)) / totalQty
//           : item.unitCost;
//
//       await conn.execute(
//         Sql.named('''
//           UPDATE warehouse_products SET
//             purchase_price = @avgCost,
//             selling_price  = COALESCE(@salePrice, selling_price),
//             updated_at     = NOW()
//           WHERE id           = @productId
//             AND warehouse_id = @warehouseId
//         '''),
//         parameters: {
//           'productId':   item.productId,
//           'warehouseId': warehouseId,
//           'avgCost':     double.parse(avgCost.toStringAsFixed(2)),
//           'salePrice':   item.salePrice,
//         },
//       );
//     }
//   }
//
//   // ── PRIVATE: supplier ledger entry ────────────────────────
//   Future<void> _handleSupplierLedger(
//       Connection conn,
//       String     poId,
//       String     warehouseId,
//       String?    supplierId,
//       String     poNumber,
//       double     remainingAmount,
//       String?    createdBy,
//       ) async {
//     if (supplierId == null || supplierId.isEmpty) return;
//
//     final balResult = await conn.execute(
//       Sql.named('''
//         SELECT outstanding_balance FROM suppliers
//         WHERE id = @supplierId
//       '''),
//       parameters: {'supplierId': supplierId},
//     );
//     final currentBalance = balResult.isNotEmpty
//         ? _toDouble(balResult.first.toColumnMap()['outstanding_balance'])
//         : 0.0;
//     final newBalance = currentBalance + remainingAmount;
//
//     await conn.execute(
//       Sql.named('''
//         INSERT INTO supplier_ledger (
//           warehouse_id, supplier_id, po_id,
//           entry_type, amount, balance_before,
//           balance_after, notes, created_by
//         ) VALUES (
//           @warehouseId, @supplierId, @poId,
//           'purchase', @amount, @balanceBefore,
//           @balanceAfter, @notes, @createdBy
//         )
//       '''),
//       parameters: {
//         'warehouseId':   warehouseId,
//         'supplierId':    supplierId,
//         'poId':          poId,
//         'amount':        remainingAmount,
//         'balanceBefore': currentBalance,
//         'balanceAfter':  newBalance,
//         'notes':         'PO $poNumber se purchase',
//         'createdBy':     createdBy,
//       },
//     );
//   }
//
//   // ── PRIVATE: items fetch ───────────────────────────────────
//   Future<List<PurchaseOrderItem>> _getItems(
//       Connection conn, String poId) async {
//     final result = await conn.execute(
//       Sql.named('''
//         SELECT
//           id, po_id, warehouse_id AS tenant_id,
//           product_id, product_name, sku,
//           quantity_ordered, quantity_received,
//           unit_cost, total_cost, sale_price
//         FROM purchase_order_items
//         WHERE po_id = @poId
//         ORDER BY id
//       '''),
//       parameters: {'poId': poId},
//     );
//
//     return result.map((row) {
//       final m = row.toColumnMap();
//       return PurchaseOrderItem(
//         id:               m['id'].toString(),
//         poId:             m['po_id'].toString(),
//         tenantId:         m['tenant_id'].toString(),
//         productId:        m['product_id']?.toString(),
//         productName:      m['product_name'].toString(),
//         sku:              m['sku']?.toString(),
//         quantityOrdered:  _toDouble(m['quantity_ordered']),
//         quantityReceived: _toDouble(m['quantity_received']),
//         unitCost:         _toDouble(m['unit_cost']),
//         totalCost:        _toDouble(m['total_cost']),
//         salePrice: m['sale_price'] != null
//             ? _toDouble(m['sale_price'])
//             : null,
//       );
//     }).toList();
//   }
//
//   // ── PRIVATE: row → model ──────────────────────────────────
//   PurchaseOrderModel _mapToModel(
//       Map<String, dynamic> m, List<PurchaseOrderItem> items) {
//     return PurchaseOrderModel(
//       id:                    m['id'].toString(),
//       tenantId:              m['tenant_id'].toString(),
//       poNumber:              m['po_number'].toString(),
//       supplierId:            m['supplier_id']?.toString(),
//       supplierName:          m['supplier_name']?.toString(),
//       supplierCompany:       m['supplier_company']?.toString(),
//       supplierPhone:         m['supplier_phone']?.toString(),
//       supplierAddress:       m['supplier_address']?.toString(),
//       supplierTaxId:         m['supplier_tax_id']?.toString(),
//       supplierPaymentTerms:  m['supplier_payment_terms'] != null
//           ? _toInt(m['supplier_payment_terms'])
//           : null,
//       destinationLocationId: m['destination_location_id'].toString(),
//       destinationName:       m['destination_name']?.toString(),
//       status:                m['status'].toString(),
//       orderDate: m['order_date'] is DateTime
//           ? m['order_date'] as DateTime
//           : DateTime.parse(m['order_date'].toString()),
//       expectedDate: m['expected_date'] != null
//           ? (m['expected_date'] is DateTime
//           ? m['expected_date'] as DateTime
//           : DateTime.parse(m['expected_date'].toString()))
//           : null,
//       receivedDate: m['received_date'] != null
//           ? (m['received_date'] is DateTime
//           ? m['received_date'] as DateTime
//           : DateTime.parse(m['received_date'].toString()))
//           : null,
//       subtotal:       _toDouble(m['subtotal']),
//       discountAmount: _toDouble(m['discount_amount']),
//       taxAmount:      _toDouble(m['tax_amount']),
//       totalAmount:    _toDouble(m['total_amount']),
//       paidAmount:     _toDouble(m['paid_amount']),
//       notes:          m['notes']?.toString(),
//       createdByName:  m['created_by_name']?.toString(),
//       createdAt: m['created_at'] is DateTime
//           ? m['created_at'] as DateTime
//           : DateTime.parse(m['created_at'].toString()),
//       updatedAt: m['updated_at'] is DateTime
//           ? m['updated_at'] as DateTime
//           : DateTime.parse(m['updated_at'].toString()),
//       items: items,
//     );
//   }
//
//   static double _toDouble(dynamic v) {
//     if (v == null) return 0.0;
//     if (v is num) return v.toDouble();
//     return double.tryParse(v.toString()) ?? 0.0;
//   }
//
//   static int _toInt(dynamic v) {
//     if (v == null) return 0;
//     if (v is int) return v;
//     return int.tryParse(v.toString()) ?? 0;
//   }
// }
