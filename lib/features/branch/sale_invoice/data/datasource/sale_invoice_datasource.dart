import 'package:postgres/postgres.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/sale_invoice_model.dart';

class SaleInvoiceDatasource {

  Future<String> generateInvoiceNo(String storeId) async {
    final conn = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('SELECT fn_next_invoice_number(@storeId::uuid)'),
      parameters: {'storeId': storeId},
    );
    return result.first.toColumnMap().values.first.toString();
  }

  Future<String> saveInvoice({
    required String             storeId,
    required String             counterId,
    required String             userId,
    required String?            customerId,
    required String             invoiceNo,
    required double             totalAmount,
    required double             totalDiscount,
    required double             grandTotal,
    required List<CartItem>     items,
    required List<PaymentEntry> payments,
  }) async {
    final conn = await DataBaseService.getConnection();
    late String invoiceId;

    await conn.runTx((tx) async {

      // ── 1. Invoice insert ──────────────────────────────
      final result = await tx.execute(
        Sql.named('''
          INSERT INTO public.sale_invoices (
            store_id, counter_id, user_id, customer_id,
            invoice_no, total_amount, total_discount, grand_total, status
          ) VALUES (
            @storeId::uuid, @counterId::uuid, @userId::uuid,
            ${customerId != null ? '@customerId::uuid' : 'NULL'},
            @invoiceNo, @totalAmount, @totalDiscount, @grandTotal, 'completed'
          )
          RETURNING id
        '''),
        parameters: {
          'storeId':       storeId,
          'counterId':     counterId,
          'userId':        userId,
          if (customerId != null) 'customerId': customerId,
          'invoiceNo':     invoiceNo,
          'totalAmount':   totalAmount,
          'totalDiscount': totalDiscount,
          'grandTotal':    grandTotal,
        },
      );

      invoiceId = result.first.toColumnMap()['id'].toString();

      // ── 2. Items insert + stock deduct ─────────────────
      for (final item in items) {
        await tx.execute(
          Sql.named('''
            INSERT INTO public.sale_invoice_items (
              invoice_id, product_id, product_name, sku, barcode,
              price, cost_price, quantity, subtotal, discount, total_amount
            ) VALUES (
              @invoiceId::uuid, @productId::uuid, @productName,
              @sku, @barcode, @price, @costPrice, @quantity,
              @subtotal, @discount, @totalAmount
            )
          '''),
          parameters: {
            'invoiceId':   invoiceId,
            'productId':   item.product.productId,
            'productName': item.product.name,
            'sku':         item.product.sku,
            'barcode':     item.product.barcode,
            'price':       item.salePrice,
            'costPrice':   item.product.costPrice,
            'quantity':    item.quantity,
            'subtotal':    item.salePrice * item.quantity,
            'discount':    item.discountAmount,
            'totalAmount': item.subTotal,
          },
        );

        await tx.execute(
          Sql.named('''
            UPDATE public.branch_stock_inventory
            SET
              stock      = GREATEST(stock - @qty, 0),
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

      // ── 3. Payments insert ─────────────────────────────
      for (final payment in payments) {
        if (payment.amount <= 0) continue;
        await tx.execute(
          Sql.named('''
            INSERT INTO public.sale_invoice_payments (
              invoice_id, store_id, counter_id, payment_method, amount
            ) VALUES (
              @invoiceId::uuid, @storeId::uuid, @counterId::uuid,
              @method, @amount
            )
          '''),
          parameters: {
            'invoiceId': invoiceId,
            'storeId':   storeId,
            'counterId': counterId,
            'method':    payment.method,
            'amount':    payment.amount,
          },
        );
      }
    });

    return invoiceId;
  }

  Future<List<Map<String, dynamic>>> getAll(String storeId) async {
    final conn = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        SELECT
          si.id, si.invoice_no, si.invoice_date,
          si.total_amount, si.total_discount, si.grand_total,
          si.status, si.notes,
          c.name          AS customer_name,
          c.phone         AS customer_phone,
          u.full_name     AS cashier_name,
          co.counter_name,
          COALESCE(SUM(CASE WHEN p.payment_method = 'cash'   THEN p.amount ELSE 0 END), 0) AS cash_amount,
          COALESCE(SUM(CASE WHEN p.payment_method = 'card'   THEN p.amount ELSE 0 END), 0) AS card_amount,
          COALESCE(SUM(CASE WHEN p.payment_method = 'credit' THEN p.amount ELSE 0 END), 0) AS credit_amount
        FROM public.sale_invoices si
        LEFT JOIN public.customer       c  ON c.id  = si.customer_id
        LEFT JOIN public.branch_users   u  ON u.id  = si.user_id
        LEFT JOIN public.branch_counter co ON co.id = si.counter_id
        LEFT JOIN public.sale_invoice_payments p ON p.invoice_id = si.id
        WHERE si.store_id   = @storeId
          AND si.deleted_at IS NULL
        GROUP BY si.id, c.name, c.phone, u.full_name, co.counter_name
        ORDER BY si.invoice_date DESC
      '''),
      parameters: {'storeId': storeId},
    );
    return result.map((r) => r.toColumnMap()).toList();
  }
}