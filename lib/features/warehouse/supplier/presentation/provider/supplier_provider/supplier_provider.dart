// Updated on 2026-10-05 03:37 PM
// =============================================================
// supplier_provider.dart
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/data/supplier_repository.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_model.dart';

class SupplierState {
  final List<SupplierModel> allSuppliers;
  final String              searchQuery;
  final String              filterStatus;
  final String              filterBalance; // 'all' | 'due' | 'clear'
  final String              sortBy;        // 'due_desc' | 'name' | 'purchase_desc' | 'newest'
  final int                 page;          // 0-based
  final int                 pageSize;
  final bool                isLoading;
  final String?             errorMessage;

  const SupplierState({
    this.allSuppliers  = const [],
    this.searchQuery   = '',
    this.filterStatus  = 'all',
    this.filterBalance = 'all',
    this.sortBy        = 'due_desc',
    this.page          = 0,
    this.pageSize      = 25,
    this.isLoading     = false,
    this.errorMessage,
  });

  /// Status ke ilawa saare filters (search + balance) — tabs ke counts isi se
  List<SupplierModel> get _baseSuppliers {
    return allSuppliers.where((s) {
      if (s.deletedAt != null) return false;
      if (filterBalance == 'due'   && !s.hasDue) return false;
      if (filterBalance == 'clear' &&  s.hasDue) return false;
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return s.name.toLowerCase().contains(q) ||
            (s.companyName?.toLowerCase().contains(q)   ?? false) ||
            (s.contactPerson?.toLowerCase().contains(q) ?? false) ||
            s.phone.contains(q) ||
            (s.address?.toLowerCase().contains(q)       ?? false);
      }
      return true;
    }).toList();
  }

  List<SupplierModel> get filteredSuppliers {
    final list = _baseSuppliers.where((s) {
      if (filterStatus == 'active'   && !s.isActive) return false;
      if (filterStatus == 'inactive' &&  s.isActive) return false;
      return true;
    }).toList();

    switch (sortBy) {
      case 'due_desc':
        list.sort((a, b) => b.outstandingBalance.compareTo(a.outstandingBalance));
        break;
      case 'name':
        list.sort((a, b) => _label(a).compareTo(_label(b)));
        break;
      case 'purchase_desc':
        list.sort((a, b) => b.totalPurchaseAmount.compareTo(a.totalPurchaseAmount));
        break;
      case 'newest':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return list;
  }

  static String _label(SupplierModel s) =>
      ((s.companyName?.isNotEmpty ?? false) ? s.companyName! : s.name)
          .toLowerCase();

  /// Tabs ke counts — search + balance filter ke baad
  Map<String, int> get statusCounts {
    final base   = _baseSuppliers;
    final active = base.where((s) => s.isActive).length;
    return {'all': base.length, 'active': active, 'inactive': base.length - active};
  }

  int    get totalCount       => allSuppliers.where((s) => s.deletedAt == null).length;
  int    get activeCount      => allSuppliers.where((s) => s.isActive && s.deletedAt == null).length;
  double get totalPurchased   => allSuppliers.fold(0, (sum, s) => sum + s.totalPurchaseAmount);
  double get totalOutstanding => allSuppliers.fold(0, (sum, s) => sum + s.outstandingBalance.clamp(0, double.infinity));

  SupplierState copyWith({
    List<SupplierModel>? allSuppliers,
    String?              searchQuery,
    String?              filterStatus,
    String?              filterBalance,
    String?              sortBy,
    int?                 page,
    int?                 pageSize,
    bool?                isLoading,
    String?              errorMessage,
    bool                 clearError = false, // true → errorMessage null (?? se null set nahi hota)
  }) {
    return SupplierState(
      allSuppliers:  allSuppliers  ?? this.allSuppliers,
      searchQuery:   searchQuery   ?? this.searchQuery,
      filterStatus:  filterStatus  ?? this.filterStatus,
      filterBalance: filterBalance ?? this.filterBalance,
      sortBy:        sortBy        ?? this.sortBy,
      page:          page          ?? this.page,
      pageSize:      pageSize      ?? this.pageSize,
      isLoading:     isLoading     ?? this.isLoading,
      errorMessage:  clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SupplierNotifier extends StateNotifier<SupplierState> {
  final SupplierRepository _repo;
  SupplierNotifier(this._repo) : super(const SupplierState()) {
    loadSuppliers();
  }

  Future<void> loadSuppliers() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final suppliers = await _repo.getAll();
      state = state.copyWith(allSuppliers: suppliers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Suppliers load karne mein masla: $e');
    }
  }

  void onSearchChanged(String query) => state = state.copyWith(searchQuery: query, page: 0);
  void onFilterChanged(String filter) => state = state.copyWith(filterStatus: filter, page: 0);
  void onBalanceFilterChanged(String v) => state = state.copyWith(filterBalance: v, page: 0);
  void onSortChanged(String v)          => state = state.copyWith(sortBy: v, page: 0);
  void onPageChanged(int page)          => state = state.copyWith(page: page);
  void onPageSizeChanged(int size)      => state = state.copyWith(pageSize: size, page: 0);

  Future<void> addSupplier(SupplierModel supplier, {double openingBalance = 0}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final saved = await _repo.insert(supplier, openingBalance: openingBalance);
      state = state.copyWith(allSuppliers: [...state.allSuppliers, saved], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Supplier save karne mein masla: $e');
    }
  }

  Future<void> updateSupplier(
      SupplierModel updated, {
        double? newBalance,   // ← yeh add karo
        String? userId,       // ← yeh add karo
      }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Step 1: Basic info update karo
      var saved = await _repo.update(updated);

      // Step 2: Agar balance change hua hai toh adjust karo
      if (newBalance != null && newBalance != saved.outstandingBalance) {
        saved = await _repo.adjustBalance(
          supplierId:  saved.id,
          newBalance:  newBalance,
          userId:      userId,
        );
      }

      final list = state.allSuppliers
          .map((s) => s.id == saved.id ? saved : s)
          .toList();
      state = state.copyWith(allSuppliers: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading:    false,
          errorMessage: 'Supplier update karne mein masla: $e');
    }
  }

  // Future<void> updateSupplier(SupplierModel updated) async {
  //   state = state.copyWith(isLoading: true, clearError: true);
  //   try {
  //     final saved = await _repo.update(updated);
  //     final list = state.allSuppliers.map((s) => s.id == saved.id ? saved : s).toList();
  //     state = state.copyWith(allSuppliers: list, isLoading: false);
  //   } catch (e) {
  //     state = state.copyWith(isLoading: false, errorMessage: 'Supplier update karne mein masla: $e');
  //   }
  // }

  Future<void> deleteSupplier(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.softDelete(id);
      final updated = state.allSuppliers.map((s) => s.id == id ? s.copyWith(deletedAt: DateTime.now()) : s).toList();
      state = state.copyWith(allSuppliers: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Supplier delete karne mein masla: $e');
    }
  }

  Future<void> toggleStatus(String id, bool isActive) async {
    try {
      await _repo.toggleStatus(id, isActive);
      final updated = state.allSuppliers.map((s) => s.id == id ? s.copyWith(isActive: isActive) : s).toList();
      state = state.copyWith(allSuppliers: updated, clearError: true);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Status update karne mein masla: $e');
    }
  }

  // ── Ek supplier DB se fresh lao (payment ke baad) ─────────
  // isLoading set NAHI karta — list screen spinner mein na jaye
  Future<void> refreshSupplier(String id) async {
    try {
      final fresh = await _repo.getById(id);
      if (fresh == null) return;
      final list = state.allSuppliers
          .map((s) => s.id == id ? fresh : s)
          .toList();
      state = state.copyWith(allSuppliers: list);
    } catch (_) {
      // Silent — list screen wapsi par loadSuppliers() karti hai
    }
  }

  Future<void> payOutstanding({
    required String supplierId,
    required double amount,
    String?         notes,
    String?         userId,
    String?         userName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repo.payToSupplier(
        supplierId: supplierId,
        amount:     amount,
        notes:      notes,
        userId:     userId,
        userName:   userName,
      );
      // State mein updated supplier replace karo
      final list = state.allSuppliers
          .map((s) => s.id == updated.id ? updated : s)
          .toList();
      state = state.copyWith(allSuppliers: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading:    false,
          errorMessage: 'Payment record karne mein masla: $e');
    }
  }
}

final supplierProvider = StateNotifierProvider<SupplierNotifier, SupplierState>(
      (ref) => SupplierNotifier(SupplierRepository.instance),
);