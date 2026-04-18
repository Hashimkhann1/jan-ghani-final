import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import 'package:jan_ghani_final/features/branch/counter/data/model/counter_model.dart';
import 'package:jan_ghani_final/features/branch/counter/presentation/provider/counter_provider.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../customer/presentation/widget/customer_action_button_widget.dart';
import '../widget/add_counter_dialog.dart';

class AllCounterScreen extends ConsumerStatefulWidget {
  const AllCounterScreen({super.key});

  @override
  ConsumerState<AllCounterScreen> createState() => _AllCounterScreenState();
}

class _AllCounterScreenState extends ConsumerState<AllCounterScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(counterProvider.notifier).loadCounters();
    });
  }

  void _openDialog(BuildContext context, {CounterModel? counter}) {
    showDialog(
      context:            context,
      barrierDismissible: false,
      builder: (_) => AddCounterDialog(counter: counter),
    );
  }

  void _confirmDelete(BuildContext context, CounterModel counter) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: const Text('Counter Delete Karein?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
            '"${counter.counterName}" ko delete karna chahte hain?',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColor.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.error,
                foregroundColor: Colors.white,
                elevation:       0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
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
  Widget build(BuildContext context) {
    final state    = ref.watch(counterProvider);
    final counters = state.counters;
    final dateFmt  = DateFormat('dd MMM yyyy');
    final auth = ref.watch(authProvider);
    print(auth.user?.storeId.toString() ?? "");
    print(auth.user?.counterId.toString() ?? "");

    ref.listen<CounterState>(counterProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(next.errorMessage!),
            backgroundColor: AppColor.error,
            behavior:        SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label:     'OK',
              textColor: Colors.white,
              onPressed: () =>
                  ref.read(counterProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counters',
            style: TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight: 60,
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(counterProvider.notifier).loadCounters(),
            icon:    const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(
                foregroundColor: AppColor.textSecondary),
          ),
          const SizedBox(width: 4),
          IntrinsicWidth(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton.icon(
                onPressed: () => _openDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  elevation:       0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon:  const Icon(Icons.add, size: 18),
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

            // ── Stat Card ────────────────────────────
            Row(
              children: [
                SummaryCard(
                  title: 'Total Counters',
                  value: '${counters.length}',
                  icon:  Icons.point_of_sale_outlined,
                  color: AppColor.primary,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Table ────────────────────────────────
            Expanded(
              child: counters.isEmpty
                  ? const _EmptyState()
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        AppColor.grey100),
                    dataRowColor:
                    WidgetStateProperty.resolveWith<Color?>(
                            (s) => s.contains(
                            WidgetState.hovered)
                            ? AppColor.primary
                            .withValues(alpha: 0.05)
                            : null),
                    dataRowMinHeight:   56,
                    dataRowMaxHeight:   56,
                    columnSpacing: 200,
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Counter Name')),
                      DataColumn(label: Text('Created Date')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: List.generate(counters.length, (i) {
                      final c = counters[i];
                      return DataRow(
                        cells: [
                          // Sr #
                          DataCell(Text(
                            '${i + 1}',
                            style: const TextStyle(
                                color:    AppColor.textSecondary,
                                fontSize: 13),
                          )),

                          // Counter Name
                          DataCell(Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColor.primary
                                      .withValues(alpha: 0.08),
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.point_of_sale_outlined,
                                  size:  15,
                                  color: AppColor.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                c.counterName,
                                style: const TextStyle(
                                    fontSize:   13,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          )),

                          // Created Date
                          DataCell(Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size:  13,
                                color: AppColor.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dateFmt.format(c.createdAt),
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColor.textSecondary),
                              ),
                            ],
                          )),

                          // Actions
                          DataCell(Row(
                            children: [
                              CustomerActionButton(
                                icon:    Icons.edit_outlined,
                                color:   AppColor.primary,
                                tooltip: 'Edit',
                                onTap: () =>
                                    _openDialog(context, counter: c),
                              ),
                              const SizedBox(width: 6),
                              CustomerActionButton(
                                icon:    Icons.delete_outline_rounded,
                                color:   AppColor.error,
                                tooltip: 'Delete',
                                onTap: () =>
                                    _confirmDelete(context, c),
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

// ── Empty State ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.point_of_sale_outlined,
              size: 64, color: AppColor.grey300),
          SizedBox(height: 16),
          Text('Koi counter nahi',
              style: TextStyle(
                  fontSize:   16,
                  fontWeight: FontWeight.w600,
                  color:      AppColor.textSecondary)),
          SizedBox(height: 6),
          Text('New Counter button se add karein',
              style: TextStyle(fontSize: 13, color: AppColor.textHint)),
        ],
      ),
    );
  }
}