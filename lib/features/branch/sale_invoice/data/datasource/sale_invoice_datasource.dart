// import 'package:postgres/postgres.dart';
// import '../../../../../core/service/db/db_service.dart';
// import '../model/sale_invoice_model.dart';
//
// class SaleInvoiceDatasource {
//
//   Future<String> generateInvoiceNo(String storeId) async {
//     final conn = await DataBaseService.getConnection();
//     final result = await conn.execute(
//       Sql.named('SELECT fn_next_invoice_number(@storeId::uuid)'),
//       parameters: {'storeId': storeId},
//     );
//     return result.first.toColumnMap().values.first.toString();
//   }
//
//   Future<String> saveInvoice({
//     required String             storeId,
//     required String             counterId,
//     required String             userId,
//     required String?            customerId,
//     required String             invoiceNo,
//     required double             totalAmount,
//     required double             totalDiscount,
//     required double             grandTotal,
//     required List<CartItem>     items,
//     required List<PaymentEntry> payments,
//   }) async {
//     final conn = await DataBaseService.getConnection();
//     late String invoiceId;
//
//     await conn.runTx((tx) async {
//
//       // ── 1. Invoice insert ──────────────────────────────
//       final result = await tx.execute(
//         Sql.named('''
//           INSERT INTO public.sale_invoices (
//             store_id, counter_id, user_id, customer_id,
//             invoice_no, total_amount, total_discount, grand_total, status
//           ) VALUES (
//             @storeId::uuid, @counterId::uuid, @userId::uuid,
//             ${customerId != null ? '@customerId::uuid' : 'NULL'},
//             @invoiceNo, @totalAmount, @totalDiscount, @grandTotal, 'completed'
//           )
//           RETURNING id
//         '''),
//         parameters: {
//           'storeId':       storeId,
//           'counterId':     counterId,
//           'userId':        userId,
//           if (customerId != null) 'customerId': customerId,
//           'invoiceNo':     invoiceNo,
//           'totalAmount':   totalAmount,
//           'totalDiscount': totalDiscount,
//           'grandTotal':    grandTotal,
//         },
//       );
//
//       invoiceId = result.first.toColumnMap()['id'].toString();
//
//       // ── 2. Items insert ────────────────────────────────
//       // NOTE: Stock deduction DB trigger (fn_sale_item_inventory)
//       //       automatically handles inventory update on INSERT.
//       //       Manual UPDATE yahan nahi karna — double deduction hoga.
//       for (final item in items) {
//         await tx.execute(
//           Sql.named('''
//             INSERT INTO public.sale_invoice_items (
//               invoice_id, product_id, product_name, sku, barcode,
//               price, cost_price, quantity, subtotal, discount, total_amount
//             ) VALUES (
//               @invoiceId::uuid, @productId::uuid, @productName,
//               @sku, @barcode, @price, @costPrice, @quantity,
//               @subtotal, @discount, @totalAmount
//             )
//           '''),
//           parameters: {
//             'invoiceId':   invoiceId,
//             'productId':   item.product.productId,
//             'productName': item.product.name,
//             'sku':         item.product.sku,
//             'barcode':     item.product.barcode,
//             'price':       item.salePrice,
//             'costPrice':   item.product.costPrice,
//             'quantity':    item.quantity,
//             'subtotal':    item.salePrice * item.quantity,
//             'discount':    item.discountAmount,
//             'totalAmount': item.subTotal,
//           },
//         );
//       }
//
//       // ── 3. Payments insert ─────────────────────────────
//       for (final payment in payments) {
//         if (payment.amount <= 0) continue;
//         await tx.execute(
//           Sql.named('''
//             INSERT INTO public.sale_invoice_payments (
//               invoice_id, store_id, counter_id, payment_method, amount
//             ) VALUES (
//               @invoiceId::uuid, @storeId::uuid, @counterId::uuid,
//               @method, @amount
//             )
//           '''),
//           parameters: {
//             'invoiceId': invoiceId,
//             'storeId':   storeId,
//             'counterId': counterId,
//             'method':    payment.method,
//             'amount':    payment.amount,
//           },
//         );
//       }
//     });
//
//     return invoiceId;
//   }
//
//   Future<List<Map<String, dynamic>>> getAll(String storeId) async {
//     final conn = await DataBaseService.getConnection();
//     final result = await conn.execute(
//       Sql.named('''
//         SELECT
//           si.id, si.invoice_no, si.invoice_date,
//           si.total_amount, si.total_discount, si.grand_total,
//           si.status, si.notes,
//           c.name          AS customer_name,
//           c.phone         AS customer_phone,
//           u.full_name     AS cashier_name,
//           co.counter_name,
//           COALESCE(SUM(CASE WHEN p.payment_method = 'cash'   THEN p.amount ELSE 0 END), 0) AS cash_amount,
//           COALESCE(SUM(CASE WHEN p.payment_method = 'card'   THEN p.amount ELSE 0 END), 0) AS card_amount,
//           COALESCE(SUM(CASE WHEN p.payment_method = 'credit' THEN p.amount ELSE 0 END), 0) AS credit_amount
//         FROM public.sale_invoices si
//         LEFT JOIN public.customer       c  ON c.id  = si.customer_id
//         LEFT JOIN public.branch_users   u  ON u.id  = si.user_id
//         LEFT JOIN public.branch_counter co ON co.id = si.counter_id
//         LEFT JOIN public.sale_invoice_payments p ON p.invoice_id = si.id
//         WHERE si.store_id   = @storeId
//           AND si.deleted_at IS NULL
//         GROUP BY si.id, c.name, c.phone, u.full_name, co.counter_name
//         ORDER BY si.invoice_date DESC
//       '''),
//       parameters: {'storeId': storeId},
//     );
//     return result.map((r) => r.toColumnMap()).toList();
//   }
// }

// lib/features/branch/sale_invoice/data/datasource/sale_invoice_datasource.dart
// ── ADD this method at the bottom of SaleInvoiceDatasource class ──

// lib/features/branch/sale_invoice/data/datasource/sale_invoice_datasource.dart

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

      // ── 2. Items insert ────────────────────────────────
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

  // ── KEY FIX ───────────────────────────────────────────────
  // Problem: Direct UPDATE balance se customer.balance update hota tha
  //          lekin cash counter (installment) update nahi hota tha.
  //
  // Fix: customer_ledger mein INSERT karo (bina 'Sale Invoice:' prefix ke)
  //      Phir 2 triggers automatically fire honge:
  //
  //   1. fn_customer_payment   → customer.balance -= extraPayment   ✓
  //   2. fn_ledger_to_cash_counter → installment += extraPayment   ✓
  //
  // Example:
  //   existing balance = 10,000 | sale = 1,680 | pays = 5,000
  //   extraPayment     = 3,320  (5000 - 1680)
  //   new balance      = 6,680  ✓
  //   installment      += 3,320 ✓
  Future<void> applyExtraCustomerPayment({
    required String storeId,
    required String counterId,
    required String customerId,
    required String customerName,
    required String invoiceNo,
    required double extraPayment,
  }) async {
    if (extraPayment <= 0) return;

    final conn = await DataBaseService.getConnection();

    // INSERT into customer_ledger — triggers handle balance + counter update
    // NOTE: notes mein 'Sale Invoice:' prefix NAHI dena
    //       kyunki wo prefix triggers ko skip karta hai
    await conn.execute(
      Sql.named('''
        INSERT INTO public.customer_ledger (
          store_id, customer_id, customer_name,
          counter_id, pay_amount, notes
        ) VALUES (
          @storeId::uuid, @customerId::uuid, @customerName,
          @counterId::uuid, @payAmount, @notes
        )
      '''),
      parameters: {
        'storeId':      storeId,
        'customerId':   customerId,
        'customerName': customerName,
        'counterId':    counterId,
        'payAmount':    extraPayment,
        'notes':        'Payment: $invoiceNo',  // ← 'Sale Invoice:' NAHI
      },
    );
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