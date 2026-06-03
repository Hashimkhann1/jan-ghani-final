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
  final String?           errorMessage;

  const BranchState({
    this.allBranches  = const [],
    this.filtered     = const [],
    this.searchQuery  = '',
    this.isLoading    = false,
    this.errorMessage,
  });

  BranchState copyWith({
    List<BranchModel>? allBranches,
    List<BranchModel>? filtered,
    String?            searchQuery,
    bool?              isLoading,
    Object?            errorMessage = _sentinel,
  }) =>
      BranchState(
        allBranches:  allBranches  ?? this.allBranches,
        filtered:     filtered     ?? this.filtered,
        searchQuery:  searchQuery  ?? this.searchQuery,
        isLoading:    isLoading    ?? this.isLoading,
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