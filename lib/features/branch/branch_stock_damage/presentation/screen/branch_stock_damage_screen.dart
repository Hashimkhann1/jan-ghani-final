// lib/features/branch/branch_stock_damage/presentation/screen/branch_stock_damage_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import '../../../customer/presentation/widget/customer_filter_chip_widget.dart';
import '../../../customer/presentation/widget/customer_action_button_widget.dart';
import '../../data/model/branch_stock_damage_model.dart';
import '../provider/branch_stock_damage_provider.dart';
import '../widget/add_damage_dialog.dart';

class BranchStockDamageScreen extends ConsumerStatefulWidget {
  const BranchStockDamageScreen({super.key});

  @override
  ConsumerState<BranchStockDamageScreen> createState() =>
      _BranchStockDamageScreenState();
}

class _BranchStockDamageScreenState
    extends ConsumerState<BranchStockDamageScreen> {
  final _searchCtrl = TextEditingController();

  void _openAddDialog() => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AddDamageDialog(),
  );

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(branchStockDamageProvider);
    final notifier = ref.read(branchStockDamageProvider.notifier);

    ref.listen<BranchStockDamageState>(branchStockDamageProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text(next.errorMessage!),
          backgroundColor: AppColor.error,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
              label: 'OK', textColor: Colors.white,
              onPressed: notifier.clearError),
        ));
      }
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text(next.successMessage!),
          backgroundColor: AppColor.success,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
              label: 'OK', textColor: Colors.white,
              onPressed: notifier.clearSuccess),
        ));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Damage Records',
            style: TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight: 60,
        actions: [
          IconButton(
            onPressed: notifier.refresh,
            icon:      const Icon(Icons.refresh_rounded),
            tooltip:   'Refresh',
            style: IconButton.styleFrom(
                foregroundColor: AppColor.textSecondary),
          ),
          const SizedBox(width: 8),
          // ── Add Damage button (AppBar) ──────────────────────────
          SizedBox(
            width: 150,
            child: ElevatedButton(
              onPressed: _openAddDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Add Damage'),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Stat Cards ───────────────────────────────────────
            Row(children: [
              SummaryCard(
                title: 'Total Records',
                value: state.totalRecords.toString(),
                icon:  Icons.receipt_long_outlined,
                color: AppColor.primary,
              ),
              const SizedBox(width: 12),
              SummaryCard(
                title: 'Total Qty Damaged',
                value: state.totalQtyDamaged.toStringAsFixed(0),
                icon:  Icons.broken_image_outlined,
                color: AppColor.warning,
              ),
              const SizedBox(width: 12),
              SummaryCard(
                title: 'Total Loss Value',
                value: 'Rs ${state.totalLossValue.toStringAsFixed(0)}',
                icon:  Icons.trending_down_rounded,
                color: AppColor.error,
              ),
              const SizedBox(width: 12),
              SummaryCard(
                title: 'This Month',
                value: state.rows
                    .where((r) =>
                r.createdAt.month == DateTime.now().month &&
                    r.createdAt.year  == DateTime.now().year)
                    .length
                    .toString(),
                icon:  Icons.calendar_month_outlined,
                color: AppColor.info,
              ),
            ]),

            const SizedBox(height: 16),

            // ── Search + Filters ──────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged:  notifier.onSearchChanged,
                    style:        const TextStyle(fontSize: 13),
                    cursorHeight: 14,
                    decoration: InputDecoration(
                      hintText: 'Search by product name...',
                      hintStyle: const TextStyle(
                          color: AppColor.textHint, fontSize: 13),
                      prefixIcon: const Icon(Icons.search,
                          size: 18, color: AppColor.grey400),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 16, color: AppColor.grey400),
                        onPressed: () {
                          _searchCtrl.clear();
                          notifier.onSearchChanged('');
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
                ...[
                  ('all',        'All'),
                  ('today',      'Today'),
                  ('this_week',  'This Week'),
                  ('this_month', 'This Month'),
                ].map((f) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CustomerFilterChip(
                    label:         f.$2,
                    value:         f.$1,
                    selectedValue: state.filterStatus,
                    onTap:         notifier.onFilterChanged,
                  ),
                )),
              ]),
            ),

            const SizedBox(height: 12),

            _PaginationBar(state: state, notifier: notifier),
            const SizedBox(height: 8),

            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.rows.isEmpty
                  ? _EmptyState(
                isSearching: state.searchQuery.isNotEmpty,
                onAdd:       _openAddDialog,
              )
                  : _DamageTable(rows: state.rows),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TABLE  — Edit + Delete buttons
// ═══════════════════════════════════════════════════════════════════
class _DamageTable extends ConsumerWidget {
  final List<BranchStockDamageModel> rows;
  const _DamageTable({required this.rows});

  static const _widths = [
    350.0, // Product Name
    150.0, // Purchase Price
    150.0, // Sale Price
    120.0, // Qty Damaged
    150.0, // Total Loss
    150.0, // Date
    200.0, // Actions  ← wider (2 buttons)
  ];

  static const _headers = [
    'Product Name', 'Purchase Price', 'Sale Price',
    'Qty Damaged', 'Total Loss', 'Date', 'Actions',
  ];

  static double get _totalWidth => _widths.fold(0.0, (s, w) => s + w) + 32;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final tableWidth =
      _totalWidth.clamp(constraints.maxWidth, double.infinity);
      const headerH = 44.0;
      final rowsH   = constraints.maxHeight - headerH - 1;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Column(children: [

            // Header
            Container(
              height:  headerH,
              color:   AppColor.error.withOpacity(0.05),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_headers.length, (i) => SizedBox(
                  width: _widths[i],
                  child: Text(
                    _headers[i],
                    textAlign: i == _headers.length - 1
                        ? TextAlign.center
                        : TextAlign.left,
                    style: const TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.textSecondary),
                  ),
                )),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Rows
            SizedBox(
              height: rowsH,
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                itemBuilder: (ctx, i) => _DamageRow(
                  record:   rows[i],
                  index:    i,
                  widths:   _widths,
                  onEdit: () => showDialog(
                    context:            ctx,
                    barrierDismissible: false,
                    builder: (_) => EditDamageDialog(record: rows[i]),
                  ),
                  onDelete: () => showDialog(
                    context: ctx,
                    builder: (_) => DeleteDamageDialog(record: rows[i]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }
}

// ── Single Row ────────────────────────────────────────────────────
class _DamageRow extends StatelessWidget {
  final BranchStockDamageModel record;
  final int          index;
  final List<double> widths;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DamageRow({
    required this.record,
    required this.index,
    required this.widths,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isEven  = index.isEven;
    final dateFmt = DateFormat('dd MMM yyyy');

    return Container(
      height: 52,
      color: isEven ? Colors.white : const Color(0xFFFFF5F5),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [

        // Product Name
        SizedBox(
          width: widths[0],
          child: Text(record.productName,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1),
        ),

        // Purchase Price
        SizedBox(
          width: widths[1],
          child: Text(record.purchasePriceLabel,
              style: const TextStyle(fontSize: 13)),
        ),

        // Sale Price
        SizedBox(
          width: widths[2],
          child: Text(record.salePriceLabel,
              style: const TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color:      AppColor.primary)),
        ),

        // Qty Damaged
        SizedBox(
          width: widths[3],
          child: Text(record.stockDamage.toString(),
            style: const TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w700,
              color:      AppColor.error,
            ),
          ),
        ),

        // Total Loss
        SizedBox(
          width: widths[4],
          child: Text(record.totalLossLabel,
            style: const TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w700,
              color:      AppColor.error,
            ),
          ),
        ),

        // Date
        SizedBox(
          width: widths[5],
          child: Text(dateFmt.format(record.createdAt),
            style: const TextStyle(
              fontSize: 12, color: AppColor.textSecondary,
            ),
          ),
        ),

        // Actions — Edit + Delete
        SizedBox(
          width: widths[6],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomerActionButton(
                icon:    Icons.edit_outlined,
                color:   AppColor.primary,
                tooltip: 'Edit Quantity',
                onTap:   onEdit,
              ),
              const SizedBox(width: 6),
              CustomerActionButton(
                icon:    Icons.delete_outline_rounded,
                color:   AppColor.error,
                tooltip: 'Delete & Restore Stock',
                onTap:   onDelete,
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PAGINATION
// ═══════════════════════════════════════════════════════════════════
class _PaginationBar extends StatelessWidget {
  final BranchStockDamageState    state;
  final BranchStockDamageNotifier notifier;
  const _PaginationBar({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (state.totalCount == 0) return const SizedBox.shrink();
    return Row(children: [
      Text('${state.fromRow}–${state.toRow} of ${state.totalCount} records',
          style: const TextStyle(
              fontSize: 13, color: AppColor.textSecondary)),
      const Spacer(),
      if (state.totalPages > 1) ...[
        const Text('Page',
            style: TextStyle(fontSize: 13, color: AppColor.textSecondary)),
        const SizedBox(width: 6),
        _PageJumper(state: state, notifier: notifier),
        Text(' of ${state.totalPages}',
            style: const TextStyle(
                fontSize: 13, color: AppColor.textSecondary)),
        const SizedBox(width: 12),
      ],
      _NavBtn(icon: Icons.chevron_left_rounded, tooltip: 'Previous',
          enabled: state.hasPrev, onPressed: notifier.prevPage),
      const SizedBox(width: 4),
      ..._pages(state).map((p) => p == -1
          ? const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('…', style: TextStyle(color: AppColor.textSecondary)))
          : _PageNumBtn(page: p, isCurrent: p == state.currentPage,
          onTap: () => notifier.goToPage(p))),
      const SizedBox(width: 4),
      _NavBtn(icon: Icons.chevron_right_rounded, tooltip: 'Next',
          enabled: state.hasNext, onPressed: notifier.nextPage),
    ]);
  }

  List<int> _pages(BranchStockDamageState s) {
    final total = s.totalPages;
    final cur   = s.currentPage;
    if (total <= 7) return List.generate(total, (i) => i);
    final Set<int> p = {0, total - 1};
    for (int i = (cur - 2).clamp(0, total - 1);
    i <= (cur + 2).clamp(0, total - 1); i++) p.add(i);
    final sorted = p.toList()..sort();
    final result = <int>[];
    for (int i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) result.add(-1);
      result.add(sorted[i]);
    }
    return result;
  }
}

class _PageNumBtn extends StatelessWidget {
  final int page; final bool isCurrent; final VoidCallback onTap;
  const _PageNumBtn({required this.page, required this.isCurrent, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: InkWell(
      onTap: isCurrent ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: isCurrent ? AppColor.error : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isCurrent ? null : Border.all(color: AppColor.grey200),
        ),
        alignment: Alignment.center,
        child: Text('${page + 1}', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: isCurrent ? Colors.white : AppColor.textPrimary)),
      ),
    ),
  );
}

class _NavBtn extends StatelessWidget {
  final IconData icon; final String tooltip;
  final bool enabled; final VoidCallback onPressed;
  const _NavBtn({required this.icon, required this.tooltip,
    required this.enabled, required this.onPressed});
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: enabled ? AppColor.grey100 : Colors.transparent,
        foregroundColor: enabled ? AppColor.textPrimary : AppColor.grey300,
        fixedSize: const Size(32, 32), padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
  );
}

class _PageJumper extends StatefulWidget {
  final BranchStockDamageState state;
  final BranchStockDamageNotifier notifier;
  const _PageJumper({required this.state, required this.notifier});
  @override
  State<_PageJumper> createState() => _PageJumperState();
}

class _PageJumperState extends State<_PageJumper> {
  late TextEditingController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = TextEditingController(text: '${widget.state.displayPage}'); }
  @override
  void didUpdateWidget(_PageJumper old) {
    super.didUpdateWidget(old);
    final t = '${widget.state.displayPage}';
    if (_ctrl.text != t && !_ctrl.selection.isValid) _ctrl.text = t;
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 48, height: 30,
    child: TextField(
      controller: _ctrl, textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      cursorHeight: 14,
      onSubmitted: (_) {
        final p = int.tryParse(_ctrl.text.trim());
        if (p != null) widget.notifier.goToPage(p - 1);
      },
      decoration: InputDecoration(
        isDense: true, filled: true, fillColor: AppColor.grey100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColor.error, width: 1.2)),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool         isSearching;
  final VoidCallback onAdd;
  const _EmptyState({required this.isSearching, required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(
          isSearching
              ? Icons.search_off_rounded
              : Icons.broken_image_outlined,
          size: 64, color: AppColor.grey300),
      const SizedBox(height: 16),
      Text(
          isSearching ? 'Koi record nahi mila' : 'Koi damage record nahi',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: AppColor.textSecondary)),
      const SizedBox(height: 6),
      Text(
          isSearching
              ? 'Search query change karein'
              : 'Pehla damage record add karein',
          style: const TextStyle(fontSize: 13, color: AppColor.textHint)),
      if (!isSearching) ...[
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon:  const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Damage'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
          ),
        ),
      ],
    ]),
  );
}