// lib/features/branch/sale_invoice/data/datasource/sale_return_datasource.dart

import 'package:postgres/postgres.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/sale_invoice_model.dart'; // PaymentEntry
import '../model/sale_return_model.dart';

class SaleReturnDatasource {

  Future<String> generateReturnNo(String storeId) async {
    final conn = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('SELECT fn_next_return_number(@storeId::uuid)'),
      parameters: {'storeId': storeId},
    );
    return result.first.toColumnMap().values.first.toString();
  }

  Future<String> saveReturn({
    required String               storeId,
    required String               counterId,
    required String               userId,
    String?                       customerId,
    required String               returnNo,
    required String               refundType,
    required double               totalAmount,
    required double               totalDiscount,
    required double               grandTotal,
    required List<ReturnCartItem> items,
    required List<PaymentEntry>   payments,
  }) async {
    final conn = await DataBaseService.getConnection();
    late String returnId;

    await conn.runTx((tx) async {

      // 1. Insert sale_return
      final result = await tx.execute(
        Sql.named('''
        INSERT INTO public.sale_returns (
          store_id, counter_id, user_id, customer_id,
          return_no, refund_type,
          total_amount, total_discount, grand_total, status
        ) VALUES (
          @storeId::uuid, @counterId::uuid, @userId::uuid,
          ${customerId != null ? '@customerId::uuid' : 'NULL'},
          @returnNo, @refundType,
          @totalAmount, @totalDiscount, @grandTotal, 'completed'
        )
        RETURNING id
      '''),
        parameters: {
          'storeId':       storeId,
          'counterId':     counterId,
          'userId':        userId,
          if (customerId != null) 'customerId': customerId,
          'returnNo':      returnNo,
          'refundType':    refundType,
          'totalAmount':   totalAmount,
          'totalDiscount': totalDiscount,
          'grandTotal':    grandTotal,
        },
      );

      returnId = result.first.toColumnMap()['id'].toString();

      // 2. Insert items + stock wapas add karo
      for (final item in items) {

        // Return item insert
        await tx.execute(
          Sql.named('''
          INSERT INTO public.sale_return_items (
            return_id, product_id, product_name,
            sku, barcode, price, quantity,
            subtotal, discount, total_amount
          ) VALUES (
            @returnId::uuid, @productId::uuid, @productName,
            @sku, @barcode, @price, @quantity,
            @subtotal, @discount, @totalAmount
          )
        '''),
          parameters: {
            'returnId':    returnId,
            'productId':   item.product.productId,
            'productName': item.product.name,
            'sku':         item.product.sku,
            'barcode':     item.product.barcode,
            'price':       item.returnPrice,
            'quantity':    item.quantity,
            'subtotal':    item.returnPrice * item.quantity,
            'discount':    item.discountAmount,
            'totalAmount': item.subTotal,
          },
        );

        // ✅ Branch stock wapas add karo
        await tx.execute(
          Sql.named('''
          UPDATE public.branch_stock_inventory
          SET
            stock      = stock + @qty,
            updated_at = NOW()
          WHERE store_id   = @storeId
            AND product_id = @productId
        '''),
          parameters: {
            'qty':       item.quantity,
            'storeId':   storeId,
            'productId': item.product.productId,
          },
        );
      }

      // 3. Payments insert
      for (final payment in payments) {
        if (payment.amount <= 0) continue;
        await tx.execute(
          Sql.named('''
          INSERT INTO public.sale_return_payments (
            return_id, store_id, counter_id, payment_method, amount
          ) VALUES (
            @returnId::uuid, @storeId::uuid, @counterId::uuid,
            @method, @amount
          )
        '''),
          parameters: {
            'returnId':  returnId,
            'storeId':   storeId,
            'counterId': counterId,
            'method':    payment.method,
            'amount':    payment.amount,
          },
        );
      }
    });

    return returnId;
  }
}