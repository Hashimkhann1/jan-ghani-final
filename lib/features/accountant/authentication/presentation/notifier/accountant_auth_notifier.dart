import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../domain/entities/accountant_user_entity.dart';
import '../../domain/repositories/accountant_auth_repository.dart';
import '../../domain/usecases/login_accountant_usecase.dart';
import '../../domain/usecases/save_session_usecase.dart';
import '../providers/accoutant_session_provider.dart';
import '../state/accountant_auth_state.dart';

class AccountantAuthNotifier extends StateNotifier<AccountantAuthState> {
  final LoginAccountantUseCase loginUseCase;
  final SaveSessionUseCase saveSessionUseCase;
  final Ref ref;
  StreamSubscription<dynamic>? _authSub;

  AccountantAuthRepository get _repo => saveSessionUseCase.repository;

  AccountantAuthNotifier({
    required this.loginUseCase,
    required this.saveSessionUseCase,
    required this.ref,
  }) : super(const AccountantAuthState()) {
    // Google redirect / deep link ke baad Auth session aata hai — usse
    // profile se jod kar login mukammal karo.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((d) {
      if (d.event == AuthChangeEvent.signedIn) _resumeFromAuthSession();
    });
    Future.microtask(_resumeFromAuthSession);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  String _message(Object e) => e is Exception
      ? e.toString().replaceAll('Exception: ', '')
      : 'Something went wrong. Please try again.';

  Future<void> _complete(AccountantUserEntity user) async {
    await saveSessionUseCase(user);
    await ref.read(sessionProvider.notifier).setUser(user);
    state = state.copyWith(status: AuthStatus.success, user: user);
  }

  Future<void> _resumeFromAuthSession() async {
    if (!mounted || state.status == AuthStatus.loading) return;
    final session = ref.read(sessionProvider);
    if (session.isRestoring || session.user != null) return;
    if (Supabase.instance.client.auth.currentSession == null) return;

    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repo.profileOfCurrentSession();
      if (user == null) {
        state = const AccountantAuthState();
        return;
      }
      await _complete(user);
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: _message(e));
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      state = state.copyWith(
        status:       AuthStatus.error,
        errorMessage: 'Email and password are required',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);

    try {
      final user = await loginUseCase(
        username: username,
        password: password,
      );

      if (user == null) {
        state = state.copyWith(
          status:       AuthStatus.error,
          errorMessage: 'Invalid email or password',
        );
        return;
      }

      await _complete(user);
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: _message(e));
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repo.signInWithGoogle();
      // Browser/redirect se wapas aane par _resumeFromAuthSession chalega.
      state = const AccountantAuthState();
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: _message(e));
    }
  }

  /// Branch ne role set kar diya ho to naya profile utha kar session update.
  Future<void> refreshProfile() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repo.profileOfCurrentSession();
      if (user == null) {
        state = const AccountantAuthState();
        return;
      }
      await _complete(user);
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: _message(e));
    }
  }

  /// Scan kiye gaye customer QR se account connect, phir profile refresh —
  /// router khud customer portal par le jata hai.
  Future<void> connectCustomer(String customerId) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repo.connectCustomerAccount(customerId);
      await refreshProfile();
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: _message(e));
    }
  }

  /// Branch User ke QR se account connect (role + branch assign), phir profile refresh.
  Future<void> connectBranchUser(String branchUserId) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repo.connectBranchUserAccount(branchUserId);
      await refreshProfile();
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: _message(e));
    }
  }

  Future<void> logout() async {
    await _repo.signOut();
    await saveSessionUseCase.repository.clearSession();
    await ref.read(sessionProvider.notifier).clear(); // ✅ await added
    state = const AccountantAuthState();
  }

  void resetState() => state = const AccountantAuthState();
}
