import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/model/customer_model.dart';
import '../../data/repository/customer_repository_impl.dart';
import '../../domain/usecase/add_customer_usecase.dart';
import '../../domain/usecase/delete_customer_usecase.dart';
import '../../domain/usecase/get_customers_usecase.dart';
import '../../domain/usecase/update_customer_usecase.dart';

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────
class CustomerState {
  final List<CustomerModel> allCustomers;
  final String  searchQuery;
  final String  filterStatus; // all | active | inactive
  final String  filterType;   // all | walkin | credit | wholesale
  final bool    isLoading;
  final String? errorMessage;

  const CustomerState({
    this.allCustomers  = const [],
    this.searchQuery   = '',
    this.filterStatus  = 'all',
    this.filterType    = 'all',
    this.isLoading     = false,
    this.errorMessage,
  });

  // ── Filtered List ─────────────────────────────────────────
  List<CustomerModel> get filteredCustomers {
    return allCustomers.where((c) {
      if (c.deletedAt != null)                              return false;
      if (filterStatus == 'active'   && !c.isActive)       return false;
      if (filterStatus == 'inactive' &&  c.isActive)       return false;
      if (filterType   != 'all' && c.customerType != filterType) return false;

      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return c.name.toLowerCase().contains(q)  ||
            c.phone.contains(q)               ||
            c.code.toLowerCase().contains(q)  ||
            (c.address?.toLowerCase().contains(q) ?? false);
      }

      return true;
    }).toList();
  }

  // ── Stats ─────────────────────────────────────────────────
  int    get totalCount =>
      allCustomers.where((c) => c.deletedAt == null).length;

  int    get activeCount =>
      allCustomers.where((c) => c.isActive && c.deletedAt == null).length;

  double get totalOutstanding =>
      allCustomers.fold(0, (sum, c) =>
      sum + c.balance.clamp(0, double.infinity));

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
      errorMessage:  errorMessage,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────
class CustomerNotifier extends StateNotifier<CustomerState> {
  final CustomerRepositoryImpl _repo;
  final GetCustomersUseCase    _getAll;
  final AddCustomerUseCase     _add;
  final UpdateCustomerUseCase  _update;
  final DeleteCustomerUseCase  _delete;
  final Ref _ref;
  String get _storeId => _ref.read(authProvider).storeId;

  CustomerNotifier(this._ref)
      : _repo   = CustomerRepositoryImpl(),
        _getAll  = GetCustomersUseCase(CustomerRepositoryImpl()),
        _add     = AddCustomerUseCase(CustomerRepositoryImpl()),
        _update  = UpdateCustomerUseCase(CustomerRepositoryImpl()),
        _delete  = DeleteCustomerUseCase(CustomerRepositoryImpl()),
        super(const CustomerState()) {
    loadCustomers();
  }

  // ── LOAD ──────────────────────────────────────────────────
  Future<void> loadCustomers() async {
    state = state.copyWith(isLoading: true);
    try {
      final customers = await _getAll(_storeId);
      state = state.copyWith(allCustomers: customers, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  // ── ADD ───────────────────────────────────────────────────
  Future<void> addCustomer({
    required String name,
    required String phone,
    String?         address,
    required String customerType,
    required double creditLimit,
    required bool   isActive,
    String?         notes,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final code = await _repo.generateCode(_storeId);

      final saved = await _add(CustomerModel(
        id:           '',
        storeId:      _storeId,
        code:         code,
        name:         name,
        phone:        phone,
        address:      address,
        customerType: customerType,
        creditLimit:  creditLimit,
        balance:      0,
        isActive:     isActive,
        notes:        notes,
        createdAt:    DateTime.now(),
        updatedAt:    DateTime.now(),
      ));

      state = state.copyWith(
        allCustomers: [saved, ...state.allCustomers],
        isLoading:    false,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Add error: $e');
    }
  }

  // ── UPDATE ────────────────────────────────────────────────
  Future<void> updateCustomer(CustomerModel updated) async {
    state = state.copyWith(isLoading: true);
    try {
      final fresh = await _update(updated);
      final list  = state.allCustomers
          .map((c) => c.id == fresh.id ? fresh : c)
          .toList();
      state = state.copyWith(allCustomers: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Update error: $e');
    }
  }

  // ── DELETE ────────────────────────────────────────────────
  Future<void> deleteCustomer(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _delete(id);
      final list = state.allCustomers.where((c) => c.id != id).toList();
      state = state.copyWith(allCustomers: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Delete error: $e');
    }
  }

  // ── FILTERS ───────────────────────────────────────────────
  void onSearchChanged(String q)       => state = state.copyWith(searchQuery: q);
  void onFilterStatusChanged(String f) => state = state.copyWith(filterStatus: f);
  void onFilterTypeChanged(String t)   => state = state.copyWith(filterType: t);
  void clearError()                    => state = state.copyWith(errorMessage: null);
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────
final customerProvider =
StateNotifierProvider<CustomerNotifier, CustomerState>(
      (ref) => CustomerNotifier(ref),
);