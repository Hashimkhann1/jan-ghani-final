// lib/features/branch/branch_stock_damage/presentation/screen/branch_stock_damage_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/app_icon.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';

import '../../../customer/presentation/widget/customer_action_button_widget.dart';
import '../../../customer/presentation/widget/customer_filter_chip_widget.dart';
import '../../data/model/branch_stock_damage_model.dart';
import '../provider/branch_stock_damage_provider.dart';
import '../widget/add_damage_dialog.dart';

// ── Shortcuts ───────────────────────────────────────────────────
//  F1 / Ctrl+F : search      Ctrl+N : add damage      F5 : refresh
//  Ctrl+1..4   : All / Today / This Week / This Month
//  Ctrl+5 : from date    Ctrl+6 : to date    Ctrl+0 : clear date filter
//  PageUp / PageDown : previous / next page
//  ↑↓ row select, phir:  Ctrl+E edit    Ctrl+D / Ctrl+Delete delete
//  Esc : selection clear, phir search clear
class BranchStockDamageScreen extends ConsumerStatefulWidget {
  const BranchStockDamageScreen({super.key});

  @override
  ConsumerState<BranchStockDamageScreen> createState() =>
      _BranchStockDamageScreenState();
}

class _BranchStockDamageScreenState
    extends ConsumerState<BranchStockDamageScreen> {
  final _searchCtrl  = TextEditingController();
  final _searchFocus = FocusNode(debugLabel: 'Damage_Search');
  String? _selectedId; // arrow keys se select hui row

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  void _openAddDialog() => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AddDamageDialog(),
  );

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final state    = ref.read(branchStockDamageProvider);
    final notifier = ref.read(branchStockDamageProvider.notifier);
    final picked = await showDatePicker(
      context:     context,
      initialDate: (isFrom ? state.fromDate : state.toDate) ?? DateTime.now(),
      firstDate:   DateTime(2020),
      lastDate:    DateTime.now(),
    );
    if (picked == null || !mounted) return;
    isFrom ? notifier.setFromDate(picked) : notifier.setToDate(picked);
  }

  void _openEditDialog(BranchStockDamageModel record) => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => EditDamageDialog(record: record),
  );

  void _openDeleteDialog(BranchStockDamageModel record) => showDialog(
    context: context,
    builder: (_) => DeleteDamageDialog(record: record),
  );

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    // Dialog / date picker khula ho ya doosri screen top par ho to kuch na karo.
    if (!(ModalRoute.of(context)?.isCurrent ?? true) ||
        Navigator.of(context, rootNavigator: true).canPop()) {
      return false;
    }

    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isAltPressed) return false; // sidebar shortcuts
    final ctrl     = keyboard.isControlPressed;
    final key      = event.logicalKey;
    final state    = ref.read(branchStockDamageProvider);
    final notifier = ref.read(branchStockDamageProvider.notifier);
    final rows     = state.rows;

    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      if (ctrl || rows.isEmpty) return false;
      final step    = key == LogicalKeyboardKey.arrowDown ? 1 : -1;
      final current = rows.indexWhere((r) => r.id == _selectedId);
      final next =
          current < 0 ? 0 : (current + step).clamp(0, rows.length - 1);
      setState(() => _selectedId = rows[next].id);
      return true;
    }
    if (event is! KeyDownEvent) return false;

    if (key == LogicalKeyboardKey.f1 ||
        (ctrl && key == LogicalKeyboardKey.keyF)) {
      _searchFocus.requestFocus();
      _searchCtrl.selection = TextSelection(
          baseOffset: 0, extentOffset: _searchCtrl.text.length);
      return true;
    }
    if (key == LogicalKeyboardKey.f5) {
      notifier.refresh();
      return true;
    }
    if (key == LogicalKeyboardKey.pageDown ||
        key == LogicalKeyboardKey.pageUp) {
      if (!state.isLoading) {
        setState(() => _selectedId = null);
        key == LogicalKeyboardKey.pageDown
            ? notifier.nextPage()
            : notifier.prevPage();
      }
      return true;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (_selectedId != null) {
        setState(() => _selectedId = null);
        return true;
      }
      if (_searchCtrl.text.isNotEmpty) {
        setState(_searchCtrl.clear);
        notifier.onSearchChanged('');
        return true;
      }
      return false;
    }
    if (!ctrl) return false;

    if (key == LogicalKeyboardKey.keyN) {
      _openAddDialog();
      return true;
    }

    final filters = {
      LogicalKeyboardKey.digit1: 'all',
      LogicalKeyboardKey.digit2: 'today',
      LogicalKeyboardKey.digit3: 'this_week',
      LogicalKeyboardKey.digit4: 'this_month',
    };
    final filter = filters[key];
    if (filter != null) {
      setState(() => _selectedId = null);
      notifier.onFilterChanged(filter);
      return true;
    }
    if (key == LogicalKeyboardKey.digit5) {
      _pickDate(isFrom: true);
      return true;
    }
    if (key == LogicalKeyboardKey.digit6) {
      _pickDate(isFrom: false);
      return true;
    }
    if (key == LogicalKeyboardKey.digit0) {
      if (state.hasDateFilter) notifier.clearDateFilter();
      return true;
    }

    // ── Selected row ke actions ───────────────────────────
    final selected = rows.where((r) => r.id == _selectedId).firstOrNull;
    final isEdit   = key == LogicalKeyboardKey.keyE;
    final isDelete = key == LogicalKeyboardKey.keyD ||
        key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace;
    if (!isEdit && !isDelete) return false;
    if (selected == null) {
      // Search field mein likhte waqt text wali keys apna kaam karein.
      if (isDelete && _searchFocus.hasFocus) return false;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Pehle row select karein (↑↓ ya row par click)'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ));
      return true;
    }
    isEdit ? _openEditDialog(selected) : _openDeleteDialog(selected);
    return true;
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
            icon:      const AppIcon('ic_refresh', size: 20, color: AppColor.textSecondary),
            tooltip:   'Refresh (F5)',
            style: IconButton.styleFrom(
                foregroundColor: AppColor.textSecondary),
          ),
          const SizedBox(width: 8),
          // ── Add Damage button (AppBar) ──────────────────────────
          SizedBox(
            width: 210,
            child: ElevatedButton(
              onPressed: _openAddDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Add Damage  (Ctrl+N)'),
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
                iconAsset: 'ic_credit_sale',
                color: AppColor.primary,
              ),
              const SizedBox(width: 12),
              SummaryCard(
                title: 'Total Qty Damaged',
                value: state.totalQtyDamaged.toStringAsFixed(0),
                iconAsset: 'ic_total_quantity',
                color: AppColor.warning,
              ),
              const SizedBox(width: 12),
              SummaryCard(
                // ✅ Filter lagi ho to label se clear ho jata hai ke ye filtered loss hai
                title: state.hasDateFilter || state.filterStatus != 'all'
                    ? 'Loss (Filtered)'
                    : 'Total Loss Value',
                value: 'Rs ${state.totalLossValue.toStringAsFixed(0)}',
                iconAsset: 'ic_cash_out',
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
                iconAsset: 'ic_calendar',
                color: AppColor.info,
              ),
            ]),

            const SizedBox(height: 16),

            // ── Search + Filters + Date Range ─────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode:  _searchFocus,
                    onChanged:  notifier.onSearchChanged,
                    style:        const TextStyle(fontSize: 13),
                    cursorHeight: 14,
                    decoration: InputDecoration(
                      hintText: 'Search by product name... (F1)',
                      hintStyle: const TextStyle(
                          color: AppColor.textHint, fontSize: 13),
                      prefixIcon: const AppIcon('ic_search',
                          size: 18, color: AppColor.grey400),
                      prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
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
                    selectedValue: state.hasDateFilter ? '' : state.filterStatus,
                    onTap:         notifier.onFilterChanged,
                  ),
                )),
                const SizedBox(width: 12),

                // ── From Date ────────────────────────────────────
                _DateFilterField(
                  label:    'From (Ctrl+5)',
                  date:     state.fromDate,
                  onTap:    () => _pickDate(isFrom: true),
                  onClear: () => notifier.setFromDate(null),
                ),
                const SizedBox(width: 8),

                // ── To Date ──────────────────────────────────────
                _DateFilterField(
                  label:    'To (Ctrl+6)',
                  date:     state.toDate,
                  onTap:    () => _pickDate(isFrom: false),
                  onClear: () => notifier.setToDate(null),
                ),

                if (state.hasDateFilter) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: notifier.clearDateFilter,
                    icon:  const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Clear Date Filter (Ctrl+0)'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColor.error,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ],
              ]),
            ),

            const SizedBox(height: 6),
            const Text(
              'F1 search  •  Ctrl+N add  •  Ctrl+1–4 filter  •  Ctrl+5 / 6 date  •  '
              'Ctrl+0 clear date  •  PgUp/PgDn page  •  ↑↓ select → Ctrl+E edit, '
              'Ctrl+D delete  •  Esc clear',
              style: TextStyle(fontSize: 11, color: AppColor.textSecondary),
            ),
            const SizedBox(height: 10),

            _PaginationBar(state: state, notifier: notifier),
            const SizedBox(height: 8),

            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.rows.isEmpty
                  ? _EmptyState(
                isSearching: state.searchQuery.isNotEmpty || state.hasDateFilter,
                onAdd:       _openAddDialog,
              )
                  : _DamageTable(
                    rows:       state.rows,
                    selectedId: _selectedId,
                    onSelect:   (id) => setState(() => _selectedId = id),
                    onEdit:     _openEditDialog,
                    onDelete:   _openDeleteDialog,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DATE FILTER FIELD
// ═══════════════════════════════════════════════════════════════════
class _DateFilterField extends StatelessWidget {
  final String        label;
  final DateTime?     date;
  final VoidCallback  onTap;
  final VoidCallback  onClear;

  const _DateFilterField({
    required this.label,
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final fmt  = DateFormat('dd MMM yyyy');
    final text = date != null ? fmt.format(date!) : label;

    return SizedBox(
      width: 160,
      child: TextField(
        readOnly:    true,
        controller:  TextEditingController(text: text),
        onTap:       onTap,
        style:       const TextStyle(fontSize: 13),
        cursorHeight: 14,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 13),
          prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          prefixIcon: const AppIcon('ic_calendar',
              size: 16, color: AppColor.grey400),
          suffixIcon: date != null
              ? IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 16, color: AppColor.grey400),
            onPressed: onClear,
          )
              : null,
          filled:    true,
          fillColor: AppColor.grey100,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:   BorderSide.none,
          ),
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
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final ValueChanged<BranchStockDamageModel> onEdit;
  final ValueChanged<BranchStockDamageModel> onDelete;
  const _DamageTable({
    required this.rows,
    required this.selectedId,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

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

  // Is se chhoti screen par hi horizontal scroll aata hai.
  static const _minTableWidth = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final tableWidth =
      constraints.maxWidth.clamp(_minTableWidth, double.infinity);
      // Columns ko available width ke hisaab se scale karo, taake Actions
      // (Edit / Delete) screen se bahar na jayein.
      final baseTotal = _widths.fold(0.0, (s, w) => s + w);
      final widths = [
        for (final w in _widths) w * (tableWidth - 32) / baseTotal,
      ];
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
                  width: widths[i],
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
                itemBuilder: (ctx, i) => GestureDetector(
                  onTap: () => onSelect(rows[i].id),
                  child: _DamageRow(
                    record:     rows[i],
                    index:      i,
                    widths:     widths,
                    isSelected: rows[i].id == selectedId,
                    onEdit:     () => onEdit(rows[i]),
                    onDelete:   () => onDelete(rows[i]),
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
class _DamageRow extends StatefulWidget {
  final BranchStockDamageModel record;
  final int          index;
  final List<double> widths;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool         isSelected;

  const _DamageRow({
    required this.record,
    required this.index,
    required this.widths,
    required this.isSelected,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_DamageRow> createState() => _DamageRowState();
}

class _DamageRowState extends State<_DamageRow> {
  @override
  void didUpdateWidget(covariant _DamageRow old) {
    super.didUpdateWidget(old);
    if (!widget.isSelected || old.isSelected) return;
    // Arrow keys se select hui row ko view mein lao (sirf vertical).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject();
      final scrollable = Scrollable.maybeOf(context, axis: Axis.vertical);
      if (box == null || scrollable == null) return;
      scrollable.position.ensureVisible(box,
          alignment: 0.5, duration: const Duration(milliseconds: 120));
    });
  }

  @override
  Widget build(BuildContext context) {
    final record   = widget.record;
    final widths   = widget.widths;
    final onEdit   = widget.onEdit;
    final onDelete = widget.onDelete;
    final isEven  = widget.index.isEven;
    final dateFmt = DateFormat('dd MMM yyyy');

    return Container(
      height: 52,
      color: widget.isSelected
          ? AppColor.primary.withValues(alpha: 0.14)
          : isEven ? Colors.white : const Color(0xFFFFF5F5),
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
                icon:      Icons.edit_outlined,
                iconAsset: 'ic_edit',
                color:     AppColor.primary,
                tooltip:   'Edit Quantity (Ctrl+E)',
                onTap:     onEdit,
              ),
              const SizedBox(width: 6),
              CustomerActionButton(
                icon:      Icons.delete_outline_rounded,
                iconAsset: 'ic_delete',
                color:     AppColor.error,
                tooltip:   'Delete & Restore Stock (Ctrl+D)',
                onTap:     onDelete,
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
          isSearching ? 'No records found' : 'No damage records yet',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: AppColor.textSecondary)),
      const SizedBox(height: 6),
      Text(
          isSearching
              ? 'Try changing the search or date filter'
              : 'Add your first damage record',
          style: const TextStyle(fontSize: 13, color: AppColor.textHint)),
      if (!isSearching) ...[
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon:  const AppIcon('ic_plus_new', size: 18, color: Colors.white),
          label: const Text('Add Damage'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    ]),
  );
}