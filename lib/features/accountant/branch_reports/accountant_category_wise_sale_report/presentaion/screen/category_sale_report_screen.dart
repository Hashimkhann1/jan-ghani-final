import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../data/datasource/category_sale_report_datasource.dart';
import '../../data/model/category_sale_report_model.dart';
import '../provider/category_sale_report_provider.dart';

class CategorySaleReportScreen extends ConsumerStatefulWidget {
  const CategorySaleReportScreen({super.key, required this.branchId});
  final String branchId;

  @override
  ConsumerState<CategorySaleReportScreen> createState() => _CategorySaleReportScreenState();
}

class _CategorySaleReportScreenState extends ConsumerState<CategorySaleReportScreen> {
  final _dateFmt  = DateFormat('dd MMM yyyy');
  final _fromCtrl = TextEditingController();
  final _toCtrl   = TextEditingController();
  final _amtFmt   = NumberFormat('#,##,###', 'en_IN');

  @override
  void initState() {
    super.initState();
    final state = ref.read(categorySaleReportProvider(widget.branchId));
    _fromCtrl.text = _dateFmt.format(state.fromDate);
    _toCtrl.text   = _dateFmt.format(state.toDate);
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  String _fmtAmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';
  String _fmtQty(double q) =>
      q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(2);

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final state = ref.read(categorySaleReportProvider(widget.branchId));
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

    if (picked != null) {
      final notifier =
      ref.read(categorySaleReportProvider(widget.branchId).notifier);
      if (isFrom) {
        _fromCtrl.text = _dateFmt.format(picked);
        notifier.setFromDate(picked);
      } else {
        _toCtrl.text = _dateFmt.format(picked);
        notifier.setToDate(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(categorySaleReportProvider(widget.branchId));
    final notifier =
    ref.read(categorySaleReportProvider(widget.branchId).notifier);
    final summary  = state.summary;

    ref.listen<CategorySaleReportState>(
        categorySaleReportProvider(widget.branchId), (_, next) {
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

    // Category dropdown items
    final categoryItems = [
      DropdownItem<String?>(
        value: null,
        label: 'All Categories',
        icon:  Icons.category_outlined,
      ),
      ...state.categories.map((c) => DropdownItem<String?>(
        value: c.id,
        label: c.name,
        icon:  Icons.label_outline_rounded,
      )),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Category Sale Report',
          style: TextStyle(
            fontSize:   17,
            fontWeight: FontWeight.w700,
            color:      Color(0xFF1A1D23),
          ),
        ),
        actions: [
          IconButton(
            onPressed: notifier.load,
            icon:    const Icon(Icons.refresh_rounded,
                color: AppColor.textSecondary),
            tooltip: 'Refresh',
          ),
          TextButton(
            onPressed: () {
              notifier.setToday();
              final today      = DateTime.now();
              final todayClean = DateTime(today.year, today.month, today.day);
              _fromCtrl.text   = _dateFmt.format(todayClean);
              _toCtrl.text     = _dateFmt.format(todayClean);
            },
            child: const Text('Today'),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(
        children: [

          // ── Filters ───────────────────────────────────────
          Container(
            color:   Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    child: _DateField(
                      label:      'Start Date',
                      controller: _fromCtrl,
                      onTap:      () => _pickDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateField(
                      label:      'End Date',
                      controller: _toCtrl,
                      onTap:      () => _pickDate(context, false),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                AppSearchableDropdown<String?>(
                  items:      categoryItems,
                  value:      state.selectedCategoryId,
                  hint:       'All Categories',
                  fullWidth:  true,
                  prefixIcon: Icons.category_outlined,
                  onChanged:  (v) => notifier.setCategory(v),
                ),
              ],
            ),
          ),

          // ── Summary Cards ─────────────────────────────────
          Container(
            color:   Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(children: [
              _SummaryTile(
                label: 'Categories',
                value: '${summary.totalCategories}',
                icon:  Icons.category_outlined,
                color: AppColor.primary,
              ),
              _divider(),
              _SummaryTile(
                label: 'Total Sale',
                value: _fmtAmt(summary.totalSales),
                icon:  Icons.payments_outlined,
                color: AppColor.success,
              ),
              _divider(),
              _SummaryTile(
                label: 'Profit',
                value: _fmtAmt(summary.totalProfit),
                icon:  Icons.trending_up_rounded,
                color: AppColor.warning,
              ),
              _divider(),
              _SummaryTile(
                label: 'Qty',
                value: _fmtQty(summary.totalQuantity),
                icon:  Icons.inventory_2_outlined,
                color: const Color(0xFF6366F1),
              ),
            ]),
          ),

          Container(height: 1, color: const Color(0xFFE5E7EB)),
          const SizedBox(height: 8),

          // ── List ──────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.reports.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              onRefresh: notifier.load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount:        state.reports.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (_, i) => _CategoryCard(
                  report:   state.reports[i],
                  fmtAmt:   _fmtAmt,
                  fmtQty:   _fmtQty,
                  rank:     i + 1,
                  branchId: widget.branchId,
                  fromDate: state.fromDate,
                  toDate:   state.toDate,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width:  1,
    height: 36,
    color:  const Color(0xFFE5E7EB),
    margin: const EdgeInsets.symmetric(horizontal: 6),
  );
}

// ═══════════════════════════════════════════════════════════
//  Category Card
// ═══════════════════════════════════════════════════════════

class _CategoryCard extends StatefulWidget {
  final CategorySaleReport      report;
  final String Function(double) fmtAmt;
  final String Function(double) fmtQty;
  final int                     rank;
  final String                  branchId;
  final DateTime                fromDate;
  final DateTime                toDate;

  const _CategoryCard({
    required this.report,
    required this.fmtAmt,
    required this.fmtQty,
    required this.rank,
    required this.branchId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool                        _expanded = false;
  bool                        _loading  = false;
  List<CategoryProductSale>   _products = [];

  Color get _rankColor {
    if (widget.rank == 1) return const Color(0xFFFFD700);
    if (widget.rank == 2) return const Color(0xFFC0C0C0);
    if (widget.rank == 3) return const Color(0xFFCD7F32);
    return AppColor.grey400;
  }

  Future<void> _toggleExpand() async {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }

    setState(() { _expanded = true; _loading = true; });

    try {
      final ds = CategorySaleReportDatasource(branchId: widget.branchId);
      final products = await ds.getCategoryProducts(
        categoryId: widget.report.categoryId,
        fromDate:   widget.fromDate,
        toDate:     widget.toDate,
      );
      setState(() { _products = products; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profitPct = widget.report.totalSales > 0
        ? (widget.report.totalProfit / widget.report.totalSales * 100)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [

          // ── Card Header ───────────────────────────────────
          InkWell(
            onTap:        _toggleExpand,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // Rank Badge
                  Container(
                    width:  40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:        _rankColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${widget.rank}',
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w800,
                        color:      _rankColor == AppColor.grey400
                            ? AppColor.textSecondary
                            : _rankColor,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Category Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize:       MainAxisSize.min,
                      children: [
                        Text(
                          widget.report.categoryName,
                          style: const TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w700,
                            color:      Color(0xFF1A1D23),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing:    5,
                          runSpacing: 4,
                          children: [
                            _Chip(
                              label: '${widget.report.invoiceCount} invoices',
                              color: AppColor.primary,
                            ),
                            _Chip(
                              label: 'Qty: ${widget.fmtQty(widget.report.totalQuantity)}',
                              color: const Color(0xFF6366F1),
                            ),
                            _Chip(
                              label: 'Profit: ${profitPct.toStringAsFixed(1)}%',
                              color: AppColor.success,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Amount + Arrow
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize:       MainAxisSize.min,
                    children: [
                      Text(
                        widget.fmtAmt(widget.report.totalSales),
                        style: const TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w800,
                          color:      Color(0xFF1A1D23),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+ ${widget.fmtAmt(widget.report.totalProfit)}',
                        style: const TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                          color:      AppColor.success,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedRotation(
                        turns:    _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          size:  18,
                          color: AppColor.grey400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded Products ─────────────────────────────
          if (_expanded) ...[
            Container(height: 1, color: const Color(0xFFE5E7EB)),

            // Loading
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child:   Center(child: CircularProgressIndicator()),
              )

            // Products List
            else if (_products.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Koi product nahi mila',
                  style: TextStyle(
                    fontSize: 12,
                    color:    AppColor.textHint,
                  ),
                ),
              )

            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  children: [

                    // Header Row
                    Padding(
                      padding:  EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(flex: 4,
                            child: _IH(text: '#  Product')),
                        Expanded(flex: 2,
                            child: _IH(text: 'Qty',   right: false)),
                        Expanded(flex: 2,
                            child: _IH(text: 'Sales',  right: true)),
                        Expanded(flex: 2,
                            child: _IH(text: 'Profit', right: true)),
                      ]),
                    ),

                    // Product Rows
                    ..._products.asMap().entries.map((entry) {
                      final i   = entry.key;
                      final p   = entry.value;
                      final isEven = i % 2 == 0;

                      return Container(
                        decoration: BoxDecoration(
                          color: isEven
                              ? const Color(0xFFF9FAFB)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 8),
                        child: Row(
                          children: [
                            // Rank number + name
                            Expanded(
                              flex: 4,
                              child: Row(
                                children: [
                                  Container(
                                    width:  20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppColor.primary
                                          .withOpacity(0.08),
                                      borderRadius:
                                      BorderRadius.circular(4),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        fontSize:   9,
                                        fontWeight: FontWeight.w700,
                                        color:      AppColor.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      p.productName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color:    AppColor.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Qty
                            Expanded(
                              flex: 2,
                              child: Text(
                                widget.fmtQty(p.totalQuantity),
                                style: const TextStyle(
                                  fontSize:   11,
                                  color:      AppColor.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            // Sales
                            Expanded(
                              flex: 2,
                              child: Text(
                                widget.fmtAmt(p.totalSales),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize:   11,
                                  color:      AppColor.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            // Profit
                            Expanded(
                              flex: 2,
                              child: Text(
                                '+ ${widget.fmtAmt(p.totalProfit)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize:   10,
                                  color:      AppColor.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color  color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize:   9,
        fontWeight: FontWeight.w600,
        color:      color,
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  Shared Widgets (same as sale report)
// ═══════════════════════════════════════════════════════════

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
      Text(label,
          style: const TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w600,
              color:      AppColor.textSecondary)),
      const SizedBox(height: 4),
      TextField(
        controller:   controller,
        readOnly:     true,
        onTap:        onTap,
        cursorHeight: 14,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600),
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
            borderSide:
            const BorderSide(color: AppColor.grey200),
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
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
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
                color:      color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColor.textHint)),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.category_outlined,
            size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Koi category nahi mili',
            style: TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      Colors.grey.shade500)),
        const SizedBox(height: 6),
        Text('Date range ya category filter change karein',
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade400)),
      ],
    ),
  );
}

class _IH extends StatelessWidget {
  final String text;
  final bool   right;
  const _IH({required this.text, this.right = false});

  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
          fontSize:      10,
          fontWeight:    FontWeight.w600,
          color:         AppColor.textHint,
          letterSpacing: 0.3));
}