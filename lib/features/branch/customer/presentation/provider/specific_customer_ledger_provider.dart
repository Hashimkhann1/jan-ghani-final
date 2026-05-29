import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/branch/customer/data/model/specific_customer_ledger_model.dart';
import '../../data/datasource/specific_customer_ledger_datasource.dart';


class CustomerLedgerState {
  final List<SpecificCustomerLedgerModel> ledger;
  final String  customerId;
  final String  customerName;
  final bool    isLoading;
  final String? errorMessage;

  const CustomerLedgerState({
    this.ledger       = const [],
    required this.customerId,
    required this.customerName,
    this.isLoading    = false,
    this.errorMessage,
  });

  double get totalPaid    => ledger.fold(0, (s, r) => s + r.payAmount);
  double get currentBalance => ledger.isEmpty ? 0 : ledger.first.newAmount;

  CustomerLedgerState copyWith({
    List<SpecificCustomerLedgerModel>? ledger,
    bool?                      isLoading,
    String?                    errorMessage,
  }) => CustomerLedgerState(
    ledger:       ledger       ?? this.ledger,
    customerId:   customerId,
    customerName: customerName,
    isLoading:    isLoading    ?? this.isLoading,
    errorMessage: errorMessage,
  );
}

class CustomerLedgerNotifier extends StateNotifier<CustomerLedgerState> {
  final SpecificCustomerLedgerDatasource _ds;

  CustomerLedgerNotifier({
    required String customerId,
    required String customerName,
  })  : _ds = SpecificCustomerLedgerDatasource(),
        super(CustomerLedgerState(
        customerId:   customerId,
        customerName: customerName,
      )) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final ledger = await _ds.getByCustomer(
          customerId: state.customerId);
      state = state.copyWith(ledger: ledger, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}


final customerLedgerProvider = StateNotifierProvider.family
<CustomerLedgerNotifier,
    CustomerLedgerState,
    ({String customerId, String customerName})>(
      (ref, args) => CustomerLedgerNotifier(
    customerId:   args.customerId,
    customerName: args.customerName,
  ),
);