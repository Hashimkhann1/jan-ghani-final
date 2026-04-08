// =============================================================
// supplier_provider.dart
// Riverpod StateNotifier + SupplierState
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jan_ghani_final/features/supplier/data/supplier_dummy_data.dart';
import 'package:jan_ghani_final/features/supplier/domian/supplier_model.dart';

// ─────────────────────────────────────────────────────────────
// STATE CLASS
// ─────────────────────────────────────────────────────────────

class SupplierState {
  final List<SupplierModel> allSuppliers;  // DB se aaye hue sab suppliers
  final String searchQuery;               // search field ki value
  final String filterStatus;              // 'all' | 'active' | 'inactive'
  final bool isLoading;                   // DB call chal rahi hai
  final String? errorMessage;             // koi error ayi to yahan

  const SupplierState({
    this.allSuppliers   = const [],
    this.searchQuery    = '',
    this.filterStatus   = 'all',
    this.isLoading      = false,
    this.errorMessage,
  });

  // ── Filtered list (search + status dono apply hote hain) ──
  List<SupplierModel> get filteredSuppliers {
    return allSuppliers.where((s) {
      // 1. Soft-deleted suppliers kabhi show mat karo
      if (s.deletedAt != null) return false;

      // 2. Status filter
      if (filterStatus == 'active'   && !s.isActive) return false;
      if (filterStatus == 'inactive' &&  s.isActive) return false;

      // 3. Search — name, contactPerson, phone, address mein dhundho
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return s.name.toLowerCase().contains(q) ||
            (s.contactPerson?.toLowerCase().contains(q) ?? false) ||
            s.phone.contains(q) ||
            (s.address?.toLowerCase().contains(q) ?? false);
      }

      return true;
    }).toList();
  }

  // ── Summary stats (stats cards ke liye) ───────────────────

  int    get totalCount       => allSuppliers.where((s) => s.deletedAt == null).length;
  int    get activeCount      => allSuppliers.where((s) => s.isActive && s.deletedAt == null).length;
  double get totalPurchased   => allSuppliers.fold(0, (sum, s) => sum + s.totalPurchaseAmount);
  double get totalOutstanding => allSuppliers.fold(0, (sum, s) => sum + s.outstandingBalance.clamp(0, double.infinity));

  // ── copyWith ───────────────────────────────────────────────
  SupplierState copyWith({
    List<SupplierModel>? allSuppliers,
    String?              searchQuery,
    String?              filterStatus,
    bool?                isLoading,
    String?              errorMessage,
  }) {
    return SupplierState(
      allSuppliers:  allSuppliers  ?? this.allSuppliers,
      searchQuery:   searchQuery   ?? this.searchQuery,
      filterStatus:  filterStatus  ?? this.filterStatus,
      isLoading:     isLoading     ?? this.isLoading,
      errorMessage:  errorMessage  ?? this.errorMessage,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────

class SupplierNotifier extends StateNotifier<SupplierState> {
  SupplierNotifier() : super(const SupplierState()) {
    loadSuppliers();
  }

  /// Suppliers load karo — abhi dummy data, baad mein Drift DB
  Future<void> loadSuppliers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // TODO: yahan Drift ka repository call aayega
      // final suppliers = await supplierRepository.getAll(tenantId);
      await Future.delayed(const Duration(milliseconds: 300)); // dummy delay
      state = state.copyWith(
        allSuppliers: supplierDummyData,
        isLoading:    false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Suppliers load karne mein masla: $e',
      );
    }
  }

  /// Search query update karo
  void onSearchChanged(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Status filter change karo ('all' | 'active' | 'inactive')
  void onFilterChanged(String filter) {
    state = state.copyWith(filterStatus: filter);
  }

  /// Supplier soft-delete karo (DB mein deleted_at set hoga)
  Future<void> deleteSupplier(String id) async {
    // TODO: Drift ke zariye DB mein soft delete karo
    // await supplierRepository.softDelete(id);

    // UI update: us supplier ko list se hata do
    final updated = state.allSuppliers
        .map((s) => s.id == id
        ? s.copyWith() // yahan deletedAt set karo jab DB ready ho
        : s)
        .where((s) => s.id != id) // filhal sirf list se hata raha hoon
        .toList();

    state = state.copyWith(allSuppliers: updated);
  }

  /// Naya supplier add karo
  Future<void> addSupplier(SupplierModel supplier) async {
    // TODO: Drift ke zariye DB mein save karo
    // await supplierRepository.insert(supplier);
    state = state.copyWith(
      allSuppliers: [...state.allSuppliers, supplier],
    );
  }

  /// Existing supplier update karo
  Future<void> updateSupplier(SupplierModel updated) async {
    // TODO: Drift ke zariye DB mein update karo
    // await supplierRepository.update(updated);
    final list = state.allSuppliers
        .map((s) => s.id == updated.id ? updated : s)
        .toList();
    state = state.copyWith(allSuppliers: list);
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────

/// Main supplier provider — poori app mein yahi use karo
final supplierProvider =
StateNotifierProvider<SupplierNotifier, SupplierState>(
      (ref) => SupplierNotifier(),
);