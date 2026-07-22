// lib/features/branch/service/presentation/provideer/service_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../cash_counter/presentation/provider/cash_counter_provider.dart';
import '../../../customer/data/model/customer_model.dart';
import '../../../customer/presentation/provider/customer_provider.dart';
import '../../data/datasource/service_datasource.dart';
import '../../data/model/service_model.dart';

// ════════════════════════════════════════════════════════════
//  1. SERVICE LIST PROVIDER  (master CRUD)
// ════════════════════════════════════════════════════════════

class ServiceListNotifier
    extends StateNotifier<AsyncValue<List<ServiceModel>>> {
  final ServiceDatasource _ds;
  final String            _storeId;

  ServiceListNotifier(this._ds, this._storeId)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _ds.getAllServices(_storeId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> create({
    required String name,
    required String serviceType,
    required double perAmount,
    required double feeAmount,
    String?         notes,
  }) async {
    try {
      await _ds.createService(
        storeId:     _storeId,
        name:        name,
        serviceType: serviceType,
        perAmount:   perAmount,
        feeAmount:   feeAmount,
        notes:       notes,
      );
      await load();
      return true;
    } catch (e) {
      debugPrint('Service create error: $e');
      return false;
    }
  }

  Future<bool> update({
    required String id,
    required String name,
    required String serviceType,
    required double perAmount,
    required double feeAmount,
    String?         notes,
  }) async {
    try {
      await _ds.updateService(
        id:          id,
        name:        name,
        serviceType: serviceType,
        perAmount:   perAmount,
        feeAmount:   feeAmount,
        notes:       notes,
      );
      await load();
      return true;
    } catch (e) {
      debugPrint('Service update error: $e');
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _ds.deleteService(id);
      await load();
      return true;
    } catch (e) {
      debugPrint('Service delete error: $e');
      return false;
    }
  }
}

final serviceListProvider = StateNotifierProvider.autoDispose<
    ServiceListNotifier, AsyncValue<List<ServiceModel>>>(
  (ref) => ServiceListNotifier(
    ServiceDatasource(),
    ref.read(authProvider).storeId,
  ),
);

// ════════════════════════════════════════════════════════════
//  2. SERVICE INVOICE PROVIDER  (transaction)
// ════════════════════════════════════════════════════════════

class ServiceInvoiceNotifier extends StateNotifier<ServiceInvoiceState> {
  final ServiceDatasource _ds;
  final Ref               _ref;

  ServiceInvoiceNotifier(this._ref)
      : _ds = ServiceDatasource(),
        super(ServiceInvoiceState(
          invoiceNo: 'INV-...',
          date:      DateTime.now(),
          cartItems: [],
        )) {
    _initInvoiceNo();
  }

  String  get _storeId   => _ref.read(authProvider).storeId;
  String? get _counterId => _ref.read(authProvider).counterId;
  String  get _userId    => _ref.read(authProvider).userId;

  Future<void> _initInvoiceNo() async {
    try {
      final no = await _ds.generateInvoiceNo(_storeId);
      state = state.copyWith(invoiceNo: no);
    } catch (_) {
      final now = DateTime.now();
      state = state.copyWith(
        invoiceNo:
            'INV-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}',
      );
    }
  }

  // ── Customer ──────────────────────────────────────────────

  void selectCustomer(CustomerModel? customer) {
    if (customer == null) {
      state = state.copyWith(clearCustomer: true);
    } else {
      state = state.copyWith(
        customerId:      customer.id,
        customerName:    customer.name,
        customerBalance: customer.balance,
      );
    }
  }

  // ── Cart ──────────────────────────────────────────────────

  void addService(ServiceModel service) {
    final exists = state.cartItems.any((i) => i.service.id == service.id);
    if (exists) {
      state = state.copyWith(
        errorMessage: '${service.name} already added hai',
      );
      return;
    }
    state = state.copyWith(
      cartItems: [
        ...state.cartItems,
        ServiceCartItem(
          cartId:        const Uuid().v4(),
          service:       service,
          amount:        0,
          calculatedFee: 0,
        ),
      ],
      clearError: true,
    );
  }

  void removeService(String cartId) {
    state = state.copyWith(
      cartItems:    state.cartItems.where((i) => i.cartId != cartId).toList(),
      clearPayment: true,
    );
  }

  void updateAmount(String cartId, double amount) {
    if (amount < 0) return;
    state = state.copyWith(
      cartItems: state.cartItems.map((i) {
        if (i.cartId != cartId) return i;
        return i.copyWith(amount: amount);
      }).toList(),
      clearPayment: true,
    );
  }

  // ── Payment ───────────────────────────────────────────────

  void setPayment(String method, double amount) {
    if (method == 'credit' && !state.hasCustomer) {
      state = state.copyWith(
        errorMessage: 'Credit payment ke liye customer select karein',
      );
      return;
    }
    state = state.copyWith(
      payment:    ServicePaymentEntry(method: method, amount: amount),
      clearError: true,
    );
  }

  void setNotes(String value) =>
      state = state.copyWith(notes: value.isEmpty ? null : value);

  // ── Save ──────────────────────────────────────────────────

  Future<bool> saveInvoice() async {
    if (state.isCartEmpty) {
      state = state.copyWith(errorMessage: 'Koi service add nahi ki');
      return false;
    }
    final hasZeroAmount = state.cartItems.any((i) => i.amount <= 0);
    if (hasZeroAmount) {
      state = state.copyWith(
          errorMessage: 'Sab services ka amount enter karein');
      return false;
    }
    if (state.payment == null || state.payment!.amount <= 0) {
      state = state.copyWith(errorMessage: 'Payment method select karein');
      return false;
    }
    if (_counterId == null || _counterId!.isEmpty) {
      state = state.copyWith(
          errorMessage: 'Counter assign nahi — login karein');
      return false;
    }

    final prevBalance = state.customerBalance;
    final newBalance  =
        (state.hasCustomer && state.payment!.method == 'credit')
            ? (prevBalance ?? 0) + state.grandTotal
            : prevBalance;

    state = state.copyWith(isSaving: true);
    try {
      await _ds.saveServiceInvoice(
        storeId:        _storeId,
        counterId:      _counterId!,
        userId:         _userId,
        invoiceNo:      state.invoiceNo,
        items:          state.cartItems,
        paymentMethod:  state.payment!.method,
        paymentAmount:  state.payment!.amount,
        customerId:     state.customerId,
        notes:          state.notes,
        previousAmount: prevBalance,
        newAmount:      newBalance,
        payAmount:      state.payment!.amount,
      );

      _ref.read(customerProvider.notifier).loadCustomers();
      _ref.read(cashCounterProvider.notifier).loadRecords();

      await _clearAndReset();
      return true;
    } catch (e) {
      state = state.copyWith(
          isSaving: false, errorMessage: 'Save error: $e');
      return false;
    }
  }

  Future<void> _clearAndReset() async {
    final no = await _ds.generateInvoiceNo(_storeId);
    state = ServiceInvoiceState(
      invoiceNo: no,
      date:      DateTime.now(),
      cartItems: [],
    );
  }

  void clearCart() {
    state = state.copyWith(
      cartItems:     [],
      clearCustomer: true,
      clearPayment:  true,
      clearNotes:    true,
      clearError:    true,
    );
    _initInvoiceNo();
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final serviceInvoiceProvider =
    StateNotifierProvider<ServiceInvoiceNotifier, ServiceInvoiceState>(
  (ref) => ServiceInvoiceNotifier(ref),
);
