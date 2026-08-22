import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../data/model/accountant_dashboard_model.dart';
import '../provider/accountant_dashboard_provider.dart';

class AccountantBranchDashboardScreen extends ConsumerStatefulWidget {
  const AccountantBranchDashboardScreen(
      {required this.branchId, super.key});
  final String branchId;

  @override
  ConsumerState<AccountantBranchDashboardScreen> createState() =>
      _AccountantBranchDashboardScreenState();
}

class _AccountantBranchDashboardScreenState
    extends ConsumerState<AccountantBranchDashboardScreen> {
  final _amtFmt       = NumberFormat('#,##,###', 'en_IN');
  final _dateFmt      = DateFormat('dd MMM yyyy');
  final _timeFmt      = DateFormat('hh:mm a');
  final _fromCtrl     = TextEditingController();
  final _toCtrl       = TextEditingController();
  final _fromTimeCtrl = TextEditingController();
  final _toTimeCtrl   = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(accountantBranchDashboardProvider(widget.branchId));
    _fromCtrl.text     = _dateFmt.format(state.fromDate);
    _toCtrl.text       = _dateFmt.format(state.toDate);
    _fromTimeCtrl.text = _timeFmt.format(state.fromDate);
    _toTimeCtrl.text   = _timeFmt.format(state.toDate);
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _fromTimeCtrl.dispose();
    _toTimeCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 800;

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final state = ref.read(accountantBranchDashboardProvider(widget.branchId));
    final init  = isFrom ? state.fromDate : state.toDate;
    final picked = await showDatePicker(
      context:     context,
      initialDate: init,
      firstDate:   DateTime(2024),
      lastDate:    DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColor.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final notifier = ref.read(
        accountantBranchDashboardProvider(widget.branchId).notifier);
    final combined = DateTime(
      picked.year, picked.month, picked.day,
      init.hour, init.minute, init.second,
    );
    if (isFrom) {
      _fromCtrl.text = _dateFmt.format(combined);
      notifier.setFromDate(combined);
    } else {
      _toCtrl.text = _dateFmt.format(combined);
      notifier.setToDate(combined);
    }
  }

  Future<void> _pickTime(BuildContext context, bool isFrom) async {
    final state = ref.read(accountantBranchDashboardProvider(widget.branchId));
    final init  = isFrom ? state.fromDate : state.toDate;
    final picked = await showTimePicker(
      context:     context,
      initialTime: TimeOfDay.fromDateTime(init),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColor.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final notifier = ref.read(
        accountantBranchDashboardProvider(widget.branchId).notifier);
    final combined = DateTime(
      init.year, init.month, init.day,
      picked.hour, picked.minute,
    );
    if (isFrom) {
      _fromTimeCtrl.text = _timeFmt.format(combined);
      notifier.setFromDate(combined);
    } else {
      _toTimeCtrl.text = _timeFmt.format(combined);
      notifier.setToDate(combined);
    }
  }

  void _setToday(dynamic notifier) {
    notifier.setToday();
    final now        = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay   = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _fromCtrl.text     = _dateFmt.format(startOfDay);
    _toCtrl.text       = _dateFmt.format(endOfDay);
    _fromTimeCtrl.text = _timeFmt.format(startOfDay);
    _toTimeCtrl.text   = _timeFmt.format(endOfDay);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
        accountantBranchDashboardProvider(widget.branchId));
    final notifier = ref.read(
        accountantBranchDashboardProvider(widget.branchId).notifier);
    final desktop = _isDesktop(context);

    ref.listen<AccountantBranchDashboardState>(
      accountantBranchDashboardProvider(widget.branchId),
          (prev, next) {
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
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: desktop
          ? _DesktopScaffold(
        state:       state,
        notifier:    notifier,
        fmtAmt:      _fmt,
        fromCtrl:    _fromCtrl,
        toCtrl:      _toCtrl,
        fromTimeCtrl: _fromTimeCtrl,
        toTimeCtrl:   _toTimeCtrl,
        onPickFrom:     () => _pickDate(context, true),
        onPickTo:       () => _pickDate(context, false),
        onPickFromTime: () => _pickTime(context, true),
        onPickToTime:   () => _pickTime(context, false),
        onToday:        () => _setToday(notifier),
      )
          : _MobileScaffold(
        state:       state,
        notifier:    notifier,
        fmtAmt:      _fmt,
        fromCtrl:    _fromCtrl,
        toCtrl:      _toCtrl,
        fromTimeCtrl: _fromTimeCtrl,
        toTimeCtrl:   _toTimeCtrl,
        onPickFrom:     () => _pickDate(context, true),
        onPickTo:       () => _pickDate(context, false),
        onPickFromTime: () => _pickTime(context, true),
        onPickToTime:   () => _pickTime(context, false),
        onToday:        () => _setToday(notifier),
      ),
    );
  }
}

// ── Desktop Scaffold ──────────────────────────────────────────────────────────
class _DesktopScaffold extends StatelessWidget {
  final AccountantBranchDashboardState state;
  final dynamic notifier;
  final String Function(double) fmtAmt;
  final TextEditingController fromCtrl;
  final TextEditingController toCtrl;
  final TextEditingController fromTimeCtrl;
  final TextEditingController toTimeCtrl;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onPickFromTime;
  final VoidCallback onPickToTime;
  final VoidCallback onToday;

  const _DesktopScaffold({
    required this.state,
    required this.notifier,
    required this.fmtAmt,
    required this.fromCtrl,
    required this.toCtrl,
    required this.fromTimeCtrl,
    required this.toTimeCtrl,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onPickFromTime,
    required this.onPickToTime,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top bar ────────────────────────────────────────
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Color(0xFF1A1D23)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F6FA),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:       MainAxisSize.min,
                children: [
                  Text(
                    'Branch Dashboard',
                    style: TextStyle(
                      fontSize:   22,
                      fontWeight: FontWeight.w700,
                      color:      Color(0xFF1A1D23),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Aaj ka branch overview',
                    style: TextStyle(
                        fontSize: 13, color: AppColor.textHint),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 90,
                child: OutlinedButton(
                  onPressed: onToday,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.primary,
                    side: const BorderSide(color: AppColor.primary),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Today'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: OutlinedButton.icon(
                  onPressed: notifier.load,
                  icon:  const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.primary,
                    side: const BorderSide(color: AppColor.primary),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // ── Date/Time filter row ─────────────────────────────
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
          child: Row(
            children: [
              Expanded(
                child: _DateField(
                  label:      'Start Date',
                  controller: fromCtrl,
                  onTap:      onPickFrom,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeField(
                  label:      'Start Time',
                  controller: fromTimeCtrl,
                  onTap:      onPickFromTime,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label:      'End Date',
                  controller: toCtrl,
                  onTap:      onPickTo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeField(
                  label:      'End Time',
                  controller: toTimeCtrl,
                  onTap:      onPickToTime,
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // ── Content ────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.data == null
              ? const _EmptyState()
              : _DesktopBody(
            data:   state.data!,
            fmtAmt: fmtAmt,
          ),
        ),
      ],
    );
  }
}

// ── Mobile Scaffold ───────────────────────────────────────────────────────────
class _MobileScaffold extends StatelessWidget {
  final AccountantBranchDashboardState state;
  final dynamic notifier;
  final String Function(double) fmtAmt;
  final TextEditingController fromCtrl;
  final TextEditingController toCtrl;
  final TextEditingController fromTimeCtrl;
  final TextEditingController toTimeCtrl;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onPickFromTime;
  final VoidCallback onPickToTime;
  final VoidCallback onToday;

  const _MobileScaffold({
    required this.state,
    required this.notifier,
    required this.fmtAmt,
    required this.fromCtrl,
    required this.toCtrl,
    required this.fromTimeCtrl,
    required this.toTimeCtrl,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onPickFromTime,
    required this.onPickToTime,
    required this.onToday,
  });

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColor.grey200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Date & Time Filter',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D23),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        onToday();
                        setSheetState(() {});
                      },
                      child: const Text('Today'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: _DateField(
                      label: 'Start Date',
                      controller: fromCtrl,
                      onTap: () async {
                        onPickFrom();
                        setSheetState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: 'Start Time',
                      controller: fromTimeCtrl,
                      onTap: () async {
                        onPickFromTime();
                        setSheetState(() {});
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: _DateField(
                      label: 'End Date',
                      controller: toCtrl,
                      onTap: () async {
                        onPickTo();
                        setSheetState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: 'End Time',
                      controller: toTimeCtrl,
                      onTap: () async {
                        onPickToTime();
                        setSheetState(() {});
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Branch Dashboard',
          style: TextStyle(
              fontSize:   17,
              fontWeight: FontWeight.w700,
              color:      Color(0xFF1A1D23)),
        ),
        actions: [
          IconButton(
            onPressed: () => _showFilterSheet(context),
            icon: const Icon(Icons.filter_list_rounded,
                color: AppColor.textSecondary),
            tooltip: 'Filters',
          ),
          IconButton(
            onPressed: notifier.load,
            icon: const Icon(Icons.refresh_rounded,
                color: AppColor.textSecondary),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.data == null
          ? const _EmptyState()
          : _MobileBody(data: state.data!, fmtAmt: fmtAmt),
    );
  }
}

// ── Desktop Body ──────────────────────────────────────────────────────────────
class _DesktopBody extends StatelessWidget {
  final AccountantBranchDashboardModel data;
  final String Function(double)        fmtAmt;

  const _DesktopBody({required this.data, required this.fmtAmt});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          // ── Summary stat cards row ─────────────────────
          Row(
            children: [
              Expanded(
                child: _SummaryStatCard(
                  icon:  Icons.trending_up_rounded,
                  label: 'Net Sale',
                  value: fmtAmt(data.netSale),
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryStatCard(
                  icon:  Icons.account_balance_wallet_outlined,
                  label: 'Amount Received',
                  value: fmtAmt(data.totalAmountReceived),
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryStatCard(
                  icon:  Icons.bar_chart_rounded,
                  label: 'Gross Profit',
                  value: fmtAmt(data.grossProfit),
                  color: data.grossProfit >= 0
                      ? AppColor.success
                      : AppColor.error,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryStatCard(
                  icon:  Icons.people_outline_rounded,
                  label: 'Receivable',
                  value: fmtAmt(data.outstandingReceivable),
                  color: AppColor.warning,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Two column: Sales + Cash/Profit/Inventory ──
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left — Sales detail
                Expanded(
                  flex: 3,
                  child: _SectionCard(
                    icon:  Icons.shopping_cart_outlined,
                    title: 'Sales',
                    color: AppColor.primary,
                    children: [
                      _DashRow(
                        icon:  Icons.receipt_outlined,
                        label: 'Total Sale',
                        value: fmtAmt(data.totalSale),
                        color: AppColor.primary,
                        bold:  true,
                      ),
                      _divider(),
                      _DashRow(
                        icon:  Icons.payments_outlined,
                        label: 'Cash Sale',
                        value: fmtAmt(data.cashSale),
                        color: AppColor.success,
                      ),
                      _DashRow(
                        icon:  Icons.credit_card_outlined,
                        label: 'Card Sale',
                        value: fmtAmt(data.cardSale),
                        color: AppColor.info,
                      ),
                      _DashRow(
                        icon:  Icons.receipt_long_outlined,
                        label: 'Credit Sale',
                        value: fmtAmt(data.creditSale),
                        color: AppColor.warning,
                      ),
                      _DashRow(
                        icon:  Icons.event_repeat_rounded,
                        label: 'Installment Sale',
                        value: fmtAmt(data.installmentSale),
                        color: const Color(0xFF8B5CF6),
                      ),
                      _divider(),
                      _DashRow(
                        icon:   Icons.undo_rounded,
                        label:  'Sale Returns',
                        value:  fmtAmt(data.totalSaleReturn),
                        color:  AppColor.error,
                        prefix: '- ',
                      ),
                      _divider(),
                      _DashRow(
                        icon:  Icons.trending_up_rounded,
                        label: 'Net Sale',
                        value: fmtAmt(data.netSale),
                        color: AppColor.primary,
                        bold:  true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Right — 3 stacked cards
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _SectionCard(
                        icon:  Icons.account_balance_wallet_outlined,
                        title: 'Cash Received',
                        color: const Color(0xFF8B5CF6),
                        children: [
                          _DashRow(
                            icon:  Icons.account_balance_wallet_outlined,
                            label: 'Total Received',
                            value: fmtAmt(data.totalAmountReceived),
                            color: const Color(0xFF8B5CF6),
                            bold:  true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        icon:  Icons.bar_chart_rounded,
                        title: 'Profit',
                        color: AppColor.success,
                        children: [
                          _DashRow(
                            icon:  Icons.bar_chart_rounded,
                            label: 'Gross Profit',
                            value: fmtAmt(data.grossProfit),
                            color: data.grossProfit >= 0
                                ? AppColor.success
                                : AppColor.error,
                            bold:  true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        icon:  Icons.inventory_2_outlined,
                        title: 'Inventory',
                        color: AppColor.info,
                        children: [
                          _DashRow(
                            icon:  Icons.inventory_2_outlined,
                            label: 'Inventory Value',
                            value: fmtAmt(data.inventoryValue),
                            color: AppColor.info,
                            bold:  true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        icon:  Icons.people_outline_rounded,
                        title: 'Outstanding',
                        color: AppColor.warning,
                        children: [
                          _DashRow(
                            icon:  Icons.people_outline_rounded,
                            label: 'Receivable',
                            value: fmtAmt(data.outstandingReceivable),
                            color: AppColor.warning,
                            bold:  true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Divider(height: 1, color: Color(0xFFE5E7EB)),
  );
}

// ── Mobile Body ───────────────────────────────────────────────────────────────
class _MobileBody extends StatelessWidget {
  final AccountantBranchDashboardModel data;
  final String Function(double)        fmtAmt;

  const _MobileBody({required this.data, required this.fmtAmt});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _SectionCard(
          icon:  Icons.shopping_cart_outlined,
          title: 'Sales',
          color: AppColor.primary,
          children: [
            _DashRow(
              icon:  Icons.receipt_outlined,
              label: 'Total Sale',
              value: fmtAmt(data.totalSale),
              color: AppColor.primary,
              bold:  true,
            ),
            _divider(),
            _DashRow(
              icon:  Icons.payments_outlined,
              label: 'Cash Sale',
              value: fmtAmt(data.cashSale),
              color: AppColor.success,
            ),
            _DashRow(
              icon:  Icons.credit_card_outlined,
              label: 'Card Sale',
              value: fmtAmt(data.cardSale),
              color: AppColor.info,
            ),
            _DashRow(
              icon:  Icons.receipt_long_outlined,
              label: 'Credit Sale',
              value: fmtAmt(data.creditSale),
              color: AppColor.warning,
            ),
            _DashRow(
              icon:  Icons.event_repeat_rounded,
              label: 'Installment Sale',
              value: fmtAmt(data.installmentSale),
              color: const Color(0xFF8B5CF6),
            ),
            _divider(),
            _DashRow(
              icon:   Icons.undo_rounded,
              label:  'Sale Returns',
              value:  fmtAmt(data.totalSaleReturn),
              color:  AppColor.error,
              prefix: '- ',
            ),
            _divider(),
            _DashRow(
              icon:  Icons.trending_up_rounded,
              label: 'Net Sale',
              value: fmtAmt(data.netSale),
              color: AppColor.primary,
              bold:  true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          icon:  Icons.account_balance_wallet_outlined,
          title: 'Cash Received',
          color: const Color(0xFF8B5CF6),
          children: [
            _DashRow(
              icon:  Icons.account_balance_wallet_outlined,
              label: 'Total Amount Received',
              value: fmtAmt(data.totalAmountReceived),
              color: const Color(0xFF8B5CF6),
              bold:  true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          icon:  Icons.bar_chart_rounded,
          title: 'Profit',
          color: AppColor.success,
          children: [
            _DashRow(
              icon:  Icons.bar_chart_rounded,
              label: 'Gross Profit',
              value: fmtAmt(data.grossProfit),
              color: data.grossProfit >= 0
                  ? AppColor.success
                  : AppColor.error,
              bold:  true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          icon:  Icons.inventory_2_outlined,
          title: 'Inventory',
          color: AppColor.info,
          children: [
            _DashRow(
              icon:  Icons.inventory_2_outlined,
              label: 'Inventory Value',
              value: fmtAmt(data.inventoryValue),
              color: AppColor.info,
              bold:  true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          icon:  Icons.people_outline_rounded,
          title: 'Outstanding',
          color: AppColor.warning,
          children: [
            _DashRow(
              icon:  Icons.people_outline_rounded,
              label: 'Receivable (Customers)',
              value: fmtAmt(data.outstandingReceivable),
              color: AppColor.warning,
              bold:  true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Divider(height: 1, color: Color(0xFFE5E7EB)),
  );
}

// ── Summary Stat Card (Desktop only) ─────────────────────────────────────────
class _SummaryStatCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;

  const _SummaryStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width:  42,
            height: 42,
            decoration: BoxDecoration(
              color:        color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColor.textHint)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                      fontSize:   16,
                      fontWeight: FontWeight.w700,
                      color:      color,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData     icon;
  final String       title;
  final Color        color;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
            ),
            child: Row(children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                    fontSize:   14,
                    fontWeight: FontWeight.w700,
                    color:      color),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// ── Dash Row ──────────────────────────────────────────────────────────────────
class _DashRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  final bool     bold;
  final String   prefix;

  const _DashRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.bold   = false,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color:        color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
                fontSize:   13,
                fontWeight: bold
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: const Color(0xFF4B5563)),
          ),
        ]),
        Text(
          '$prefix$value',
          style: TextStyle(
              fontSize:   13,
              fontWeight: bold
                  ? FontWeight.w800
                  : FontWeight.w700,
              color: color),
        ),
      ],
    ),
  );
}

// ── Empty State ───────────────────────────────────────────────────────────────
// ── Shared date/time filter fields ──────────────────────────────────────────
class _DateField extends StatelessWidget {
  final String                label;
  final TextEditingController controller;
  final VoidCallback          onTap;

  const _DateField({
    required this.label,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize:   11,
          fontWeight: FontWeight.w600,
          color:      AppColor.textSecondary,
        ),
      ),
      const SizedBox(height: 4),
      TextField(
        controller:   controller,
        readOnly:     true,
        onTap:        onTap,
        cursorHeight: 14,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1D23)),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.calendar_today_outlined,
              size: 16, color: AppColor.primary),
          filled:     true,
          fillColor:  AppColor.grey100,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:   BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColor.grey200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
                color: AppColor.primary, width: 1.5),
          ),
        ),
      ),
    ],
  );
}

class _TimeField extends StatelessWidget {
  final String                label;
  final TextEditingController controller;
  final VoidCallback          onTap;

  const _TimeField({
    required this.label,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize:   11,
          fontWeight: FontWeight.w600,
          color:      AppColor.textSecondary,
        ),
      ),
      const SizedBox(height: 4),
      TextField(
        controller:   controller,
        readOnly:     true,
        onTap:        onTap,
        cursorHeight: 14,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1D23)),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.access_time_rounded,
              size: 16, color: AppColor.primary),
          filled:     true,
          fillColor:  AppColor.grey100,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:   BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColor.grey200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
                color: AppColor.primary, width: 1.5),
          ),
        ),
      ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.dashboard_outlined,
          size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(
        'No data found',
        style: TextStyle(
            fontSize:   16,
            fontWeight: FontWeight.w600,
            color:      Colors.grey.shade500),
      ),
      const SizedBox(height: 6),
      Text(
        'Change date range and refresh',
        style: TextStyle(
            fontSize: 13, color: Colors.grey.shade400),
      ),
    ]),
  );
}