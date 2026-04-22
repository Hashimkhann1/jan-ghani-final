import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/providers/assign_stock_report_provider.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/widgets/assign_stock_details_dialog_widget.dart';

// ─── Main Screen ──────────────────────────────────────────────────────────────

class AssignStockReportScreen extends ConsumerWidget {
  const AssignStockReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transferReportProvider);

    return Scaffold(
      backgroundColor: AppColor.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top Bar ──────────────────────────────────────────────────────
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppColor.surface,
              border:
              Border(bottom: BorderSide(color: AppColor.grey200)),
            ),
            child: Row(
              children: [
                
                IconButton(onPressed: () {Navigator.pop(context);}, icon: Icon(Icons.arrow_back)),
                SizedBox(width: 20,),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Stock Transfer Report',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary),
                    ),
                    Text(
                      'Warehouse se store ko assign kiya gaya stock',
                      style: TextStyle(
                          fontSize: 13, color: AppColor.textSecondary),
                    ),
                  ],
                ),
                const Spacer(),
                // Refresh button
                InkWell(
                  onTap: () =>
                      ref.read(transferReportProvider.notifier).refresh(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.grey100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColor.grey200),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        size: 18, color: AppColor.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          if (state.isLoading)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Summary Cards ────────────────────────────────────────
                  _SummaryCards(state: state),
                  const SizedBox(height: 20),

                  // ── Filters ──────────────────────────────────────────────
                  _FilterBar(state: state),
                  const SizedBox(height: 16),

                  // ── Table ────────────────────────────────────────────────
                  _TransferTable(state: state),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Cards ────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final TransferReportState state;
  const _SummaryCards({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Card(
          icon: Icons.swap_horiz_rounded,
          iconColor: AppColor.primary,
          bgColor: AppColor.primary.withOpacity(0.08),
          label: 'Total Transfers',
          value: '${state.totalTransfers}',
        ),
        const SizedBox(width: 12),
        _Card(
          icon: Icons.schedule_rounded,
          iconColor: Colors.orange,
          bgColor: Colors.orange.withOpacity(0.08),
          label: 'Pending',
          value: '${state.pendingCount}',
        ),
        const SizedBox(width: 12),
        _Card(
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppColor.success,
          bgColor: AppColor.success.withOpacity(0.08),
          label: 'Accepted',
          value: '${state.acceptedCount}',
        ),
        const SizedBox(width: 12),
        _Card(
          icon: Icons.calendar_month_rounded,
          iconColor: const Color(0xFF5C6BC0),
          bgColor: const Color(0xFF5C6BC0).withOpacity(0.08),
          label: 'This Month',
          value: 'Rs ${_fmt(state.thisMonthCost)}',
        ),
        const SizedBox(width: 12),
        _Card(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: AppColor.error,
          bgColor: AppColor.error.withOpacity(0.08),
          label: 'Grand Total Cost',
          value: 'Rs ${_fmt(state.grandTotalCost)}',
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}K';
    }
    return v.toStringAsFixed(0);
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String value;

  const _Card({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColor.grey200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: AppColor.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends ConsumerStatefulWidget {
  final TransferReportState state;
  const _FilterBar({required this.state});

  @override
  ConsumerState<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<_FilterBar> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(transferReportProvider.notifier);
    final filter = widget.state.filter;
    final stores = widget.state.linkedStores;

    final statusOptions = [
      {'value': null, 'label': 'All'},
      {'value': 'pending', 'label': 'Pending'},
      {'value': 'accepted', 'label': 'Accepted'},
      {'value': 'rejected', 'label': 'Rejected'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Search
              SizedBox(
                width: 500,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => notifier.applyFilters(search: v),
                  style: const TextStyle(
                      fontSize: 13, color: AppColor.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Transfer number, store ya assigned by...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColor.textHint),
                    prefixIcon: const Icon(Icons.search,
                        size: 16, color: AppColor.grey400),
                    filled: true,
                    fillColor: AppColor.grey100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        const BorderSide(color: AppColor.grey200)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        const BorderSide(color: AppColor.grey200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColor.primary, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Row(
                children: [
                  // From Date
                  _DatePickerButton(
                    label: filter.fromDate == null
                        ? 'From Date'
                        : DateFormat('dd MMM yyyy').format(filter.fromDate!),
                    icon: Icons.calendar_today_outlined,
                    hasValue: filter.fromDate != null,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: filter.fromDate ?? DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) notifier.applyFilters(fromDate: d);
                    },
                    onClear: () =>
                        notifier.applyFilters(clearFromDate: true),
                  ),
                  const SizedBox(width: 8),

                  // To Date
                  _DatePickerButton(
                    label: filter.toDate == null
                        ? 'To Date'
                        : DateFormat('dd MMM yyyy').format(filter.toDate!),
                    icon: Icons.calendar_today_outlined,
                    hasValue: filter.toDate != null,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: filter.toDate ?? DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) notifier.applyFilters(toDate: d);
                    },
                    onClear: () => notifier.applyFilters(clearToDate: true),
                  ),
                  const SizedBox(width: 12),

                  // Store dropdown
                  SizedBox(
                    width: 250,
                    child: DropdownButtonFormField<String?>(
                      value: filter.selectedStoreId,
                      hint: const Text('All Stores',
                          style: TextStyle(
                              fontSize: 13, color: AppColor.textHint)),
                      onChanged: (v) {
                        if (v == null) {
                          notifier.applyFilters(clearStore: true);
                        } else {
                          notifier.applyFilters(storeId: v);
                        }
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.store_outlined,
                            size: 16, color: AppColor.grey400),
                        filled: true,
                        fillColor: AppColor.grey100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            const BorderSide(color: AppColor.grey200)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            const BorderSide(color: AppColor.grey200)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColor.primary, width: 1.5)),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Stores',
                              style: TextStyle(fontSize: 13)),
                        ),
                        ...stores.map((s) => DropdownMenuItem<String?>(
                          value: s['store_id'] as String,
                          child: Text(s['store_name'] as String,
                              style: const TextStyle(fontSize: 13)),
                        )),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Reset
                  if (filter.fromDate != null ||
                      filter.toDate != null ||
                      filter.selectedStoreId != null ||
                      filter.selectedStatus != null ||
                      filter.searchQuery.isNotEmpty)
                    InkWell(
                      onTap: () {
                        _searchCtrl.clear();
                        notifier.resetFilters();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColor.errorLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColor.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.close_rounded,
                                size: 14, color: AppColor.error),
                            SizedBox(width: 4),
                            Text('Reset',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColor.error,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),

          // Status filter tabs
          Row(
            children: statusOptions.map((opt) {
              final isSelected = filter.selectedStatus == opt['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    if (opt['value'] == null) {
                      notifier.applyFilters(clearStatus: true);
                    } else {
                      notifier.applyFilters(
                          status: opt['value'] as String?);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColor.primary
                          : AppColor.grey100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColor.primary
                            : AppColor.grey200,
                      ),
                    ),
                    child: Text(
                      opt['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : AppColor.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool hasValue;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DatePickerButton({
    required this.label,
    required this.icon,
    required this.hasValue,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hasValue
              ? AppColor.primary.withOpacity(0.07)
              : AppColor.grey100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
            hasValue ? AppColor.primary.withOpacity(0.4) : AppColor.grey200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color:
                hasValue ? AppColor.primary : AppColor.grey400),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: hasValue ? AppColor.primary : AppColor.textHint,
                fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
            if (hasValue) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    size: 13, color: AppColor.primary),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// ─── Transfer Table ───────────────────────────────────────────────────────────

class _TransferTable extends ConsumerWidget {
  final TransferReportState state;
  const _TransferTable({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(transferReportProvider.notifier);
    final transfers = state.filteredTransfers;

    if (state.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (transfers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColor.grey200),
        ),
        child: const Column(
          children: [
            Icon(Icons.swap_horiz_rounded,
                size: 48, color: AppColor.grey300),
            SizedBox(height: 12),
            Text('Koi transfer nahi mila',
                style: TextStyle(
                    fontSize: 15, color: AppColor.textHint)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColor.grey100,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                  bottom: BorderSide(color: AppColor.grey200)),
            ),
            child: Row(
              children: const [
                Expanded(
                    flex: 3, child: _TH(text: 'Transfer Number')),
                Expanded(flex: 2, child: _TH(text: 'Store')),
                Expanded(flex: 2, child: _TH(text: 'Assigned By')),
                Expanded(flex: 2, child: _TH(text: 'Date')),
                SizedBox(width: 90, child: _TH(text: 'Status')),
                Expanded(flex: 2, child: _TH(text: 'Total Cost')),
                Expanded(flex: 2, child: _TH(text: 'Sale Price')),
                Expanded(flex: 1, child: _TH(text: 'Items')),
                SizedBox(width: 40),
              ],
            ),
          ),

          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transfers.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: AppColor.grey200),
            itemBuilder: (context, index) {
              final t = transfers[index];
              return _TransferRow(
                transfer: t,
                // ✅ KEY FIX: showDialog use karo — Stack approach
                // desktop pe reliable nahi tha
                onTap: () async {
                  await notifier.openTransferDetail(t);
                  if (context.mounted) {
                    await showDialog(
                      context: context,
                      barrierColor: Colors.black38,
                      barrierDismissible: true,
                      builder: (_) => const AssignStockDetailsDialogWidget(),
                    );
                    // Dialog band hone ke baad state clear karo
                    notifier.closeDetail();
                  }
                },
              );
            },
          ),

          // Footer totals
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.04),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12)),
              border: Border(top: BorderSide(color: AppColor.grey200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${transfers.length} transfers',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary),
                  ),
                ),
                const Spacer(flex: 7),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Rs ${_fmtFull(transfers.fold(0.0, (s, t) => s + t.totalCost))}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColor.primary),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Rs ${_fmtFull(transfers.fold(0.0, (s, t) => s + t.totalSalePrice))}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColor.success),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(flex: 1, child: SizedBox()),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtFull(double v) => v.toStringAsFixed(0);
}

class _TH extends StatelessWidget {
  final String text;
  const _TH({required this.text});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColor.textSecondary,
        letterSpacing: 0.3),
    textAlign: TextAlign.center,
  );
}

// ✅ FIX: GestureDetector hataya — InkWell use kiya (desktop pe reliable)
class _TransferRow extends StatefulWidget {
  final TransferReportItem transfer;
  final VoidCallback onTap;

  const _TransferRow({required this.transfer, required this.onTap});

  @override
  State<_TransferRow> createState() => _TransferRowState();
}

class _TransferRowState extends State<_TransferRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.transfer;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          color: _hovered
              ? AppColor.primary.withOpacity(0.03)
              : Colors.transparent,
          child: Row(
            children: [
              // Transfer number
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.transferNumber,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColor.primary),
                    ),
                    if (t.notes != null && t.notes!.isNotEmpty)
                      Text(
                        t.notes!,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColor.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Store
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColor.grey100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColor.grey200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.store_rounded,
                              size: 11,
                              color: AppColor.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              t.toStoreName,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColor.textSecondary,
                                  fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Assigned by
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Avatar(name: t.assignedByName ?? 'W'),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        t.assignedByName ?? '—',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColor.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Date
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(t.assignedAt),
                      style: const TextStyle(
                          fontSize: 12, color: AppColor.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      DateFormat('hh:mm a').format(t.assignedAt),
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColor.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Status
              SizedBox(
                width: 90,
                child: Center(child: _StatusBadge(status: t.status)),
              ),

              // Total cost
              Expanded(
                flex: 2,
                child: Text(
                  'Rs ${t.totalCost.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary),
                  textAlign: TextAlign.center,
                ),
              ),

              // Sale price
              Expanded(
                flex: 2,
                child: Text(
                  'Rs ${t.totalSalePrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColor.success),
                  textAlign: TextAlign.center,
                ),
              ),

              // Items count
              Expanded(
                flex: 1,
                child: Text(
                  '${t.totalItems}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColor.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),

              // View icon
              SizedBox(
                width: 40,
                child: Center(
                  child: Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: _hovered
                        ? AppColor.primary
                        : AppColor.grey400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  Color _colorFromName(String n) {
    final colors = [
      const Color(0xFF1E88E5),
      const Color(0xFF43A047),
      const Color(0xFFE53935),
      const Color(0xFF8E24AA),
      const Color(0xFFFB8C00),
    ];
    return colors[n.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final initials =
    name.trim().isEmpty ? 'W' : name.trim()[0].toUpperCase();
    final color = _colorFromName(initials);
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color),
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;
    switch (status.toLowerCase()) {
      case 'accepted':
        bg = AppColor.success.withOpacity(0.12);
        fg = AppColor.success;
        label = '● Accepted';
        break;
      case 'pending':
        bg = Colors.orange.withOpacity(0.12);
        fg = Colors.orange;
        label = '● Pending';
        break;
      case 'rejected':
        bg = AppColor.error.withOpacity(0.12);
        fg = AppColor.error;
        label = '● Rejected';
        break;
      default:
        bg = AppColor.grey200;
        fg = AppColor.textSecondary;
        label = status;
    }
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

// ─── Page wrapper — router mein yahi use karo ─────────────────────────────────

class AssignStockReportPage extends ConsumerWidget {
  const AssignStockReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AssignStockReportScreen();
  }
}