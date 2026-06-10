import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/login_accountant_usecase.dart';
import '../../domain/usecases/save_session_usecase.dart';
import '../providers/accoutant_session_provider.dart';
import '../state/accountant_auth_state.dart';

class AccountantAuthNotifier extends StateNotifier<AccountantAuthState> {
  final LoginAccountantUseCase loginUseCase;
  final SaveSessionUseCase saveSessionUseCase;
  final Ref ref;

  AccountantAuthNotifier({
    required this.loginUseCase,
    required this.saveSessionUseCase,
    required this.ref,
  }) : super(const AccountantAuthState());

  Future<void> login({
    required String username,
    required String password,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Email aur password zaroor bharo',
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
          errorMessage: 'Email ya password galat hai',
        );
        return;
      }

      // SharedPreferences mein save karo
      await saveSessionUseCase(user);

      // Riverpod global session mein set karo
      ref.read(sessionProvider.notifier).setUser(user);

      state = state.copyWith(
        status: AuthStatus.success,
        user: user,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Kuch ghalat ho gaya. Dobara koshish karo.',
      );
    }
  }

  Future<void> logout() async {
    await saveSessionUseCase.repository.clearSession();
    ref.read(sessionProvider.notifier).clear();
    state = const AccountantAuthState();
  }

  void resetState() => state = const AccountantAuthState();
}