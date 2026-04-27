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
        super([]) {
    _loadFromDb();
  }

  String get _storeId   => _ref.read(authProvider).storeId;
  String get _counterId => _ref.read(authProvider).counterId ?? '';
  String get _userId    => _ref.read(authProvider).userId;

  /// ── App start pe DB se active holds load karo ─────────────────
  Future<void> _loadFromDb() async {
    try {
      final rows = await _ds.getActiveHolds(_storeId);
      final holds = rows.map((row) {
        // items_json parse karo
        List<CartItem> items = [];
        try {
          final rawItems = row['items_json'] as List<dynamic>? ?? [];
          items = rawItems
              .map((e) => CartItem.fromJson(
            Map<String, dynamic>.from(e as Map),
          ))
              .toList();
        } catch (_) {}

        // Customer reconstruct karo — saare required fields do
        CustomerModel? customer;
        if (row['customer_name'] != null) {
          customer = CustomerModel(
            id:           row['customer_id']?.toString() ?? '',
            storeId:      _storeId,
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

        return HeldInvoice(
          id:         row['id'].toString(),
          invoiceNo:  row['invoice_no']?.toString() ?? '',
          holdLabel:  row['hold_label']?.toString(),
          customer:   customer,
          cartItems:  items,
          heldAt:     row['held_at'] as DateTime? ?? DateTime.now(),
          grandTotal: (row['grand_total'] as num?)?.toDouble() ?? 0,
        );
      }).toList();

      state = holds;
    } catch (_) {
      // DB error — in-memory se kaam chalao
    }
  }

  /// ── New hold add karo ─────────────────────────────────────────
  Future<String> holdInvoice({
    required String         invoiceNo,
    required CustomerModel? customer,
    required List<CartItem> items,
    required double         grandTotal,
    String?                 label,
  }) async {
    final localId = const Uuid().v4();

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

    // DB mein bhi save karo (async, fire & forget)
    _ds.holdInvoice(
      storeId:      _storeId,
      counterId:    _counterId,
      userId:       _userId,
      customerId:   customer?.id.isEmpty == true ? null : customer?.id,
      customerName: customer?.name,
      customerCode: customer?.code,
      invoiceNo:    invoiceNo,
      holdLabel:    label,
      items:        items,
      grandTotal:   grandTotal,
    ).then((dbId) {
      // DB id se local id replace karo
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
    }).catchError((_) {
      // DB fail — in-memory hold keep karo, koi bat nahi
    });

    return localId;
  }

  /// ── Hold remove karo (resume ya discard) ──────────────────────
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