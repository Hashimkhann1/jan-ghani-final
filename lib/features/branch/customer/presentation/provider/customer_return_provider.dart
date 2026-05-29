import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/customer_return_datasource.dart';
import '../../data/model/customer_return_model.dart';

class CustomerReturnState {
  final List<CustomerReturnInvoice> returns;
  final String   customerId;
  final String   customerName;
  final DateTime fromDate;
  final DateTime toDate;
  final String?  selectedRefundType;
  final bool     isLoading;
  final String?  errorMessage;

  CustomerReturnState({
    this.returns           = const [],
    required this.customerId,
    required this.customerName,
    DateTime? fromDate,
    DateTime? toDate,
    this.selectedRefundType,
    this.isLoading         = false,
    this.errorMessage,
  })  : fromDate = fromDate ?? _today(),
        toDate   = toDate   ?? _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  CustomerReturnSummary get summary => CustomerReturnSummary(
    totalReturns:  returns.length,
    totalAmount:   returns.fold(0, (s, r) => s + r.grandTotal),
    totalQuantity: returns.fold(0, (s, r) => s + r.totalQuantity),
    totalDiscount: returns.fold(0, (s, r) => s + r.totalDiscount),
  );

  CustomerReturnState copyWith({
    List<CustomerReturnInvoice>? returns,
    DateTime?                    fromDate,
    DateTime?                    toDate,
    String?                      selectedRefundType,
    bool                         clearRefund = false,
    bool?                        isLoading,
    String?                      errorMessage,
  }) => CustomerReturnState(
    returns:            returns             ?? this.returns,
    customerId:         customerId,
    customerName:       customerName,
    fromDate:           fromDate            ?? this.fromDate,
    toDate:             toDate              ?? this.toDate,
    selectedRefundType: clearRefund
        ? null
        : (selectedRefundType ?? this.selectedRefundType),
    isLoading:          isLoading           ?? this.isLoading,
    errorMessage:       errorMessage,
  );
}

class CustomerReturnNotifier extends StateNotifier<CustomerReturnState> {
  final CustomerReturnDatasource _ds;

  CustomerReturnNotifier({
    required String customerId,
    required String customerName,
  })  : _ds = CustomerReturnDatasource(),
        super(CustomerReturnState(
        customerId:   customerId,
        customerName: customerName,
      )) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final returns = await _ds.getByCustomer(
        customerId: state.customerId,
        fromDate:   state.fromDate,
        toDate:     state.toDate,
        refundType: state.selectedRefundType,
      );
      state = state.copyWith(returns: returns, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  void setFromDate(DateTime d) {
    state = state.copyWith(fromDate: d);
    load();
  }

  void setToDate(DateTime d) {
    state = state.copyWith(toDate: d);
    load();
  }

  void setRefundType(String? type) {
    state = state.copyWith(
      selectedRefundType: type,
      clearRefund:        type == null,
    );
    load();
  }

  void setToday() {
    final today = CustomerReturnState._today();
    state = state.copyWith(fromDate: today, toDate: today);
    load();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

final customerReturnProvider = StateNotifierProvider.family
<CustomerReturnNotifier,
    CustomerReturnState,
    ({String customerId, String customerName})>(
      (ref, args) => CustomerReturnNotifier(
    customerId:   args.customerId,
    customerName: args.customerName,
  ),
);