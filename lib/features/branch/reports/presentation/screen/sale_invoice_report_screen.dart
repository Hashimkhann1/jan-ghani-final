import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import 'package:jan_ghani_final/features/branch/authentication/presentation/provider/auth_provider.dart';
import 'package:jan_ghani_final/features/branch/customer/presentation/provider/customer_provider.dart';
import 'package:jan_ghani_final/features/branch/reports/data/model/sale_invoice_report_model.dart';
import '../../../../../core/service/print/print_service.dart';
import '../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../sale_invoice/data/model/sale_invoice_model.dart';
import '../provider/sale_invoice_report_provider.dart';

class SaleInvoiceListScreen extends ConsumerStatefulWidget {
  const SaleInvoiceListScreen({super.key});

  @override
  ConsumerState<SaleInvoiceListScreen> createState() =>
      _SaleInvoiceListScreenState();
}

class _SaleInvoiceListScreenState
    extends ConsumerState<SaleInvoiceListScreen> {
  final _searchCtrl     = TextEditingController();
  final _startDateCtrl  = TextEditingController();
  final _endDateCtrl    = TextEditingController();
  final _startTimeCtrl  = TextEditingController();
  final _endTimeCtrl    = TextEditingController();
  final _dateFmt        = DateFormat('dd MMM yyyy');
  final _timeFmt        = DateFormat('hh:mm a');
  final _inputFmt       = DateFormat('dd/MM/yyyy');
  final _inputTimeFmt   = DateFormat('hh:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(saleInvoiceListProvider.notifier).load();
      _syncDateFields();
    });
  }

  void _syncDateFields() {
    final state = ref.read(saleInvoiceListProvider);
    _startDateCtrl.text = _inputFmt.format(state.fromDate);
    _endDateCtrl.text   = _inputFmt.format(state.toDate);
    _startTimeCtrl.text = _inputTimeFmt.format(state.fromDate);
    _endTimeCtrl.text   = _inputTimeFmt.format(state.toDate);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    super.dispose();
  }

  // ── Date Picker ───────────────────────────────────────────
  Future<DateTime?> _pickDate(
      BuildContext context, DateTime initial) async {
    return showDatePicker(
      context:     context,
      initialDate: initial,
      firstDate:   DateTime(2024),
      lastDate:    DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   AppColor.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
  }

  // ── Time Picker ───────────────────────────────────────────
  Future<TimeOfDay?> _pickTime(
      BuildContext context, DateTime initial) async {
    return showTimePicker(
      context:     context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   AppColor.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
  }

  // ── Date Tap Handlers ─────────────────────────────────────
  Future<void> _onStartDateTap() async {
    final state  = ref.read(saleInvoiceListProvider);
    final picked = await _pickDate(context, state.fromDate);
    if (picked != null) {
      final newDate = DateTime(
        picked.year, picked.month, picked.day,
        state.fromDate.hour, state.fromDate.minute, state.fromDate.second,
      );
      _startDateCtrl.text = _inputFmt.format(newDate);
      ref.read(saleInvoiceListProvider.notifier)
          .setDateRange(newDate, state.toDate);
    }
  }

  Future<void> _onEndDateTap() async {
    final state  = ref.read(saleInvoiceListProvider);
    final picked = await _pickDate(context, state.toDate);
    if (picked != null) {
      final newDate = DateTime(
        picked.year, picked.month, picked.day,
        state.toDate.hour, state.toDate.minute, state.toDate.second,
      );
      _endDateCtrl.text = _inputFmt.format(newDate);
      ref.read(saleInvoiceListProvider.notifier)
          .setDateRange(state.fromDate, newDate);
    }
  }

  // ── Time Tap Handlers ─────────────────────────────────────
  Future<void> _onStartTimeTap() async {
    final state  = ref.read(saleInvoiceListProvider);
    final picked = await _pickTime(context, state.fromDate);
    if (picked != null) {
      final newDate = DateTime(
        state.fromDate.year, state.fromDate.month, state.fromDate.day,
        picked.hour, picked.minute, 0,
      );
      _startTimeCtrl.text = _inputTimeFmt.format(newDate);
      ref.read(saleInvoiceListProvider.notifier)
          .setDateRange(newDate, state.toDate);
    }
  }

  Future<void> _onEndTimeTap() async {
    final state  = ref.read(saleInvoiceListProvider);
    final picked = await _pickTime(context, state.toDate);
    if (picked != null) {
      final newDate = DateTime(
        state.toDate.year, state.toDate.month, state.toDate.day,
        picked.hour, picked.minute, 59,
      );
      _endTimeCtrl.text = _inputTimeFmt.format(newDate);
      ref.read(saleInvoiceListProvider.notifier)
          .setDateRange(state.fromDate, newDate);
    }
  }

  // ── Date Field Widget ─────────────────────────────────────
  Widget _dateField({
    required String                label,
    required TextEditingController ctrl,
    required VoidCallback          onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AbsorbPointer(
          child: SizedBox(
            width: 155,
            child: TextField(
              controller: ctrl,
              readOnly:   true,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText:  label,
                labelStyle: const TextStyle(
                    fontSize: 11, color: AppColor.textSecondary),
                prefixIcon: const Icon(Icons.calendar_today_rounded,
                    size: 15, color: AppColor.primary),
                filled:    true,
                fillColor: AppColor.grey100,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:   BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppColor.primary, width: 1.2),
                ),
              ),
            ),
          ),
        ),
      );

  // ── Time Field Widget ─────────────────────────────────────
  Widget _timeField({
    required String                label,
    required TextEditingController ctrl,
    required VoidCallback          onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AbsorbPointer(
          child: SizedBox(
            width: 120,
            child: TextField(
              controller: ctrl,
              readOnly:   true,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText:  label,
                labelStyle: const TextStyle(
                    fontSize: 11, color: AppColor.textSecondary),
                prefixIcon: const Icon(Icons.access_time_rounded,
                    size: 15, color: AppColor.primary),
                filled:    true,
                fillColor: AppColor.grey100,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:   BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppColor.primary, width: 1.2),
                ),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(saleInvoiceListProvider);
    final auth      = ref.watch(authProvider);
    final invoices  = state.filteredInvoices;
    final customers = ref.watch(customerProvider).allCustomers
        .where((c) => c.deletedAt == null && c.isActive)
        .toList();

    // ── Customer dropdown items ────────────────────────────
    final customerItems = <DropdownItem<String?>>[
      const DropdownItem<String?>(
        value: null,
        label: 'All Customers',
        icon:  Icons.people_outline_rounded,
      ),
      ...customers.map(
            (c) => DropdownItem<String?>(
          value: c.id,
          label: c.name,
          icon:  Icons.person_outline_rounded,
        ),
      ),
    ];

    // ── Cashier dropdown items ─────────────────────────────
    final cashierItems = <DropdownItem<String?>>[
      const DropdownItem<String?>(
        value: null,
        label: 'All Cashiers',
        icon:  Icons.people_outline_rounded,
      ),
      ...state.cashiers.map(
            (c) => DropdownItem<String?>(
          value: c.id,
          label: c.fullName,
          icon:  Icons.person_outline_rounded,
        ),
      ),
    ];

    ref.listen<SaleInvoiceListState>(saleInvoiceListProvider, (_, next) {
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
            onPressed: () =>
                ref.read(saleInvoiceListProvider.notifier).clearError(),
          ),
        ));
      }
      _startDateCtrl.text = _inputFmt.format(next.fromDate);
      _endDateCtrl.text   = _inputFmt.format(next.toDate);
      _startTimeCtrl.text = _inputTimeFmt.format(next.fromDate);
      _endTimeCtrl.text   = _inputTimeFmt.format(next.toDate);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Sale Invoices',
            style: TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight:   60,
        backgroundColor: Colors.white,
        elevation:       0.5,
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(saleInvoiceListProvider.notifier).load(),
            icon:    const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(
                foregroundColor: AppColor.textSecondary),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Stat Cards ──────────────────────────────
            if (state.isCustomerSelected) ...[
              _CustomerStatsBanner(state: state),
            ] else ...[
              Row(
                children: [
                  SummaryCard(
                    title: 'Total Invoices',
                    value: '${state.totalCount}',
                    icon:  Icons.receipt_long_outlined,
                    color: AppColor.primary,
                  ),
                  const SizedBox(width: 12),
                  SummaryCard(
                    title: 'Grand Total',
                    value: 'Rs ${state.totalGrand.toStringAsFixed(0)}',
                    icon:  Icons.payments_outlined,
                    color: AppColor.success,
                  ),
                  const SizedBox(width: 12),
                  SummaryCard(
                    title: 'Total Discount',
                    value: 'Rs ${state.totalDiscount.toStringAsFixed(0)}',
                    icon:  Icons.discount_outlined,
                    color: AppColor.warning,
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // ── Filters ─────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [

                  // ── Search ───────────────────────────
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged:  ref
                          .read(saleInvoiceListProvider.notifier)
                          .onSearchChanged,
                      style:        const TextStyle(fontSize: 13),
                      cursorHeight: 14,
                      decoration: InputDecoration(
                        hintText: 'Search invoice, customer...',
                        hintStyle: const TextStyle(
                            color: AppColor.textHint, fontSize: 12),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: AppColor.grey400),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear,
                              size:  16,
                              color: AppColor.grey400),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref
                                .read(saleInvoiceListProvider
                                .notifier)
                                .onSearchChanged('');
                          },
                        )
                            : null,
                        filled:    true,
                        fillColor: AppColor.grey100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:   BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ── Customer Dropdown ─────────────────
                  AppSearchableDropdown<String?>(
                    hint:         'All Customers',
                    prefixIcon:   Icons.person_search_outlined,
                    desktopWidth: 200,
                    value:        state.selectedCustomerId,
                    items:        customerItems,
                    onChanged: (id) {
                      final customer = id != null
                          ? customers
                          .where((c) => c.id == id)
                          .firstOrNull
                          : null;
                      ref
                          .read(saleInvoiceListProvider.notifier)
                          .selectCustomer(id, customer?.name);
                    },
                  ),
                  const SizedBox(width: 12),

                  // ── Cashier Dropdown (Manager only) ───
                  if (auth.isManager) ...[
                    state.isCashiersLoading
                        ? const SizedBox(
                      width:  42,
                      height: 42,
                      child: Center(
                        child: SizedBox(
                          width:  18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        ),
                      ),
                    )
                        : AppSearchableDropdown<String?>(
                      hint:         'All Cashiers',
                      prefixIcon:   Icons.badge_outlined,
                      desktopWidth: 200,
                      value:        state.selectedCashierId,
                      items:        cashierItems,
                      onChanged: (id) => ref
                          .read(saleInvoiceListProvider.notifier)
                          .selectCashier(id),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // ── Today Button ──────────────────────
                  IntrinsicWidth(
                    child: OutlinedButton.icon(
                      onPressed: () => ref
                          .read(saleInvoiceListProvider.notifier)
                          .setToday(),
                      icon:  const Icon(Icons.today_rounded, size: 16),
                      label: const Text('Today',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColor.primary,
                        side: const BorderSide(color: AppColor.primary),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ── Start Date + Time ─────────────────
                  _dateField(
                    label: 'Start Date',
                    ctrl:  _startDateCtrl,
                    onTap: _onStartDateTap,
                  ),
                  const SizedBox(width: 6),
                  _timeField(
                    label: 'Start Time',
                    ctrl:  _startTimeCtrl,
                    onTap: _onStartTimeTap,
                  ),

                  const SizedBox(width: 8),
                  const Text('—',
                      style: TextStyle(
                          color:      AppColor.textSecondary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),

                  // ── End Date + Time ───────────────────
                  _dateField(
                    label: 'End Date',
                    ctrl:  _endDateCtrl,
                    onTap: _onEndDateTap,
                  ),
                  const SizedBox(width: 6),
                  _timeField(
                    label: 'End Time',
                    ctrl:  _endTimeCtrl,
                    onTap: _onEndTimeTap,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Invoice List ─────────────────────────────
            Expanded(
              child: invoices.isEmpty
                  ? _EmptyState(
                  isSearching: state.searchQuery.isNotEmpty ||
                      state.isCustomerSelected)
                  : ListView.separated(
                itemCount:        invoices.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
                itemBuilder: (context, index) => _InvoiceCard(
                  inv:       invoices[index],
                  dateFmt:   _dateFmt,
                  timeFmt:   _timeFmt,
                  isManager: auth.isManager,
                  storeName: 'Jan Ghani',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Customer Stats Banner
// ══════════════════════════════════════════════════════════════
class _CustomerStatsBanner extends StatelessWidget {
  final SaleInvoiceListState state;
  const _CustomerStatsBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:        AppColor.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(
                color: AppColor.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_pin_outlined,
                  size: 16, color: AppColor.primary),
              const SizedBox(width: 8),
              Text(
                state.selectedCustomerName ?? 'Selected Customer',
                style: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color:      AppColor.primary),
              ),
              const Spacer(),
              Text(
                '${state.customerInvoiceCount} invoices',
                style: const TextStyle(
                    fontSize: 12, color: AppColor.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            SummaryCard(
              title: 'Total Sale',
              value: 'Rs ${state.customerTotalSale.toStringAsFixed(0)}',
              icon:  Icons.payments_outlined,
              color: AppColor.primary,
            ),
            const SizedBox(width: 12),
            SummaryCard(
              title: 'Cash Sale',
              value: 'Rs ${state.customerCashSale.toStringAsFixed(0)}',
              icon:  Icons.money_outlined,
              color: AppColor.success,
            ),
            const SizedBox(width: 12),
            SummaryCard(
              title: 'Credit Sale',
              value: 'Rs ${state.customerCreditSale.toStringAsFixed(0)}',
              icon:  Icons.credit_card_outlined,
              color: AppColor.warning,
            ),
            const SizedBox(width: 12),
            SummaryCard(
              title: 'Discount',
              value: 'Rs ${state.customerTotalDiscount.toStringAsFixed(0)}',
              icon:  Icons.discount_outlined,
              color: AppColor.error,
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Invoice Card
// ══════════════════════════════════════════════════════════════
class _InvoiceCard extends StatefulWidget {
  final SaleInvoiceListModel inv;
  final DateFormat dateFmt;
  final DateFormat timeFmt;
  final bool isManager;
  final String storeName;

  const _InvoiceCard({
    required this.inv,
    required this.dateFmt,
    required this.timeFmt,
    required this.isManager,
    required this.storeName,
  });

  @override
  State<_InvoiceCard> createState() => _InvoiceCardState();
}

class _InvoiceCardState extends State<_InvoiceCard> {
  bool _isPrinting = false;

  Future<void> _print() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    try {
      final inv         = widget.inv;
      final hasCustomer = inv.customerId != null;

      // ── Report items (flat) -> CartItem (printer ke liye) ──
      final cartItems = inv.items.map((item) {
        final product = BranchStockModel(
          id:               '',
          storeId:          '',
          productId:        '',
          sku:              item.sku ?? '',
          barcode:          null,
          name:             item.productName,
          unitOfMeasure:    'pcs',
          costPrice:        item.purchasePrice,
          sellingPrice:     item.salePrice,
          taxRate:          0,
          discount:         0,
          minStockLevel:    0,
          maxStockLevel:    0,
          reorderPoint:     0,
          isActive:         true,
          isTrackStock:     true,
          quantity:         0,
          reservedQuantity: 0,
          updatedAt:        DateTime.now(),
        );
        return CartItem(
          cartId:         '${inv.id}_${item.productName}_${item.sku ?? ''}',
          product:        product,
          quantity:       item.quantity,
          salePrice:      item.salePrice,
          taxAmount:      0,
          discountAmount: item.discount,
        );
      }).toList();

      // ── Report payments -> PaymentEntry ─────────────────────
      final payments = inv.payments.map((p) => PaymentEntry(method: p.method, amount: p.amount)).toList();

      // ── Derived values (same logic ThermalPrintService uses) ──
      final isCreditSale = payments.any((p) => p.method.toLowerCase() == 'credit' && p.amount > 0.01,
      );
      final creditAmount = payments.where((p) => p.method.toLowerCase() == 'credit').fold(0.0, (s, p) => s + p.amount);

      // ── Paid amount: stored si.pay_amount ko prefer karo,
      //    purani invoices ke liye payments se calculate karo ──
      final paidAmount = inv.payAmount ?? payments.where((p) => p.method.toLowerCase() != 'credit').fold<double>(0.0, (s, p) => s + p.amount);
      // ════════════════════════════════════════════════════════
      // FULL DEBUG LOG (no physical printer needed to verify)
      // ════════════════════════════════════════════════════════
      debugPrint('╔══════════════════════════════════════════════════╗');
      debugPrint('║        SALE INVOICE PRINT DEBUG (REPORT)          ║');
      debugPrint('╚══════════════════════════════════════════════════╝');
      debugPrint('Invoice No     : ${inv.invoiceNo}');
      debugPrint('Invoice Date   : ${inv.invoiceDate}');
      debugPrint('Status         : ${inv.status}');
      debugPrint('Customer       : ${inv.customerName ?? "WALK IN"}');
      debugPrint('Customer ID    : ${inv.customerId ?? "-"}');
      debugPrint('Cashier        : ${inv.cashierName ?? "Unknown"}');
      debugPrint('Counter        : ${inv.counterName ?? "-"}');
      debugPrint('Notes          : ${inv.notes ?? "-"}');
      debugPrint('──────────────── ITEMS (${inv.items.length}) ────────────────');
      for (final item in inv.items) {
        debugPrint(
          '  ${item.productName.padRight(22)} '
              'qty=${item.quantity}  rate=${item.salePrice}  '
              'dis=${item.discount}  amt=${item.totalAmount}',
        );
      }
      debugPrint('──────────────── TOTALS ────────────────');
      debugPrint('Sub Total      : ${inv.totalAmount}');
      debugPrint('Total Discount : ${inv.totalDiscount}');
      debugPrint('Grand Total    : ${inv.grandTotal}');
      debugPrint('──────────────── PAYMENTS (${payments.length}) ────────────────');
      for (final p in payments) {
        debugPrint('  ${p.method.toUpperCase().padRight(8)} : ${p.amount}');
      }
      debugPrint('isCreditSale   : $isCreditSale');
      debugPrint('──────────────── CUSTOMER LEDGER ────────────────');
      debugPrint('hasCustomer    : $hasCustomer');
      debugPrint('Previous Bal   : ${inv.previousBalance ?? "-"}');
      debugPrint('Credit Amount  : $creditAmount');
      debugPrint('Stored PayAmt  : ${inv.payAmount ?? "- (fallback used)"}');
      debugPrint('Paid Amount    : $paidAmount');
      debugPrint('Current Bal    : ${inv.currentBalance ?? "-"}');
      debugPrint('══════════════════════════════════════════════════');

      await ThermalPrintService.printSaleInvoice(
        storeName:       widget.storeName,
        invoiceNo:       inv.invoiceNo,
        date:            inv.invoiceDate,
        customerName:    inv.customerName,
        customerId:      inv.customerId,
        items:           cartItems,
        totalAmount:     inv.totalAmount,
        totalDiscount:   inv.totalDiscount,
        grandTotal:      inv.grandTotal,
        payments:        payments,
        cashierName:     inv.cashierName ?? 'Unknown',
        previousBalance: hasCustomer ? inv.previousBalance : null,
        paidAmount:      hasCustomer ? paidAmount           : null,
        currentBalance:  hasCustomer ? inv.currentBalance   : null,
        notes:           inv.notes,
      );

      debugPrint('✅ Print successful');
    } catch (e) {
      debugPrint('❌ Print error (no printer connected? — log above is still valid): $e');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv     = widget.inv;
    final dateFmt = widget.dateFmt;
    final timeFmt = widget.timeFmt;

    final double subtotal =
    inv.items.fold(0.0, (s, i) => s + (i.totalAmount as double? ?? 0.0));

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
              border: Border(
                bottom: BorderSide(
                    color: AppColor.grey300.withValues(alpha: 0.6)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 15, color: AppColor.primary),
                const SizedBox(width: 6),
                Text(inv.invoiceNo,
                    style: const TextStyle(
                        fontSize:      13,
                        fontWeight:    FontWeight.w800,
                        color:         AppColor.primary,
                        letterSpacing: 0.3)),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(dateFmt.format(inv.invoiceDate),
                        style: const TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w700,
                            color:      AppColor.textPrimary)),
                    Text(timeFmt.format(inv.invoiceDate),
                        style: const TextStyle(
                            fontSize: 11,
                            color:    AppColor.textSecondary)),
                  ],
                ),
                const SizedBox(width: 8),

                // ── Print Button ─────────────────────────
                _isPrinting
                    ? const SizedBox(
                  width:  32,
                  height: 32,
                  child: Center(
                    child: SizedBox(
                      width:  16,
                      height: 16,
                      child:  CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                )
                    : Material(
                  color:        Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap:        _print,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColor.primary
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColor.primary
                                .withValues(alpha: 0.2)),
                      ),
                      child: const Icon(
                        Icons.print_rounded,
                        size:  16,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Customer + Payment ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 13, color: AppColor.textSecondary),
                const SizedBox(width: 5),
                Text(
                  inv.customerName ?? 'Walk In',
                  style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                      color: inv.customerName != null
                          ? AppColor.textPrimary
                          : AppColor.textSecondary),
                ),
                const Spacer(),
                _PaymentBadge(type: inv.paymentType),
              ],
            ),
          ),

          if (inv.counterName != null)
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.point_of_sale_outlined,
                      size: 13, color: AppColor.textSecondary),
                  const SizedBox(width: 6),
                  const Text('Counter: ',
                      style: TextStyle(
                          fontSize: 12,
                          color:    AppColor.textSecondary)),
                  _CounterChip(name: inv.counterName as String),
                ],
              ),
            ),

          if (inv.notes != null && inv.notes.toString().trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note_outlined,
                      size: 13, color: AppColor.textSecondary),
                  const SizedBox(width: 5),
                  const Text('Note: ',
                      style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                          color:      AppColor.textSecondary)),
                  Expanded(
                    child: Text(
                      inv.notes.toString(),
                      style: const TextStyle(
                          fontSize: 12, color: AppColor.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

          if (inv.cashierName != null)
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined,
                      size: 13, color: AppColor.textSecondary),
                  const SizedBox(width: 6),
                  const Text('Added By: ',
                      style: TextStyle(
                          fontSize: 12,
                          color:    AppColor.textSecondary)),
                  _CashierChip(name: inv.cashierName as String),
                ],
              ),
            ),

          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // ── Product Table ────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                      color:        AppColor.grey100,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Expanded(
                          flex: 4,
                          child: Text('Product',
                              style: TextStyle(
                                  fontSize:   11,
                                  fontWeight: FontWeight.w700,
                                  color:      AppColor.textSecondary))),
                      Expanded(
                          flex: 2,
                          child: Text('Price',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize:   11,
                                  fontWeight: FontWeight.w700,
                                  color:      AppColor.textSecondary))),
                      Expanded(
                          flex: 1,
                          child: Text('Qty',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize:   11,
                                  fontWeight: FontWeight.w700,
                                  color:      AppColor.textSecondary))),
                      Expanded(
                          flex: 2,
                          child: Text('Discount',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize:   11,
                                  fontWeight: FontWeight.w700,
                                  color:      AppColor.textSecondary))),
                      Expanded(
                          flex: 2,
                          child: Text('Sub Total',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize:   11,
                                  fontWeight: FontWeight.w700,
                                  color:      AppColor.textSecondary))),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                ...inv.items.asMap().entries.map<Widget>((entry) {
                  final idx  = entry.key;
                  final item = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: idx % 2 != 0
                          ? AppColor.grey100.withValues(alpha: 0.5)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              Container(
                                width:  5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: AppColor.primary
                                      .withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                    item.productName,
                                    style: const TextStyle(
                                        fontSize:   12,
                                        fontWeight: FontWeight.w500,
                                        color:      AppColor.textPrimary),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                            flex: 2,
                            child: Text(item.priceLabel,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color:    AppColor.textPrimary))),
                        Expanded(
                            flex: 1,
                            child: Text(item.qtyLabel,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize:   11,
                                    fontWeight: FontWeight.w600,
                                    color:      AppColor.textPrimary))),
                        Expanded(
                            flex: 2,
                            child: Text(
                                'Rs ${(item.discount).toStringAsFixed(0)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color:    AppColor.warning))),
                        Expanded(
                            flex: 2,
                            child: Text(item.totalLabel,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize:   11,
                                    fontWeight: FontWeight.w700,
                                    color:      AppColor.primary))),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 10),

                _TotalRow(
                  label:      'Sub Total',
                  value:      'Rs ${subtotal.toStringAsFixed(0)}',
                  valueColor: AppColor.textPrimary,
                ),

                if (inv.totalDiscount > 0) ...[
                  const SizedBox(height: 4),
                  _TotalRow(
                    label:      'Discount',
                    value:      inv.discountLabel,
                    valueColor: AppColor.warning,
                  ),
                ],

                const SizedBox(height: 10),
                if (inv.customerId != null &&
                    (inv.previousBalance != null || inv.currentBalance != null)) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: _CustomerBalanceSection(
                      previousBalance: inv.previousBalance,
                      currentBalance:  inv.currentBalance,
                      payments:        inv.payments,
                    ),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColor.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColor.success.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatusBadge(status: inv.status),
                      Row(
                        children: [
                          const Text('Total Amount:',
                              style: TextStyle(
                                  fontSize:   12,
                                  fontWeight: FontWeight.w600,
                                  color:      AppColor.textSecondary)),
                          const SizedBox(width: 10),
                          Text(inv.grandTotalLabel,
                              style: const TextStyle(
                                  fontSize:   15,
                                  fontWeight: FontWeight.w800,
                                  color:      AppColor.success)),
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
}

// ══════════════════════════════════════════════════════════════
// Helper Widgets
// ══════════════════════════════════════════════════════════════

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  valueColor;
  const _TotalRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Text('$label:',
          style: const TextStyle(
              fontSize: 12, color: AppColor.textSecondary)),
      const SizedBox(width: 12),
      SizedBox(
        width: 110,
        child: Text(value,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      valueColor)),
      ),
    ],
  );
}

class _CounterChip extends StatelessWidget {
  final String name;
  const _CounterChip({required this.name});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color:        AppColor.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.point_of_sale_outlined,
            size: 11, color: AppColor.primary),
        const SizedBox(width: 4),
        Text(name,
            style: const TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      AppColor.primary)),
      ],
    ),
  );
}

class _CashierChip extends StatelessWidget {
  final String name;
  const _CashierChip({required this.name});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color:        AppColor.info.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.badge_outlined,
            size: 11, color: AppColor.info),
        const SizedBox(width: 4),
        Text(name,
            style: const TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      AppColor.info)),
      ],
    ),
  );
}

class _PaymentBadge extends StatelessWidget {
  final String type;
  const _PaymentBadge({required this.type});

  Color get _color => const {
    'cash':   AppColor.success,
    'card':   AppColor.info,
    'credit': AppColor.warning,
  }[type] ??
      AppColor.grey400;

  IconData get _icon => const {
    'cash':   Icons.payments_outlined,
    'card':   Icons.credit_card_outlined,
    'credit': Icons.person_outline_rounded,
  }[type] ??
      Icons.help_outline;

  String get _label => const {
    'cash':   'Cash',
    'card':   'Card',
    'credit': 'Credit',
  }[type] ??
      type;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color:        _color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
      border:       Border.all(color: _color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, size: 11, color: _color),
        const SizedBox(width: 4),
        Text(_label,
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      _color)),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color => const {
    'completed': AppColor.success,
    'cancelled': AppColor.error,
    'returned':  AppColor.warning,
  }[status] ??
      AppColor.grey400;

  IconData get _icon => const {
    'completed': Icons.check_circle_outline_rounded,
    'cancelled': Icons.cancel_outlined,
    'returned':  Icons.assignment_return_outlined,
  }[status] ??
      Icons.help_outline;

  String get _label => const {
    'completed': 'Completed',
    'cancelled': 'Cancelled',
    'returned':  'Returned',
  }[status] ??
      status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color:        _color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, size: 12, color: _color),
        const SizedBox(width: 4),
        Text(_label,
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      _color)),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  const _EmptyState({this.isSearching = false});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSearching
              ? Icons.search_off_rounded
              : Icons.receipt_long_outlined,
          size:  64,
          color: AppColor.grey300,
        ),
        const SizedBox(height: 16),
        Text(
          isSearching ? 'Koi invoice nahi mila' : 'Koi invoice nahi',
          style: const TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w600,
              color:      AppColor.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          isSearching
              ? 'Filter change karein'
              : 'Sales karne ke baad yahan dikhega',
          style: const TextStyle(
              fontSize: 13, color: AppColor.textHint),
        ),
      ],
    ),
  );
}


class _CustomerBalanceSection extends StatelessWidget {
  final double? previousBalance;
  final double? currentBalance;
  final List<SaleInvoicePaymentDetail> payments;

  const _CustomerBalanceSection({
    required this.previousBalance,
    required this.currentBalance,
    required this.payments,
  });

  double get _creditAmount => payments
      .where((p) => p.method.toLowerCase() == 'credit')
      .fold(0.0, (s, p) => s + p.amount);

  @override
  Widget build(BuildContext context) {
    final prevBal    = previousBalance ?? 0.0;
    final currBal    = currentBalance  ?? 0.0;
    final creditAmt  = _creditAmount;
    final isInDebt   = currBal > 0;

    return Container(
      margin:      const EdgeInsets.only(bottom: 12),
      decoration:  BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColor.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10)),
              border: Border(
                bottom: BorderSide(
                    color: AppColor.primary.withValues(alpha: 0.15)),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 14, color: AppColor.primary),
                SizedBox(width: 6),
                Text('Customer account balance',
                    style: TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w600,
                        color:      AppColor.primary)),
              ],
            ),
          ),

          // ── Three columns ────────────────────────────────
          IntrinsicHeight(
            child: Row(
              children: [
                // Previous Balance
                Expanded(
                  child: _BalanceCell(
                    label: 'Previous balance',
                    value: 'Rs ${prevBal.toStringAsFixed(0)}',
                    valueColor: AppColor.textSecondary,
                    showDivider: true,
                  ),
                ),
                // Credit Added
                Expanded(
                  child: _BalanceCell(
                    label: 'This invoice credit',
                    value: creditAmt > 0
                        ? '+ Rs ${creditAmt.toStringAsFixed(0)}'
                        : '—',
                    valueColor: AppColor.info,
                    showDivider: true,
                  ),
                ),
                // New Balance
                Expanded(
                  child: _BalanceCell(
                    label: 'New balance',
                    value: 'Rs ${currBal.toStringAsFixed(0)}',
                    valueColor: isInDebt
                        ? AppColor.error
                        : AppColor.success,
                    showDivider: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCell extends StatelessWidget {
  final String label;
  final String value;
  final Color  valueColor;
  final bool   showDivider;

  const _BalanceCell({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      border: showDivider
          ? const Border(
          right: BorderSide(color: Color(0xFFEEEEEE)))
          : null,
    ),
    child: Column(
      children: [
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 10,
                color:    AppColor.textSecondary,
                letterSpacing: 0.2)),
        const SizedBox(height: 4),
        Text(value,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                color:      valueColor)),
      ],
    ),
  );
}