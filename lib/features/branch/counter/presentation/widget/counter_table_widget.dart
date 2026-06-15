import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/branch/counter/data/model/counter_model.dart';
import 'counter_name_cell_widget.dart';
import 'counter_date_cell_widget.dart';
import 'counter_action_cell_widget.dart';

class CounterTableWidget extends StatelessWidget {
  const CounterTableWidget({
    super.key,
    required this.counters,
    required this.dateFmt,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CounterModel>         counters;
  final DateFormat                 dateFmt;
  final ValueChanged<CounterModel> onEdit;
  final ValueChanged<CounterModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth =
        constraints.maxWidth > 600 ? constraints.maxWidth : 600.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: tableWidth),
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor:
                WidgetStateProperty.all(AppColor.grey100),
                dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                      (s) => s.contains(WidgetState.hovered)
                      ? AppColor.primary.withValues(alpha: 0.05)
                      : null,
                ),
                dataRowMinHeight:  56,
                dataRowMaxHeight:  56,
                columnSpacing:     (tableWidth * 0.08).clamp(24.0, 120.0),
                showCheckboxColumn: false,
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('Counter Name')),
                  DataColumn(label: Text('Created Date')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: List.generate(counters.length, (i) {
                  final c = counters[i];
                  return DataRow(cells: [
                    DataCell(Text(
                      '${i + 1}',
                      style: const TextStyle(
                          color: AppColor.textSecondary, fontSize: 13),
                    )),
                    DataCell(CounterNameCellWidget(name: c.counterName)),
                    DataCell(CounterDateCellWidget(
                        date: dateFmt.format(c.createdAt))),
                    DataCell(CounterActionCellWidget(
                      onEdit:   () => onEdit(c),
                      onDelete: () => onDelete(c),
                    )),
                  ]);
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}