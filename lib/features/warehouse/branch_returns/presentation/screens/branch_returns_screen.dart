// Updated on 2026-11-16 09:59 AM
// =============================================================
// branch_returns_screen.dart — Branch Returns (warehouse side)
// Session 19 list pattern: TopBar · toolbar (search + tabs/counts)
// · table (return, branch, items, cost, status) · footer + pager.
// Row tap → BranchReturnDetailDialog (Accept / Reject).
// =============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/warehouse_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';

import '../../domain/branch_return_model.dart';
import '../provider/branch_returns_provider.dart';
import '../widgets/branch_return_detail_dialog.dart';
import '../widgets/branch_return_parts.dart';

// Column flex
const _cReturn = 22;
const _cBranch = 20;
const _cItems  = 14;
const _cCost   = 14;
const _cStatus = 22;
const _cAction = 56.0;

class BranchReturnsScreen extends ConsumerStatefulWidget {
  const BranchReturnsScreen({super.key});

  @override
  ConsumerState<BranchReturnsScreen> createState() =>
      _BranchReturnsScreenState();
}

class _BranchReturnsScreenState extends ConsumerState<BranchReturnsScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(branchReturnsProvider.notifier).load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400),
        () => ref.read(branchReturnsProvider.notifier).onSearch(q));
  }

  Future<void> _open(BranchReturn r) async {
    final result = await BranchReturnDetailDialog.show(context, r);
    if (result != null && mounted) showReturnSnack(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(branchReturnsProvider);
    final n = ref.read(branchReturnsProvider.notifier);

    return Scaffold(
      backgroundColor: WarehouseAppColor.grey100,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(loading: s.isLoading, onRefresh: n.load),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _Toolbar(
              controller: _searchCtrl,
              state:      s,
              onSearch:   _onSearch,
              onClear: () {
                _searchCtrl.clear();
                _debounce?.cancel();
                setState(() {});
                n.onSearch('');
              },
              onTab: n.onTab,
            ),
          ),
          if (s.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _ErrorBanner(message: s.error!, onRetry: n.load),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _Table(state: s, onOpen: _open, onPage: n.onPage),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool         loading;
  final VoidCallback onRefresh;
  const _TopBar({required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color:  WarehouseAppColor.surface,
        border: Border(bottom: BorderSide(color: WarehouseAppColor.grey200)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color:        WarehouseAppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.assignment_return_outlined,
                size: 20, color: WarehouseAppColor.primary),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Branch Returns',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700,
                        color: WarehouseAppColor.textPrimary)),
                Text('Branches se wapas aaya stock — Accept par warehouse stock mein add',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13, color: WarehouseAppColor.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 40,
            child: OutlinedButton.icon(
              onPressed: loading ? null : onRefresh,
              icon: loading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              // Theme minimumSize width = infinity → Row mein crash (S7);
              // isliye yahan Size.zero
              style: OutlinedButton.styleFrom(
                minimumSize:   Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                foregroundColor: WarehouseAppColor.textPrimary,
                side: const BorderSide(color: WarehouseAppColor.grey300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOOLBAR — search + Pending / Accepted / Rejected tabs
// ─────────────────────────────────────────────────────────────
class _Toolbar extends StatelessWidget {
  final TextEditingController controller;
  final BranchReturnsState    state;
  final ValueChanged<String>  onSearch;
  final VoidCallback          onClear;
  final ValueChanged<String>  onTab;

  const _Toolbar({
    required this.controller,
    required this.state,
    required this.onSearch,
    required this.onClear,
    required this.onTab,
  });

  static const _tabs = [
    ('Pending',  'pending',  WarehouseAppColor.warningDark),
    ('Accepted', 'accepted', WarehouseAppColor.success),
    ('Rejected', 'rejected', WarehouseAppColor.error),
  ];

  @override
  Widget build(BuildContext context) {
    final search = SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onChanged:  onSearch,
        style:      const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText:  'Return number ya branch se search...',
          hintStyle: const TextStyle(color: WarehouseAppColor.textHint, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              color: WarehouseAppColor.grey400, size: 18),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: onClear)
              : null,
          filled:         true,
          fillColor:      WarehouseAppColor.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: WarehouseAppColor.grey300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: WarehouseAppColor.grey300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: WarehouseAppColor.primary, width: 1.5)),
        ),
      ),
    );

    final tabs = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color:        WarehouseAppColor.grey100,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (label, value, color) in _tabs)
            _TabPill(
              label:    label,
              count:    state.counts[value] ?? 0,
              color:    color,
              selected: state.tab == value,
              onTap:    () => onTab(value),
            ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        WarehouseAppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: WarehouseAppColor.grey200),
      ),
      child: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth >= 760) {
          // Search jagah ke hisaab se chhota ho sakta hai (max 340) — tabs fixed
          return Row(children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: search,
                ),
              ),
            ),
            const SizedBox(width: 12),
            tabs,
          ]);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            search,
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal, child: tabs),
            ),
          ],
        );
      }),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String       label;
  final int          count;
  final Color        color;
  final bool         selected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:        selected ? WarehouseAppColor.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: selected
              ? [BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 3, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? WarehouseAppColor.textPrimary
                        : WarehouseAppColor.textSecondary)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? color.withOpacity(0.12)
                    : WarehouseAppColor.grey200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: selected ? color : WarehouseAppColor.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        WarehouseAppColor.errorLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WarehouseAppColor.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: WarehouseAppColor.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Load nahi hua: $message',
                style: const TextStyle(
                    fontSize: 13, color: WarehouseAppColor.error)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TABLE
// ─────────────────────────────────────────────────────────────
class _Table extends StatelessWidget {
  final BranchReturnsState         state;
  final ValueChanged<BranchReturn> onOpen;
  final ValueChanged<int>          onPage;

  const _Table({
    required this.state,
    required this.onOpen,
    required this.onPage,
  });

  @override
  Widget build(BuildContext context) {
    final rows = state.returns;

    Widget body;
    if (state.isLoading && rows.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (rows.isEmpty) {
      body = _EmptyState(tab: state.tab, searching: state.search.isNotEmpty);
    } else {
      body = ListView.builder(
        itemCount:  rows.length,
        itemExtent: 65,
        itemBuilder: (_, i) => Column(
          children: [
            SizedBox(
              height: 64,
              child: _Row(
                key:   ValueKey(rows[i].id),
                ret:   rows[i],
                busy:  state.busyIds.contains(rows[i].id),
                onTap: () => onOpen(rows[i]),
              ),
            ),
            const Divider(height: 1, color: WarehouseAppColor.grey100),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color:        WarehouseAppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: WarehouseAppColor.grey200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final w = c.maxWidth < 860 ? 860.0 : c.maxWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: w,
                  child: Column(children: [
                    const _Header(),
                    Expanded(child: body),
                  ]),
                ),
              );
            }),
          ),
          _Footer(state: state, onPage: onPage),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  static const _style = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: WarehouseAppColor.textSecondary, letterSpacing: 0.6);

  @override
  Widget build(BuildContext context) {
    Widget th(String t, int flex, [TextAlign a = TextAlign.left]) =>
        Expanded(flex: flex, child: Text(t, textAlign: a, style: _style));
    return Container(
      height:  46,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color:  Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: WarehouseAppColor.grey200)),
      ),
      child: Row(children: [
        th('RETURN', _cReturn),
        th('BRANCH', _cBranch),
        th('ITEMS',  _cItems),
        th('TOTAL COST', _cCost, TextAlign.right),
        const SizedBox(width: 24),
        th('STATUS', _cStatus),
        const SizedBox(width: _cAction),
      ]),
    );
  }
}

class _Row extends StatefulWidget {
  final BranchReturn ret;
  final bool         busy;
  final VoidCallback onTap;
  const _Row({super.key, required this.ret, required this.busy, required this.onTap});

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hover = false;

  @override
  void deactivate() {
    _hover = false;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.ret;
    const strong = TextStyle(
        fontSize: 13.5, fontWeight: FontWeight.w600,
        color: WarehouseAppColor.textPrimary);
    const muted = TextStyle(
        fontSize: 12, color: WarehouseAppColor.textSecondary);

    final products = r.items.length;
    final qty      = r.items.isEmpty ? r.totalItems : r.itemsQty;
    final cost     = r.items.isEmpty ? r.totalCost : r.itemsCost;

    String statusLine;
    if (r.isPending) {
      statusLine = r.returnedByName == null || r.returnedByName!.isEmpty
          ? 'Faisla baaqi'
          : 'Bheja: ${r.returnedByName}';
    } else {
      final who  = r.respondedByName ?? '—';
      final when = r.respondedAt == null ? '' : ' · ${fmtReturnDate(r.respondedAt!)}';
      statusLine = '$who$when';
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          color: _hover ? WarehouseAppColor.grey100 : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                flex: _cReturn,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.returnNumber,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: strong.copyWith(color: WarehouseAppColor.primary)),
                    const SizedBox(height: 2),
                    Text(fmtReturnDate(r.returnedAt), style: muted),
                  ],
                ),
              ),
              Expanded(
                flex: _cBranch,
                child: Row(children: [
                  const Icon(Icons.storefront_outlined,
                      size: 16, color: WarehouseAppColor.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        r.fromStoreName.isEmpty ? 'Branch' : r.fromStoreName,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: strong.copyWith(fontWeight: FontWeight.w500)),
                  ),
                ]),
              ),
              Expanded(
                flex: _cItems,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$products products',
                        style: strong.copyWith(fontWeight: FontWeight.w500)),
                    Text('Qty ${fmtReturnQty(qty)}', style: muted),
                  ],
                ),
              ),
              Expanded(
                flex: _cCost,
                child: Text('Rs ${cost.pkrFormat}',
                    textAlign: TextAlign.right, style: strong),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: _cStatus,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReturnStatusPill(status: r.status),
                    const SizedBox(height: 3),
                    Text(statusLine,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: muted),
                  ],
                ),
              ),
              SizedBox(
                width: _cAction,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: widget.busy
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Tooltip(
                          message: r.isPending ? 'Dekhein / Accept / Reject' : 'Detail',
                          child: Icon(
                              r.isPending
                                  ? Icons.chevron_right_rounded
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: WarehouseAppColor.textSecondary),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String tab;
  final bool   searching;
  const _EmptyState({required this.tab, required this.searching});

  @override
  Widget build(BuildContext context) {
    final text = searching
        ? 'Search se koi return nahi mila'
        : switch (tab) {
            'pending'  => 'Koi pending return nahi',
            'accepted' => 'Abhi tak koi return accept nahi hua',
            _          => 'Koi rejected return nahi',
          };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_return_outlined,
              size: 44, color: WarehouseAppColor.grey300),
          const SizedBox(height: 10),
          Text(text,
              style: const TextStyle(
                  fontSize: 14, color: WarehouseAppColor.textSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FOOTER — count + pager
// ─────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final BranchReturnsState state;
  final ValueChanged<int>  onPage;
  const _Footer({required this.state, required this.onPage});

  @override
  Widget build(BuildContext context) {
    final total = state.totalInTab;
    final first = total == 0 ? 0 : state.page * state.pageSize + 1;
    final last  = state.page * state.pageSize + state.returns.length;
    const muted = TextStyle(fontSize: 12.5, color: WarehouseAppColor.textSecondary);
    const bold  = TextStyle(fontSize: 12.5,
        fontWeight: FontWeight.w700, color: WarehouseAppColor.textPrimary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: WarehouseAppColor.grey200))),
      child: Row(
        children: [
          Text.rich(TextSpan(style: muted, children: [
            const TextSpan(text: 'Showing '),
            TextSpan(text: '$first–$last', style: bold),
            const TextSpan(text: ' of '),
            TextSpan(text: '$total', style: bold),
            const TextSpan(text: ' returns'),
          ])),
          const Spacer(),
          _PageBtn(
            icon:  Icons.chevron_left_rounded,
            onTap: state.page > 0 ? () => onPage(state.page - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('Page ${state.page + 1} / ${state.pageCount}',
                style: muted),
          ),
          _PageBtn(
            icon:  Icons.chevron_right_rounded,
            onTap: state.page < state.pageCount - 1
                ? () => onPage(state.page + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData      icon;
  final VoidCallback? onTap;
  const _PageBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: 32, height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: WarehouseAppColor.grey300),
        ),
        child: Icon(icon,
            size: 18,
            color: onTap == null
                ? WarehouseAppColor.grey400
                : WarehouseAppColor.textPrimary),
      ),
    );
  }
}
