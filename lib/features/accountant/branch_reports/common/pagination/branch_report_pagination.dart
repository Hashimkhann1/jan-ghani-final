/// Reusable pagination helper shared by every branch report screen.
///
/// Fixed page size of 20 rows, matching Supabase's `.range(start, end)`
/// (both bounds inclusive).
class BranchReportPagination {
  static const int pageSize = 20;

  /// Inclusive (start, end) row indexes for [page] (0-based) to pass into
  /// a Supabase `.range(start, end)` call.
  static (int start, int end) range(int page) {
    final start = page * pageSize;
    return (start, start + pageSize - 1);
  }

  /// Heuristic used across all report datasources: if a page comes back
  /// with fewer rows than [pageSize], there is no next page.
  static bool hasNextPage(int rowsReturned) => rowsReturned == pageSize;
}

/// Immutable pagination state to embed as a field in a report's Riverpod
/// state class (`copyWith` composes the same way the rest of the state does).
class BranchReportPageState {
  final int page;
  final bool hasNextPage;
  final bool isLoadingPage;

  const BranchReportPageState({
    this.page = 0,
    this.hasNextPage = false,
    this.isLoadingPage = false,
  });

  bool get hasPreviousPage => page > 0;

  BranchReportPageState copyWith({
    int? page,
    bool? hasNextPage,
    bool? isLoadingPage,
  }) =>
      BranchReportPageState(
        page: page ?? this.page,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        isLoadingPage: isLoadingPage ?? this.isLoadingPage,
      );
}
