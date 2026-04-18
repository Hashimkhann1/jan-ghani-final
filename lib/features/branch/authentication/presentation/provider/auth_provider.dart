import 'package:flutter_riverpod/legacy.dart';
import '../../../../../core/service/session/session_service.dart';
import '../../../store_user/data/model/user_model.dart';
import '../../data/datasource/auth_remote_datasource.dart';

class AuthState {
  final UserModel? user;
  final bool       isLoading;
  final String?    errorMessage;
  final bool       isLoggedIn;

  const AuthState({
    this.user,
    this.isLoading    = false,
    this.errorMessage,
    this.isLoggedIn   = false,
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
  }) => AuthState(
    user:         user         ?? this.user,
    isLoading:    isLoading    ?? this.isLoading,
    errorMessage: errorMessage,
    isLoggedIn:   isLoggedIn   ?? this.isLoggedIn,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRemoteDataSource _ds;

  AuthNotifier(): _ds = AuthRemoteDataSource(), super(const AuthState()) {
    _restoreSession();
  }

  // ── RESTORE SESSION ───────────────────────────────────────
  Future<void> _restoreSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final loggedIn = await SessionService.isLoggedIn();
      if (!loggedIn) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final session = await SessionService.getSession();

      final user = UserModel(
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

      state = state.copyWith(
        user:       user,
        isLoggedIn: true,
        isLoading:  false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  // ── LOGIN ─────────────────────────────────────────────────
  Future<void> login(String username, String password) async {
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

      // ✅ SharedPreferences mein save karo
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
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Login error: $e',
      );
    }
  }

  // ── LOGOUT ────────────────────────────────────────────────
  Future<void> logout() async {
    await SessionService.clearSession(); // ✅ Session clear
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
      (ref) => AuthNotifier(),
);