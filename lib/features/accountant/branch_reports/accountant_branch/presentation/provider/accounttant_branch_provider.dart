import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/accountant_branch_datasource.dart';
import '../../data/model/accountant_branch_model.dart';


// ── State ─────────────────────────────────────────────────
class BranchState {
  final List<BranchModel> allBranches;
  final List<BranchModel> filtered;
  final String            searchQuery;
  final bool              isLoading;
  final bool              isSaving;     // ✅ NEW
  final String?           errorMessage;

  const BranchState({
    this.allBranches  = const [],
    this.filtered     = const [],
    this.searchQuery  = '',
    this.isLoading    = false,
    this.isSaving     = false,          // ✅ NEW
    this.errorMessage,
  });

  BranchState copyWith({
    List<BranchModel>? allBranches,
    List<BranchModel>? filtered,
    String?            searchQuery,
    bool?              isLoading,
    bool?              isSaving,         // ✅ NEW
    Object?            errorMessage = _sentinel,
  }) =>
      BranchState(
        allBranches:  allBranches  ?? this.allBranches,
        filtered:     filtered     ?? this.filtered,
        searchQuery:  searchQuery  ?? this.searchQuery,
        isLoading:    isLoading    ?? this.isLoading,
        isSaving:     isSaving     ?? this.isSaving,
        errorMessage: errorMessage == _sentinel
            ? this.errorMessage
            : errorMessage as String?,
      );
}

const _sentinel = Object();

// ── Notifier ──────────────────────────────────────────────
class BranchNotifier extends StateNotifier<BranchState> {
  final BranchDatasource _datasource;

  BranchNotifier(this._datasource) : super(const BranchState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final branches = await _datasource.fetchBranches();
      state = state.copyWith(
        allBranches: branches,
        filtered:    _applySearch(branches, state.searchQuery),
        isLoading:   false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: e.toString(),
      );
    }
  }

  // ── NEW: Add branch ─────────────────────────────────────
  Future<bool> addBranch({required String code, required String name, required String address, required String phone,}) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final newBranch = await _datasource.createBranch(
        code:    code.trim(),
        name:    name.trim(),
        address: address.trim(),
        phone:   phone.trim(),
      );

      final updated = [...state.allBranches, newBranch]
        ..sort((a, b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      state = state.copyWith(
        allBranches: updated,
        filtered:    _applySearch(updated, state.searchQuery),
        isSaving:    false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving:     false,
        errorMessage: _friendlyError(e),
      );
      return false;
    }
  }

  String nextBranchCode() {
    const prefix = 'BR-';
    int max = 0;

    for (final b in state.allBranches) {
      final code = b.code.trim().toUpperCase();
      if (code.startsWith(prefix)) {
        final n = int.tryParse(code.substring(prefix.length));
        if (n != null && n > max) max = n;
      }
    }

    final next = max + 1;
    return '$prefix${next.toString().padLeft(3, '0')}';
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('duplicate') ||
        msg.contains('unique') ||
        msg.contains('23505')) {
      return 'Yeh branch code pehle se mojood hai. Koi aur code use karein.';
    }
    return 'Branch save nahi ho saki: $e';
  }

  void search(String q) {
    state = state.copyWith(
      searchQuery: q,
      filtered:    _applySearch(state.allBranches, q),
    );
  }

  void clearError() => state = state.copyWith(errorMessage: null);

  List<BranchModel> _applySearch(List<BranchModel> all, String q) {
    if (q.isEmpty) return all;
    final lower = q.toLowerCase();
    return all.where((b) =>
    b.name.toLowerCase().contains(lower) ||
        b.code.toLowerCase().contains(lower) ||
        b.address.toLowerCase().contains(lower)).toList();
  }
}

// ── Provider ──────────────────────────────────────────────
final branchProvider = StateNotifierProvider.autoDispose
<BranchNotifier, BranchState>((ref) {
  final datasource = BranchDatasource(client: Supabase.instance.client);
  return BranchNotifier(datasource);
});