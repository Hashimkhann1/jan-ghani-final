import '../../domain/entities/accountant_user_entity.dart';

enum AuthStatus { initial, loading, success, error }

class AccountantAuthState {
  final AuthStatus status;
  final AccountantUserEntity? user;
  final String? errorMessage;

  const AccountantAuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AccountantAuthState copyWith({
    AuthStatus? status,
    AccountantUserEntity? user,
    String? errorMessage,
  }) {
    return AccountantAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}