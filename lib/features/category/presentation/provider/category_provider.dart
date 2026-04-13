// =============================================================
// category_provider.dart
// =============================================================

import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import '../../data/model/category_model.dart';
import '../../data/repository/category_repository_impl.dart';
import '../../domain/usecase/get_categories_usecase.dart';
import '../../domain/usecase/add_category_usecase.dart';
import '../../domain/usecase/update_category_usecase.dart';
import '../../domain/usecase/delete_category_usecase.dart';

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────
class CategoryState {
  final List<CategoryModel> allCategories;
  final String              searchQuery;
  final String              filterStatus; // 'all' | 'active' | 'inactive'
  final bool                isLoading;
  final String?             errorMessage;

  const CategoryState({
    this.allCategories = const [],
    this.searchQuery   = '',
    this.filterStatus  = 'all',
    this.isLoading     = false,
    this.errorMessage,
  });

  // ── Filtered list ─────────────────────────────────────────
  List<CategoryModel> get filteredCategories {
    return allCategories.where((c) {
      if (c.deletedAt != null) return false;

      if (filterStatus == 'active'   && !c.isActive) return false;
      if (filterStatus == 'inactive' &&  c.isActive) return false;

      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return c.name.toLowerCase().contains(q) ||
            (c.description?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();
  }

  // ── Stats ─────────────────────────────────────────────────
  int get totalCount  =>
      allCategories.where((c) => c.deletedAt == null).length;
  int get activeCount =>
      allCategories.where((c) => c.isActive && c.deletedAt == null).length;

  // ── copyWith ──────────────────────────────────────────────
  CategoryState copyWith({
    List<CategoryModel>? allCategories,
    String?              searchQuery,
    String?              filterStatus,
    bool?                isLoading,
    String?              errorMessage,
  }) {
    return CategoryState(
      allCategories: allCategories ?? this.allCategories,
      searchQuery:   searchQuery   ?? this.searchQuery,
      filterStatus:  filterStatus  ?? this.filterStatus,
      isLoading:     isLoading     ?? this.isLoading,
      errorMessage:  errorMessage,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────
class CategoryNotifier extends StateNotifier<CategoryState> {
  final CategoryRepositoryImpl _repo;
  final GetCategoriesUseCase   _getAll;
  final AddCategoryUseCase     _add;
  final UpdateCategoryUseCase  _update;
  final DeleteCategoryUseCase  _delete;

  String get _wid => AppConfig.warehouseId;

  CategoryNotifier()
      : _repo   = CategoryRepositoryImpl(),
        _getAll  = GetCategoriesUseCase(CategoryRepositoryImpl()),
        _add     = AddCategoryUseCase(CategoryRepositoryImpl()),
        _update  = UpdateCategoryUseCase(CategoryRepositoryImpl()),
        _delete  = DeleteCategoryUseCase(CategoryRepositoryImpl()),
        super(const CategoryState()) {
    loadCategories();
  }

  // ── Load ──────────────────────────────────────────────────
  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true);
    try {
      final categories = await _getAll(_wid);
      state = state.copyWith(
          allCategories: categories, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading:    false,
          errorMessage: 'Categories load karne mein masla: $e');
    }
  }

  // ── Add ───────────────────────────────────────────────────
  Future<void> addCategory(CategoryModel category) async {
    state = state.copyWith(isLoading: true);
    try {
      // Name duplicate check
      final exists = await _repo.nameExists(category.name, _wid);
      if (exists) {
        state = state.copyWith(
            isLoading:    false,
            errorMessage: '"${category.name}" already exists');
        return;
      }

      final saved = await _add(category);
      state = state.copyWith(
        allCategories: [...state.allCategories, saved],
        isLoading:     false,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading:    false,
          errorMessage: 'Category add karne mein masla: $e');
    }
  }

  // ── Update ────────────────────────────────────────────────
  Future<void> updateCategory(CategoryModel updated) async {
    state = state.copyWith(isLoading: true);
    try {
      // Name duplicate check — apni current entry exclude karo
      final exists = await _repo.nameExists(
          updated.name, _wid, excludeId: updated.id);
      if (exists) {
        state = state.copyWith(
            isLoading:    false,
            errorMessage: '"${updated.name}" already exists');
        return;
      }

      final saved = await _update(updated);
      final list  = state.allCategories
          .map((c) => c.id == saved.id ? saved : c)
          .toList();
      state = state.copyWith(allCategories: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading:    false,
          errorMessage: 'Category update karne mein masla: $e');
    }
  }

  // ── Delete ────────────────────────────────────────────────
  Future<void> deleteCategory(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _delete(id);
      final updated = state.allCategories
          .map((c) => c.id == id
              ? c.copyWith(deletedAt: DateTime.now())
              : c)
          .toList();
      state = state.copyWith(
          allCategories: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading:    false,
          errorMessage: 'Category delete karne mein masla: $e');
    }
  }

  // ── Filters ───────────────────────────────────────────────
  void onSearchChanged(String q) =>
      state = state.copyWith(searchQuery: q);
  void onFilterChanged(String f) =>
      state = state.copyWith(filterStatus: f);
  void clearError() =>
      state = state.copyWith(errorMessage: null);
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────
final categoryProvider =
    StateNotifierProvider<CategoryNotifier, CategoryState>(
        (ref) => CategoryNotifier());
