import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../data/model/cash_transfer_model.dart';
import '../provider/cash_transfer_provider.dart';

// =============================================================
// Accountant → Sent Cash Transfers (read-only status list)
// pending / accepted / rejected dikhata hai
// =============================================================
class AccountantCashTransfersScreen extends ConsumerStatefulWidget {
  // Agar warehouseId diya ho to sirf usi warehouse ke transfers,
  // warna accountant ke saare bheje transfers.
  final String? warehouseId;
  const AccountantCashTransfersScreen({super.key, this.warehouseId});

  @override
  ConsumerState<AccountantCashTransfersScreen> createState() =>
      _AccountantCashTransfersScreenState();
}

class _AccountantCashTransfersScreenState
    extends ConsumerState<AccountantCashTransfersScreen> {
  // Default: last 2 weeks (aaj se 14 din pehle → aaj tak)
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _toDate   = DateTime(now.year, now.month, now.day);
    _fromDate = _toDate.subtract(const Duration(days: 14));
  }

  // Transfer ki date selected range mein hai? (inclusive, pura "to" din shamil)
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
    final warehouseId = widget.warehouseId;
    final transfersAsync = warehouseId != null
        ? ref.watch(warehouseCashTransfersProvider(warehouseId))
        : ref.watch(myCashTransfersProvider);

    // Selected date range ke transfers — rejected count nahi
    final rangeTransfers = (transfersAsync.value ?? const <CashTransferModel>[])
        .where((t) => _inRange(t.createdAt) && t.status != 'rejected')
        .toList();
    final totalValue =
        rangeTransfers.fold<double>(0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColor.textDark),
        title: const Text(
          'Cash Transfers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColor.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Total Cash Transfer Value (selected dates, rejected nahi) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:      Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset:     const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width:  44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:        AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: AppColor.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total Cash Transfer Value',
                            style: TextStyle(
                                fontSize: 12, color: AppColor.textMuted),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _fmtRs(totalValue),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color:        AppColor.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${rangeTransfers.length} transfers',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Date range filter — default last 1 week ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: _rangeField(),
            ),

            Expanded(
              child: RefreshIndicator(
                color: AppColor.primary,
                onRefresh: () async => warehouseId != null
                    ? ref.invalidate(
                        warehouseCashTransfersProvider(warehouseId))
                    : ref.invalidate(myCashTransfersProvider),
                child: transfersAsync.when(
                  data: (all) {
                    final list =
                        all.where((t) => _inRange(t.createdAt)).toList();

                    if (list.isEmpty) {
                      return ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text(
                              'Is range mein koi cash transfer nahi',
                              style: TextStyle(color: AppColor.textMuted),
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: list.length,
                      itemBuilder: (_, i) =>
                          _TransferTile(transfer: list[i]),
                    );
                  },
                  loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: AppColor.primary),
                  ),
                  error: (e, _) => ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'Transfers load nahi hue — pull to refresh',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
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

// Rs. formatting (thousands separator)
String _fmtRs(double v) {
  final neg = v < 0;
  final s = v.abs().toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  return '${neg ? '- ' : ''}Rs. $s';
}

class _TransferTile extends StatelessWidget {
  final CashTransferModel transfer;
  const _TransferTile({required this.transfer});

  String _money(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'Rs. $s';
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  ({Color color, Color bg, IconData icon}) _statusStyle() {
    switch (transfer.status) {
      case 'accepted':
        return (
          color: AppColor.cashIn,
          bg: const Color(0xFFECFDF5),
          icon: Icons.check_circle_rounded
        );
      case 'rejected':
        return (
          color: AppColor.cashOut,
          bg: const Color(0xFFFEF2F2),
          icon: Icons.cancel_rounded
        );
      default: // pending
        return (
          color: const Color(0xFFF59E0B),
          bg: const Color(0xFFFFF4E5),
          icon: Icons.hourglass_top_rounded
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _statusStyle();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: s.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(s.icon, color: s.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transfer.warehouseName ?? 'Warehouse',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 15,
                    color: AppColor.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _date(transfer.createdAt),
                  style: const TextStyle(
                      fontSize: 12, color: AppColor.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _money(transfer.amount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: s.bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  transfer.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: s.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
