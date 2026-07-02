import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../data/model/accountant_finance_model.dart';
import '../provider/accountant_finance_provider.dart';

// =============================================================
// Accountant → Warehouse Finance (read-only)
// Cash in Hand + Expenses + selected warehouse ki saari
// warehouse_cash_transactions. Koi edit/delete nahi.
// =============================================================
class AccountantWarehouseFinanceScreen extends ConsumerStatefulWidget {
  final String warehouseId;
  final String warehouseName;
  const AccountantWarehouseFinanceScreen({
    super.key,
    required this.warehouseId,
    this.warehouseName = 'Warehouse',
  });

  @override
  ConsumerState<AccountantWarehouseFinanceScreen> createState() =>
      _AccountantWarehouseFinanceScreenState();
}

class _AccountantWarehouseFinanceScreenState
    extends ConsumerState<AccountantWarehouseFinanceScreen> {
  String _filter = 'all'; // all | cash_in | expense | supplier_payment | purchase

  // Default: last 1 week (aaj se 7 din pehle → aaj tak)
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _toDate   = DateTime(now.year, now.month, now.day);
    _fromDate = _toDate.subtract(const Duration(days: 7));
  }

  // Transaction ki date selected range mein hai? (inclusive, pura "to" din shamil)
  bool _inRange(DateTime d) {
    final from = DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
    final to   = DateTime(_toDate.year, _toDate.month, _toDate.day, 23, 59, 59);
    return !d.isBefore(from) && !d.isAfter(to);
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // Single range picker — start + end aik saath
  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context:          context,
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      firstDate:        DateTime(2020),
      lastDate:         DateTime(now.year, now.month, now.day), // aaj tak
      helpText:         'Select range',
      saveText:         'Save',
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate   = picked.end;
      });
    }
  }

  // Date range field — tap par range picker. Mobile + website dono par fit.
  Widget _rangeField() {
    return InkWell(
      onTap:        _pickRange,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:        AppColor.grey100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range_rounded,
                size: 18, color: AppColor.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Date range',
                    style: TextStyle(fontSize: 10, color: AppColor.textMuted),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${_fmtDate(_fromDate)}  –  ${_fmtDate(_toDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: AppColor.textMuted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync =
        ref.watch(accFinanceSummaryProvider(widget.warehouseId));
    final txAsync =
        ref.watch(accFinanceTransactionsProvider(widget.warehouseId));

    // Selected range ki transactions — cards ke 3 totals + list dono isi se
    final allTx = txAsync.value ?? const <AccCashTransactionModel>[];
    final dateFiltered = allTx.where((t) => _inRange(t.createdAt)).toList();

    double sumWhere(bool Function(AccCashTransactionModel) test) =>
        dateFiltered.where(test).fold(0.0, (s, t) => s + t.amount.abs());

    final rangeCashIn  = sumWhere((t) => t.entryType == 'cash_in');
    final rangeExpense = sumWhere((t) => t.entryType == 'expense');
    final rangeCashOut = sumWhere((t) => !t.isCashIn); // purchase + supplier + expense

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColor.textDark),
        title: const Text(
          'Warehouse Finance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColor.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColor.primary,
          onRefresh: () async {
            ref.invalidate(accFinanceSummaryProvider(widget.warehouseId));
            ref.invalidate(accFinanceTransactionsProvider(widget.warehouseId));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Summary (4 cards) ─────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: txAsync.isLoading
                      ? const _SummaryShimmer()
                      : _SummarySection(
                          cashInHand:    summaryAsync.value?.cashInHand ?? 0,
                          totalCashIn:   rangeCashIn,
                          totalExpense:  rangeExpense,
                          totalCashOut:  rangeCashOut,
                          warehouseName: widget.warehouseName,
                        ),
                ),
              ),

              // ── Date range filter (cards ke neeche) — default last week ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: _rangeField(),
                ),
              ),

              // ── Section title + filters ───────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cash Transactions',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _chip('All', 'all'),
                            _chip('Cash In', 'cash_in'),
                            _chip('Expense', 'expense'),
                            _chip('Supplier Pay', 'supplier_payment'),
                            _chip('Purchase', 'purchase'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // ── Transactions list ─────────────────────────
              txAsync.when(
                data: (all) {
                  // Pehle date range, phir entry-type chip filter
                  final list = all.where((t) {
                    if (!_inRange(t.createdAt)) return false;
                    if (_filter == 'all') return true;
                    return t.entryType == _filter;
                  }).toList();

                  if (list.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'Koi transaction nahi mili',
                            style: TextStyle(color: AppColor.textMuted),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _TxTile(tx: list[i]),
                        childCount: list.length,
                      ),
                    ),
                  );
                },
                loading: () => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: List.generate(
                        6,
                        (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: _ShimmerBox(height: 68),
                        ),
                      ),
                    ),
                  ),
                ),
                error: (e, _) => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: _ErrorBox(msg: 'Transactions load nahi hui'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColor.primary : AppColor.grey100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColor.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Summary Section (4 compact cards, no icons) ───────────────────────────────
class _SummarySection extends StatelessWidget {
  final double cashInHand;
  final double totalCashIn;
  final double totalExpense;
  final double totalCashOut;
  final String warehouseName;
  const _SummarySection({
    required this.cashInHand,
    required this.totalCashIn,
    required this.totalExpense,
    required this.totalCashOut,
    required this.warehouseName,
  });

  String _money(double v) {
    final neg = v < 0;
    final s = v.abs().toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '${neg ? '- ' : ''}Rs. $s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Warehouse name (chhota label)
        Text(
          warehouseName,
          style: const TextStyle(fontSize: 12, color: AppColor.textMuted),
        ),
        const SizedBox(height: 10),

        // Row 1 — Cash in Hand | Total Cash In
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Cash in Hand',
                value: _money(cashInHand),
                valueColor:
                    cashInHand < 0 ? AppColor.cashOut : AppColor.textDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Total Cash In',
                value: _money(totalCashIn),
                valueColor: AppColor.cashIn,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2 — Total Expenses | Total Cash Out
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Expenses',
                value: _money(totalExpense),
                valueColor: AppColor.cashOut,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Total Cash Out',
                value: _money(totalCashOut),
                valueColor: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Compact stat card — bina icon (kam height)
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColor.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColor.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transaction Tile (expandable) ─────────────────────────────────────────────
class _TxTile extends StatelessWidget {
  final AccCashTransactionModel tx;
  const _TxTile({required this.tx});

  String _money(double v) {
    final neg = v < 0;
    final s = v.abs().toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '${neg ? '- ' : ''}Rs. $s';
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _dateTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ap = d.hour < 12 ? 'AM' : 'PM';
    final m = d.minute.toString().padLeft(2, '0');
    return '${_date(d)}  $h:$m $ap';
  }

  @override
  Widget build(BuildContext context) {
    final isIn = tx.isCashIn;
    final color = isIn ? AppColor.cashIn : AppColor.cashOut;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isIn ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            tx.entryTypeLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColor.textDark,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              // Expense ke saath notes, supplier payment ke saath supplier name
              tx.entryType == 'expense' && tx.notes?.isNotEmpty == true
                  ? '${_date(tx.createdAt)}  •  ${tx.notes}'
                  : (tx.supplierName?.isNotEmpty == true
                      ? '${_date(tx.createdAt)}  •  ${tx.supplierName}'
                      : _date(tx.createdAt)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColor.textMuted),
            ),
          ),
          trailing: Text(
            '${isIn ? '+ ' : '- '}${_money(tx.amount.abs())}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 10),
            _row('Type', tx.entryTypeLabel),
            if (tx.supplierName?.isNotEmpty == true)
              _row('Paid To', tx.supplierName!, valueColor: AppColor.primary),
            _row('Amount', '${isIn ? '+ ' : '- '}${_money(tx.amount.abs())}',
                valueColor: color),
            _row('Date & Time', _dateTime(tx.createdAt)),
            _row('Cash Before', _money(tx.cashInHandBefore)),
            _row('Cash After', _money(tx.cashInHandAfter)),
            if (tx.createdByName?.isNotEmpty == true)
              _row('Created By', tx.createdByName!),
            if (tx.notes?.isNotEmpty == true) _row('Notes', tx.notes!),
            _row('Transaction ID', tx.id),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColor.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColor.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer / Error ───────────────────────────────────────────────────────────
class _SummaryShimmer extends StatelessWidget {
  const _SummaryShimmer();
  @override
  Widget build(BuildContext context) => Column(
        children: const [
          Row(
            children: [
              Expanded(child: _ShimmerBox(height: 70, radius: 16)),
              SizedBox(width: 12),
              Expanded(child: _ShimmerBox(height: 70, radius: 16)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ShimmerBox(height: 70, radius: 16)),
              SizedBox(width: 12),
              Expanded(child: _ShimmerBox(height: 70, radius: 16)),
            ],
          ),
        ],
      );
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  final double radius;
  const _ShimmerBox({required this.height, this.radius = 14});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

class _ErrorBox extends StatelessWidget {
  final String msg;
  const _ErrorBox({required this.msg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
          ],
        ),
      );
}
