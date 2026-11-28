import 'package:postgres/postgres.dart';

import '../../../../../core/service/db/db_service.dart';

/// Ek cashier ya ek product ki scan / manual ginti (invoice lines).
class EntryMethodRow {
  final String name;
  final int scan;
  final int manual;
  final int mixed;

  const EntryMethodRow({
    required this.name,
    required this.scan,
    required this.manual,
    required this.mixed,
  });

  int get total => scan + manual + mixed;

  /// Jin lines mein manual add shamil tha (manual + mixed).
  double get manualPercent => total == 0 ? 0 : (manual + mixed) * 100 / total;
}

class EntryMethodReport {
  final List<EntryMethodRow> cashiers;
  final List<EntryMethodRow> products;
  const EntryMethodReport({required this.cashiers, required this.products});
}

class EntryMethodReportDatasource {
  // Sale + Sale Return dono ki lines. Purani sales (entry_method NULL) bahar.
  static String _lines(String counterFilter) => '''
    WITH lines AS (
      SELECT s.user_id, i.product_id, i.product_name, i.entry_method
      FROM public.sale_invoice_items i
      JOIN public.sale_invoices s ON s.id = i.invoice_id
      WHERE s.store_id = @storeId::uuid
        AND s.deleted_at IS NULL
        AND s.status <> 'cancelled'
        AND s.invoice_date >= @fromDate::timestamptz
        AND s.invoice_date <= @toDate::timestamptz
        AND i.entry_method IS NOT NULL
        $counterFilter
      UNION ALL
      SELECT s.user_id, i.product_id, i.product_name, i.entry_method
      FROM public.sale_return_items i
      JOIN public.sale_returns s ON s.id = i.return_id
      WHERE s.store_id = @storeId::uuid
        AND s.deleted_at IS NULL
        AND s.status <> 'cancelled'
        AND s.return_date >= @fromDate::timestamptz
        AND s.return_date <= @toDate::timestamptz
        AND i.entry_method IS NOT NULL
        $counterFilter
    )
  ''';

  static const _counts = '''
    COUNT(*) FILTER (WHERE l.entry_method = 'barcode') AS scan,
    COUNT(*) FILTER (WHERE l.entry_method = 'manual')  AS manual,
    COUNT(*) FILTER (WHERE l.entry_method = 'mixed')   AS mixed
  ''';

  Future<EntryMethodReport> load({
    required String storeId,
    required DateTime fromDate,
    required DateTime toDate,
    String? counterId,
    String? userId,
  }) async {
    final conn = await DataBaseService.getConnection();
    final filter = [
      if (counterId != null) 'AND s.counter_id = @counterId::uuid',
      if (userId != null) 'AND s.user_id = @userId::uuid',
    ].join(' ');
    final params = <String, dynamic>{
      'storeId': storeId,
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      if (counterId != null) 'counterId': counterId,
      if (userId != null) 'userId': userId,
    };

    final cashiers = await conn.execute(
      Sql.named('''
        ${_lines(filter)}
        SELECT COALESCE(u.full_name, 'Unknown') AS name, $_counts
        FROM lines l
        LEFT JOIN public.branch_users u ON u.id = l.user_id
        GROUP BY l.user_id, u.full_name
        ORDER BY COUNT(*) FILTER (WHERE l.entry_method <> 'barcode') DESC
      '''),
      parameters: params,
    );

    final products = await conn.execute(
      Sql.named('''
        ${_lines(filter)}
        SELECT MAX(l.product_name) AS name, $_counts
        FROM lines l
        GROUP BY l.product_id
        HAVING COUNT(*) FILTER (WHERE l.entry_method <> 'barcode') > 0
        ORDER BY COUNT(*) FILTER (WHERE l.entry_method <> 'barcode') DESC
        LIMIT 100
      '''),
      parameters: params,
    );

    return EntryMethodReport(
      cashiers: cashiers.map(_row).toList(),
      products: products.map(_row).toList(),
    );
  }

  static EntryMethodRow _row(ResultRow r) {
    final m = r.toColumnMap();
    int n(String k) => int.tryParse('${m[k]}') ?? 0;
    return EntryMethodRow(
      name: m['name']?.toString() ?? 'Unknown',
      scan: n('scan'),
      manual: n('manual'),
      mixed: n('mixed'),
    );
  }
}
