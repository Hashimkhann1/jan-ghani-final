import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/assigned_stock_model.dart';

/// Every warehouse → branch stock transfer assigned to [branchId].
class AssignedStockDatasource {
  final _client = Supabase.instance.client;
  final String branchId;

  AssignedStockDatasource({required this.branchId});

  static const int _chunk = 200;

  Future<List<AssignedStockTransfer>> fetch({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final toEnd = DateTime(toDate.year, toDate.month, toDate.day + 1);
    final all = <dynamic>[];
    var start = 0;
    while (true) {
      final res = await _client
          .from('stock_transfers')
          .select('''
            transfer_number, assigned_at, assigned_by_name, status, notes,
            stock_transfer_items (
              product_name, sku, unit_of_measure,
              quantity_sent, purchase_price, unit_cost, sale_price
            )
          ''')
          .eq('to_store_id', branchId)
          .isFilter('deleted_at', null)
          .gte('assigned_at', fromDate.toUtc().toIso8601String())
          .lt('assigned_at', toEnd.toUtc().toIso8601String())
          .order('assigned_at', ascending: false)
          .range(start, start + _chunk - 1) as List;
      all.addAll(res);
      if (res.length < _chunk) break;
      start += _chunk;
    }

    return [
      for (final r in all)
        AssignedStockTransfer(
          transferNumber: r['transfer_number']?.toString() ?? '',
          assignedAt: (DateTime.tryParse('${r['assigned_at']}') ??
                  DateTime.now())
              .toLocal(),
          assignedByName: r['assigned_by_name']?.toString(),
          status: r['status']?.toString() ?? 'pending',
          notes: r['notes']?.toString() ?? '',
          items: [
            for (final i in (r['stock_transfer_items'] as List? ?? []))
              AssignedStockItem(
                productName: i['product_name']?.toString() ?? '',
                sku: i['sku']?.toString() ?? '',
                unit: i['unit_of_measure']?.toString() ?? 'pcs',
                quantitySent: _dbl(i['quantity_sent']),
                purchasePrice: _dbl(i['purchase_price'] ?? i['unit_cost']),
                salePrice: _dbl(i['sale_price']),
              ),
          ],
        ),
    ];
  }

  static double _dbl(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
}
