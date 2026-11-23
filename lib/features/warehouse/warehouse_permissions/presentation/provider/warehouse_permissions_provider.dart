// Updated on 2026-11-22 06:03 PM
// =============================================================
// warehouse_permissions_provider.dart (S31)
//
//   • warehousePermissionsProvider — Permissions screen ka state
//       saved  = DB mein jo hai (sidebar / buttons isi se chalte)
//       draft  = editor ke unsaved toggles (Save par DB)
//   • warehouseAccessProvider — logged-in user ka access:
//       ref.watch(warehouseAccessProvider).can('supplier.pay')
//     Owner hamesha true. Unsaved draft ka koi asar nahi.
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/warehouse/auth/presentation/provider/auth_provider.dart';

import '../../data/warehouse_permissions_datasource.dart';
import '../../domain/warehouse_permission_catalog.dart';

class WarehousePermissionsState {
  /// DB mein saved customization (sirf customized users).
  final Map<String, Set<String>> saved;

  /// Editor ke unsaved changes (userId → keys). Reset pending users
  /// ka entry yahan nahi hota.
  final Map<String, Set<String>> draft;

  /// "Role defaults par wapas" dabaya — Save par row delete.
  final Set<String> resetPending;

  final Set<String> saving;
  final bool    isLoading;
  final bool    loaded;
  final String? errorMessage;

  const WarehousePermissionsState({
    this.saved        = const {},
    this.draft        = const {},
    this.resetPending = const {},
    this.saving       = const {},
    this.isLoading    = false,
    this.loaded       = false,
    this.errorMessage,
  });

  /// DB wala access (sidebar / buttons).
  Set<String> savedKeysFor(String userId, String role) {
    if (WarehousePermissionCatalog.isFullAccessRole(role)) {
      return WarehousePermissionCatalog.allKeys.toSet();
    }
    return saved[userId] ?? WarehousePermissionCatalog.defaultsForRole(role);
  }

  /// Editor mein jo dikhana hai (draft > reset > saved).
  Set<String> editKeysFor(String userId, String role) {
    if (WarehousePermissionCatalog.isFullAccessRole(role)) {
      return WarehousePermissionCatalog.allKeys.toSet();
    }
    if (draft.containsKey(userId)) return draft[userId]!;
    if (resetPending.contains(userId)) {
      return WarehousePermissionCatalog.defaultsForRole(role);
    }
    return savedKeysFor(userId, role);
  }

  bool isDirty(String userId) =>
      draft.containsKey(userId) || resetPending.contains(userId);
  bool isSaving(String userId)     => saving.contains(userId);
  bool isCustomized(String userId) => saved.containsKey(userId);

  WarehousePermissionsState copyWith({
    Map<String, Set<String>>? saved,
    Map<String, Set<String>>? draft,
    Set<String>?              resetPending,
    Set<String>?              saving,
    bool?                     isLoading,
    bool?                     loaded,
    String?                   errorMessage,
    bool                      clearError = false,
  }) =>
      WarehousePermissionsState(
        saved:        saved        ?? this.saved,
        draft:        draft        ?? this.draft,
        resetPending: resetPending ?? this.resetPending,
        saving:       saving       ?? this.saving,
        isLoading:    isLoading    ?? this.isLoading,
        loaded:       loaded       ?? this.loaded,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class WarehousePermissionsNotifier
    extends StateNotifier<WarehousePermissionsState> {
  WarehousePermissionsNotifier(this._ref)
      : super(const WarehousePermissionsState());

  final Ref _ref;
  final _ds = WarehousePermissionsDatasource.instance;

  /// DB se load. `force` = refresh (unsaved draft bhi saaf).
  Future<void> load({bool force = false}) async {
    if (state.isLoading) return;
    if (state.loaded && !force) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final saved = await _ds.getCustomized();
      state = state.copyWith(
        saved:        saved,
        draft:        const {},
        resetPending: const {},
        isLoading:    false,
        loaded:       true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Permissions load nahi ho sakin: $e',
      );
    }
  }

  void _commit(String userId, Set<String> keys) {
    state = state.copyWith(
      draft:        {...state.draft, userId: keys},
      resetPending: {...state.resetPending}..remove(userId),
    );
  }

  /// Ek action on/off. Koi action on → `view` bhi on; `view` off →
  /// poora module band.
  void toggle(String userId, String role, WhPermModule m,
      WhPermAction a, bool value) {
    final keys = {...state.editKeysFor(userId, role)};
    if (value) {
      keys
        ..add(m.actionKey(a))
        ..add(m.viewKey);
    } else if (a.key == WhPermAction.view.key) {
      keys.removeWhere((k) => k.startsWith('${m.key}.'));
    } else {
      keys.remove(m.actionKey(a));
    }
    _commit(userId, keys);
  }

  /// Poore module ke saare actions on/off.
  void toggleModule(String userId, String role, WhPermModule m, bool value) {
    final keys = {...state.editKeysFor(userId, role)};
    for (final a in m.actions) {
      value ? keys.add(m.actionKey(a)) : keys.remove(m.actionKey(a));
    }
    _commit(userId, keys);
  }

  /// Poore group ke saare actions on/off.
  void toggleGroup(String userId, String role, WhPermGroup g, bool value) {
    final keys = {...state.editKeysFor(userId, role)};
    for (final m in g.modules) {
      for (final a in m.actions) {
        value ? keys.add(m.actionKey(a)) : keys.remove(m.actionKey(a));
      }
    }
    _commit(userId, keys);
  }

  void grantAll(String userId) =>
      _commit(userId, WarehousePermissionCatalog.allKeys.toSet());

  void revokeAll(String userId) => _commit(userId, <String>{});

  /// Doosre user ka access copy (draft mein — Save karna hoga).
  void copyFrom(String userId, String fromUserId, String fromRole) =>
      _commit(userId, {...state.savedKeysFor(fromUserId, fromRole)});

  void resetToRoleDefaults(String userId) {
    state = state.copyWith(
      draft:        {...state.draft}..remove(userId),
      resetPending: {...state.resetPending, userId},
    );
  }

  /// Unsaved changes chhod do.
  void discard(String userId) {
    state = state.copyWith(
      draft:        {...state.draft}..remove(userId),
      resetPending: {...state.resetPending}..remove(userId),
    );
  }

  /// DB par save. `true` = kamyab.
  Future<bool> save(String userId, String role) async {
    if (WarehousePermissionCatalog.isFullAccessRole(role)) return false;
    state = state.copyWith(
      saving: {...state.saving, userId}, clearError: true);
    try {
      final by = _ref.read(authProvider).user;
      final saved = {...state.saved};
      if (state.resetPending.contains(userId)) {
        await _ds.resetToDefaults(userId);
        saved.remove(userId);
      } else {
        final keys = state.editKeysFor(userId, role);
        await _ds.save(userId, keys,
            byUserId: by?.id, byUserName: by?.fullName);
        saved[userId] = {...keys};
      }
      state = state.copyWith(
        saved:        saved,
        draft:        {...state.draft}..remove(userId),
        resetPending: {...state.resetPending}..remove(userId),
        saving:       {...state.saving}..remove(userId),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        saving:       {...state.saving}..remove(userId),
        errorMessage: 'Permissions save nahi ho sakin: $e',
      );
      return false;
    }
  }
}

final warehousePermissionsProvider = StateNotifierProvider<
    WarehousePermissionsNotifier, WarehousePermissionsState>(
  (ref) => WarehousePermissionsNotifier(ref),
);

// ─────────────────────────────────────────────────────────────
// Logged-in user ka access
// ─────────────────────────────────────────────────────────────
class WarehouseAccess {
  final Set<String> keys;
  final bool        fullAccess;

  const WarehouseAccess({required this.keys, required this.fullAccess});

  /// `can('supplier.pay')`
  bool can(String permKey) => fullAccess || keys.contains(permKey);

  /// `canView('supplier')` = `supplier.view`
  bool canView(String moduleKey) => can('$moduleKey.view');
}

final warehouseAccessProvider = Provider<WarehouseAccess>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) {
    return const WarehouseAccess(keys: {}, fullAccess: false);
  }
  final perms = ref.watch(warehousePermissionsProvider);
  return WarehouseAccess(
    keys:       perms.savedKeysFor(user.id, user.role),
    fullAccess: WarehousePermissionCatalog.isFullAccessRole(user.role),
  );
});
