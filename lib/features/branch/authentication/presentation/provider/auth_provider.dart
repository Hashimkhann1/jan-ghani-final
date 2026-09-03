import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/service/session/session_service.dart';
import '../../../store_user/data/model/user_model.dart';
import '../../data/datasource/auth_remote_datasource.dart';

class AuthState {
  final UserModel? user;
  final bool       isLoading;
  final String?    errorMessage;
  final bool       isLoggedIn;
  final bool?      hasBranch;      // null = still checking
  final bool       checkFailed;   // true = DB unreachable during init

  const AuthState({
    this.user,
    this.isLoading    = false,
    this.errorMessage,
    this.isLoggedIn   = false,
    this.hasBranch,
    this.checkFailed  = false,
  });

  String  get userId    => user?.id        ?? '';
  String  get storeId   => user?.storeId   ?? '';
  String  get role      => user?.role      ?? '';
  String  get username  => user?.username  ?? '';
  String  get fullName  => user?.fullName  ?? '';
  String? get counterId => user?.counterId;

  bool get isOwner   => user?.isOwner   ?? false;
  bool get isManager => user?.isManager ?? false;
  bool get isCashier => user?.isCashier ?? false;
  bool get isStock   => user?.isStock   ?? false;

  AuthState copyWith({
    UserModel? user,
    bool?      isLoading,
    String?    errorMessage,
    bool?      isLoggedIn,
    bool?      hasBranch,
    bool?      checkFailed,
  }) => AuthState(
    user:         user         ?? this.user,
    isLoading:    isLoading    ?? this.isLoading,
    errorMessage: errorMessage,          // transient: cleared unless passed
    isLoggedIn:   isLoggedIn   ?? this.isLoggedIn,
    hasBranch:    hasBranch    ?? this.hasBranch,
    checkFailed:  checkFailed  ?? this.checkFailed,
  );
}


class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRemoteDataSource _ds;

  AuthNotifier(): _ds = AuthRemoteDataSource(), super(const AuthState()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    state = state.copyWith(isLoading: true, checkFailed: false);
    try {
      final branchExists = await _ds.hasBranchData();

      if (!branchExists) {
        state = state.copyWith(isLoading: false, hasBranch: false);
        return;
      }

      final loggedIn = await SessionService.isLoggedIn();
      if (!loggedIn) {
        state = state.copyWith(isLoading: false, hasBranch: true);
        return;
      }

      final session = await SessionService.getSession();
      final userId  = session['user_id'] ?? '';

      // Re-validate the stored session against the DB so a deactivated or
      // deleted account (or a changed role/counter) does not stay logged in.
      UserModel? user;
      try {
        user = userId.isEmpty ? null : await _ds.getActiveById(userId);
      } catch (e) {
        // Transient read failure — fall back to the cached session instead of
        // logging the user out or nuking their stored credentials.
        if (kDebugMode) debugPrint('session revalidate failed: $e');
        state = state.copyWith(
          user:       _userFromSession(session),
          isLoggedIn: true,
          isLoading:  false,
          hasBranch:  true,
        );
        return;
      }

      if (user == null) {
        await SessionService.clearSession();
        state = state.copyWith(isLoading: false, hasBranch: true, isLoggedIn: false);
        return;
      }

      // Refresh the cached session with the current DB values.
      await SessionService.saveSession(
        userId:    user.id,
        storeId:   user.storeId,
        role:      user.role,
        username:  user.username,
        fullName:  user.fullName,
        counterId: user.counterId,
      );

      state = state.copyWith(
        user:       user,
        isLoggedIn: true,
        isLoading:  false,
        hasBranch:  true,
      );
    } on AuthConnectionException catch (e) {
      if (kDebugMode) debugPrint('auth init failed: $e');
      state = state.copyWith(isLoading: false, checkFailed: true);
    } catch (e) {
      if (kDebugMode) debugPrint('auth init failed: $e');
      state = state.copyWith(isLoading: false, checkFailed: true);
    }
  }

  /// Retry the branch/session check after a connection failure.
  Future<void> retryInit() => _restoreSession();

  UserModel _userFromSession(Map<String, String?> session) => UserModel(
        id:           session['user_id']   ?? '',
        storeId:      session['store_id']  ?? '',
        username:     session['username']  ?? '',
        passwordHash: '',
        fullName:     session['full_name'] ?? '',
        role:         session['role']      ?? 'cashier',
        isActive:     true,
        counterId:    session['counter_id'],
        createdAt:    DateTime.now(),
        updatedAt:    DateTime.now(),
      );

  // ── LOGIN ─────────────────────────────────────────────────
  Future<void> login(String username, String password) async {
    if (state.isLoading) return; // guard against double submit
    state = state.copyWith(isLoading: true);
    try {
      final user = await _ds.login(username, password);

      if (user == null) {
        state = state.copyWith(
          isLoading:    false,
          errorMessage: 'Username ya password galat hai',
        );
        return;
      }

      await SessionService.saveSession(
        userId:    user.id,
        storeId:   user.storeId,
        role:      user.role,
        username:  user.username,
        fullName:  user.fullName,
        counterId: user.counterId,
      );

      state = state.copyWith(
        user:       user,
        isLoggedIn: true,
        isLoading:  false,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('login error: $e');
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Login nahi ho saka. Connection check karein.',
      );
    }
  }

  // ── LOGOUT ────────────────────────────────────────────────
  Future<void> logout() async {
    await SessionService.clearSession();
    state = AuthState(hasBranch: state.hasBranch);
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
      (ref) => AuthNotifier(),
);
