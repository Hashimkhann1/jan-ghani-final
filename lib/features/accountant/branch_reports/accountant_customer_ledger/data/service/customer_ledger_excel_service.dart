import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/accountant_customer_ledger_model.dart';

class CustomerLedgerExcelService {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  /// [items]: always the CURRENT FILTERED list (customer + date + search),
  /// same as the PDF export — the ledger screen already holds every entry
  /// in memory, so no extra fetch is needed.
  static Future<void> exportAndSave({
    required List<CustomerLedgerModel> items,
    String? customerName,
    DateTime? startDate,
    DateTime? endDate,
    String searchQuery = '',
  }) async {
    await ReportExcelExport.save(
      fileNamePrefix: 'customer_ledger',
      sheets: [
        buildSheet(
          items: items,
          customerName: customerName,
          startDate: startDate,
          endDate: endDate,
          searchQuery: searchQuery,
        ),
      ],
    );
  }

  static ExcelSheetData buildSheet({
    required List<CustomerLedgerModel> items,
    String? customerName,
    DateTime? startDate,
    DateTime? endDate,
    String searchQuery = '',
  }) {
    final filters = <String>[
      if (customerName != null && customerName.isNotEmpty)
        'Customer: $customerName',
      if (startDate != null || endDate != null)
        'Date: ${startDate != null ? _dateFmt.format(startDate) : '...'}'
            '  →  ${endDate != null ? _dateFmt.format(endDate) : '...'}',
      if (searchQuery.isNotEmpty) 'Search: "$searchQuery"',
    ];
    final subtitle = [
      filters.isEmpty ? 'All Entries' : filters.join('   •   '),
      '${items.length} entries',
    ].join('   •   ');

    var totalPaid = 0.0;
    final rows = <List<Object?>>[];
    for (final e in items) {
      totalPaid += e.payAmount;
      rows.add([
        e.createdAt.toLocal(),
        e.customerName.isNotEmpty ? e.customerName : '-',
        e.previousAmount,
        e.payAmount,
        e.newAmount,
        e.notes ?? '',
      ]);
    }

    return ExcelSheetData(
      name:     'Customer Ledger',
      title:    'Customer Ledger',
      subtitle: subtitle,
      columns: const [
        ExcelColumn('Date & Time', width: 22, type: ExcelColType.dateTime),
        ExcelColumn('Customer',    width: 28),
        ExcelColumn('Previous',    width: 15, type: ExcelColType.amount),
        ExcelColumn('Paid',        width: 15, type: ExcelColType.amount),
        ExcelColumn('Remaining',   width: 15, type: ExcelColType.amount),
        ExcelColumn('Notes',       width: 40),
      ],
      rows:   rows,
      totals: ['TOTAL', null, null, totalPaid, null, null],
    );
  }
}
