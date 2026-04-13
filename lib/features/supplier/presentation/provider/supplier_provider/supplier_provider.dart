// =============================================================
// supplier_provider.dart
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jan_ghani_final/features/supplier/data/supplier_repository.dart';
import 'package:jan_ghani_final/features/supplier/domian/supplier_model.dart';

class SupplierState {
  final List<SupplierModel> allSuppliers;
  final String              searchQuery;
  final String              filterStatus;
  final bool                isLoading;
  final String?             errorMessage;

  const SupplierState({
    this.allSuppliers = const [],
    this.searchQuery  = '',
    this.filterStatus = 'all',
    this.isLoading    = false,
    this.errorMessage,
  });

  List<SupplierModel> get filteredSuppliers {
    return allSuppliers.where((s) {
      if (s.deletedAt != null) return false;
      if (filterStatus == 'active'   && !s.isActive) return false;
      if (filterStatus == 'inactive' &&  s.isActive) return false;
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

  int    get totalCount       => allSuppliers.where((s) => s.deletedAt == null).length;
  int    get activeCount      => allSuppliers.where((s) => s.isActive && s.deletedAt == null).length;
  double get totalPurchased   => allSuppliers.fold(0, (sum, s) => sum + s.totalPurchaseAmount);
  double get totalOutstanding => allSuppliers.fold(0, (sum, s) => sum + s.outstandingBalance.clamp(0, double.infinity));

  SupplierState copyWith({
    List<SupplierModel>? allSuppliers,
    String?              searchQuery,
    String?              filterStatus,
    bool?                isLoading,
    String?              errorMessage,
  }) {
    return SupplierState(
      allSuppliers: allSuppliers ?? this.allSuppliers,
      searchQuery:  searchQuery  ?? this.searchQuery,
      filterStatus: filterStatus ?? this.filterStatus,
      isLoading:    isLoading    ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SupplierNotifier extends StateNotifier<SupplierState> {
  final SupplierRepository _repo;
  SupplierNotifier(this._repo) : super(const SupplierState()) {
    loadSuppliers();
  }

  Future<void> loadSuppliers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final suppliers = await _repo.getAll();
      state = state.copyWith(allSuppliers: suppliers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Suppliers load karne mein masla: $e');
    }
  }

  void onSearchChanged(String query) => state = state.copyWith(searchQuery: query);
  void onFilterChanged(String filter) => state = state.copyWith(filterStatus: filter);

  Future<void> addSupplier(SupplierModel supplier, {double openingBalance = 0}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final saved = await _repo.insert(supplier, openingBalance: openingBalance);
      state = state.copyWith(allSuppliers: [...state.allSuppliers, saved], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Supplier save karne mein masla: $e');
    }
  }

  Future<void> updateSupplier(SupplierModel updated) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final saved = await _repo.update(updated);
      final list = state.allSuppliers.map((s) => s.id == saved.id ? saved : s).toList();
      state = state.copyWith(allSuppliers: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Supplier update karne mein masla: $e');
    }
  }

  Future<void> deleteSupplier(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
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
      state = state.copyWith(allSuppliers: updated);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Status update karne mein masla: $e');
    }
  }

  Future<void> payOutstanding({
    required String supplierId,
    required double amount,
    String?         notes,
    String?         userId,
    String?         userName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repo.payToSupplier(
        supplierId: supplierId,
        amount:     amount,
        notes:      notes,
        userId:     userId,
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