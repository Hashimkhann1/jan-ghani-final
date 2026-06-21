// ── Single table backup result ────────────────────────────────────────────────
class TableBackupResult {
  final String tableName;
  final int rowsFetched;
  final int rowsUpserted;
  final bool success;
  final String? error;

  const TableBackupResult({
    required this.tableName,
    required this.rowsFetched,
    required this.rowsUpserted,
    required this.success,
    this.error,
  });
}

// ── Overall backup progress ───────────────────────────────────────────────────
class BackupProgress {
  final int totalTables;
  final int completedTables;
  final String currentTable;
  final List<TableBackupResult> results;

  const BackupProgress({
    this.totalTables = 0,
    this.completedTables = 0,
    this.currentTable = '',
    this.results = const [],
  });

  double get percentage =>
      totalTables == 0 ? 0 : completedTables / totalTables;

  int get totalRowsUpserted =>
      results.fold(0, (sum, r) => sum + r.rowsUpserted);

  int get failedTables => results.where((r) => !r.success).length;

  BackupProgress copyWith({
    int? totalTables,
    int? completedTables,
    String? currentTable,
    List<TableBackupResult>? results,
  }) {
    return BackupProgress(
      totalTables: totalTables ?? this.totalTables,
      completedTables: completedTables ?? this.completedTables,
      currentTable: currentTable ?? this.currentTable,
      results: results ?? this.results,
    );
  }
}