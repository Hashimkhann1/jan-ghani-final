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

  @override
  Widget build(BuildContext context) {
    final summaryAsync =
        ref.watch(accFinanceSummaryProvider(widget.warehouseId));
    final txAsync =
        ref.watch(accFinanceTransactionsProvider(widget.warehouseId));

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
              // ── Summary ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: summaryAsync.when(
                    data: (s) => _SummarySection(
                      summary: s,
                      warehouseName: widget.warehouseName,
                    ),
                    loading: () => const _SummaryShimmer(),
                    error: (e, _) => const _ErrorBox(
                        msg: 'Finance summary load nahi hui'),
                  ),
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
                  final list = _filter == 'all'
                      ? all
                      : all.where((t) => t.entryType == _filter).toList();

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

// ── Summary Section ───────────────────────────────────────────────────────────
class _SummarySection extends StatelessWidget {
  final AccFinanceSummary summary;
  final String warehouseName;
  const _SummarySection({required this.summary, required this.warehouseName});

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
        // Cash in Hand (highlight)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColor.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Cash in Hand',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85), fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _money(summary.cashInHand),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                warehouseName,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Expenses + Cash Out
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.receipt_long_rounded,
                iconColor: AppColor.cashOut,
                iconBg: const Color(0xFFFEF2F2),
                label: 'Total Expenses',
                value: _money(summary.totalExpense),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.arrow_upward_rounded,
                iconColor: const Color(0xFFF59E0B),
                iconBg: const Color(0xFFFFF4E5),
                label: 'Total Cash Out',
                value: _money(summary.totalCashOut),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColor.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColor.textDark,
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
              tx.supplierName?.isNotEmpty == true
                  ? '${_date(tx.createdAt)}  •  ${tx.supplierName}'
                  : _date(tx.createdAt),
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
        children: [
          const _ShimmerBox(height: 130, radius: 20),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: _ShimmerBox(height: 96)),
              SizedBox(width: 12),
              Expanded(child: _ShimmerBox(height: 96)),
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
