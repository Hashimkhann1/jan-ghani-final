// lib/features/branch/service/data/datasource/service_datasource.dart

import 'package:postgres/postgres.dart';

import '../../../../../core/service/db/db_service.dart';
import '../model/service_model.dart';

class ServiceDatasource {

  // ────────────────────────────────────────────────────────
  // SERVICES MASTER  CRUD
  // ────────────────────────────────────────────────────────

  Future<List<ServiceModel>> getAllServices(String storeId) async {
    final conn   = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        SELECT * FROM public.services
        WHERE store_id  = @storeId::uuid
          AND deleted_at IS NULL
        ORDER BY name ASC
      '''),
      parameters: {'storeId': storeId},
    );
    return result.map((r) => ServiceModel.fromMap(r.toColumnMap())).toList();
  }

  Future<ServiceModel> createService({
    required String storeId,
    required String name,
    required String serviceType,
    required double perAmount,
    required double feeAmount,
    String?         notes,
  }) async {
    final conn   = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO public.services (
          store_id, name, service_type, per_amount, fee_amount, notes
        ) VALUES (
          @storeId::uuid, @name, @serviceType, @perAmount, @feeAmount, @notes
        )
        RETURNING *
      '''),
      parameters: {
        'storeId':     storeId,
        'name':        name,
        'serviceType': serviceType,
        'perAmount':   perAmount,
        'feeAmount':   feeAmount,
        'notes':       notes,
      },
    );
    return ServiceModel.fromMap(result.first.toColumnMap());
  }

  Future<ServiceModel> updateService({
    required String id,
    required String name,
    required String serviceType,
    required double perAmount,
    required double feeAmount,
    String?         notes,
  }) async {
    final conn   = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        UPDATE public.services SET
          name         = @name,
          service_type = @serviceType,
          per_amount   = @perAmount,
          fee_amount   = @feeAmount,
          notes        = @notes,
          updated_at   = NOW()
        WHERE id = @id::uuid
        RETURNING *
      '''),
      parameters: {
        'id':          id,
        'name':        name,
        'serviceType': serviceType,
        'perAmount':   perAmount,
        'feeAmount':   feeAmount,
        'notes':       notes,
      },
    );
    return ServiceModel.fromMap(result.first.toColumnMap());
  }

  Future<void> deleteService(String id) async {
    final conn = await DataBaseService.getConnection();
    await conn.execute(
      Sql.named(
        'UPDATE public.services SET deleted_at = NOW() WHERE id = @id::uuid',
      ),
      parameters: {'id': id},
    );
  }

  // ────────────────────────────────────────────────────────
  // INVOICE NUMBER  (same fn as sale_invoices)
  // ────────────────────────────────────────────────────────

  Future<String> generateInvoiceNo(String storeId) async {
    final conn   = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('SELECT fn_next_invoice_number(@storeId::uuid)'),
      parameters: {'storeId': storeId},
    );
    return result.first.toColumnMap().values.first.toString();
  }

  // ────────────────────────────────────────────────────────
  // SAVE SERVICE INVOICE
  //   service_invoices      → header
  //   service_invoice_items → line items
  //   service_invoice_payments → payment
  // ────────────────────────────────────────────────────────

  Future<String> saveServiceInvoice({
    required String                storeId,
    required String                counterId,
    required String                userId,
    required String                invoiceNo,
    required List<ServiceCartItem> items,
    required String                paymentMethod,
    required double                paymentAmount,
    String?                        customerId,
    String?                        notes,
    double?                        previousAmount,
    double?                        newAmount,
    double?                        payAmount,
  }) async {
    final conn = await DataBaseService.getConnection();
    late String invoiceId;

    final totalAmount = items.fold<double>(0, (s, i) => s + i.amount);
    final totalFee    = items.fold<double>(0, (s, i) => s + i.calculatedFee);
    final grandTotal  = totalAmount + totalFee;

    await conn.runTx((tx) async {

      // ── 1. service_invoices INSERT ───────────────────────
      final result = await tx.execute(
        Sql.named('''
          INSERT INTO public.service_invoices (
            store_id, counter_id, user_id, customer_id,
            invoice_no, total_amount, total_fee, grand_total,
            status, notes,
            previous_amount, new_amount, pay_amount
          ) VALUES (
            @storeId::uuid, @counterId::uuid, @userId::uuid,
            ${customerId != null ? '@customerId::uuid' : 'NULL'},
            @invoiceNo, @totalAmount, @totalFee, @grandTotal,
            'completed', @notes,
            ${previousAmount != null ? '@previousAmount' : 'NULL'},
            ${newAmount      != null ? '@newAmount'      : 'NULL'},
            ${payAmount      != null ? '@payAmount'      : 'NULL'}
          )
          RETURNING id
        '''),
        parameters: {
          'storeId':     storeId,
          'counterId':   counterId,
          'userId':      userId,
          if (customerId     != null) 'customerId':     customerId,
          'invoiceNo':   invoiceNo,
          'totalAmount': totalAmount,
          'totalFee':    totalFee,
          'grandTotal':  grandTotal,
          'notes':       notes,
          if (previousAmount != null) 'previousAmount': previousAmount,
          if (newAmount      != null) 'newAmount':      newAmount,
          if (payAmount      != null) 'payAmount':      payAmount,
        },
      );
      invoiceId = result.first.toColumnMap()['id'].toString();

      // ── 2. service_invoice_items INSERT ─────────────────
      for (final item in items) {
        await tx.execute(
          Sql.named('''
            INSERT INTO public.service_invoice_items (
              invoice_id, service_id,
              service_name, service_type,
              amount, per_amount, fee_amount,
              calculated_fee, total
            ) VALUES (
              @invoiceId::uuid, @serviceId::uuid,
              @serviceName, @serviceType,
              @amount, @perAmount, @feeAmount,
              @calculatedFee, @total
            )
          '''),
          parameters: {
            'invoiceId':    invoiceId,
            'serviceId':    item.service.id,
            'serviceName':  item.service.name,
            'serviceType':  item.service.serviceType,
            'amount':       item.amount,
            'perAmount':    item.service.perAmount,
            'feeAmount':    item.service.feeAmount,
            'calculatedFee': item.calculatedFee,
            'total':        item.total,
          },
        );
      }

      // ── 3. service_invoice_payments INSERT ───────────────
      if (paymentAmount > 0) {
        await tx.execute(
          Sql.named('''
            INSERT INTO public.service_invoice_payments (
              invoice_id, store_id, counter_id,
              payment_method, amount
            ) VALUES (
              @invoiceId::uuid, @storeId::uuid, @counterId::uuid,
              @method, @amount
            )
          '''),
          parameters: {
            'invoiceId': invoiceId,
            'storeId':   storeId,
            'counterId': counterId,
            'method':    paymentMethod,
            'amount':    paymentAmount,
          },
        );
      }
    });

    return invoiceId;
  }

  // ────────────────────────────────────────────────────────
  // GET ALL SERVICE INVOICES
  // ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllServiceInvoices(
      String storeId) async {
    final conn   = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        SELECT
          si.id,
          si.invoice_no,
          si.invoice_date,
          si.total_amount,
          si.total_fee,
          si.grand_total,
          si.status,
          si.notes,
          c.name        AS customer_name,
          c.phone       AS customer_phone,
          u.full_name   AS cashier_name,
          co.counter_name,
          COALESCE(SUM(CASE WHEN p.payment_method = 'cash'
                            THEN p.amount ELSE 0 END), 0) AS cash_amount,
          COALESCE(SUM(CASE WHEN p.payment_method = 'credit'
                            THEN p.amount ELSE 0 END), 0) AS credit_amount
        FROM public.service_invoices si
        LEFT JOIN public.customer             c  ON c.id  = si.customer_id
        LEFT JOIN public.branch_users         u  ON u.id  = si.user_id
        LEFT JOIN public.branch_counter       co ON co.id = si.counter_id
        LEFT JOIN public.service_invoice_payments p
               ON p.invoice_id = si.id
        WHERE si.store_id  = @storeId
          AND si.deleted_at IS NULL
        GROUP BY si.id, c.name, c.phone, u.full_name, co.counter_name
        ORDER BY si.invoice_date DESC
      '''),
      parameters: {'storeId': storeId},
    );
    return result.map((r) => r.toColumnMap()).toList();
  }

  // ────────────────────────────────────────────────────────
  // GET ITEMS OF A SINGLE SERVICE INVOICE
  // ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getServiceInvoiceItems(
      String invoiceId) async {
    final conn   = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        SELECT sii.*, s.service_type AS master_type
        FROM public.service_invoice_items sii
        LEFT JOIN public.services s ON s.id = sii.service_id
        WHERE sii.invoice_id = @invoiceId::uuid
        ORDER BY sii.created_at ASC
      '''),
      parameters: {'invoiceId': invoiceId},
    );
    return result.map((r) => r.toColumnMap()).toList();
  }
}
