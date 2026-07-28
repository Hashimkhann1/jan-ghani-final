// =============================================================
// company_provider.dart
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import '../../data/model/company_model.dart';
import '../../data/repository/company_repository_impl.dart';
import '../../domain/usecase/get_companies_usecase.dart';
import '../../domain/usecase/add_company_usecase.dart';
import '../../domain/usecase/update_company_usecase.dart';
import '../../domain/usecase/delete_company_usecase.dart';

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────
class CompanyState {
  final List<CompanyModel> allCompanies;
  final String             searchQuery;
  final String             filterStatus; // 'all' | 'active' | 'inactive'
  final bool               isLoading;
  final String?            errorMessage;

  const CompanyState({
    this.allCompanies = const [],
    this.searchQuery  = '',
    this.filterStatus = 'all',
    this.isLoading    = false,
    this.errorMessage,
  });

  // ── Filtered list ─────────────────────────────────────────
  List<CompanyModel> get filteredCompanies {
    return allCompanies.where((c) {
      if (c.deletedAt != null) return false;

      if (filterStatus == 'active'   && !c.isActive) return false;
      if (filterStatus == 'inactive' &&  c.isActive) return false;

      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return c.name.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  // ── Stats ─────────────────────────────────────────────────
  int get totalCount  =>
      allCompanies.where((c) => c.deletedAt == null).length;
  int get activeCount =>
      allCompanies.where((c) => c.isActive && c.deletedAt == null).length;

  // ── copyWith ──────────────────────────────────────────────
  CompanyState copyWith({
    List<CompanyModel>? allCompanies,
    String?             searchQuery,
    String?             filterStatus,
    bool?               isLoading,
    String?             errorMessage,
  }) {
    return CompanyState(
      allCompanies: allCompanies ?? this.allCompanies,
      searchQuery:  searchQuery  ?? this.searchQuery,
      filterStatus: filterStatus ?? this.filterStatus,
      isLoading:    isLoading    ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────
class CompanyNotifier extends StateNotifier<CompanyState> {
  final CompanyRepositoryImpl _repo;
  final GetCompaniesUseCase   _getAll;
  final AddCompanyUseCase     _add;
  final UpdateCompanyUseCase  _update;
  final DeleteCompanyUseCase  _delete;

  String get _wid => AppConfig.warehouseId;

  CompanyNotifier()
      : _repo   = CompanyRepositoryImpl(),
        _getAll = GetCompaniesUseCase(CompanyRepositoryImpl()),
        _add    = AddCompanyUseCase(CompanyRepositoryImpl()),
        _update = UpdateCompanyUseCase(CompanyRepositoryImpl()),
        _delete = DeleteCompanyUseCase(CompanyRepositoryImpl()),
        super(const CompanyState()) {
    loadCompanies();
  }

  // ── Load ──────────────────────────────────────────────────
  Future<void> loadCompanies() async {
    state = state.copyWith(isLoading: true);
    try {
      final companies = await _getAll(_wid);
      state = state.copyWith(allCompanies: companies, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading:    false,
          errorMessage: 'Companies load karne mein masla: $e');
    }
  }

  // ── Add ───────────────────────────────────────────────────
  Future<void> addCompany(CompanyModel company) async {
    state = state.copyWith(isLoading: true);
    try {
      final exists = await _repo.nameExists(company.name, _wid);
      if (exists) {
        state = state.copyWith(
            isLoading:    false,
            errorMessage: '"${company.name}" already exists');
        return;
      }

      final saved = await _add(company);
      state = state.copyWith(
        allCompanies: [...state.allCompanies, saved],
        isLoading:    false,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading:    false,
          errorMessage: 'Company add karne mein masla: $e');
    }
  }

  // ── Update ────────────────────────────────────────────────
  Future<void> updateCompany(CompanyModel updated) async {
    state = state.copyWith(isLoading: true);
    try {
      final exists = await _repo.nameExists(
          updated.name, _wid, excludeId: updated.id);
      if (exists) {
        state = state.copyWith(
            isLoading:    false,
            errorMessage: '"${updated.name}" already exists');
        return;
      }

      final saved = await _update(updated);
      final list  = state.allCompanies
          .map((c) => c.id == saved.id ? saved : c)
          .toList();
      state = state.copyWith(allCompanies: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading:    false,
          errorMessage: 'Company update karne mein masla: $e');
    }
  }

  // ── Delete ────────────────────────────────────────────────
  Future<void> deleteCompany(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _delete(id);
      final updated = state.allCompanies
          .map((c) => c.id == id ? c.copyWith(deletedAt: DateTime.now()) : c)
          .toList();
      state = state.copyWith(allCompanies: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading:    false,
          errorMessage: 'Company delete karne mein masla: $e');
    }
  }

  // ── Filters ───────────────────────────────────────────────
  void onSearchChanged(String q) => state = state.copyWith(searchQuery: q);
  void onFilterChanged(String f) => state = state.copyWith(filterStatus: f);
  void clearError()              => state = state.copyWith(errorMessage: null);
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────
final companyProvider =
    StateNotifierProvider<CompanyNotifier, CompanyState>(
        (ref) => CompanyNotifier());
