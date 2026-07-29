import 'package:postgres/postgres.dart';
import '../../../../../core/service/db/db_service.dart';

class CustomerLogRemoteDataSource {

  Future<void> insertLog({
    required String storeId,
    required String customerId,
    required String customerName,
    required double oldBalance,
    required double newBalance,
    required String createdBy,
  }) async {
    final changeAmount = newBalance - oldBalance;

    await DataBaseService.close();
    final conn = await DataBaseService.getConnection();

    await conn.execute(
      Sql.named('''
        INSERT INTO public.customer_logs (
          store_id, customer_id, customer_name,
          old_balance, new_balance, change_amount,
          created_by
        ) VALUES (
          @storeId, @customerId, @customerName,
          @oldBalance, @newBalance, @changeAmount,
          @createdBy
        )
      '''),
      parameters: {
        'storeId':      storeId,
        'customerId':   customerId,
        'customerName': customerName,
        'oldBalance':   oldBalance,
        'newBalance':   newBalance,
        'changeAmount': changeAmount,
        'createdBy':    createdBy,
      },
    );
  }
}