import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import 'package:jan_ghani_final/features/branch/counter/data/model/counter_model.dart';
import 'package:jan_ghani_final/features/branch/counter/presentation/provider/counter_provider.dart';
import '../widget/add_counter_dialog.dart';
import '../widget/counter_table_widget.dart';
import '../widget/counter_empty_state_widget.dart';

class AllCounterScreen extends ConsumerWidget {
  const AllCounterScreen({super.key});

  static final _dateFmt = DateFormat('dd MMM yyyy');

  void _openDialog(BuildContext context, {CounterModel? counter}) {
    showDialog(
      context:            context,
      barrierDismissible: false,
      builder: (_) => AddCounterDialog(counter: counter),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, CounterModel counter) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Delete Counter?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete "${counter.counterName}"?',
          style: const TextStyle(fontSize: 13),
        ),
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
                  borderRadius: BorderRadius.circular(8)),
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
    final state    = ref.watch(counterProvider);
    final counters = state.counters;

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
            Expanded(
              child: counters.isEmpty
                  ? const CounterEmptyStateWidget()
                  : CounterTableWidget(
                counters: counters,
                dateFmt:  _dateFmt,
                onEdit:   (c) => _openDialog(context, counter: c),
                onDelete: (c) => _confirmDelete(context, ref, c),
              ),
            ),
          ],
        ),
      ),
    );
  }
}