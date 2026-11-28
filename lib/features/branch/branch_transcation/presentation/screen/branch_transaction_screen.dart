import 'package:jan_ghani_final/core/widget/branch_ui.dart';
import 'package:jan_ghani_final/core/color/branch_color.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:jan_ghani_final/core/widget/app_icon.dart';
import 'package:jan_ghani_final/core/widget/pagination_bar.dart';

import '../provider/branch_transaction_provider.dart';
import '../widget/cash_out_dilog.dart';

// ── Shortcuts ───────────────────────────────────────────────────
//  Ctrl+N : cash out        F5 : refresh
//  Ctrl+1 : start date      Ctrl+2 : end date      Ctrl+0 / Esc : clear dates
//  PageUp / PageDown : previous / next page
class BranchTransactionScreen extends ConsumerStatefulWidget {
  const BranchTransactionScreen({super.key});

  @override
  ConsumerState<BranchTransactionScreen> createState() =>
      _BranchTransactionScreenState();
}

class _BranchTransactionScreenState
    extends ConsumerState<BranchTransactionScreen> {
  final TextEditingController _startDateCtrl = TextEditingController();
  final TextEditingController _endDateCtrl   = TextEditingController();
  final DateFormat _dateOnly = DateFormat('dd MMM yyyy');

  int _page = 0;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    // Provider is global — a date filter set on an earlier visit is still
    // active, so reflect it in the text fields instead of showing them blank.
    final s = ref.read(branchTransactionProvider);
    if (s.startDate != null) _startDateCtrl.text = _dateOnly.format(s.startDate!);
    if (s.endDate != null)   _endDateCtrl.text   = _dateOnly.format(s.endDate!);

    Future.microtask(
          () => ref.read(branchTransactionProvider.notifier).loadData(),
    );
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    // Dialog / date picker khula ho ya doosri screen top par ho to kuch na karo.
    if (!(ModalRoute.of(context)?.isCurrent ?? true) ||
        Navigator.of(context, rootNavigator: true).canPop()) {
      return false;
    }

    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isAltPressed) return false; // sidebar shortcuts
    final ctrl  = keyboard.isControlPressed;
    final key   = event.logicalKey;
    final state = ref.read(branchTransactionProvider);
    final hasDateFilter = state.startDate != null || state.endDate != null;

    if (key == LogicalKeyboardKey.f5) {
      ref.read(branchTransactionProvider.notifier).loadData();
      return true;
    }
    if (key == LogicalKeyboardKey.pageDown ||
        key == LogicalKeyboardKey.pageUp) {
      final total = state.history.length;
      if (total == 0) return true;
      // 25 = PaginationBar / pageSlice ka default page size.
      final lastPage = (total - 1) ~/ 25;
      final step = key == LogicalKeyboardKey.pageDown ? 1 : -1;
      setState(() => _page = (_page.clamp(0, lastPage) + step).clamp(0, lastPage));
      return true;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (!hasDateFilter) return false;
      _clearDates();
      return true;
    }
    if (!ctrl) return false;

    if (key == LogicalKeyboardKey.keyN) {
      if (!state.isLoading) _openCashOutDialog();
      return true;
    }
    if (key == LogicalKeyboardKey.digit1) {
      _pickStartDate();
      return true;
    }
    if (key == LogicalKeyboardKey.digit2) {
      _pickEndDate();
      return true;
    }
    if (key == LogicalKeyboardKey.digit0) {
      if (hasDateFilter) _clearDates();
      return true;
    }
    return false;
  }

  void _openCashOutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CashOutDialog(),
    );
  }

  Future<void> _pickStartDate() async {
    final state  = ref.read(branchTransactionProvider);
    final picked = await showDatePicker(
      context:     context,
      initialDate: state.startDate ?? DateTime.now(),
      firstDate:   DateTime(2020),
      lastDate:    DateTime.now(),
    );
    if (picked == null) return;

    final currentEnd = state.endDate ?? picked;
    final newEnd = currentEnd.isBefore(picked) ? picked : currentEnd;

    _startDateCtrl.text = _dateOnly.format(picked);
    _endDateCtrl.text   = _dateOnly.format(newEnd);

    ref.read(branchTransactionProvider.notifier).setDateRange(picked, newEnd);
  }

  Future<void> _pickEndDate() async {
    final state  = ref.read(branchTransactionProvider);
    final picked = await showDatePicker(
      context:     context,
      initialDate: state.endDate ?? DateTime.now(),
      firstDate:   state.startDate ?? DateTime(2020),
      lastDate:    DateTime.now(),
    );
    if (picked == null) return;

    final currentStart = state.startDate ?? picked;
    final newStart = currentStart.isAfter(picked) ? picked : currentStart;

    _startDateCtrl.text = _dateOnly.format(newStart);
    _endDateCtrl.text   = _dateOnly.format(picked);

    ref.read(branchTransactionProvider.notifier).setDateRange(newStart, picked);
  }

  void _clearDates() {
    _startDateCtrl.clear();
    _endDateCtrl.clear();
    ref.read(branchTransactionProvider.notifier).clearDateRange();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(branchTransactionProvider);
    final fmt   = DateFormat('dd MMM yyyy  hh:mm a');

    ref.listen(branchTransactionProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(next.errorMessage!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label:     'OK',
              textColor: Colors.white,
              onPressed: () =>
                  ref.read(branchTransactionProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: BranchAppBar(
        title:    'Branch Transactions',
        subtitle: 'Accountant ko diya gaya cash',
        actions: [
          BranchRefreshButton(
              tooltip:   'Refresh (F5)',
              onPressed: () =>
                  ref.read(branchTransactionProvider.notifier).loadData()),
          // Paisa bahar jata hai, is liye laal.
          BranchActionButton(
            label:     'Cash Out  (Ctrl+N)',
            iconAsset: 'ic_cash_out',
            color:     AppColor.error,
            iconColor: Colors.white,
            onPressed: state.isLoading ? null : _openCashOutDialog,
          ),
        ],
      ),

      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ── Stat Cards ──────────────────────────
            Row(
              children: [
                BranchStatCard(
                  title:     'Cash In Hand',
                  value:     branchMoney(state.totalAmount),
                  iconAsset: 'ic_cash_in',
                  color:     AppColor.success,
                ),
                const SizedBox(width: 12),
                BranchStatCard(
                  title: 'Total Pay Amount',
                  value: branchMoney(state.history
                      .fold(0.0, (sum, t) => sum + t.payAmount)),
                  iconAsset: 'ic_cash_out',
                  color:     AppColor.error,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Date Range Filter (TextFields) ──────
            LayoutBuilder(
                  builder: (ctx, constraints) {
                    final isWide = constraints.maxWidth > 600;

                    final startField = TextField(
                      controller: _startDateCtrl,
                      readOnly:   true,
                      onTap:      _pickStartDate,
                      decoration: InputDecoration(
                        labelText: 'Start Date (Ctrl+1)',
                        hintText:  'dd MMM yyyy',
                        isDense:   true,
                        prefixIcon: const AppIcon('ic_calendar', size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 13),
                    );

                    final endField = TextField(
                      controller: _endDateCtrl,
                      readOnly:   true,
                      onTap:      _pickEndDate,
                      decoration: InputDecoration(
                        labelText: 'End Date (Ctrl+2)',
                        hintText:  'dd MMM yyyy',
                        isDense:   true,
                        prefixIcon: const AppIcon('ic_calendar', size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 13),
                    );

                    final clearBtn = IconButton(
                      tooltip: 'Clear filter (Ctrl+0)',
                      onPressed: (state.startDate != null ||
                          state.endDate != null)
                          ? _clearDates
                          : null,
                      icon: const Icon(Icons.close_rounded),
                    );

                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(child: startField),
                          const SizedBox(width: 12),
                          Expanded(child: endField),
                          clearBtn,
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: startField),
                            clearBtn,
                          ],
                        ),
                        const SizedBox(height: 10),
                        endField,
                      ],
                    );
                  },
                ),

            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ctrl+N cash out  •  F5 refresh  •  Ctrl+1 / 2 date  •  '
                'Ctrl+0 / Esc clear date  •  PgUp/PgDn page',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),

            // ── DataTable ────────────────────────────
            Expanded(
              child: BranchTableCard(
                child: state.history.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz_rounded,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Koi transaction nahi mili',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
                  : Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                onRefresh: () => ref
                    .read(branchTransactionProvider.notifier)
                    .loadData(),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    const double minWidth = 900;
                    final tableWidth =
                    constraints.maxWidth > minWidth
                        ? constraints.maxWidth
                        : minWidth;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minWidth: tableWidth),
                        child: SingleChildScrollView(
                          child: DataTable(
                            dataRowMinHeight: 56,
                            dataRowMaxHeight: 56,
                            columnSpacing:    28,
                            headingRowHeight: 46,
                          dividerThickness: 0.6,
                          horizontalMargin: 16,
                          showCheckboxColumn: false,
                            columns: const [
                              DataColumn(label: Text('Type')),
                              DataColumn(label: Text('Before Amount'), numeric: true),
                              DataColumn(label: Text('Pay Amount'), numeric: true),
                              DataColumn(label: Text('After Amount'), numeric: true),
                              DataColumn(label: Text('By')),
                              DataColumn(label: Text('Date & Time')),
                            ],
                            rows: pageSlice(state.history, _page).map((t) {
                              return DataRow(cells: [

                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius:
                                    BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AppIcon('ic_transfer',
                                          size:  13,
                                          color: Colors.red.shade400),
                                      const SizedBox(width: 5),
                                      Text(
                                        t.type.toUpperCase()
                                            .replaceAll('_', ' '),
                                        style: TextStyle(
                                            fontSize:   11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.red.shade600),
                                      ),
                                    ],
                                  ),
                                )),

                                DataCell(BranchAmount(t.beforeAmount,
                                    color: AppColor.textSecondary)),

                                DataCell(BranchAmount(t.payAmount,
                                    color: AppColor.error, isBold: true)),

                                DataCell(BranchAmount(t.afterAmount,
                                    isBold: true,
                                    color: t.afterAmount >= 0
                                        ? BranchColor.navy
                                        : AppColor.error)),

                                DataCell(Text(
                                  t.assignByName,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54),
                                )),

                                DataCell(Text(
                                  fmt.format(t.createdAt),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black45),
                                )),

                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: PaginationBar(
                      total: state.history.length,
                      page:  _page,
                      onPageChanged: (p) => setState(() => _page = p),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
