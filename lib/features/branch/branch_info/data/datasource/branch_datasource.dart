import 'package:postgres/postgres.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/branch_model.dart';

class BranchDatasource {

  Future<BranchModel?> getBranchById(String branchId) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        SELECT id, code, name, address, phone,
               is_active, created_at, updated_at, deleted_at
        FROM public.branch
        WHERE id = @branchId
        LIMIT 1
      '''),
      parameters: {'branchId': branchId},
    );

    if (result.isEmpty) return null;

    return BranchModel.fromMap(_toMap(result.first));
  }

  Map<String, dynamic> _toMap(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id':         m['id']?.toString()      ?? '',
      'code':       m['code'],
      'name':       m['name'],
      'address':    m['address'],
      'phone':      m['phone'],
      'is_active':  m['is_active'],
      'created_at': m['created_at']?.toString(),
      'updated_at': m['updated_at']?.toString(),
      'deleted_at': m['deleted_at']?.toString(),
    };
  }
}