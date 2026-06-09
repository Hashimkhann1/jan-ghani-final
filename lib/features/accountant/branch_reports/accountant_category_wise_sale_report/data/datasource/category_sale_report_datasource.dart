// data/datasource/category_sale_report_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/category_sale_report_model.dart';

class CategorySaleReportDatasource {
  final _client  = Supabase.instance.client;
  final String   branchId;

  CategorySaleReportDatasource({required this.branchId});

  // ── Categories dropdown ke liye ───────────────────────────
  Future<List<CategoryOption>> getCategories() async {
    final result = await _client
        .from('warehouse_categories')
        .select('id, name')
        .eq('is_active', true)
        .order('name');

    return (result as List)
        .map((r) => CategoryOption(
      id:   r['id'].toString(),
      name: r['name']?.toString() ?? '',
    ))
        .toList();
  }

  Future<List<CategoryProductSale>> getCategoryProducts({
    required String categoryId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final response = await _client.rpc(
      'get_category_product_sales',
      params: {
        'p_store_id':   branchId,
        'p_category_id': categoryId,
        'p_from':       fromDate.toIso8601String(),
        'p_to':         DateTime(
          toDate.year, toDate.month, toDate.day, 23, 59, 59,
        ).toIso8601String(),
      },
    );

    return (response as List)
        .map((e) => CategoryProductSale.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── RPC call ──────────────────────────────────────────────
  Future<List<CategorySaleReport>> getReport({
    required DateTime fromDate,
    required DateTime toDate,
    String?           categoryId,
  }) async {
    final response = await _client.rpc(
      'get_category_wise_sales',
      params: {
        'p_store_id': branchId,
        'p_from':     fromDate.toIso8601String(),
        'p_to':       DateTime(
          toDate.year, toDate.month, toDate.day, 23, 59, 59,
        ).toIso8601String(),
      },
    );

    List<CategorySaleReport> list = (response as List)
        .map((e) => CategorySaleReport.fromJson(e as Map<String, dynamic>))
        .toList();

    // Category filter client-side (agar selected ho)
    if (categoryId != null && categoryId.isNotEmpty) {
      list = list.where((c) => c.categoryId == categoryId).toList();
    }

    return list;
  }
}