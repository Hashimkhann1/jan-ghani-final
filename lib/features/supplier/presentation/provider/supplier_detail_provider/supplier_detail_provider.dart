// =============================================================
// supplier_detail_provider.dart
// Supplier detail screen ka Riverpod State + Notifier + Provider
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jan_ghani_final/features/supplier/data/supplier_detail_dummy_data.dart';
import 'package:jan_ghani_final/features/supplier/domian/supplier_detail_models.dart';

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────

class SupplierDetailState {
  final List<SupplierLedgerEntry>   ledgerEntries;
  final List<SupplierPurchaseOrder> purchaseOrders;
  final SupplierFinancialSummary?   financialSummary;
  final bool                        isLoading;
  final String?                     errorMessage;
  final String                      activeTab; // 'ledger' | 'orders'

  const SupplierDetailState({
    this.ledgerEntries    = const [],
    this.purchaseOrders   = const [],
    this.financialSummary,
    this.isLoading        = false,
    this.errorMessage,
    this.activeTab        = 'ledger',
  });

  SupplierDetailState copyWith({
    List<SupplierLedgerEntry>?   ledgerEntries,
    List<SupplierPurchaseOrder>? purchaseOrders,
    SupplierFinancialSummary?    financialSummary,
    bool?                        isLoading,
    String?                      errorMessage,
    String?                      activeTab,
  }) {
    return SupplierDetailState(
      ledgerEntries:    ledgerEntries    ?? this.ledgerEntries,
      purchaseOrders:   purchaseOrders   ?? this.purchaseOrders,
      financialSummary: financialSummary ?? this.financialSummary,
      isLoading:        isLoading        ?? this.isLoading,
      errorMessage:     errorMessage     ?? this.errorMessage,
      activeTab:        activeTab        ?? this.activeTab,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────

class SupplierDetailNotifier extends StateNotifier<SupplierDetailState> {
  SupplierDetailNotifier() : super(const SupplierDetailState());

  /// Supplier ka data load karo supplierId se
  Future<void> loadData(String supplierId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // TODO: Drift se real data:
      // final ledger  = await ledgerRepo.getBySupplierId(supplierId);
      // final orders  = await poRepo.getBySupplierId(supplierId);
      // final summary = await balanceRepo.getSummary(supplierId);

      await Future.delayed(const Duration(milliseconds: 250));

      state = state.copyWith(
        ledgerEntries:    dummyLedgerEntries,
        purchaseOrders:   dummyPurchaseOrders,
        financialSummary: dummyFinancialSummary,
        isLoading:        false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Data load karne mein masla: $e',
      );
    }
  }

  /// Tab switch karo
  void switchTab(String tab) => state = state.copyWith(activeTab: tab);
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────

/// autoDispose — screen close hone pe automatically dispose hoga
final supplierDetailProvider =
StateNotifierProvider.autoDispose<SupplierDetailNotifier, SupplierDetailState>(
      (ref) => SupplierDetailNotifier(),
);