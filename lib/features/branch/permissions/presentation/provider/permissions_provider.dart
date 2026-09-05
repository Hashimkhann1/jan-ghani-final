import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasource/permissions_remote_datasource.dart';
import '../../domain/permission_catalog.dart';

/// userId → granted permission-keys ( `<module>.<action>` ), plus the
/// bits of UI state (dirty / saving / reset-pending / error) needed to
/// drive the Permissions screen and the sidebar's own permission checks.
class PermissionsState {
  /// userId → granted permission-keys, sirf un users ke liye jinhone
  /// role defaults se hat kar apni customization save ki hai.
  final Map<String, Set<String>> byUser;

  /// userId → kya us user ke toggles chhue gaye / unsaved hain.
  final Set<String> dirtyUsers;

  /// userId → "Reset to role defaults" dabaya gaya hai, Save par yeh
  /// customization poori tarah hata degi (row delete + flag false).
  final Set<String> resetPendingUsers;

  final Set<String> savingUsers;

  final bool    isLoading;
  final bool    loaded;
  final String? loadedStoreId;
  final String? errorMessage;

  const PermissionsState({
    this.byUser            = const {},
    this.dirtyUsers        = const {},
    this.resetPendingUsers = const {},
    this.savingUsers       = const {},
    this.isLoading         = false,
    this.loaded            = false,
    this.loadedStoreId,
    this.errorMessage,
  });

  Set<String> keysFor(String userId, String role) =>
      byUser[userId] ?? PermissionCatalog.defaultsForRole(role);

  bool isGranted(String userId, String role, String permKey) =>
      keysFor(userId, role).contains(permKey);

  bool isDirty(String userId)  => dirtyUsers.contains(userId);
  bool isSaving(String userId) => savingUsers.contains(userId);

  PermissionsState copyWith({
    Map<String, Set<String>>? byUser,
    Set<String>?              dirtyUsers,
    Set<String>?              resetPendingUsers,
    Set<String>?              savingUsers,
    bool?                     isLoading,
    bool?                     loaded,
    String?                   loadedStoreId,
    String?                   errorMessage,
  }) =>
      PermissionsState(
        byUser:            byUser            ?? this.byUser,
        dirtyUsers:        dirtyUsers        ?? this.dirtyUsers,
        resetPendingUsers: resetPendingUsers ?? this.resetPendingUsers,
        savingUsers:       savingUsers       ?? this.savingUsers,
        isLoading:         isLoading         ?? this.isLoading,
        loaded:            loaded            ?? this.loaded,
        loadedStoreId:     loadedStoreId     ?? this.loadedStoreId,
        errorMessage:      errorMessage,
      );
}

class PermissionsNotifier extends StateNotifier<PermissionsState> {
  final PermissionsRemoteDataSource _ds;

  PermissionsNotifier() : _ds = PermissionsRemoteDataSource(),
        super(const PermissionsState());

  Set<String> _current(String userId, String role) =>
      {...state.keysFor(userId, role)};

  void _commit(String userId, Set<String> keys) {
    state = state.copyWith(
      byUser:            {...state.byUser, userId: keys},
      dirtyUsers:        {...state.dirtyUsers, userId},
      resetPendingUsers: {...state.resetPendingUsers}..remove(userId),
    );
  }

  /// Store ke saare customized users DB se load karta hai. Idempotent
  /// hai per store — dobara call karne par sirf refresh karta hai jab
  /// tak `force` na ho (Save/refresh ke baad).
  Future<void> loadForStore(String storeId, {bool force = false}) async {
    if (storeId.isEmpty) return;
    if (!force && state.loaded && state.loadedStoreId == storeId) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final byUser = await _ds.getCustomizedForStore(storeId);
      state = state.copyWith(
        byUser:        byUser,
        isLoading:     false,
        loaded:        true,
        loadedStoreId: storeId,
        dirtyUsers:        const {},
        resetPendingUsers: const {},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Permissions load nahi ho sakin: $e',
      );
    }
  }

  /// Ek single (module.action) toggle.
  void toggle(String userId, String role, String permKey, bool value) {
    final keys = _current(userId, role);
    if (value) {
      keys.add(permKey);
      // Koi bhi action grant karo to `view` bhi apne aap on ho jaye.
      final module = permKey.split('.').first;
      keys.add('$module.${PermAction.view.name}');
    } else {
      keys.remove(permKey);
      // `view` off karo to poora module band.
      if (permKey.endsWith('.${PermAction.view.name}')) {
        final module = permKey.split('.').first;
        keys.removeWhere((k) => k.startsWith('$module.'));
      }
    }
    _commit(userId, keys);
  }

  /// Poore module ki saari actions on/off.
  void toggleModule(
      String userId, String role, PermModule module, bool value) {
    final keys = _current(userId, role);
    for (final a in module.actions) {
      final k = module.actionKey(a);
      value ? keys.add(k) : keys.remove(k);
    }
    _commit(userId, keys);
  }

  /// Poore group ki saari actions on/off.
  void toggleGroup(
      String userId, String role, PermGroup group, bool value) {
    final keys = _current(userId, role);
    for (final m in group.modules) {
      for (final a in m.actions) {
        final k = m.actionKey(a);
        value ? keys.add(k) : keys.remove(k);
      }
    }
    _commit(userId, keys);
  }

  /// Role ke default par wapas (Save dabane par persist hota hai).
  void resetToRoleDefaults(String userId, String role) {
    final map = {...state.byUser}..remove(userId);
    state = state.copyWith(
      byUser:            map,
      dirtyUsers:        {...state.dirtyUsers, userId},
      resetPendingUsers: {...state.resetPendingUsers, userId},
    );
  }

  /// Sab kuch grant.
  void grantAll(String userId, String role) =>
      _commit(userId, PermissionCatalog.allKeys.toSet());

  /// Sab kuch revoke.
  void revokeAll(String userId, String role) => _commit(userId, {});

  /// "Save" — DB par persist karta hai. `true` return karta hai success
  /// par, warna `false` (aur `errorMessage` state me set ho jaata hai).
  Future<bool> save(String userId, String role) async {
    state = state.copyWith(
      savingUsers:  {...state.savingUsers, userId},
      errorMessage: null,
    );
    try {
      if (state.resetPendingUsers.contains(userId)) {
        await _ds.resetToDefaults(userId);
      } else {
        await _ds.save(userId, state.keysFor(userId, role));
      }
      state = state.copyWith(
        dirtyUsers:        {...state.dirtyUsers}..remove(userId),
        resetPendingUsers: {...state.resetPendingUsers}..remove(userId),
        savingUsers:       {...state.savingUsers}..remove(userId),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        savingUsers:  {...state.savingUsers}..remove(userId),
        errorMessage: 'Permissions save nahi ho sakin: $e',
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

final permissionsProvider =
    StateNotifierProvider<PermissionsNotifier, PermissionsState>(
  (ref) => PermissionsNotifier(),
);
