import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/color/app_color.dart';
import '../../data/datasource/entry_method_report_datasource.dart';

/// Scan vs Manual report — cashier ke hisaab se aur product ke hisaab se.
class EntryMethodReportDialog extends StatefulWidget {
  final String storeId;
  final DateTime fromDate;
  final DateTime toDate;
  final String? counterId;
  final String? userId;

  const EntryMethodReportDialog({
    super.key,
    required this.storeId,
    required this.fromDate,
    required this.toDate,
    this.counterId,
    this.userId,
  });

  @override
  State<EntryMethodReportDialog> createState() =>
      _EntryMethodReportDialogState();
}

class _EntryMethodReportDialogState extends State<EntryMethodReportDialog> {
  late final Future<EntryMethodReport> _report =
      EntryMethodReportDatasource().load(
    storeId: widget.storeId,
    fromDate: widget.fromDate,
    toDate: widget.toDate,
    counterId: widget.counterId,
    userId: widget.userId,
  );

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 720,
        height: 560,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              ListTile(
                title: const Text('Scan / Manual Report',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${fmt.format(widget.fromDate)}  —  ${fmt.format(widget.toDate)}\n'
                  'Ginti invoice lines ki hai (Sale + Sale Return)',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColor.textSecondary),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const TabBar(
                labelColor: AppColor.primary,
                tabs: [
                  Tab(text: 'Cashier ke hisaab se'),
                  Tab(text: 'Manual add hone wale products'),
                ],
              ),
              Expanded(
                child: FutureBuilder<EntryMethodReport>(
                  future: _report,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('Report load nahi hui: ${snap.error}',
                              style: const TextStyle(color: AppColor.error)),
                        ),
                      );
                    }
                    final data = snap.data;
                    if (data == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return TabBarView(children: [
                      _Table(nameLabel: 'Cashier', rows: data.cashiers),
                      _Table(nameLabel: 'Product', rows: data.products),
                    ]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Table extends StatelessWidget {
  final String nameLabel;
  final List<EntryMethodRow> rows;
  const _Table({required this.nameLabel, required this.rows});

  Widget _line(List<String> cells, {bool header = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: i == 0 ? 4 : 1,
              child: Text(
                cells[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: i == 0 ? TextAlign.left : TextAlign.right,
                style: TextStyle(
                  fontSize: header ? 11.5 : 12.5,
                  fontWeight: header ? FontWeight.w700 : FontWeight.w500,
                  color: header ? AppColor.textSecondary : AppColor.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text('Is date range mein koi record nahi',
            style: TextStyle(color: AppColor.textSecondary)),
      );
    }
    return Column(
      children: [
        _line([nameLabel, 'Scan', 'Manual', 'Mixed', 'Manual %'], header: true),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = rows[i];
              return _line([
                r.name,
                '${r.scan}',
                '${r.manual}',
                '${r.mixed}',
                '${r.manualPercent.toStringAsFixed(0)}%',
              ]);
            },
          ),
        ),
      ],
    );
  }
}
