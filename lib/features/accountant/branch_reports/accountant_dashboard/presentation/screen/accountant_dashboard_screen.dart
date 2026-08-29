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

  List<_StatSpec> _specs() => _dashboardSpecs(data, fmtAmt);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: _StatCardsGrid(specs: _specs(), crossAxisCount: 4, childAspectRatio: 2.5),
    );
  }
}

// ── Mobile Body ───────────────────────────────────────────────────────────────
class _MobileBody extends StatelessWidget {
  final AccountantBranchDashboardModel data;
  final String Function(double)        fmtAmt;

  const _MobileBody({required this.data, required this.fmtAmt});

  List<_StatSpec> _specs() => _dashboardSpecs(data, fmtAmt);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: _StatCardsGrid(specs: _specs(), crossAxisCount: 2, childAspectRatio: 1.7),
    );
  }
}

// ── Stat spec list (shared desktop/mobile) ─────────────────────────────────────
class _StatSpec {
  final String label;
  final String value;
  const _StatSpec(this.label, this.value);
}

List<_StatSpec> _dashboardSpecs(
  AccountantBranchDashboardModel data,
  String Function(double) fmtAmt,
) =>
    [
      _StatSpec('Total Sale', fmtAmt(data.totalSale)),
      _StatSpec('Cash Sale', fmtAmt(data.cashSale)),
      _StatSpec('Card Sale', fmtAmt(data.cardSale)),
      _StatSpec('Credit Sale', fmtAmt(data.creditSale)),
      _StatSpec('Installment Sale', fmtAmt(data.installmentSale)),
      _StatSpec('Sale Returns', fmtAmt(data.totalSaleReturn)),
      _StatSpec('Gross Profit', fmtAmt(data.grossProfit)),
      _StatSpec('Cash In', fmtAmt(data.cashIn)),
      _StatSpec('Cash Out', fmtAmt(data.cashOut)),
      _StatSpec('Stock Sale Value', fmtAmt(data.stockSaleValue)),
      _StatSpec('Stock Purchase Value', fmtAmt(data.inventoryValue)),
      _StatSpec('Total Damage', fmtAmt(data.totalDamage)),
      _StatSpec('Outstanding Receivable', fmtAmt(data.outstandingReceivable)),
    ];

// ── Stat Cards Grid ──────────────────────────────────────────────────────────
class _StatCardsGrid extends StatelessWidget {
  final List<_StatSpec> specs;
  final int             crossAxisCount;
  final double          childAspectRatio;

  const _StatCardsGrid({
    required this.specs,
    required this.crossAxisCount,
    required this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: specs.length,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: childAspectRatio,
    ),
    itemBuilder: (_, i) =>
        _FlatStatCard(label: specs[i].label, value: specs[i].value),
  );
}

// ── Flat Stat Card ───────────────────────────────────────────────────────────
class _FlatStatCard extends StatelessWidget {
  final String label;
  final String value;

  const _FlatStatCard({required this.label, required this.value});

  static const _cardColor = Color(0xFF4B5563);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    decoration: BoxDecoration(
      color:        _cardColor,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize:   18,
            fontWeight: FontWeight.w800,
            color:      Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize:   13,
            fontWeight: FontWeight.w500,
            color:      Colors.white.withOpacity(0.85),
          ),
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