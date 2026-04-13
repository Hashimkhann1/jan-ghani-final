// =============================================================
// auth_provider.dart
// Login → SharedPreferences mein save
// Logout → SharedPreferences clear
// App start → SharedPreferences se load
// =============================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jan_ghani_final/core/widget/sidebar/sidebar_widget.dart';
import 'package:jan_ghani_final/features/auth/local/auth_local_storage.dart';
import 'package:jan_ghani_final/features/warehouse_user/data/model/user_model.dart';
import '../../data/datasource/auth_remote_datasource.dart';

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRemoteDataSource _ds;

  AuthNotifier()
      : _ds = AuthRemoteDataSource(),
        super(const AuthState()) {
    _checkSavedLogin();
  }

  // ── App start pe check karo ───────────────────────────────
  // Agar pehle se login tha toh dobara login screen na aaye
  Future<void> _checkSavedLogin() async {
    state = state.copyWith(isLoading: true);
    try {
      final savedUser = await AuthLocalStorage.loadUser();
      if (savedUser != null) {
        final user = UserModel.fromMap(savedUser);
        state = state.copyWith(
          user:      user,
          isLoggedIn: true,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      // Koi masla aaye toh login screen dikha do
      await AuthLocalStorage.clear();
      state = state.copyWith(isLoading: false);
    }
  }

  // ── Login ──────────────────────────────────────────────────
  Future<void> login(BuildContext context, String username, String password) async {
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

      // SharedPreferences mein save karo
      await AuthLocalStorage.saveUser({
        'id':            user.id,
        'warehouse_id':  user.warehouseId,
        'username':      user.username,
        'password_hash': user.passwordHash,
        'full_name':     user.fullName,
        'phone':         user.phone,
        'role':          user.role,
        'is_active':     user.isActive,
        'created_at':    user.createdAt.toIso8601String(),
        'updated_at':    user.updatedAt.toIso8601String(),
      });

      state = state.copyWith(
        user:       user,
        isLoggedIn: true,
        isLoading:  false,
      );

      Navigator.push(context, MaterialPageRoute(builder: (context) => SideBar()));

    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Login mein masla: $e',
      );
    }
  }

  // ── Logout ────────────────────────────────────────────────
  Future<void> logout() async {
    // SharedPreferences clear karo
    await AuthLocalStorage.clear();
    // State reset karo
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────
final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
        (ref) => AuthNotifier());
