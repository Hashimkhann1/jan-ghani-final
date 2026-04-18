import 'package:postgres/postgres.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/counter_model.dart';

class CounterRemoteDataSource {

  // ── GET ALL ───────────────────────────────────────────────
  Future<List<CounterModel>> getAll(String storeId) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        SELECT id, store_id, counter_name, created_at, updated_at, deleted_at
        FROM public.branch_counter
        WHERE store_id  = @storeId
          AND deleted_at IS NULL
        ORDER BY created_at DESC
      '''),
      parameters: {'storeId': storeId},
    );

    return result.map((r) => CounterModel.fromMap(_toMap(r))).toList();
  }

  // ── ADD ───────────────────────────────────────────────────
  Future<CounterModel> add(String storeId, String counterName) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        INSERT INTO public.branch_counter (store_id, counter_name)
        VALUES (@storeId, @counterName)
        RETURNING *
      '''),
      parameters: {
        'storeId':     storeId,
        'counterName': counterName,
      },
    );

    return CounterModel.fromMap(_toMap(result.first));
  }

  // ── UPDATE ────────────────────────────────────────────────
  Future<CounterModel> update(String id, String counterName) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        UPDATE public.branch_counter
        SET counter_name = @counterName,
            updated_at   = NOW()
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id':          id,
        'counterName': counterName,
      },
    );

    return CounterModel.fromMap(_toMap(result.first));
  }

  // ── SOFT DELETE ───────────────────────────────────────────
  Future<void> delete(String id) async {
    final conn = await DataBaseService.getConnection();

    await conn.execute(
      Sql.named('''
        UPDATE public.branch_counter
        SET deleted_at = NOW(), updated_at = NOW()
        WHERE id = @id
      '''),
      parameters: {'id': id},
    );
  }

  // ── ROW → MAP ─────────────────────────────────────────────
  Map<String, dynamic> _toMap(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id':           m['id']?.toString()           ?? '',
      'store_id':     m['store_id']?.toString()     ?? '',
      'counter_name': m['counter_name']?.toString() ?? '',
      'created_at':   m['created_at']?.toString()   ?? DateTime.now().toIso8601String(),
      'updated_at':   m['updated_at']?.toString()   ?? DateTime.now().toIso8601String(),
      'deleted_at':   m['deleted_at']?.toString(),
    };
  }
}