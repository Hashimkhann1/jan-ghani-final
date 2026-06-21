import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/backup_datasource.dart';
import '../../data/model/backup_progress_model.dart';
import '../../data/model/branch_backup_model.dart';


// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────
class BackupState {
  final List<BackupBranchModel> branches;
  final BackupBranchModel? selectedBranch;
  final bool isLoadingBranches;

  // backup progress
  final bool isBackingUp;
  final bool backupDone;
  final BackupProgress progress;
  final String? errorMessage;

  const BackupState({
    this.branches = const [],
    this.selectedBranch,
    this.isLoadingBranches = false,
    this.isBackingUp = false,
    this.backupDone = false,
    this.progress = const BackupProgress(),
    this.errorMessage,
  });

  BackupState copyWith({
    List<BackupBranchModel>? branches,
    BackupBranchModel? selectedBranch,
    bool clearSelectedBranch = false,
    bool? isLoadingBranches,
    bool? isBackingUp,
    bool? backupDone,
    BackupProgress? progress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BackupState(
      branches: branches ?? this.branches,
      selectedBranch: clearSelectedBranch
          ? null
          : (selectedBranch ?? this.selectedBranch),
      isLoadingBranches: isLoadingBranches ?? this.isLoadingBranches,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      backupDone: backupDone ?? this.backupDone,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────
class BackupNotifier extends StateNotifier<BackupState> {
  final BackupDatasource _ds;

  BackupNotifier(this._ds) : super(const BackupState()) {
    _loadBranches();
  }

  // ── Load branches ──────────────────────────────────────────────────────────
  Future<void> _loadBranches() async {
    state = state.copyWith(isLoadingBranches: true, clearError: true);
    try {
      final branches = await _ds.fetchBranches();
      state = state.copyWith(
        branches: branches,
        isLoadingBranches: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingBranches: false,
        errorMessage: 'Branches load nahi huin: $e',
      );
    }
  }

  // ── Select branch ──────────────────────────────────────────────────────────
  void selectBranch(BackupBranchModel? branch) {
    state = state.copyWith(
      selectedBranch: branch,
      backupDone: false,
      progress: const BackupProgress(),
      clearError: true,
    );
  }

  // ── Start backup — stream based ────────────────────────────────────────────
  Future<void> performBackup() async {
    if (state.selectedBranch == null) {
      state = state.copyWith(errorMessage: 'Pehle branch select karo');
      return;
    }

    state = state.copyWith(
      isBackingUp: true,
      backupDone: false,
      progress: const BackupProgress(),
      clearError: true,
    );

    try {
      await for (final progress in _ds.performBackup(
        branchId: state.selectedBranch!.id,
      )) {
        state = state.copyWith(progress: progress);
      }

      // Done!
      state = state.copyWith(
        isBackingUp: false,
        backupDone: true,
      );
    } catch (e) {
      state = state.copyWith(
        isBackingUp: false,
        errorMessage: 'Backup fail ho gaya: $e',
      );
    }
  }

  void reset() {
    state = state.copyWith(
      backupDone: false,
      progress: const BackupProgress(),
      clearError: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────
final backupDatasourceProvider = Provider<BackupDatasource>((ref) {
  return BackupDatasource(Supabase.instance.client);
});

final backupProvider =
StateNotifierProvider<BackupNotifier, BackupState>((ref) {
  return BackupNotifier(ref.watch(backupDatasourceProvider));
});