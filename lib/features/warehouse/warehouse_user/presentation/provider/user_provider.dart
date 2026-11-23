// Updated on 2026-11-23 12:27 PM
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/helper/password_helper.dart';
import '../../data/datasource/user_remote_datasource.dart';
import '../../data/model/user_model.dart';
import '../../data/repository/user_repository_impl.dart';
import '../../domain/usecase/add_user_usecase.dart';
import '../../domain/usecase/delete_user_usecase.dart';
import '../../domain/usecase/get_users_usecase.dart';
import '../../domain/usecase/update_user_usecase.dart';

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────
class UserState {
  final List<UserModel> allUsers;
  final String  searchQuery;
  final String  filterStatus;
  final String  filterRole;
  final bool    isLoading;
  final String? errorMessage;

  const UserState({
    this.allUsers     = const [],
    this.searchQuery  = '',
    this.filterStatus = 'all',
    this.filterRole   = 'all',
    this.isLoading    = false,
    this.errorMessage,
  });

  // ── Filtered list ─────────────────────────────────────────
  List<UserModel> get filteredUsers {
    return allUsers.where((u) {
      if (u.deletedAt != null)                                return false;
      if (filterStatus == 'active'   && !u.isActive)         return false;
      if (filterStatus == 'inactive' &&  u.isActive)         return false;
      if (filterRole   != 'all'      && u.role != filterRole) return false;

      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return u.fullName.toLowerCase().contains(q) ||
            u.username.toLowerCase().contains(q)    ||
            (u.phone?.contains(q) ?? false);
      }
      return true;
    }).toList();
  }

  // ── Stats ─────────────────────────────────────────────────
  int get totalCount   => allUsers.where((u) => u.deletedAt == null).length;
  int get activeCount  => allUsers.where((u) => u.isActive && u.deletedAt == null).length;
  int get ownerCount   => allUsers.where((u) => u.isOwner  && u.deletedAt == null).length;

  // ── copyWith ──────────────────────────────────────────────
  UserState copyWith({
    List<UserModel>? allUsers,
    String?          searchQuery,
    String?          filterStatus,
    String?          filterRole,
    bool?            isLoading,
    String?          errorMessage,
  }) => UserState(
    allUsers:     allUsers     ?? this.allUsers,
    searchQuery:  searchQuery  ?? this.searchQuery,
    filterStatus: filterStatus ?? this.filterStatus,
    filterRole:   filterRole   ?? this.filterRole,
    isLoading:    isLoading    ?? this.isLoading,
    errorMessage: errorMessage,
  );
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────
class UserNotifier extends StateNotifier<UserState> {
  final UserRepositoryImpl _repo;
  final GetUsersUseCase    _getAll;
  final AddUserUseCase     _add;
  final UpdateUserUseCase  _update;
  final DeleteUserUseCase  _delete;

  // AppConfig se warehouse_id aata hai — hardcoded nahi
  String get _wid => AppConfig.warehouseId;

  UserNotifier()
      : _repo   = UserRepositoryImpl(),
        _getAll  = GetUsersUseCase(UserRepositoryImpl()),
        _add     = AddUserUseCase(UserRepositoryImpl()),
        _update  = UpdateUserUseCase(UserRepositoryImpl()),
        _delete  = DeleteUserUseCase(UserRepositoryImpl()),
        super(const UserState()) {
    loadUsers();
  }

  // ── Load ──────────────────────────────────────────────────
  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true);
    try {
      final users = await _getAll(_wid);
      state = state.copyWith(allUsers: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Users load karne mein masla: $e');
    }
  }

  // ── Add ───────────────────────────────────────────────────
  Future<void> addUser({
    required String username,
    required String password,
    required String fullName,
    String?         phone,
    required String role,
    required bool   isActive,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      // Username unique check
      final exists = await _repo.usernameExists(username, _wid);
      if (exists) {
        state = state.copyWith(
            isLoading:    false,
            errorMessage: 'Username "$username" already exists');
        return;
      }

      final user = UserModel(
        id:           '',
        warehouseId:  _wid,
        username:     username,
        passwordHash: password, // TODO: bcrypt hash karo production mein
        fullName:     fullName,
        phone:        phone,
        role:         role,
        isActive:     isActive,
        createdAt:    DateTime.now(),
        updatedAt:    DateTime.now(),
      );

      final saved = await _add(user);
      state = state.copyWith(
        allUsers:  [...state.allUsers, saved],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'User add karne mein masla: $e');
    }
  }

  // ── Update ────────────────────────────────────────────────
  Future<void> updateUser(UserModel updated) async {
    state = state.copyWith(isLoading: true);
    try {
      final fresh = await _update(updated);
      final list  = state.allUsers
          .map((u) => u.id == fresh.id ? fresh : u)
          .toList()
          .cast<UserModel>();
      state = state.copyWith(allUsers: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'User update karne mein masla: $e');
    }
  }

  // ── Password change (S31 — Permissions screen, sirf Owner) ──
  // null = kamyab, warna error message
  Future<String?> changePassword(String id, String newPassword) async {
    try {
      final hash = PasswordHelper.hash(newPassword);
      await UserRemoteDataSource().updatePassword(id, hash);
      state = state.copyWith(allUsers: [
        for (final u in state.allUsers)
          u.id == id ? u.copyWith(passwordHash: hash) : u,
      ]);
      return null;
    } catch (e) {
      return 'Password change nahi hua: $e';
    }
  }

  // ── Naam / Role (S31 — Permissions screen) ──────────────────
  // null = kamyab, warna error message
  Future<String?> updateNameRole(String id, String fullName, String role) async {
    try {
      await UserRemoteDataSource().updateNameRole(id, fullName, role);
      state = state.copyWith(allUsers: [
        for (final u in state.allUsers)
          u.id == id ? u.copyWith(fullName: fullName, role: role) : u,
      ]);
      return null;
    } catch (e) {
      return 'Update nahi hua: $e';
    }
  }

  // ── Delete ────────────────────────────────────────────────
  Future<void> deleteUser(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _delete(id);
      final list = state.allUsers
          .map((u) => u.id == id
              ? u.copyWith(deletedAt: DateTime.now())
              : u)
          .toList();
      state = state.copyWith(allUsers: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'User delete karne mein masla: $e');
    }
  }

  // ── Filters ───────────────────────────────────────────────
  void onSearchChanged(String q)       =>
      state = state.copyWith(searchQuery: q);
  void onFilterStatusChanged(String f) =>
      state = state.copyWith(filterStatus: f);
  void onFilterRoleChanged(String r)   =>
      state = state.copyWith(filterRole: r);
  void clearError()                    =>
      state = state.copyWith(errorMessage: null);
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────
final userProvider =
    StateNotifierProvider<UserNotifier, UserState>(
        (ref) => UserNotifier());
