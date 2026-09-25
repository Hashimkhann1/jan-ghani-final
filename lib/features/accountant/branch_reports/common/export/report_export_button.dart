import 'package:flutter/material.dart';
import '../../../../../core/color/app_color.dart';
import 'report_excel_export.dart';
import 'report_file_export.dart';

enum _Choice { excel, pdf, csv, all }

/// App-bar / toolbar export control shared by every branch report. Lets the
/// user pick Excel, PDF, CSV, or all three at once.
///
/// [loadSheets] runs only when the user picks a format and must return the
/// full, filtered data (not just the visible page). Returning an empty list
/// shows a "nothing to export" message.
///
/// A report with a hand-designed PDF can pass [customPdf] to use it instead
/// of the generic table PDF.
class ReportExportButton extends StatefulWidget {
  const ReportExportButton({
    super.key,
    required this.fileNamePrefix,
    required this.loadSheets,
    this.customPdf,
    this.enabled = true,
    this.filled = false,
    this.label = 'Export',
  });

  final String fileNamePrefix;
  final Future<List<ExcelSheetData>> Function() loadSheets;
  final Future<void> Function()? customPdf;
  final bool enabled;

  /// Renders as a labelled filled button (for toolbars) instead of an icon.
  final bool filled;

  /// Text on the filled button.
  final String label;

  @override
  State<ReportExportButton> createState() => _ReportExportButtonState();
}

class _ReportExportButtonState extends State<ReportExportButton> {
  bool _busy = false;

  Future<void> _run(_Choice choice) async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    messenger.showSnackBar(const SnackBar(
      content: Text('Preparing export...'),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
    try {
      final sheets = await widget.loadSheets();
      if (sheets.isEmpty || sheets.every((s) => s.rows.isEmpty)) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(const SnackBar(
          content: Text('No data to export for the selected filters'),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      final formats = choice == _Choice.all
          ? ReportExportFormat.values
          : [
              switch (choice) {
                _Choice.excel => ReportExportFormat.excel,
                _Choice.pdf   => ReportExportFormat.pdf,
                _ => ReportExportFormat.csv,
              }
            ];
      for (final f in formats) {
        if (f == ReportExportFormat.pdf && widget.customPdf != null) {
          await widget.customPdf!();
        } else {
          await ReportFileExport.saveFormat(
            format: f,
            fileNamePrefix: widget.fileNamePrefix,
            sheets: sheets,
          );
        }
      }
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text('Export failed: $e'),
        backgroundColor: AppColor.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && !_busy;
    final spinner = const SizedBox(
        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));

    return PopupMenuButton<_Choice>(
      enabled: enabled,
      tooltip: 'Export',
      onSelected: _run,
      position: PopupMenuPosition.under,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _Choice.excel,
          child: _Item(Icons.table_view_outlined, 'Excel (.xlsx)'),
        ),
        PopupMenuItem(
          value: _Choice.pdf,
          child: _Item(Icons.picture_as_pdf_outlined, 'PDF (.pdf)'),
        ),
        PopupMenuItem(
          value: _Choice.csv,
          child: _Item(Icons.description_outlined, 'CSV (.csv)'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _Choice.all,
          child: _Item(Icons.download_for_offline_outlined, 'All 3 formats'),
        ),
      ],
      child: widget.filled
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: enabled ? AppColor.primary : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _busy
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.file_download_outlined,
                        size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Text(widget.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ]),
            )
          : Padding(
              padding: const EdgeInsets.all(8),
              child: _busy
                  ? spinner
                  : Icon(Icons.file_download_outlined,
                      size: 22,
                      color: enabled ? AppColor.primary : Colors.grey),
            ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 20, color: AppColor.primary),
        const SizedBox(width: 10),
        Text(label),
      ]);
}
