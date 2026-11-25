// Mobile app se branch PC ke LOCAL Postgres tak (same Wi-Fi) read-only access.
// Branch desktop ka DataBaseService use nahi hota (wo StoreConfig.dbHost =
// 127.0.0.1 par jata hai) — yahan host user ke set kiye hue IP se aata hai.

import 'package:jan_ghani_final/core/config/store_config.dart';
import 'package:jan_ghani_final/features/branch/branch_stock_inventory/data/model/branch_stock_model.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanStockService {
  LanStockService._();
  static final LanStockService instance = LanStockService._();

  static const _kHost = 'lan_stock_host';
  static const _kPort = 'lan_stock_port';
  static const defaultHost = '192.168.100.250';

  Future<({String host, int port})> loadTarget() async {
    final p = await SharedPreferences.getInstance();
    return (
      host: p.getString(_kHost) ?? defaultHost,
      port: p.getInt(_kPort) ?? StoreConfig.dbPort,
    );
  }

  Future<void> saveTarget(String host, int port) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kHost, host.trim());
    await p.setInt(_kPort, port);
  }

  Future<Connection> _open() async {
    final t = await loadTarget();
    return Connection.open(
      Endpoint(
        host: t.host,
        port: t.port,
        database: StoreConfig.dbName,
        username: StoreConfig.dbUser,
        password: StoreConfig.dbPassword,
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.disable,
        timeZone: 'Asia/Karachi',
        connectTimeout: Duration(seconds: 4),
        applicationName: 'jan_ghani_mobile',
      ),
    ).timeout(const Duration(seconds: 5));
  }

  /// Shelf update — desktop (updateShelfAndStockLimits) jaisa hi: row update +
  /// updated_at (sync is se chalta hai) + log row. Sirf shelf_name badalta hai.
  Future<void> updateShelf(
      {required String id, String? shelfName, double? stock}) async {
    final shelf = (shelfName ?? '').trim().isEmpty ? null : shelfName!.trim();
    final conn = await _open();
    try {
      await conn.runTx((tx) async {
        final r = await tx.execute(
          Sql.named('''
            SELECT store_id, product_id, product_name, shelf_name, stock
            FROM public.branch_stock_inventory WHERE id = @id FOR UPDATE
          '''),
          parameters: {'id': id},
        );
        if (r.isEmpty) throw Exception('Product DB mein nahi mila');
        final old = r.first.toColumnMap();
        final oldStock = double.tryParse('${old['stock']}') ?? 0;
        final stockChanged = stock != null && stock != oldStock;
        await tx.execute(
          Sql.named('''
            UPDATE public.branch_stock_inventory
            SET shelf_name = @shelf,
                stock = CASE WHEN @changed THEN @stock ELSE stock END,
                updated_at = now()
            WHERE id = @id
          '''),
          parameters: {
            'id': id,
            'shelf': shelf,
            'changed': stockChanged,
            'stock': stock ?? oldStock,
          },
        );
        await tx.execute(
          Sql.named('''
            INSERT INTO public.branch_stock_inventory_logs (
              store_id, product_id, product_name, change_type,
              old_shelf_name, new_shelf_name, old_stock, new_stock, notes
            ) VALUES (
              @storeId, @productId, @productName, @changeType,
              @oldShelf, @newShelf, @oldStock, @newStock, 'mobile app'
            )
          '''),
          parameters: {
            'storeId': old['store_id'].toString(),
            'productId': old['product_id'].toString(),
            'productName': old['product_name'].toString(),
            'oldShelf': old['shelf_name']?.toString(),
            'newShelf': shelf,
            'changeType': stockChanged ? 'full_update' : 'shelf_update',
            'oldStock': oldStock,
            'newStock': stockChanged ? stock : oldStock,
          },
        );
      });
    } finally {
      await conn.close();
    }
  }

  /// Har refresh par nayi short-lived connection — mobile Wi-Fi badalne par
  /// purana socket stale ho jata hai, is liye cache nahi karte.
  Future<List<BranchStockModel>> fetchAll() async {
    final conn = await _open();
    try {
      await conn.execute('SET default_transaction_read_only = on');
      final result = await conn.execute(
        Sql.named('''
          SELECT
            id              AS inv_id,
            store_id,
            product_id,
            stock           AS quantity,
            0               AS reserved_quantity,
            sku,
            barcode::text,
            product_name    AS name,
            unit            AS unit_of_measure,
            purchase_price  AS cost_price,
            sale_price      AS selling_price,
            wholesale_price,
            min_stock       AS min_stock_level,
            max_stock       AS max_stock_level,
            min_stock       AS reorder_point,
            (product_type = 'physical') AS is_track_stock,
            product_type,
            shelf_name,
            updated_at
          -- Local DB ek hi branch ka hota hai; config ki store_id se filter nahi
          -- (DB ki store_id config se alag ho sakti hai).
          FROM public.branch_stock_inventory
          WHERE deleted_at IS NULL
          ORDER BY product_name ASC
        '''),
      ).timeout(const Duration(seconds: 20));
      return result
          .map((r) => BranchStockModel.fromMap(r.toColumnMap()))
          .toList();
    } finally {
      await conn.close();
    }
  }
}
