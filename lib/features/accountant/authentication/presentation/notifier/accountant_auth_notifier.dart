import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/service/session/accountant_session.dart';
import '../../domain/usecases/login_accountant_usecase.dart';
import '../../domain/usecases/save_session_usecase.dart';
import '../state/accountant_auth_state.dart';

class AccountantAuthNotifier extends StateNotifier<AccountantAuthState> {
  final LoginAccountantUseCase loginUseCase;
  final SaveSessionUseCase saveSessionUseCase;

  AccountantAuthNotifier({
    required this.loginUseCase,
    required this.saveSessionUseCase,
  }) : super(const AccountantAuthState());

  Future<void> login({
    required String username,
    required String password,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Username aur password zaroor bharo',
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
          status: AuthStatus.error,
          errorMessage: 'Username ya password galat hai',
        );
        return;
      }

      // await saveSessionUseCase(user);
      await AccountantSession.save(
        id        : user.id,
        name      : user.name,
        username  : user.username,
        phone     : user.phone,
        isActive  : user.isActive,
        createdAt : user.createdAt.toIso8601String(),
      );
      print('✅ Session saved: ${user.id} | ${user.name}');

      state = state.copyWith(
        status: AuthStatus.success,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Kuch ghalat ho gaya. Dobara koshish karo.',
      );
    }
  }

  void resetState() {
    state = const AccountantAuthState();
  }
}