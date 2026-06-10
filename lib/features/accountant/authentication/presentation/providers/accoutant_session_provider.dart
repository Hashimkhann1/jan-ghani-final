import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/accountant_user_entity.dart';

// ── Global session state ─────────────────────────────────────────────────────
// Har jagah se: ref.watch(sessionProvider)
// User set karo: ref.read(sessionProvider.notifier).setUser(user)
// Logout karo:   ref.read(sessionProvider.notifier).clear()

class SessionNotifier extends StateNotifier<AccountantUserEntity?> {
  SessionNotifier() : super(null);

  void setUser(AccountantUserEntity user) => state = user;
  void clear() => state = null;

  // Convenience getters
  String? get role     => state?.role;
  String? get branchId => state?.branchId;
  bool get isLoggedIn  => state != null;
}

final sessionProvider =
StateNotifierProvider<SessionNotifier, AccountantUserEntity?>(
      (ref) => SessionNotifier(),
);

// ── Shortcut providers ───────────────────────────────────────────────────────
// Sirf role chahiye: ref.watch(currentRoleProvider)
final currentRoleProvider = Provider<String?>(
      (ref) => ref.watch(sessionProvider)?.role,
);

// Sirf branch: ref.watch(currentBranchIdProvider)
final currentBranchIdProvider = Provider<String?>(
      (ref) => ref.watch(sessionProvider)?.branchId,
);

// Logged in hai ya nahi: ref.watch(isLoggedInProvider)
final isLoggedInProvider = Provider<bool>(
      (ref) => ref.watch(sessionProvider) != null,
);