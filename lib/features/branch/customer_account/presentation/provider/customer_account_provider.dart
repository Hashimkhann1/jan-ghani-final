import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../customer/data/model/customer_model.dart';
import '../../data/datasource/customer_account_datasource.dart';
import '../../data/model/customer_account_model.dart';


// ── STATE ──────────────────────────────────────────────────
class CustomerAccountState {
  final List<CustomerModel>        customers;
  final List<CustomerAccountModel> accounts;
  final bool   loadingCustomers;
  final bool   loadingAccounts;
  final bool   saving;
  final String? error;
  final bool   success;

  const CustomerAccountState({
    this.customers         = const [],
    this.accounts          = const [],
    this.loadingCustomers  = false,
    this.loadingAccounts   = false,
    this.saving            = false,
    this.error             = null,
    this.success           = false,
  });

  CustomerAccountState copyWith({
    List<CustomerModel>?        customers,
    List<CustomerAccountModel>? accounts,
    bool?   loadingCustomers,
    bool?   loadingAccounts,
    bool?   saving,
    String? error,
    bool?   success,
  }) {
    return CustomerAccountState(
      customers        : customers        ?? this.customers,
      accounts         : accounts         ?? this.accounts,
      loadingCustomers : loadingCustomers ?? this.loadingCustomers,
      loadingAccounts  : loadingAccounts  ?? this.loadingAccounts,
      saving           : saving           ?? this.saving,
      error            : error,
      success          : success          ?? this.success,
    );
  }
}

// ── NOTIFIER ───────────────────────────────────────────────
class CustomerAccountNotifier extends StateNotifier<CustomerAccountState> {
  CustomerAccountNotifier() : super(const CustomerAccountState());

  final _ds = CustomerAccountDatasource();

  // ── Load customers for dropdown ───────────────────────────
  // Account ban chuke customers automatically filter ho jaate hain
  Future<void> loadCustomers(String storeId) async {
    state = state.copyWith(loadingCustomers: true, error: null);
    try {
      final list = await _ds.getCustomers(storeId);
      state = state.copyWith(customers: list, loadingCustomers: false);
    } catch (e) {
      state = state.copyWith(
        loadingCustomers: false,
        error: 'Failed to load customers: $e',
      );
    }
  }

  // ── Load existing accounts ────────────────────────────────
  Future<void> loadAccounts(String storeId) async {
    state = state.copyWith(loadingAccounts: true, error: null);
    try {
      final list = await _ds.getStoreAccounts(storeId);
      state = state.copyWith(accounts: list, loadingAccounts: false);
    } catch (e) {
      state = state.copyWith(
        loadingAccounts: false,
        error: 'Failed to load accounts: $e',
      );
    }
  }

  // ── Create new account ────────────────────────────────────
  Future<void> createAccount({
    required CustomerModel customer,
    required String email,
    required String password,
    required String storeId,
  }) async {
    state = state.copyWith(saving: true, error: null, success: false);
    try {
      final exists = await _ds.accountExists(customer.id);
      if (exists) {
        state = state.copyWith(
          saving: false,
          error: 'Account already exists for ${customer.name}',
        );
        return;
      }

      await _ds.createAccount(
        customerId: customer.id,
        fullName:   customer.name,
        email:      email,
        password:   password,
      );

      // Dono reload — naya account wala customer dropdown se hat jaayega
      await Future.wait([
        loadAccounts(storeId),
        loadCustomers(storeId),
      ]);
      state = state.copyWith(saving: false, success: true);
    } catch (e) {
      state = state.copyWith(
        saving: false,
        error: 'Failed to create account: $e',
      );
    }
  }

  // ── Update password ───────────────────────────────────────
  Future<void> updatePassword({
    required String userId,
    required String newPassword,
    required String storeId,
  }) async {
    state = state.copyWith(saving: true, error: null, success: false);
    try {
      await _ds.updatePassword(userId: userId, newPassword: newPassword);
      await loadAccounts(storeId);
      state = state.copyWith(saving: false, success: true);
    } catch (e) {
      state = state.copyWith(
        saving: false,
        error: 'Failed to update password: $e',
      );
    }
  }

  void resetSuccess() => state = state.copyWith(success: false);
  void clearError()   => state = state.copyWith(error: null);
}

// ── PROVIDER ───────────────────────────────────────────────
final customerAccountProvider =
StateNotifierProvider.autoDispose<CustomerAccountNotifier, CustomerAccountState>(
      (_) => CustomerAccountNotifier(),
);