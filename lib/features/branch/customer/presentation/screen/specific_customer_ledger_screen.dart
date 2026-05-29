import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/color/app_color.dart';
import '../../data/model/specific_customer_ledger_model.dart';
import '../provider/specific_customer_ledger_provider.dart';

class CustomerLedgerScreen extends ConsumerWidget {
  final String customerId;
  final String customerName;

  const CustomerLedgerScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  ({String customerId, String customerName}) get _args => (
  customerId:   customerId,
  customerName: customerName,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(customerLedgerProvider(_args));
    final notifier = ref.read(customerLedgerProvider(_args).notifier);
    final dateFmt  = DateFormat('dd MMM yyyy');
    final timeFmt  = DateFormat('hh:mm a');
    final amtFmt   = NumberFormat('#,##,###', 'en_IN');
    ref.listen(customerLedgerProvider(_args), (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text(next.errorMessage!),
          backgroundColor: AppColor.error,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label:     'OK',
            textColor: Colors.white,
            onPressed: notifier.clearError,
          ),
        ));
      }
    });

    String fmtAmt(double v) => 'Rs ${amtFmt.format(v.toInt())}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer Ledger',
                style: TextStyle(
                    fontSize:   16,
                    fontWeight: FontWeight.w700,
                    color:      Color(0xFF1A1D23))),
            Text(customerName,
                style: const TextStyle(
                    fontSize: 12, color: AppColor.textSecondary)),
          ],
        ),
        toolbarHeight: 65,
        actions: [
          IconButton(
            onPressed: notifier.load,
            icon: const Icon(Icons.refresh_rounded,
                color: AppColor.textSecondary),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [

        // ── Summary ────────────────────────────────────
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Row(children: [
            _SummaryTile(
              label: 'Transactions',
              value: '${state.ledger.length}',
              icon:  Icons.receipt_long_outlined,
              color: AppColor.primary,
            ),
            _divider(),
            _SummaryTile(
              label: 'Total Paid',
              value: fmtAmt(state.totalPaid),
              icon:  Icons.payments_outlined,
              color: AppColor.success,
            ),
            _divider(),
            _SummaryTile(
              label: 'Balance',
              value: fmtAmt(state.currentBalance),
              icon:  Icons.account_balance_wallet_outlined,
              color: state.currentBalance > 0
                  ? AppColor.error
                  : AppColor.success,
            ),
          ]),
        ),

        Container(height: 1, color: const Color(0xFFE5E7EB)),
        const SizedBox(height: 8),

        // ── Ledger List ────────────────────────────────
        Expanded(
          child: state.ledger.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount:        state.ledger.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
              itemBuilder: (_, i) => _LedgerRow(
                entry:   state.ledger[i],
                dateFmt: dateFmt,
                timeFmt: timeFmt,
                amtFmt:  amtFmt,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _divider() => Container(
    width:  1,
    height: 36,
    color:  const Color(0xFFE5E7EB),
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );
}

// ── Ledger Row ────────────────────────────────────────────────
class _LedgerRow extends StatelessWidget {
  final SpecificCustomerLedgerModel entry;
  final DateFormat          dateFmt;
  final DateFormat          timeFmt;
  final NumberFormat        amtFmt;

  const _LedgerRow({
    required this.entry,
    required this.dateFmt,
    required this.timeFmt,
    required this.amtFmt,
  });

  String _fmt(double v) => 'Rs ${amtFmt.format(v.toInt())}';

  @override
  Widget build(BuildContext context) {
    final isPayment = entry.isPayment;
    final color     = isPayment ? AppColor.success : AppColor.error;
    final icon      = isPayment
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final label     = isPayment ? 'Payment' : 'Credit';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [

        // ── Icon ────────────────────────────────────────
        Container(
          width:  40,
          height: 40,
          decoration: BoxDecoration(
            color:        color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),

        // ── Info ────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Label + Notes
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color:        color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(label,
                            style: TextStyle(
                                fontSize:   10,
                                fontWeight: FontWeight.w700,
                                color:      color)),
                      ),
                      if (entry.notes != null &&
                          entry.notes!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(entry.notes!,
                            style: const TextStyle(
                                fontSize: 11,
                                color:    AppColor.textHint)),
                      ],
                    ],
                  ),

                  // Pay Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isPayment
                            ? '- ${_fmt(entry.payAmount)}'
                            : '+ ${_fmt(entry.payAmount)}',
                        style: TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w800,
                            color:      color),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 8),

              // ── Previous → New Balance ───────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date
                  Text(
                    '${dateFmt.format(entry.createdAt)}  ${timeFmt.format(entry.createdAt)}',
                    style: const TextStyle(
                        fontSize: 10, color: AppColor.textHint),
                  ),

                  // Prev → New
                  Row(children: [
                    Text(_fmt(entry.previousAmount),
                        style: const TextStyle(
                            fontSize: 11,
                            color:    AppColor.textSecondary)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 12, color: AppColor.textHint),
                    ),
                    Text(_fmt(entry.newAmount),
                        style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                            color: entry.newAmount > 0
                                ? AppColor.error
                                : AppColor.success)),
                  ]),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────
class _SummaryTile extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(height: 6),
      Text(value,
          style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w800,
              color:      color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(
              fontSize: 10, color: AppColor.textHint)),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.account_balance_wallet_outlined,
          size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text('Koi record nahi mila',
          style: TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w600,
              color:      Colors.grey.shade500)),
      const SizedBox(height: 6),
      Text('Is customer ka koi ledger entry nahi',
          style: TextStyle(
              fontSize: 13, color: Colors.grey.shade400)),
    ]),
  );
}