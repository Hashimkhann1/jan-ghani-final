import 'package:postgres/postgres.dart';

import '../../../../../core/service/db/db_service.dart';

/// Customer ki aakhri sale aur aakhri jama (wasooli) ki rakam.
class CustomerLastActivity {
  final double?   saleAmount;
  final String?   saleInvoiceNo;
  final DateTime? saleAt;

  final double?   paymentAmount;
  final String?   paymentMethod; // cash | card
  final DateTime? paymentAt;

  const CustomerLastActivity({
    this.saleAmount,
    this.saleInvoiceNo,
    this.saleAt,
    this.paymentAmount,
    this.paymentMethod,
    this.paymentAt,
  });
}

class CustomerActivityDataSource {
  double? _d(dynamic v) => v == null ? null : double.tryParse(v.toString());
  DateTime? _t(dynamic v) =>
      v is DateTime ? v.toLocal() : DateTime.tryParse('$v')?.toLocal();

  Future<CustomerLastActivity> getLast(String customerId) async {
    final conn = await DataBaseService.getConnection();

    final sale = await conn.execute(
      Sql.named('''
        SELECT invoice_no, grand_total, created_at
        FROM public.sale_invoices
        WHERE customer_id = @id::uuid
          AND status = 'completed'
          AND deleted_at IS NULL
        ORDER BY created_at DESC
        LIMIT 1
      '''),
      parameters: {'id': customerId},
    );

    final pay = await conn.execute(
      Sql.named('''
        SELECT pay_amount, payment_method, created_at
        FROM public.customer_ledger
        WHERE customer_id = @id::uuid
          AND deleted_at IS NULL
        ORDER BY created_at DESC
        LIMIT 1
      '''),
      parameters: {'id': customerId},
    );

    final s = sale.isEmpty ? null : sale.first.toColumnMap();
    final p = pay.isEmpty ? null : pay.first.toColumnMap();

    return CustomerLastActivity(
      saleAmount:    _d(s?['grand_total']),
      saleInvoiceNo: s?['invoice_no']?.toString(),
      saleAt:        _t(s?['created_at']),
      paymentAmount: _d(p?['pay_amount']),
      paymentMethod: p?['payment_method']?.toString(),
      paymentAt:     _t(p?['created_at']),
    );
  }
}
