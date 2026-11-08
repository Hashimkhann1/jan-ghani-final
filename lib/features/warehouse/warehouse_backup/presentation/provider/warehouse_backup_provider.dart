// Updated on 2026-11-08 09:48 AM
// =============================================================
// warehouse_backup_provider.dart
// Backup screen ka state — history, chuna hua folder, backup chal raha hai?
// Aakhri chuna folder SharedPreferences mein yaad (har computer ka apna).
// =============================================================

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/warehouse/auth/local/auth_local_storage.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_backup/data/warehouse_backup_repository.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_backup/domain/warehouse_backup_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLastFolderKey = 'warehouse_backup_last_folder';

class WarehouseBackupState {
  final List<WarehouseBackupRecord> history;
  final bool    isLoading;
  final bool    isBackingUp;
  final String? folderPath;
  final String? errorMessage;

  const WarehouseBackupState({
    this.history      = const [],
    this.isLoading    = false,
    this.isBackingUp  = false,
    this.folderPath,
    this.errorMessage,
  });

  /// Aakhri KAMYAB backup (last backup card)
  WarehouseBackupRecord? get lastSuccess {
    for (final r in history) {
      if (r.isSuccess) return r;
    }
    return null;
  }

  int get successCount => history.where((r) => r.isSuccess).length;
  int get failedCount  => history.length - successCount;

  WarehouseBackupState copyWith({
    List<WarehouseBackupRecord>? history,
    bool?   isLoading,
    bool?   isBackingUp,
    String? folderPath,
    String? errorMessage,
    bool    clearError = false,
  }) {
    return WarehouseBackupState(
      history:      history     ?? this.history,
      isLoading:    isLoading   ?? this.isLoading,
      isBackingUp:  isBackingUp ?? this.isBackingUp,
      folderPath:   folderPath  ?? this.folderPath,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class WarehouseBackupNotifier extends StateNotifier<WarehouseBackupState> {
  WarehouseBackupNotifier() : super(const WarehouseBackupState()) {
    _init();
  }

  final _repo = WarehouseBackupRepository.instance;

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kLastFolderKey);
      if (saved != null && saved.isNotEmpty && mounted) {
        state = state.copyWith(folderPath: saved);
      }
    } catch (_) {}
    await load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getHistory();
      if (!mounted) return;
      state = state.copyWith(history: list, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
          isLoading: false, errorMessage: 'Record load nahi hua: $e');
    }
  }

  /// Folder chunne ka dialog — chuna to yaad rakho
  Future<void> pickFolder() async {
    try {
      final path = await getDirectoryPath(
        initialDirectory:  state.folderPath,
        confirmButtonText: 'Yeh folder chunein',
      );
      if (path == null || path.isEmpty) return; // cancel
      state = state.copyWith(folderPath: path, clearError: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastFolderKey, path);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Folder nahi chuna ja saka: $e');
    }
  }

  /// Backup lo — record return (success / failed dono), null = shuru hi nahi hua
  Future<WarehouseBackupRecord?> runBackup() async {
    final folder = state.folderPath;
    if (folder == null || folder.isEmpty || state.isBackingUp) return null;

    state = state.copyWith(isBackingUp: true, clearError: true);
    try {
      final user = await AuthLocalStorage.loadUser();
      final record = await _repo.createBackup(
        folderPath: folder,
        userId:     user?['id']?.toString(),
        userName:   user?['full_name']?.toString(),
      );
      if (!mounted) return record;
      state = state.copyWith(
        isBackingUp: false,
        history:     [record, ...state.history],
      );
      return record;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
            isBackingUp: false, errorMessage: 'Backup record save nahi hua: $e');
      }
      return null;
    }
  }

  Future<void> openFolder(String path) async {
    try {
      await _repo.openFolder(path);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Folder khul nahi saka: $e');
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final warehouseBackupProvider =
    StateNotifierProvider<WarehouseBackupNotifier, WarehouseBackupState>(
        (ref) => WarehouseBackupNotifier());
