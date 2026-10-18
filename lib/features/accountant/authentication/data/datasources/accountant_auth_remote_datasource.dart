import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/accountant_user_entity.dart';
import '../model/accountant_user_model.dart';

/// Login / sign up Supabase Auth se hota hai (password auth.users mein).
/// `public.users` sirf profile hai (role, branch, ...) — auth user se email
/// ke zariye match hota hai. Sign up par DB trigger row role = NULL ke saath
/// banata hai (supabase/migrations/2026_10_17_users_auto_profile.sql); jab tak
/// branch role nahi deta, login ke baad user ko sirf "visit your nearest
/// branch" screen dikhti hai (AccPaths.connectAccount).
abstract class AccountantAuthRemoteDatasource {
  Future<AccountantUserEntity?> login({
    required String email,
    required String password,
  });

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset(String email);

  /// Google OAuth shuru karta hai (web par redirect, mobile par browser).
  Future<void> signInWithGoogle();

  /// Mojooda Auth session (jaise Google redirect ke baad) ka profile.
  Future<AccountantUserEntity?> profileOfCurrentSession();

  Future<void> signOut();

  /// Branch ke QR (customer id) se account connect — RPC
  /// `connect_customer_account` (supabase/migrations/2026_10_17_connect_customer_account.sql).
  Future<void> connectCustomerAccount(String customerId);

  /// Installment customer ke QR (`inst:<id>`) se account connect — RPC
  /// `connect_installment_account` (supabase/migrations/2026_10_18_installment_system.sql).
  Future<void> connectInstallmentAccount(String installmentId);

  /// Branch User drawer ke QR (`user:<id>`) se account connect — RPC
  /// `connect_branch_user_account` (supabase/migrations/2026_10_19_connect_branch_user_account.sql).
  Future<void> connectBranchUserAccount(String branchUserId);
}

class AccountantAuthRemoteDatasourceImpl
    implements AccountantAuthRemoteDatasource {
  final SupabaseClient _client;
  const AccountantAuthRemoteDatasourceImpl(this._client);

  /// Mobile par Google ke baad app wapas kholne ka deep link.
  /// (AndroidManifest / Info.plist aur Supabase Redirect URLs mein bhi chahiye.)
  static const _mobileRedirect = 'io.janghani.app://login-callback/';

  @override
  Future<AccountantUserEntity?> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth
          .signInWithPassword(email: email, password: password);
      return _profileOf(res.user);
    } on AuthException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  @override
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      // Approval se pehle session nahi chahiye (email confirm off ho tab bhi).
      if (_client.auth.currentSession != null) await _client.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : _mobileRedirect,
      );
    } on AuthException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  @override
  Future<AccountantUserEntity?> profileOfCurrentSession() =>
      _profileOf(_client.auth.currentUser);

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> connectInstallmentAccount(String installmentId) async {
    try {
      await _client.rpc('connect_installment_account',
          params: {'p_installment_id': installmentId});
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<void> connectBranchUserAccount(String branchUserId) async {
    try {
      await _client.rpc('connect_branch_user_account',
          params: {'p_branch_user_id': branchUserId});
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<void> connectCustomerAccount(String customerId) async {
    try {
      await _client.rpc('connect_customer_account',
          params: {'p_customer_id': customerId});
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Auth user → `public.users` profile. Email confirm na ho ya profile na ho
  /// to Auth session band kar deta hai. Role NULL ho to user `role == ''` ke
  /// saath wapas aata hai — router usse "visit nearest branch" screen dikhata hai.
  Future<AccountantUserEntity?> _profileOf(User? authUser) async {
    final email = authUser?.email;
    if (authUser == null || email == null) return null;

    // Confirm na ho to koi bhi doosre ki email se sign up karke uska role le sakta hai.
    if (authUser.emailConfirmedAt == null) {
      await _client.auth.signOut();
      throw Exception('Please confirm your email first');
    }

    // Pehle auth id se (purani/seed rows ka email alag ho sakta hai), phir email se.
    final data = await _client
            .from('users')
            .select()
            .eq('id', authUser.id)
            .maybeSingle() ??
        await _client
            .from('users')
            .select()
            .ilike('email', email)
            .maybeSingle();

    if (data == null) {
      await _client.auth.signOut();
      throw Exception('Account not found. Please sign up first');
    }
    return AccountantUserModel.fromMap(data);
  }

  String _friendly(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login')) return 'Invalid email or password';
    if (m.contains('not confirmed')) return 'Please confirm your email first';
    if (m.contains('already registered')) {
      return 'An account with this email already exists';
    }
    if (m.contains('password')) return e.message;
    if (m.contains('rate limit')) return 'Too many attempts. Try again later';
    return e.message;
  }
}
