import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/model/user_model.dart';
import '../../data/repository/user_repository_impl.dart';
import '../../domain/usecase/add_user_usecase.dart';
import '../../domain/usecase/delete_user_usecase.dart';
import '../../domain/usecase/get_users_usecase.dart';
import '../../domain/usecase/update_user_usecase.dart';

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

  List<UserModel> get filteredUsers {
    return allUsers.where((u) {
      if (u.deletedAt != null)                                  return false;
      if (filterStatus == 'active'   && !u.isActive)           return false;
      if (filterStatus == 'inactive' &&  u.isActive)           return false;
      if (filterRole   != 'all'      && u.role != filterRole)  return false;

      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return u.fullName.toLowerCase().contains(q) ||
            u.username.toLowerCase().contains(q) ||
            (u.phone?.contains(q) ?? false);
      }
      return true;
    }).toList();
  }

  int get totalCount  => allUsers.where((u) => u.deletedAt == null).length;
  int get activeCount => allUsers.where((u) => u.isActive && u.deletedAt == null).length;
  int get ownerCount  => allUsers.where((u) => u.isOwner  && u.deletedAt == null).length;

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

// ── Notifier ──────────────────────────────────────────────────
class UserNotifier extends StateNotifier<UserState> {
  final UserRepositoryImpl _repo;
  final GetUsersUseCase    _getAll;
  final AddUserUseCase     _add;
  final UpdateUserUseCase  _update;
  final DeleteUserUseCase  _delete;
  final Ref _ref;


  String get _storeId => _ref.read(authProvider).storeId;


  UserNotifier(this._ref)
      : _repo   = UserRepositoryImpl(),
        _getAll  = GetUsersUseCase(UserRepositoryImpl()),
        _add     = AddUserUseCase(UserRepositoryImpl()),
        _update  = UpdateUserUseCase(UserRepositoryImpl()),
        _delete  = DeleteUserUseCase(UserRepositoryImpl()),
        super(const UserState()) {
    loadUsers();
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true);
    try {
      final users = await _getAll(_storeId);
      state = state.copyWith(allUsers: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  Future<void> addUser({
    required String  username,
    required String  password,
    required String  fullName,
    String?          phone,
    required String  role,
    required bool    isActive,
    String?          counterId,   // ← new
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final exists = await _repo.usernameExists(username, _storeId);
      if (exists) {
        state = state.copyWith(
            isLoading:    false,
            errorMessage: 'Username "$username" already exists');
        return;
      }

      final saved = await _add(UserModel(
        id:           '',
        storeId:      _storeId,
        username:     username,
        passwordHash: password,
        fullName:     fullName,
        phone:        phone,
        role:         role,
        isActive:     isActive,
        counterId:    counterId,  // ← new
        createdAt:    DateTime.now(),
        updatedAt:    DateTime.now(),
      ));

      state = state.copyWith(
        allUsers:  [saved, ...state.allUsers],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Add error: $e');
    }
  }

  Future<void> updateUser(UserModel updated) async {
    state = state.copyWith(isLoading: true);
    try {
      final fresh = await _update(updated);
      final list  = state.allUsers
          .map((u) => u.id == fresh.id ? fresh : u)
          .toList();
      state = state.copyWith(allUsers: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Update error: $e');
    }
  }

  Future<void> deleteUser(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _delete(id);
      final list = state.allUsers.where((u) => u.id != id).toList();
      state = state.copyWith(allUsers: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Delete error: $e');
    }
  }

  void onSearchChanged(String q)       => state = state.copyWith(searchQuery: q);
  void onFilterStatusChanged(String f) => state = state.copyWith(filterStatus: f);
  void onFilterRoleChanged(String r)   => state = state.copyWith(filterRole: r);
  void clearError()                    => state = state.copyWith(errorMessage: null);
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) => UserNotifier(ref),);