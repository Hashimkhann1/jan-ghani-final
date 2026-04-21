import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/accountant_auth_local_datasource.dart';
import '../../data/datasources/accountant_auth_remote_datasource.dart';
import '../../data/repositories/accountant_auth_repository_impl.dart';
import '../../domain/repositories/accountant_auth_repository.dart';
import '../../domain/usecases/login_accountant_usecase.dart';
import '../../domain/usecases/save_session_usecase.dart';
import '../notifier/accountant_auth_notifier.dart';
import '../state/accountant_auth_state.dart';

// ── Supabase client ──────────────────────────────────────────────────────────
final supabaseClientProvider = Provider<SupabaseClient>(
      (ref) => Supabase.instance.client,
);

// ── Datasources ──────────────────────────────────────────────────────────────
final remoteDataSourceProvider = Provider<AccountantAuthRemoteDatasource>(
      (ref) => AccountantAuthRemoteDatasourceImpl(
    ref.watch(supabaseClientProvider),
  ),
);

final localDataSourceProvider = Provider<AccountantAuthLocalDatasource>(
      (ref) => AccountantAuthLocalDatasourceImpl(),
);

// ── Repository ───────────────────────────────────────────────────────────────
final accountantAuthRepositoryProvider = Provider<AccountantAuthRepository>(
      (ref) => AccountantAuthRepositoryImpl(
    remote: ref.watch(remoteDataSourceProvider),
    local: ref.watch(localDataSourceProvider),
  ),
);

// ── Use Cases ────────────────────────────────────────────────────────────────
final loginUseCaseProvider = Provider<LoginAccountantUseCase>(
      (ref) => LoginAccountantUseCase(
    ref.watch(accountantAuthRepositoryProvider),
  ),
);

final saveSessionUseCaseProvider = Provider<SaveSessionUseCase>(
      (ref) => SaveSessionUseCase(
    ref.watch(accountantAuthRepositoryProvider),
  ),
);

// ── Notifier ─────────────────────────────────────────────────────────────────
final accountantAuthNotifierProvider =
StateNotifierProvider<AccountantAuthNotifier, AccountantAuthState>(
      (ref) => AccountantAuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    saveSessionUseCase: ref.watch(saveSessionUseCaseProvider),
  ),
);