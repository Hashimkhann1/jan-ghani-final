// lib/features/branch/sale_invoice/data/datasource/held_invoice_datasource.dart

import 'dart:convert';
import 'package:postgres/postgres.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/held_invoice_model.dart';
import '../model/sale_invoice_model.dart';

class HeldInvoiceDatasource {

  /// ── Hold karo ────────────────────────────────────────────────
  Future<String> holdInvoice({
    required String         storeId,
    required String         counterId,
    required String         userId,
    String?                 customerId,
    String?                 customerName,
    String?                 customerCode,
    required String         invoiceNo,
    String?                 holdLabel,
    required List<CartItem> items,
    required double         grandTotal,
  }) async {
    final conn      = await DataBaseService.getConnection();
    final itemsJson = jsonEncode(items.map((i) => i.toJson()).toList());

    final result = await conn.execute(
      Sql.named('''
        INSERT INTO public.held_invoices (
          store_id, counter_id, user_id, customer_id,
          customer_name, customer_code,
          invoice_no, hold_label, items_json, grand_total
        ) VALUES (
          @storeId::uuid, @counterId::uuid, @userId::uuid,
          ${customerId != null ? '@customerId::uuid' : 'NULL'},
          @customerName, @customerCode,
          @invoiceNo, @holdLabel, @itemsJson::jsonb, @grandTotal
        )
        RETURNING id
      '''),
      parameters: {
        'storeId':      storeId,
        'counterId':    counterId,
        'userId':       userId,
        if (customerId != null) 'customerId': customerId,
        'customerName': customerName,
        'customerCode': customerCode,
        'invoiceNo':    invoiceNo,
        'holdLabel':    holdLabel,
        'itemsJson':    itemsJson,
        'grandTotal':   grandTotal,
      },
    );

    return result.first.toColumnMap()['id'].toString();
  }

  /// ── Active holds fetch karo ───────────────────────────────────
  Future<List<Map<String, dynamic>>> getActiveHolds(String storeId) async {
    final conn   = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        SELECT id, invoice_no, hold_label, customer_name,
               customer_code, items_json, grand_total, held_at
        FROM   public.held_invoices
        WHERE  store_id    = @storeId::uuid
          AND  released_at IS NULL
        ORDER  BY held_at DESC
      '''),
      parameters: {'storeId': storeId},
    );
    return result.map((r) => r.toColumnMap()).toList();
  }

  /// ── Hold release karo (resume ya discard) ────────────────────
  Future<void> releaseHold(String holdId, {String by = 'resumed'}) async {
    final conn = await DataBaseService.getConnection();
    await conn.execute(
      Sql.named('''
        UPDATE public.held_invoices
        SET    released_at = NOW(),
               released_by = @by
        WHERE  id = @holdId::uuid
      '''),
      parameters: {'holdId': holdId, 'by': by},
    );
  }

  /// ── All holds discard karo (clear all) ───────────────────────
  Future<void> discardAllHolds(String storeId) async {
    final conn = await DataBaseService.getConnection();
    await conn.execute(
      Sql.named('''
        UPDATE public.held_invoices
        SET    released_at = NOW(),
               released_by = 'discarded'
        WHERE  store_id    = @storeId::uuid
          AND  released_at IS NULL
      '''),
      parameters: {'storeId': storeId},
    );
  }
}