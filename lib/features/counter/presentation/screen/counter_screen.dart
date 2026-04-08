import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../../../core/widget/figure_card_widget.dart';
import '../../../warehouse_stock_inventory/presentation/widget/action_button_widget.dart';
import '../../data/model/counter_model.dart';
import '../provider/counter_provider.dart';
import '../widget/add_counter_dialog.dart';


class AllCounterScreen extends ConsumerWidget {
  const AllCounterScreen({super.key});

  void _openDialog(BuildContext context, {CounterModel? counter}) {
    showDialog(
      context: context,
      builder: (_) => AddCounterDialog(counter: counter),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CounterModel counter) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Counter Delete Karein?'),
        content: Text('"${counter.counterName}" ko delete karna chahte hain?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(counterProvider.notifier).deleteCounter(counter.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(counterProvider);
    final counters = state.counters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counters'),
        toolbarHeight: 60,
        actions: [
          IntrinsicWidth(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton.icon(
                onPressed: () => _openDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Counter',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stat Cards (Optional - aap add kar sakte hain)
            Row(
              children: [
                SummaryCard(
                  title: 'Total Counters',
                  value: '${counters.length}',
                  icon: Icons.point_of_sale,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Total Sale Today',
                  value: 'Rs ${counters.fold(0.0, (sum, c) => sum + c.total).toStringAsFixed(0)}',
                  icon: Icons.credit_card_outlined,
                  color: AppColor.success,
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColor.grey100),
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 56,
                    columnSpacing: 65,
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Counter Name')),
                      DataColumn(label: Text('Username')),
                      DataColumn(label: Text('Password')),
                      DataColumn(label: Text('Cash Sale')),
                      DataColumn(label: Text('Card Sale')),
                      DataColumn(label: Text('Credit Sale')),
                      DataColumn(label: Text('Installment')),
                      DataColumn(label: Text('Total Sale')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: List.generate(counters.length, (i) {
                      final c = counters[i];
                      return DataRow(
                        cells: [
                          DataCell(Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Text(c.counterName, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(c.username)),
                          DataCell(Text(c.password, style: const TextStyle(color: Colors.grey))),
                          DataCell(Text('Rs ${c.cashSale.toStringAsFixed(0)}')),
                          DataCell(Text('Rs ${c.cardSale.toStringAsFixed(0)}')),
                          DataCell(Text('Rs ${c.creditSale.toStringAsFixed(0)}')),
                          DataCell(Text('Rs ${c.installment.toStringAsFixed(0)}')),
                          DataCell(Text(
                            'Rs ${c.total.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColor.primary),
                          )),
                          DataCell(Row(
                            children: [
                              ActionBtn(
                                icon: Icons.edit_outlined,
                                color: AppColor.primary,
                                onTap: () => _openDialog(context, counter: c),
                              ),
                              const SizedBox(width: 8),
                              ActionBtn(
                                icon: Icons.delete_outline_rounded,
                                color: AppColor.error,
                                onTap: () => _confirmDelete(context, ref, c),
                              ),
                            ],
                          )),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}