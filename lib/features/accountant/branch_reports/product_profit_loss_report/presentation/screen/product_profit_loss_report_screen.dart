import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../../../../core/widget/app_icon.dart';
import '../../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../../common/export/report_excel_export.dart';
import '../../../common/export/report_export_button.dart';
import '../../../common/filter/report_filter_dialog.dart';
import '../../data/model/product_profit_loss_model.dart';
import '../../data/service/product_profit_loss_excel_service.dart';
import '../../data/service/product_profit_loss_pdf_service.dart';
import '../provider/product_profit_loss_provider.dart';

const _kBg      = Color(0xFFF5F6FA);
const _kInk     = Color(0xFF1A1D23);
const _kBorder  = Color(0xFFEEEEEE);
const _kPurple  = Color(0xFF8B5CF6);
const _kBlue    = Color(0xFF0EA5E9);

final _amtFmt  = NumberFormat('#,##,###.##', 'en_IN');
final _dateFmt = DateFormat('dd MMM yyyy');

String _fmtAmt(double v) =>
    v < 0 ? '-Rs ${_amtFmt.format(-v)}' : 'Rs ${_amtFmt.format(v)}';
String _fmtQty(double q) => q.toStringAsFixed(2);
Color _pnlColor(double v) => v >= 0 ? AppColor.success : AppColor.error;

class ProductProfitLossReportScreen extends ConsumerStatefulWidget {
  const ProductProfitLossReportScreen({
    super.key,
    required this.branchId,
    this.provider,
    this.showBack = true,
  });
  final String branchId;

  /// Which data source to read from. Defaults to the accountant (Supabase)
  /// provider; the branch app passes its local-database one.
  final AutoDisposeStateNotifierProviderFamily<ProductProfitLossNotifier,
      ProductProfitLossState, String>? provider;

  /// Back arrow in the desktop header. Off when the screen is a sidebar
  /// root (branch app) and there is nothing to go back to.
  final bool showBack;

  @override
  ConsumerState<ProductProfitLossReportScreen> createState() =>
      _ProductProfitLossReportScreenState();
}

class _ProductProfitLossReportScreenState
    extends ConsumerState<ProductProfitLossReportScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _export(ProductProfitLossState state) async {
    final items = state.exportItems;
    if (items.isEmpty) return;

    String? categoryName;
    if (state.categoryFilter != null) {
      final m = state.categories.where((c) => c.id == state.categoryFilter);
      categoryName = m.isNotEmpty ? m.first.name : null;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(
      content: Text('Generating PDF...'),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
    try {
      await ProductProfitLossPdfService.exportAndShare(
        items: items,
        fromDate: state.fromDate,
        toDate: state.toDate,
        isSelection: state.selectedIds.isNotEmpty,
        categoryName: categoryName,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Export failed: $e'),
        backgroundColor: AppColor.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<List<ExcelSheetData>> _exportSheets(ProductProfitLossState state) async {
    final items = state.exportItems;
    if (items.isEmpty) return const [];

    String? categoryName;
    if (state.categoryFilter != null) {
      final m = state.categories.where((c) => c.id == state.categoryFilter);
      categoryName = m.isNotEmpty ? m.first.name : null;
    }

    return [
      ProductProfitLossExcelService.buildSheet(
        items: items,
        fromDate: state.fromDate,
        toDate: state.toDate,
        isSelection: state.selectedIds.isNotEmpty,
        categoryName: categoryName,
      ),
    ];
  }

  Widget _exportButton(ProductProfitLossState state,
          {required String label, bool filled = false}) =>
      ReportExportButton(
        fileNamePrefix: 'product_profit_loss',
        filled: filled,
        label: label,
        enabled: state.filtered.isNotEmpty,
        loadSheets: () => _exportSheets(state),
        customPdf: () => _export(state),
      );

  void _openFilters() {
    final provider = widget.provider ?? productProfitLossProvider;
    showReportFilterDialog(
      context: context,
      content: Consumer(builder: (ctx, ref, _) {
        final state    = ref.watch(provider(widget.branchId));
        final notifier = ref.read(provider(widget.branchId).notifier);
        return _Filters(
          state: state,
          notifier: notifier,
          searchCtrl: _searchCtrl,
          desktop: false,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider ?? productProfitLossProvider;
    final state    = ref.watch(provider(widget.branchId));
    final notifier = ref.read(provider(widget.branchId).notifier);
    final desktop  = MediaQuery.of(context).size.width >= 800;

    ref.listen<ProductProfitLossState>(
      provider(widget.branchId),
      (_, next) {
        if (next.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColor.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: notifier.clearError,
            ),
          ));
        }
      },
    );

    final selCount = state.selectedIds.length;
    final exportLabel =
        selCount > 0 ? 'Export ($selCount)' : 'Export';

    final body = Column(
      children: [
        _SummaryRow(items: state.exportItems, isSelection: selCount > 0),
        const Divider(height: 1, color: _kBorder),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.filtered.isEmpty
                  ? const _EmptyState()
                  : desktop
                      ? _Table(state: state, notifier: notifier)
                      : _CardList(state: state, notifier: notifier),
        ),
      ],
    );

    if (desktop) {
      return Scaffold(
        backgroundColor: _kBg,
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
              child: Row(
                children: [
                  if (widget.showBack) ...[
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: _kInk),
                      style: IconButton.styleFrom(
                        backgroundColor: _kBg,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Product Profit & Loss',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _kInk)),
                      SizedBox(height: 2),
                      Text('Stock, sales, returns and profit per product',
                          style: TextStyle(
                              fontSize: 13, color: AppColor.textHint)),
                    ],
                  ),
                  const Spacer(),
                  if (selCount > 0) ...[
                    TextButton(
                      onPressed: notifier.clearSelection,
                      child: const Text('Clear selection'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ReportFilterButton(
                    onPressed:   _openFilters,
                    activeCount: (state.searchQuery.isNotEmpty ? 1 : 0) +
                        (state.categoryFilter != null ? 1 : 0),
                  ),
                  const SizedBox(width: 6),
                  _exportButton(state, label: exportLabel, filled: true),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: notifier.load,
                    icon: const AppIcon('ic_refresh',
                        size: 18, color: AppColor.primary),
                    label: const Text('Refresh'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      foregroundColor: AppColor.primary,
                      side: const BorderSide(color: AppColor.primary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Product Profit & Loss',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: _kInk)),
        actions: [
          ReportFilterButton(
            onPressed:   _openFilters,
            activeCount: (state.searchQuery.isNotEmpty ? 1 : 0) +
                (state.categoryFilter != null ? 1 : 0),
          ),
          Badge(
            isLabelVisible: selCount > 0,
            label: Text('$selCount'),
            child: _exportButton(state, label: exportLabel),
          ),
          IconButton(
            onPressed: notifier.load,
            icon: const AppIcon('ic_refresh',
                size: 22, color: AppColor.textSecondary),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: body,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Filters (date range, quick ranges, search, category, only-sold)
// ══════════════════════════════════════════════════════════════════════════════
class _Filters extends StatelessWidget {
  final ProductProfitLossState state;
  final ProductProfitLossNotifier notifier;
  final TextEditingController searchCtrl;
  final bool desktop;

  const _Filters({
    required this.state,
    required this.notifier,
    required this.searchCtrl,
    required this.desktop,
  });

  Future<void> _pick(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? state.fromDate : state.toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColor.primary)),
        child: child!,
      ),
    );
    if (picked == null) return;
    if (isStart) {
      notifier.setDateRange(
          picked, picked.isAfter(state.toDate) ? picked : state.toDate);
    } else {
      notifier.setDateRange(
          picked.isBefore(state.fromDate) ? picked : state.fromDate, picked);
    }
  }

  void _quick(String key) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (key) {
      case 'today':
        notifier.setDateRange(today, today);
        break;
      case 'week':
        notifier.setDateRange(today.subtract(const Duration(days: 6)), today);
        break;
      case 'month':
        notifier.setDateRange(DateTime(now.year, now.month, 1), today);
        break;
      case 'year':
        notifier.setDateRange(DateTime(now.year, 1, 1), today);
        break;
    }
  }

  /// The branch report has no category data (names live in the warehouse
  /// DB), so the filter and column only appear when categories loaded.
  bool get showCategory => state.categories.isNotEmpty;

  List<DropdownItem<String?>> get _categoryItems => [
        const DropdownItem<String?>(
            value: null, label: 'All Categories', icon: Icons.apps_rounded),
        ...state.categories.map((c) => DropdownItem<String?>(
            value: c.id, label: c.name, icon: Icons.category_outlined)),
      ];

  Widget _dateBtn(BuildContext context, String label, DateTime d, bool isStart) =>
      InkWell(
        onTap: () => _pick(context, isStart),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: AppColor.grey100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColor.grey200),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_today_rounded,
                size: 15, color: AppColor.primary),
            const SizedBox(width: 8),
            Text('$label: ${_dateFmt.format(d)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  List<Widget> _chips() => const [
        ('today', 'Today'),
        ('week', 'This Week'),
        ('month', 'This Month'),
        ('year', 'This Year'),
      ]
          .map((c) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  label: Text(c.$2,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                  backgroundColor: AppColor.primary.withOpacity(0.06),
                  side: BorderSide(color: AppColor.primary.withOpacity(0.3)),
                  labelStyle: const TextStyle(color: AppColor.primary),
                  onPressed: () => _quick(c.$1),
                ),
              ))
          .toList();

  Widget _search() => SizedBox(
        height: 42,
        child: TextField(
          controller: searchCtrl,
          onChanged: notifier.search,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Product name or SKU...',
            hintStyle: const TextStyle(fontSize: 13, color: AppColor.textHint),
            prefixIcon: const AppIcon('ic_search', size: 18, color: AppColor.primary),
            suffixIcon: state.searchQuery.isNotEmpty
                ? IconButton(
                    icon: const AppIcon('ic_clear', size: 16, color: AppColor.textHint),
                    onPressed: () {
                      searchCtrl.clear();
                      notifier.search('');
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColor.grey100,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColor.grey200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColor.primary, width: 1.5)),
          ),
        ),
      );

  Widget _onlySold() => FilterChip(
        label: const Text('Only sold / returned',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        selected: state.onlyWithActivity,
        onSelected: (_) => notifier.toggleOnlyWithActivity(),
        selectedColor: AppColor.primary.withOpacity(0.15),
        checkmarkColor: AppColor.primary,
      );

  @override
  Widget build(BuildContext context) {
    if (desktop) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _dateBtn(context, 'From', state.fromDate, true),
              const SizedBox(width: 10),
              _dateBtn(context, 'To', state.toDate, false),
              const SizedBox(width: 16),
              ..._chips(),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _search()),
              const SizedBox(width: 16),
              if (showCategory) ...[
                AppSearchableDropdown<String?>(
                  items: _categoryItems,
                  value: state.categoryFilter,
                  hint: 'Category',
                  prefixIcon: Icons.category_outlined,
                  desktopWidth: 220,
                  onChanged: notifier.setCategoryFilter,
                ),
                const SizedBox(width: 12),
              ],
              _onlySold(),
            ]),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _dateBtn(context, 'From', state.fromDate, true)),
            const SizedBox(width: 8),
            Expanded(child: _dateBtn(context, 'To', state.toDate, false)),
          ]),
          const SizedBox(height: 8),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal, child: Row(children: _chips())),
          const SizedBox(height: 8),
          _search(),
          const SizedBox(height: 10),
          if (showCategory) ...[
            AppSearchableDropdown<String?>(
              items: _categoryItems,
              value: state.categoryFilter,
              hint: 'Category',
              prefixIcon: Icons.category_outlined,
              fullWidth: true,
              onChanged: notifier.setCategoryFilter,
            ),
            const SizedBox(height: 6),
          ],
          _onlySold(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Summary (of ticked products, or of everything visible when none ticked)
// ══════════════════════════════════════════════════════════════════════════════
class _SummaryRow extends StatelessWidget {
  final List<ProductProfitLossModel> items;
  final bool isSelection;

  const _SummaryRow({required this.items, required this.isSelection});

  @override
  Widget build(BuildContext context) {
    final s = ProductProfitLossSummary.from(items);
    final cards = [
      _StatCard(
          label: isSelection ? 'Selected' : 'Products',
          value: '${s.products}',
          color: AppColor.primary),
      _StatCard(label: 'Inventory Stock', value: _fmtQty(s.inventoryStock), color: _kPurple),
      _StatCard(label: 'Sold Qty', value: _fmtQty(s.soldQty), color: _kBlue),
      _StatCard(label: 'Return Qty', value: _fmtQty(s.returnQty), color: AppColor.warningDark),
      _StatCard(
          label: s.netProfit >= 0 ? 'Net Profit' : 'Net Loss',
          value: _fmtAmt(s.netProfit),
          color: _pnlColor(s.netProfit)),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth >= 700) {
          return Row(children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: cards[i]),
            ],
          ]);
        }
        return SizedBox(
          height: 62,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final w in cards) ...[
                SizedBox(width: 130, child: w),
                const SizedBox(width: 8),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppColor.textHint)),
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// Desktop table
// ══════════════════════════════════════════════════════════════════════════════
class _Table extends StatelessWidget {
  final ProductProfitLossState state;
  final ProductProfitLossNotifier notifier;
  const _Table({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final items = state.filtered;
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
          child: Row(children: [
            SizedBox(
              width: 40,
              child: Checkbox(
                value: state.allFilteredSelected,
                onChanged: (_) => notifier.toggleSelectAll(),
                activeColor: AppColor.primary,
              ),
            ),
            const _TH('#', flex: 1),
            const _TH('Product', flex: 4),
            if (state.categories.isNotEmpty) const _TH('Category', flex: 2),
            const _TH('Sale Price', flex: 2, right: true),
            const _TH('Purchase Price', flex: 2, right: true),
            const _TH('Inventory Stock', flex: 2, center: true),
            const _TH('Sold Qty', flex: 2, center: true),
            const _TH('Return Qty', flex: 2, center: true),
            const _TH('Net Sold', flex: 2, center: true),
            const _TH('Profit / Loss', flex: 3, right: true),
          ]),
        ),
        const Divider(height: 1, color: _kBorder),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
            itemBuilder: (_, i) => _Row(
              index: i + 1,
              item: items[i],
              showCategory: state.categories.isNotEmpty,
              selected: state.selectedIds.contains(items[i].productId),
              onToggle: () => notifier.toggleSelect(items[i].productId),
            ),
          ),
        ),
      ],
    );
  }
}

class _TH extends StatelessWidget {
  final String label;
  final int flex;
  final bool right, center;
  const _TH(this.label, {this.flex = 1, this.right = false, this.center = false});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(
          label,
          textAlign: right
              ? TextAlign.right
              : center
                  ? TextAlign.center
                  : TextAlign.left,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColor.textHint,
              letterSpacing: 0.3),
        ),
      );
}

class _Row extends StatelessWidget {
  final int index;
  final ProductProfitLossModel item;
  final bool showCategory;
  final bool selected;
  final VoidCallback onToggle;
  const _Row({
    required this.index,
    required this.item,
    required this.showCategory,
    required this.selected,
    required this.onToggle,
  });

  Widget _cell(int flex, String text,
          {TextAlign align = TextAlign.left,
          Color color = AppColor.textSecondary,
          FontWeight weight = FontWeight.w500,
          double size = 12}) =>
      Expanded(
        flex: flex,
        child: Text(text,
            textAlign: align,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: size, fontWeight: weight, color: color)),
      );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Container(
        color: selected ? AppColor.primary.withOpacity(0.05) : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: selected,
              onChanged: (_) => onToggle(),
              activeColor: AppColor.primary,
            ),
          ),
          _cell(1, '$index', color: AppColor.textHint),
          _cell(4, item.productName,
              color: _kInk, weight: FontWeight.w600, size: 13),
          if (showCategory) _cell(2, item.categoryName, size: 11),
          _cell(2, _fmtAmt(item.salePrice),
              align: TextAlign.right, color: AppColor.primary, weight: FontWeight.w600),
          _cell(2, _fmtAmt(item.purchasePrice),
              align: TextAlign.right, color: _kPurple, weight: FontWeight.w600),
          _cell(2, _fmtQty(item.inventoryStock),
              align: TextAlign.center,
              color: item.inventoryStock <= 0 ? AppColor.error : _kInk,
              weight: FontWeight.w700),
          _cell(2, _fmtQty(item.soldQty),
              align: TextAlign.center, color: _kBlue, weight: FontWeight.w700),
          _cell(2, _fmtQty(item.returnQty),
              align: TextAlign.center,
              color: item.returnQty > 0 ? AppColor.warningDark : AppColor.textHint,
              weight: FontWeight.w700),
          _cell(2, _fmtQty(item.netSoldQty),
              align: TextAlign.center, color: _kInk, weight: FontWeight.w700),
          Expanded(
            flex: 3,
            child: Text(
              _fmtAmt(item.netProfit),
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _pnlColor(item.netProfit)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Mobile cards
// ══════════════════════════════════════════════════════════════════════════════
class _CardList extends StatelessWidget {
  final ProductProfitLossState state;
  final ProductProfitLossNotifier notifier;
  const _CardList({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final items = state.filtered;
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            Checkbox(
              value: state.allFilteredSelected,
              onChanged: (_) => notifier.toggleSelectAll(),
              activeColor: AppColor.primary,
            ),
            Text(
              state.selectedIds.isEmpty
                  ? 'Select all (${items.length})'
                  : '${state.selectedIds.length} selected',
              style: const TextStyle(fontSize: 12, color: AppColor.textSecondary),
            ),
            const Spacer(),
            if (state.selectedIds.isNotEmpty)
              TextButton(
                  onPressed: notifier.clearSelection,
                  child: const Text('Clear', style: TextStyle(fontSize: 12))),
          ]),
        ),
        const Divider(height: 1, color: _kBorder),
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _Card(
                item: items[i],
                showCategory: state.categories.isNotEmpty,
                selected: state.selectedIds.contains(items[i].productId),
                onToggle: () => notifier.toggleSelect(items[i].productId),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final ProductProfitLossModel item;
  final bool showCategory;
  final bool selected;
  final VoidCallback onToggle;
  const _Card({
    required this.item,
    required this.showCategory,
    required this.selected,
    required this.onToggle,
  });

  Widget _kv(String k, String v, Color c) => Expanded(
        child: Column(children: [
          Text(v,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(k, style: const TextStyle(fontSize: 9, color: AppColor.textHint)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColor.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColor.primary.withOpacity(0.5) : _kBorder),
        ),
        padding: const EdgeInsets.fromLTRB(4, 10, 14, 12),
        child: Column(
          children: [
            Row(children: [
              Checkbox(
                value: selected,
                onChanged: (_) => onToggle(),
                activeColor: AppColor.primary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: _kInk)),
                    if (showCategory) ...[
                      const SizedBox(height: 2),
                      Text(item.categoryName,
                          style: const TextStyle(
                              fontSize: 11, color: AppColor.textHint)),
                    ],
                  ],
                ),
              ),
              Text(_fmtAmt(item.netProfit),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _pnlColor(item.netProfit))),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                  color: _kBg, borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                Row(children: [
                  _kv('Sale Price', _fmtAmt(item.salePrice), AppColor.primary),
                  _kv('Purchase Price', _fmtAmt(item.purchasePrice), _kPurple),
                  _kv('Inventory', _fmtQty(item.inventoryStock),
                      item.inventoryStock <= 0 ? AppColor.error : _kInk),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  _kv('Sold', _fmtQty(item.soldQty), _kBlue),
                  _kv('Returned', _fmtQty(item.returnQty), AppColor.warningDark),
                  _kv('Net Sold', _fmtQty(item.netSoldQty), _kInk),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon('sidebar_icons/branch_stock',
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No product found',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500)),
            const SizedBox(height: 6),
            Text('Try a different date range or clear filters',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      );
}
