import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../common/export/branch_export_lookups.dart';
import '../model/stock_movement_model.dart';

/// Builds the stock movement log by merging every source that changes a
/// branch's stock: sales, returns, warehouse transfers received, damage,
/// applied inventory counts and manual stock edits.
class StockMovementDatasource {
  final _client = Supabase.instance.client;
  final String  branchId;

  StockMovementDatasource({required this.branchId})
      : _lookups = BranchExportLookups(branchId: branchId);

  final BranchExportLookups _lookups;

  static const int _chunk = 200;

  Future<StockMovementReportData> fetchReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final toEnd = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999);

    // Events are fetched from [fromDate] all the way to now, not just to
    // [toDate]: the stock level after an event is derived by walking back
    // from today's stock, so every later event has to be accounted for.
    final results = await Future.wait([
      _sales(fromDate),
      _returns(fromDate),
      _transfersReceived(fromDate),
      _damage(fromDate),
      _countCorrections(fromDate),
      _manualAdjustments(fromDate),
      _lookups.branchName(),
      _lookups.inventorySnapshot(),
    ]);

    final events = [
      for (var i = 0; i < 6; i++) ...results[i] as List<StockMovementEntry>,
    ];
    final snapshot = results[7] as ({
      Map<String, String> categoryNames,
      Map<String, double> stock,
    });

    final rows = buildRows(
      events:        events,
      currentStock:  snapshot.stock,
      categoryNames: snapshot.categoryNames,
    ).where((r) =>
        !r.entry.dateTime.isBefore(fromDate) &&
        !r.entry.dateTime.isAfter(toEnd)).toList();

    return StockMovementReportData(
      rows:       rows,
      branchName: results[6] as String,
    );
  }

  static const uncategorized = 'Uncategorized';

  /// Pure: attaches category and resulting stock to every event, newest
  /// first.
  ///
  /// Resulting stock is reconstructed per product by walking back from the
  /// current stock: the newest event ended at today's stock, so the one
  /// before it ended at `today − newest.qtyChange`, and so on. Events that
  /// record their own before/after stock (count corrections, manual edits)
  /// re-anchor the walk, so an unrecorded movement can't drift the numbers
  /// past them.
  static List<StockMovementRow> buildRows({
    required List<StockMovementEntry> events,
    required Map<String, double>      currentStock,
    required Map<String, String>      categoryNames,
  }) {
    final newestFirst = [...events]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final cursor = <String, double?>{};
    final rows   = <StockMovementRow>[];

    for (final e in newestFirst) {
      final pid   = e.productId;
      final known = cursor.containsKey(pid) ? cursor[pid] : currentStock[pid];

      final after  = e.stockAfter ?? known;
      final before = e.stockBefore ?? (after == null ? null : after - e.qtyChange);
      cursor[pid]  = before;

      rows.add(StockMovementRow(
        entry:          e,
        categoryName:   categoryNames[pid] ?? uncategorized,
        resultingStock: after,
      ));
    }
    return rows;
  }

  // ── Sources ────────────────────────────────────────────────────────────

  Future<List<StockMovementEntry>> _sales(DateTime from) async {
    final rows = await _fetchAll((start, end) async {
      final res = await _client
          .from('sale_invoices')
          .select('''
            invoice_no, invoice_date, deleted_at,
            sale_invoice_items (product_id, product_name, quantity)
          ''')
          .eq('store_id', branchId)
          .eq('status', 'completed')
          .gte('invoice_date', from.toUtc().toIso8601String())
          .order('invoice_date', ascending: false)
          .range(start, end);
      return res as List;
    });

    return [
      for (final r in rows)
        if (r['deleted_at'] == null)
          for (final i in (r['sale_invoice_items'] as List? ?? []))
            if (i['product_id'] != null)
              StockMovementEntry(
                dateTime:    _time(r['invoice_date']),
                productId:   i['product_id'].toString(),
                productName: i['product_name']?.toString() ?? '',
                type:        StockMovementType.sale,
                qtyChange:   -(_dbl(i['quantity']) ?? 0),
                referenceNo: r['invoice_no']?.toString() ?? '',
              ),
    ];
  }

  Future<List<StockMovementEntry>> _returns(DateTime from) async {
    final rows = await _fetchAll((start, end) async {
      final res = await _client
          .from('sale_returns')
          .select('''
            return_no, return_date, return_reason, deleted_at,
            sale_return_items (product_id, product_name, quantity)
          ''')
          .eq('store_id', branchId)
          .eq('status', 'completed')
          .gte('return_date', from.toUtc().toIso8601String())
          .order('return_date', ascending: false)
          .range(start, end);
      return res as List;
    });

    return [
      for (final r in rows)
        if (r['deleted_at'] == null)
          for (final i in (r['sale_return_items'] as List? ?? []))
            if (i['product_id'] != null)
              StockMovementEntry(
                dateTime:    _time(r['return_date']),
                productId:   i['product_id'].toString(),
                productName: i['product_name']?.toString() ?? '',
                type:        StockMovementType.saleReturn,
                qtyChange:   _dbl(i['quantity']) ?? 0,
                referenceNo: r['return_no']?.toString() ?? '',
                reason:      r['return_reason']?.toString() ?? '',
              ),
    ];
  }

  /// Warehouse → branch transfers the branch accepted. Stamped with the
  /// accept time (`updated_at`), which is when the stock actually landed.
  Future<List<StockMovementEntry>> _transfersReceived(DateTime from) async {
    final rows = await _fetchAll((start, end) async {
      final res = await _client
          .from('stock_transfers')
          .select('''
            transfer_number, assigned_at, updated_at, notes,
            stock_transfer_items (product_id, product_name, quantity_sent)
          ''')
          .eq('to_store_id', branchId)
          .eq('status', 'accepted')
          .gte('updated_at', from.toUtc().toIso8601String())
          .order('updated_at', ascending: false)
          .range(start, end);
      return res as List;
    });

    return [
      for (final r in rows)
        for (final i in (r['stock_transfer_items'] as List? ?? []))
          if (i['product_id'] != null)
            StockMovementEntry(
              dateTime:    _time(r['updated_at'] ?? r['assigned_at']),
              productId:   i['product_id'].toString(),
              productName: i['product_name']?.toString() ?? '',
              type:        StockMovementType.purchase,
              qtyChange:   _dbl(i['quantity_sent']) ?? 0,
              referenceNo: r['transfer_number']?.toString() ?? '',
              reason:      _orDefault(r['notes'], 'Stock received from warehouse'),
            ),
    ];
  }

  Future<List<StockMovementEntry>> _damage(DateTime from) async {
    final rows = await _fetchAll((start, end) async {
      final res = await _client
          .from('branch_stock_damage')
          .select('id, product_id, product_name, stock_damage, created_at')
          .eq('store_id', branchId)
          .gte('created_at', from.toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .range(start, end);
      return res as List;
    });

    return [
      for (final r in rows)
        if (r['product_id'] != null)
          StockMovementEntry(
            dateTime:    _time(r['created_at']),
            productId:   r['product_id'].toString(),
            productName: r['product_name']?.toString() ?? '',
            type:        StockMovementType.damage,
            qtyChange:   -(_dbl(r['stock_damage']) ?? 0),
            reason:      'Damaged stock',
          ),
    ];
  }

  /// Inventory-balance items the branch accepted — the physical count became
  /// the new stock, so before/after are exact.
  Future<List<StockMovementEntry>> _countCorrections(DateTime from) async {
    final rows = await _fetchAll((start, end) async {
      final res = await _client
          .from('inventory_balance_items')
          .select('''
            product_id, product_name, applied_at,
            applied_stock_before, applied_stock_after,
            branch_reason, reviewer_reason,
            batch:batch_id ( batch_number )
          ''')
          .eq('store_id', branchId)
          .eq('status', 'applied')
          .gte('applied_at', from.toUtc().toIso8601String())
          .order('applied_at', ascending: false)
          .range(start, end);
      return res as List;
    });

    final out = <StockMovementEntry>[];
    for (final r in rows) {
      final before = _dbl(r['applied_stock_before']);
      final after  = _dbl(r['applied_stock_after']);
      if (r['product_id'] == null || before == null || after == null) continue;
      out.add(StockMovementEntry(
        dateTime:    _time(r['applied_at']),
        productId:   r['product_id'].toString(),
        productName: r['product_name']?.toString() ?? '',
        type:        StockMovementType.countCorrection,
        qtyChange:   after - before,
        referenceNo: (r['batch'] as Map?)?['batch_number']?.toString() ?? '',
        reason:      _orDefault(r['branch_reason'],
            _orDefault(r['reviewer_reason'], 'Physical count adjustment')),
        stockBefore: before,
        stockAfter:  after,
      ));
    }
    return out;
  }

  /// Stock edited by hand on the product screen (or a product removed) —
  /// logged in `branch_stock_inventory_logs` with old/new stock.
  Future<List<StockMovementEntry>> _manualAdjustments(DateTime from) async {
    final rows = await _fetchAll((start, end) async {
      final res = await _client
          .from('branch_stock_inventory_logs')
          .select('product_id, product_name, change_type, old_stock, new_stock, created_at')
          .eq('store_id', branchId)
          .isFilter('deleted_at', null)
          .not('old_stock', 'is', null)
          .not('new_stock', 'is', null)
          .gte('created_at', from.toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .range(start, end);
      return res as List;
    });

    final out = <StockMovementEntry>[];
    for (final r in rows) {
      final before = _dbl(r['old_stock']);
      final after  = _dbl(r['new_stock']);
      if (r['product_id'] == null || before == null || after == null) continue;
      if (before == after) continue; // price/shelf-only edit, stock untouched
      out.add(StockMovementEntry(
        dateTime:    _time(r['created_at']),
        productId:   r['product_id'].toString(),
        productName: r['product_name']?.toString() ?? '',
        type:        StockMovementType.adjustment,
        qtyChange:   after - before,
        reason:      r['change_type']?.toString() == 'delete'
            ? 'Product removed from inventory'
            : 'Stock edited manually',
        stockBefore: before,
        stockAfter:  after,
      ));
    }
    return out;
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Future<List<dynamic>> _fetchAll(
    Future<List<dynamic>> Function(int start, int end) page,
  ) async {
    final all = <dynamic>[];
    var start = 0;
    while (true) {
      final rows = await page(start, start + _chunk - 1);
      all.addAll(rows);
      if (rows.length < _chunk) break;
      start += _chunk;
    }
    return all;
  }

  static DateTime _time(dynamic v) =>
      (DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now()).toLocal();

  static String _orDefault(dynamic v, String fallback) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? fallback : s;
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}
