import 'package:flutter_riverpod/legacy.dart';

import '../../data/mock/customer_mock_data.dart';
import '../../data/model/customer_model.dart';


// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────

class CustomerState {
  final List<CustomerModel> allCustomers;
  final String searchQuery;
  final String filterStatus;   // 'all' | 'active' | 'inactive'
  final String filterType;     // 'all' | 'walkin' | 'credit' | 'wholesale'
  final bool isLoading;
  final String? errorMessage;

  const CustomerState({
    this.allCustomers  = const [],
    this.searchQuery   = '',
    this.filterStatus  = 'all',
    this.filterType    = 'all',
    this.isLoading     = false,
    this.errorMessage,
  });

  // ── Filtered list ──────────────────────────────────────────
  List<CustomerModel> get filteredCustomers {
    return allCustomers.where((c) {
      if (c.deletedAt != null) return false;

      if (filterStatus == 'active'   && !c.isActive) return false;
      if (filterStatus == 'inactive' &&  c.isActive) return false;

      if (filterType != 'all' && c.customerType != filterType) return false;

      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return c.name.toLowerCase().contains(q) ||
            c.phone.contains(q) ||
            c.code.toLowerCase().contains(q) ||
            (c.address?.toLowerCase().contains(q) ?? false);
      }

      return true;
    }).toList();
  }

  // ── Summary stats ──────────────────────────────────────────
  int    get totalCount       => allCustomers.where((c) => c.deletedAt == null).length;
  int    get activeCount      => allCustomers.where((c) => c.isActive && c.deletedAt == null).length;
  double get totalOutstanding => allCustomers.fold(0, (sum, c) => sum + c.currentBalance.clamp(0, double.infinity));
  double get totalSales       => allCustomers.fold(0, (sum, c) => sum + c.totalSaleAmount);

  CustomerState copyWith({
    List<CustomerModel>? allCustomers,
    String?              searchQuery,
    String?              filterStatus,
    String?              filterType,
    bool?                isLoading,
    String?              errorMessage,
  }) {
    return CustomerState(
      allCustomers:  allCustomers  ?? this.allCustomers,
      searchQuery:   searchQuery   ?? this.searchQuery,
      filterStatus:  filterStatus  ?? this.filterStatus,
      filterType:    filterType    ?? this.filterType,
      isLoading:     isLoading     ?? this.isLoading,
      errorMessage:  errorMessage  ?? this.errorMessage,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────

class CustomerNotifier extends StateNotifier<CustomerState> {
  CustomerNotifier() : super(const CustomerState()) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // TODO: Drift DB call aayega yahan
      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(
        allCustomers: customerDummyData,
        isLoading:    false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Customers load karne mein masla: $e',
      );
    }
  }

  void onSearchChanged(String query) =>
      state = state.copyWith(searchQuery: query);

  void onFilterStatusChanged(String filter) =>
      state = state.copyWith(filterStatus: filter);

  void onFilterTypeChanged(String type) =>
      state = state.copyWith(filterType: type);

  Future<void> addCustomer(CustomerModel customer) async {
    // TODO: Drift DB insert
    state = state.copyWith(
      allCustomers: [...state.allCustomers, customer],
    );
  }

  Future<void> updateCustomer(CustomerModel updated) async {
    // TODO: Drift DB update
    final list = state.allCustomers
        .map((c) => c.id == updated.id ? updated : c)
        .toList();
    state = state.copyWith(allCustomers: list);
  }

  Future<void> deleteCustomer(String id) async {
    // TODO: Drift soft delete
    final list = state.allCustomers.where((c) => c.id != id).toList();
    state = state.copyWith(allCustomers: list);
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────

final customerProvider =
StateNotifierProvider<CustomerNotifier, CustomerState>(
      (ref) => CustomerNotifier(),
);