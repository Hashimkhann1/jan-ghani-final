import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../customer/data/model/customer_model.dart';
import '../../data/datasource/held_invoice_datasource.dart';
import '../../data/model/held_invoice_model.dart';
import '../../data/model/sale_invoice_model.dart';

class HeldInvoicesNotifier extends StateNotifier<List<HeldInvoice>> {
  final HeldInvoiceDatasource _ds;
  final Ref                   _ref;

  HeldInvoicesNotifier(this._ref)
      : _ds = HeldInvoiceDatasource(),
        super([]);

  Future<void> reload() => _loadFromDb();

  Future<void> _loadFromDb() async {
    final storeId = _ref.read(authProvider).storeId;

    debugPrint('🔍 HeldInvoices → storeId="$storeId"');
    if (storeId.isEmpty) {
      debugPrint('⚠️  storeId empty — skipping');
      return;
    }

    try {
      final rows = await _ds.getActiveHolds(storeId);
      debugPrint('📦 DB returned ${rows.length} active holds');

      final holds = <HeldInvoice>[];

      for (final row in rows) {
        try {
          // ── items_json ─────────────────────────────────────────
          // postgres jsonb → already List/Map, fallback String
          List<CartItem> items = [];
          final rawItems = row['items_json'];
          if (rawItems is List) {
            items = rawItems
                .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
          } else if (rawItems is String) {
            final decoded = jsonDecode(rawItems) as List;
            items = decoded
                .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
          }

          // ── held_at ────────────────────────────────────────────
          DateTime heldAt;
          final rawDate = row['held_at'];
          if (rawDate is DateTime) {
            heldAt = rawDate;
          } else {
            heldAt = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
          }

          // ── customer ───────────────────────────────────────────
          CustomerModel? customer;
          if (row['customer_name'] != null) {
            customer = CustomerModel(
              id:           row['customer_id']?.toString() ?? '',
              storeId:      storeId,
              code:         row['customer_code']?.toString() ?? '',
              name:         row['customer_name'].toString(),
              phone:        '',
              customerType: 'credit',
              creditLimit:  0.0,
              balance:      0.0,
              isActive:     true,
              createdAt:    DateTime.now(),
              updatedAt:    DateTime.now(),
            );
          }

          holds.add(HeldInvoice(
            id:         row['id'].toString(),
            invoiceNo:  row['invoice_no']?.toString() ?? '',
            holdLabel:  row['hold_label']?.toString(),
            customer:   customer,
            cartItems:  items,
            heldAt:     heldAt,
            grandTotal: double.tryParse(row['grand_total'].toString()) ?? 0,
          ));
        } catch (rowErr) {
          debugPrint('❌ Row parse error: $rowErr  |  row: $row');
        }
      }

      debugPrint('✅ Holds loaded: ${holds.length}');
      state = holds;

    } catch (e, st) {
      debugPrint('❌ getActiveHolds error: $e\n$st');
    }
  }

  Future<String> holdInvoice({
    required String         invoiceNo,
    required CustomerModel? customer,
    required List<CartItem> items,
    required double         grandTotal,
    String?                 label,
  }) async {
    final localId   = const Uuid().v4();
    final storeId   = _ref.read(authProvider).storeId;
    final counterId = _ref.read(authProvider).counterId ?? '';
    final userId    = _ref.read(authProvider).userId;

    final held = HeldInvoice(
      id:         localId,
      invoiceNo:  invoiceNo,
      holdLabel:  label,
      customer:   customer,
      cartItems:  List.unmodifiable(items),
      heldAt:     DateTime.now(),
      grandTotal: grandTotal,
    );

    state = [...state, held];

    _ds.holdInvoice(
      storeId:      storeId,
      counterId:    counterId,
      userId:       userId,
      customerId:   customer?.id.isEmpty == true ? null : customer?.id,
      customerName: customer?.name,
      customerCode: customer?.code,
      invoiceNo:    invoiceNo,
      holdLabel:    label,
      items:        items,
      grandTotal:   grandTotal,
    ).then((dbId) {
      state = state.map((h) => h.id == localId
          ? HeldInvoice(
        id:         dbId,
        invoiceNo:  h.invoiceNo,
        holdLabel:  h.holdLabel,
        customer:   h.customer,
        cartItems:  h.cartItems,
        heldAt:     h.heldAt,
        grandTotal: h.grandTotal,
      )
          : h).toList();
    }).catchError((_) {});

    return localId;
  }

  Future<void> releaseHold(String id, {bool discard = false}) async {
    state = state.where((h) => h.id != id).toList();
    try {
      await _ds.releaseHold(id, by: discard ? 'discarded' : 'resumed');
    } catch (_) {}
  }

  HeldInvoice? findById(String id) =>
      state.where((h) => h.id == id).firstOrNull;
}

final heldInvoicesProvider =
StateNotifierProvider<HeldInvoicesNotifier, List<HeldInvoice>>(
      (ref) => HeldInvoicesNotifier(ref),
);