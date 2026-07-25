import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/inventory_counting_report_model.dart';

class InventoryCountingReportRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  static const int _chunkSize = 200;
  static const int _pageSize  = 1000;

  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }

  // Pehle total row count nikalo, phir saray pages ek sath (parallel) fetch karo
  Future<List<Map<String, dynamic>>> _fetchAllCounting() async {
    final countResponse = await _client
        .from('inventory_counting')
        .select('id')
        .count(CountOption.exact);

    final total = countResponse.count;
    print('🔵 inventory_counting total rows: $total');

    if (total == 0) return [];

    final pageStarts = <int>[];
    for (var i = 0; i < total; i += _pageSize) {
      pageStarts.add(i);
    }

    final results = await Future.wait(pageStarts.map((start) async {
      final response = await _client
          .from('inventory_counting')
          .select('id, product_id, product_stock, counting_stock, updated_at, created_at, counted_date')
          .order('created_at', ascending: true)
          .range(start, start + _pageSize - 1);
      return (response as List).map((e) => e as Map<String, dynamic>).toList();
    }));

    final all = results.expand((e) => e).toList();
    print('🔵 inventory_counting fetched total: ${all.length}');
    return all;
  }

  Future<List<InventoryCountingRecord>> fetchAllRecords({
    required String storeId,
  }) async {
    final stopwatch = Stopwatch()..start();
    print('🟢 fetchAllRecords started for storeId: $storeId');

    final countingList = await _fetchAllCounting();
    if (countingList.isEmpty) {
      print('🟡 No inventory_counting records found');
      return [];
    }

    final productIds = countingList
        .map((e) => e['product_id'] as String)
        .toSet()
        .toList();

    print('🟣 Distinct product_ids: ${productIds.length}');

    final inventoryMap = <String, Map<String, dynamic>>{};
    final batches = _chunk(productIds, _chunkSize);
    print('🟣 Batches (own store): ${batches.length}');

    final results = await Future.wait(batches.map((batch) async {
      final res = await _client
          .from('branch_stock_inventory')
          .select('product_id, product_name, barcode, min_stock, max_stock, store_id')
          .eq('store_id', storeId)
          .inFilter('product_id', batch);
      return res as List;
    }));

    for (final rows in results) {
      for (final item in rows) {
        inventoryMap[item['product_id'] as String] = item as Map<String, dynamic>;
      }
    }

    print('🟣 Matched in own store: ${inventoryMap.length} / ${productIds.length}');

    final missingIds = productIds.where((id) => !inventoryMap.containsKey(id)).toList();
    if (missingIds.isNotEmpty) {
      print('🟠 Fallback fetch (any store) for: ${missingIds.length}');
      final missingBatches = _chunk(missingIds, _chunkSize);

      final fallbackResults = await Future.wait(missingBatches.map((batch) async {
        final res = await _client
            .from('branch_stock_inventory')
            .select('product_id, product_name, barcode, min_stock, max_stock, store_id')
            .inFilter('product_id', batch);
        return res as List;
      }));

      for (final rows in fallbackResults) {
        for (final item in rows) {
          final map = item as Map<String, dynamic>;
          inventoryMap.putIfAbsent(map['product_id'] as String, () => map);
        }
      }
    }

    print('🟢 Final inventoryMap size: ${inventoryMap.length}');

    final records = countingList.map((map) {
      final productId = map['product_id'] as String;
      final inv = inventoryMap[productId] ?? {};
      return InventoryCountingRecord.fromMerged(counting: map, inventory: inv);
    }).toList();

    records.sort((a, b) {
      final dateCompare = b.countedDate.compareTo(a.countedDate);
      if (dateCompare != 0) return dateCompare;
      return a.productName.toLowerCase().compareTo(b.productName.toLowerCase());
    });

    stopwatch.stop();
    print('🟢 fetchAllRecords completed → ${records.length} records in ${stopwatch.elapsedMilliseconds}ms');
    return records;
  }
}