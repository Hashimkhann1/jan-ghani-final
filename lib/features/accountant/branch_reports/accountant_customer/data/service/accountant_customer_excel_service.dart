import '../../../common/export/report_excel_export.dart';
import '../model/accountant_customer_model.dart';

class AccountantCustomerExcelService {
  /// [items] is the CURRENT FILTERED list (search + type filter), so the sheet
  /// matches what's on screen — same as the PDF.
  ///
  /// One sheet, a snapshot fact table: one row per customer, no totals row so
  /// it can be pivoted/loaded into BI tools.
  static Future<void> exportAndSave({
    required List<AccountantCustomerReportModel> items,
    required String branchName,
    String? filterType,
    String searchQuery = '',
  }) async {
    final subtitle = [
      'Filter: ${_filterLabel(filterType)}',
      if (searchQuery.isNotEmpty) 'Search: "$searchQuery"',
    ].join('   •   ');

    await ReportExcelExport.save(
      fileNamePrefix: 'customer_report',
      sheets: buildSheets(
        items:      items,
        branchName: branchName,
        subtitle:   subtitle,
      ),
    );
  }

  static List<ExcelSheetData> buildSheets({
    required List<AccountantCustomerReportModel> items,
    required String branchName,
    required String subtitle,
    DateTime? snapshotAt,
  }) {
    final now = snapshotAt ?? DateTime.now();
    final snapshotDate = DateTime(now.year, now.month, now.day);

    final rows = <List<Object?>>[
      for (final c in items)
        [
          snapshotDate,
          branchName,
          c.code,
          c.name,
          c.phone,
          c.address,
          _cap(c.customerType),
          c.creditLimit,
          c.balance,
          c.isCreditLimitExceeded ? 'Yes' : 'No',
          c.isActive ? 'Active' : 'Inactive',
          c.createdAt,
        ],
    ];

    return [
      ExcelSheetData(
        name:     'Customers',
        title:    'Current Customer Snapshot (one row per customer, refreshed each export)',
        subtitle: '$subtitle   •   ${rows.length} customers',
        columns: const [
          ExcelColumn('snapshot_date',  width: 15, type: ExcelColType.dateTime,
              format: 'yyyy-mm-dd'),
          ExcelColumn('branch',         width: 20),
          ExcelColumn('code',           width: 14),
          ExcelColumn('customer',       width: 28),
          ExcelColumn('phone',          width: 16),
          ExcelColumn('address',        width: 30),
          ExcelColumn('customer_type',  width: 15),
          ExcelColumn('credit_limit',   width: 14, type: ExcelColType.amount),
          ExcelColumn('balance',        width: 14, type: ExcelColType.amount),
          ExcelColumn('limit_exceeded', width: 15),
          ExcelColumn('status',         width: 11),
          ExcelColumn('created_at',     width: 18, type: ExcelColType.dateTime,
              format: 'yyyy-mm-dd hh:mm'),
        ],
        rows: rows,
      ),
    ];
  }

  static String _filterLabel(String? filterType) {
    switch (filterType) {
      case null:       return 'All';
      case 'exceeded': return 'Credit limit exceeded';
      default:         return _cap(filterType);
    }
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
