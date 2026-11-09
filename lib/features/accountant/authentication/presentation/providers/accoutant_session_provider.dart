import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/accountant_user_entity.dart';

/// Dual-account user abhi kaun sa account use kar raha hai.
enum AccountMode { staff, customer }

// ── Session State ─────────────────────────────────────────
class SessionState {
  final AccountantUserEntity? user;

  /// null = abhi chuna nahi (dual user ko chooser dikhega).
  final AccountMode? mode;
  final bool isRestoring; // ✅ SharedPrefs se restore ho raha hai?

  const SessionState({
    this.user,
    this.mode,
    this.isRestoring = true, // default: true (app start pe)
  });

  SessionState copyWith({
    AccountantUserEntity? user,
    AccountMode? mode,
    bool clearMode = false,
    bool clearUser = false,
    bool? isRestoring,
  }) =>
      SessionState(
        user:        clearUser ? null : user ?? this.user,
        mode:        (clearUser || clearMode) ? null : mode ?? this.mode,
        isRestoring: isRestoring ?? this.isRestoring,
      );
}

// ── Notifier ──────────────────────────────────────────────
class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(const SessionState(isRestoring: true)) {
    _restoreSession();
  }

  static const _kId            = 'session_id';
  static const _kFullName      = 'session_full_name';
  static const _kEmail         = 'session_email';
  static const _kRole          = 'session_role';
  static const _kBranchId      = 'session_branch_id';
  static const _kWarehouseId   = 'session_warehouse_id';
  static const _kCustomerToken = 'session_customer_token';
  static const _kIsActive      = 'session_is_active';
  static const _kCreatedAt     = 'session_created_at';
  static const _kMode          = 'session_account_mode';

  static String? _nullIfEmpty(String? v) => (v == null || v.isEmpty) ? null : v;

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kId);

    if (id == null || id.isEmpty) {
      // Koi session nahi — restore done, user null
      state = state.copyWith(isRestoring: false, clearUser: true);
      return;
    }

    final branchIdRaw = prefs.getString(_kBranchId);
    final modeRaw     = prefs.getString(_kMode);

    state = state.copyWith(
      isRestoring: false,
      mode: AccountMode.values.where((m) => m.name == modeRaw).firstOrNull,
      user: AccountantUserEntity(
        id:            id,
        fullName:      prefs.getString(_kFullName)      ?? '',
        email:         prefs.getString(_kEmail)         ?? '',
        role:          prefs.getString(_kRole)          ?? '',
        branchId:      (branchIdRaw == null || branchIdRaw.isEmpty)
            ? null
            : branchIdRaw, // ✅ empty string → null
        warehouseId:   prefs.getString(_kWarehouseId),
        customerToken: prefs.getString(_kCustomerToken),
        isActive:      prefs.getBool(_kIsActive)        ?? true,
        createdAt:     DateTime.tryParse(
            prefs.getString(_kCreatedAt) ?? '') ??
            DateTime.now(),
      ),
    );
  }

  /// Naya login / profile refresh: account ka intekhab dobara hoga.
  Future<void> setUser(AccountantUserEntity user) async {
    state = state.copyWith(user: user, clearMode: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kMode);
    await prefs.setString(_kId,            user.id);
    await prefs.setString(_kFullName,      user.fullName);
    await prefs.setString(_kEmail,         user.email);
    await prefs.setString(_kRole,          user.role);
    await prefs.setString(_kBranchId,      user.branchId      ?? '');
    await prefs.setString(_kWarehouseId,   user.warehouseId   ?? '');
    await prefs.setString(_kCustomerToken, user.customerToken ?? '');
    await prefs.setBool(  _kIsActive,      user.isActive);
    await prefs.setString(_kCreatedAt,     user.createdAt.toIso8601String());
  }

  /// Choose / switch account. null = chooser dobara dikhao.
  Future<void> setMode(AccountMode? mode) async {
    state = mode == null
        ? state.copyWith(clearMode: true)
        : state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    if (mode == null) {
      await prefs.remove(_kMode);
    } else {
      await prefs.setString(_kMode, mode.name);
    }
  }

  Future<void> clear() async {
    state = state.copyWith(clearUser: true, isRestoring: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kId);
    await prefs.remove(_kFullName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kRole);
    await prefs.remove(_kBranchId);
    await prefs.remove(_kWarehouseId);
    await prefs.remove(_kCustomerToken);
    await prefs.remove(_kIsActive);
    await prefs.remove(_kCreatedAt);
    await prefs.remove(_kMode);
  }
}

// ── Providers ─────────────────────────────────────────────
final sessionProvider =
StateNotifierProvider<SessionNotifier, SessionState>(
      (ref) => SessionNotifier(),
);

// Convenience providers
final currentUserProvider = Provider<AccountantUserEntity?>(
      (ref) => ref.watch(sessionProvider).user,
);

final currentRoleProvider = Provider<String?>(
      (ref) => ref.watch(sessionProvider).user?.role,
);

final currentBranchIdProvider = Provider<String?>(
      (ref) => ref.watch(sessionProvider).user?.branchId,
);

final isRestoringSessionProvider = Provider<bool>(
      (ref) => ref.watch(sessionProvider).isRestoring,
);

final isLoggedInProvider = Provider<bool>(
      (ref) => ref.watch(sessionProvider).user != null,
);