import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/category_sale_report_datasource.dart';
import '../../data/model/category_sale_report_model.dart';

// ── State ─────────────────────────────────────────────────
class CategorySaleReportState {
  final List<CategorySaleReport> reports;
  final List<CategoryOption>     categories;
  final DateTime                 fromDate;
  final DateTime                 toDate;
  final String?                  selectedCategoryId;
  final bool                     isLoading;
  final bool                     isLoadingCategories;
  final String?                  errorMessage;

  CategorySaleReportState({
    this.reports              = const [],
    this.categories           = const [],
    DateTime?                 fromDate,
    DateTime?                 toDate,
    this.selectedCategoryId,
    this.isLoading            = false,
    this.isLoadingCategories  = false,
    this.errorMessage,
  })  : fromDate = fromDate ?? _today(),
        toDate   = toDate   ?? _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  CategorySaleReportSummary get summary => CategorySaleReportSummary(
    totalCategories: reports.length,
    totalSales:      reports.fold(0, (s, r) => s + r.totalSales),
    totalProfit:     reports.fold(0, (s, r) => s + r.totalProfit),
    totalQuantity:   reports.fold(0, (s, r) => s + r.totalQuantity),
  );

  CategorySaleReportState copyWith({
    List<CategorySaleReport>? reports,
    List<CategoryOption>?     categories,
    DateTime?                 fromDate,
    DateTime?                 toDate,
    String?                   selectedCategoryId,
    bool                      clearCategory = false,
    bool?                     isLoading,
    bool?                     isLoadingCategories,
    String?                   errorMessage,
  }) =>
      CategorySaleReportState(
        reports:             reports             ?? this.reports,
        categories:          categories          ?? this.categories,
        fromDate:            fromDate            ?? this.fromDate,
        toDate:              toDate              ?? this.toDate,
        selectedCategoryId:  clearCategory
            ? null : (selectedCategoryId ?? this.selectedCategoryId),
        isLoading:           isLoading           ?? this.isLoading,
        isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
        errorMessage:        errorMessage,
      );
}

// ── Notifier ──────────────────────────────────────────────
class CategorySaleReportNotifier
    extends StateNotifier<CategorySaleReportState> {
  final CategorySaleReportDatasource _ds;

  CategorySaleReportNotifier({required String branchId})
      : _ds = CategorySaleReportDatasource(branchId: branchId),
        super(CategorySaleReportState()) {
    _loadCategories();
    load();
  }

  Future<void> _loadCategories() async {
    state = state.copyWith(isLoadingCategories: true);
    try {
      final cats = await _ds.getCategories();
      state = state.copyWith(categories: cats, isLoadingCategories: false);
    } catch (e) {
      state = state.copyWith(isLoadingCategories: false);
    }
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _ds.getReport(
        fromDate:   state.fromDate,
        toDate:     state.toDate,
        categoryId: state.selectedCategoryId,
      );
      state = state.copyWith(reports: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Error: $e',
      );
    }
  }

  void setFromDate(DateTime d) {
    state = state.copyWith(fromDate: d);
    load();
  }

  void setToDate(DateTime d) {
    state = state.copyWith(toDate: d);
    load();
  }

  void setCategory(String? id) {
    state = state.copyWith(
      selectedCategoryId: id,
      clearCategory:      id == null,
    );
    load();
  }

  void setToday() {
    final today = CategorySaleReportState._today();
    state = state.copyWith(fromDate: today, toDate: today);
    load();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ── Provider ──────────────────────────────────────────────
final categorySaleReportProvider = StateNotifierProvider.autoDispose
    .family<CategorySaleReportNotifier, CategorySaleReportState, String>(
      (ref, branchId) => CategorySaleReportNotifier(branchId: branchId),
);