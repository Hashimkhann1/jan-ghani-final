import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/color/app_color.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../branch_stock_inventory/presentation/provider/branch_stock_inventory_provider.dart';
import '../../data/model/stock_return_model.dart';
import '../provider/stock_return_provider.dart';

// ── Shortcuts ───────────────────────────────────────────────────
//  F1 / Ctrl+F : search     Ctrl+N : note        F5 : refresh
//  Ctrl+1..4   : tabs       Ctrl+S / Ctrl+Enter : send    Ctrl+D : clear
//  Search: ↑↓ select → Enter → Qty → Enter add  |  Esc clear
final returnSearchFocusProvider = Provider<FocusNode>((ref) {
  final fn = FocusNode(debugLabel: 'Return_Search');
  ref.onDispose(fn.dispose);
  return fn;
});
final returnNoteFocusProvider = Provider<FocusNode>((ref) {
  final fn = FocusNode(debugLabel: 'Return_Note');
  ref.onDispose(fn.dispose);
  return fn;
});

/// 'send' | 'clear' — New Return tab consume karke null kar deta hai.
final returnActionProvider = StateProvider<String?>((ref) => null);

final _money = NumberFormat('#,##0.##');
String _rs(double v) => 'Rs ${_money.format(v)}';

class ReturnStockScreen extends ConsumerStatefulWidget {
  const ReturnStockScreen({super.key});

  @override
  ConsumerState<ReturnStockScreen> createState() => _ReturnStockScreenState();
}

class _ReturnStockScreenState extends ConsumerState<ReturnStockScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 4, vsync: this);

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _tab.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(returnRestoreProvider);
    ref.invalidate(returnCountsProvider);
    ref.invalidate(returnListProvider);
    ref.read(branchStockProvider.notifier).load();
  }

  /// New Return tab par jao, phir [then] chalao (tab build hone ke baad).
  void _onNewTab(VoidCallback then) {
    if (_tab.index != 0) _tab.animateTo(0);
    WidgetsBinding.instance.addPostFrameCallback((_) => then());
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    // Dialog khula ho ya doosri screen top par ho to kuch na karo.
    if (Navigator.of(context, rootNavigator: true).canPop()) return false;

    final key     = event.logicalKey;
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final ctrl = pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
    final alt = pressed.contains(LogicalKeyboardKey.altLeft) ||
        pressed.contains(LogicalKeyboardKey.altRight);
    if (alt) return false; // sidebar shortcuts

    if (key == LogicalKeyboardKey.f1 ||
        (ctrl && key == LogicalKeyboardKey.keyF)) {
      _onNewTab(() => ref.read(returnSearchFocusProvider).requestFocus());
      return true;
    }
    if (key == LogicalKeyboardKey.f5) {
      _refresh();
      return true;
    }
    if (!ctrl) return false;

    final tabKeys = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
    ];
    final ti = tabKeys.indexOf(key);
    if (ti >= 0) {
      _tab.animateTo(ti);
      return true;
    }
    if (key == LogicalKeyboardKey.keyN) {
      _onNewTab(() => ref.read(returnNoteFocusProvider).requestFocus());
      return true;
    }
    if (key == LogicalKeyboardKey.keyS ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _onNewTab(() => ref.read(returnActionProvider.notifier).state = 'send');
      return true;
    }
    if (key == LogicalKeyboardKey.keyD) {
      _onNewTab(() => ref.read(returnActionProvider.notifier).state = 'clear');
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final counts = ref.watch(returnCountsProvider).valueOrNull ?? const {};
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Return Stock',
                style: TextStyle(
                    color: Color(0xFF1A1D23),
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            Text('Branch se Warehouse ko stock wapis',
                style: TextStyle(color: AppColor.textHint, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                size: 20, color: AppColor.textSecondary),
            tooltip: 'Refresh (F5)',
            onPressed: _refresh,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _ReturnTabBar(
            controller: _tab,
            tabs: [
              const _TabSpec('New Return', Icons.add_box_rounded, 'Ctrl+1',
                  AppColor.primary),
              _TabSpec('Pending', Icons.hourglass_top_rounded, 'Ctrl+2',
                  AppColor.warningDark,
                  count: counts['pending'] ?? 0),
              _TabSpec('Accepted', Icons.check_circle_rounded, 'Ctrl+3',
                  AppColor.success,
                  count: counts['accepted'] ?? 0),
              _TabSpec('Rejected', Icons.cancel_rounded, 'Ctrl+4',
                  AppColor.error,
                  count: counts['rejected'] ?? 0),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _NewReturnTab(onSent: () => _tab.animateTo(1)),
          const _ReturnListTab(status: 'pending'),
          const _ReturnListTab(status: 'accepted'),
          const _ReturnListTab(status: 'rejected'),
        ],
      ),
    );
  }
}

class _TabSpec {
  final String label;
  final IconData icon;
  final String hint;
  final Color color;
  final int count;
  const _TabSpec(this.label, this.icon, this.hint, this.color,
      {this.count = 0});
}

/// Pill-style tab bar: icon + label + rang wala count badge + shortcut hint.
class _ReturnTabBar extends StatelessWidget {
  final TabController controller;
  final List<_TabSpec> tabs;
  const _ReturnTabBar({required this.controller, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: AnimatedBuilder(
        animation: controller.animation!,
        builder: (_, __) {
          final cur = controller.animation!.value.round();
          return Row(children: [
            for (var i = 0; i < tabs.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _TabPill(
                  spec: tabs[i],
                  selected: cur == i,
                  onTap: () => controller.animateTo(i),
                ),
              ),
            ],
          ]);
        },
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;
  const _TabPill(
      {required this.spec, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = spec.color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? c.withValues(alpha: .12) : AppColor.grey100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? c : Colors.transparent, width: 1.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(spec.icon,
                  size: 18, color: selected ? c : AppColor.textSecondary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(spec.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected ? c : AppColor.textSecondary)),
              ),
              if (spec.count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${spec.count}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ],
              const SizedBox(width: 8),
              _KeyChip(spec.hint, color: selected ? c : AppColor.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyChip extends StatelessWidget {
  final String t;
  final Color? color;
  const _KeyChip(this.t, {this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColor.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(t,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: c)),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// NEW RETURN — invoice-style (left: products, right: return cart)
// ═════════════════════════════════════════════════════════════════
class _NewReturnTab extends ConsumerStatefulWidget {
  final VoidCallback onSent;
  const _NewReturnTab({required this.onSent});

  @override
  ConsumerState<_NewReturnTab> createState() => _NewReturnTabState();
}

class _NewReturnTabState extends ConsumerState<_NewReturnTab>
    with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  final _notes  = TextEditingController();
  String _q = '';

  // ── Product list keyboard navigation (sale invoice jaisa) ──
  int _hover = -1;
  final _scroll    = ScrollController();
  final _itemKeys  = <int, GlobalKey>{};
  final _qtyCtrl   = TextEditingController(text: '1');
  final _qtyFocus  = FocusNode();
  final _searchKb  = FocusNode(skipTraversal: true);
  final _qtyKb     = FocusNode(skipTraversal: true);

  void _onSearchKey(KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return;
    final k = e.logicalKey;
    final list = _products(watch: false);

    if (k == LogicalKeyboardKey.escape && e is KeyDownEvent) {
      if (_search.text.isNotEmpty) {
        _search.clear();
        setState(() {
          _q = '';
          _hover = -1;
        });
      }
      return;
    }
    if (k == LogicalKeyboardKey.arrowDown) {
      if (list.isEmpty) return;
      setState(() => _hover = (_hover + 1).clamp(0, list.length - 1));
      _scrollToHover();
      return;
    }
    if (k == LogicalKeyboardKey.arrowUp) {
      if (list.isEmpty) return;
      setState(() => _hover = _hover <= 0 ? 0 : _hover - 1);
      _scrollToHover();
    }
  }

  void _onQtyKey(KeyEvent e) {
    if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
      ref.read(returnSearchFocusProvider).requestFocus();
    }
  }

  void _scrollToHover() {
    final ctx = _itemKeys[_hover]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        alignment: 0.3);
  }

  void _focusQty() {
    _qtyFocus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _qtyCtrl.selection =
          TextSelection(baseOffset: 0, extentOffset: _qtyCtrl.text.length);
    });
  }

  /// Selected (hover) product ko Qty field ki qty ke saath cart mein dalo.
  void _addSelected() {
    final list = _products(watch: false);
    if (_hover < 0 || _hover >= list.length) return;
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 1;
    if (qty <= 0) return;
    ref.read(returnCartProvider.notifier).add(list[_hover], qty: qty);
    _qtyCtrl.text = '1';
    _search.clear();
    setState(() {
      _q = '';
      _hover = -1;
    });
    ref.read(returnSearchFocusProvider).requestFocus();
  }

  void _clearAll() {
    _notes.clear();
    ref.read(returnCartProvider.notifier).clear();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _search.dispose();
    _notes.dispose();
    _scroll.dispose();
    _qtyCtrl.dispose();
    _qtyFocus.dispose();
    _searchKb.dispose();
    _qtyKb.dispose();
    super.dispose();
  }

  List<BranchStockModel> _products({bool watch = true}) {
    final all = watch
        ? ref.watch(branchStockProvider).allProducts
        : ref.read(branchStockProvider).allProducts;
    final q = _q.trim().toLowerCase();
    return all.where((p) {
      if (p.isDigital || p.quantity <= 0) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          (p.barcode?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _onSubmitted(String v) {
    final list = _products(watch: false);
    final q = v.trim().toLowerCase();

    // Barcode / SKU exact match -> seedha cart mein (qty 1).
    if (q.isNotEmpty) {
      final exact = list.where((p) {
        if (p.sku.toLowerCase() == q) return true;
        final codes = (p.barcode ?? '')
            .toLowerCase()
            .split(RegExp(r'[{},"\s]+'))
            .where((c) => c.isNotEmpty);
        return codes.contains(q);
      }).toList();
      if (exact.length == 1) {
        ref.read(returnCartProvider.notifier).add(exact.first);
        _search.clear();
        setState(() {
          _q = '';
          _hover = -1;
        });
        return;
      }
    }

    if (list.length == 1) {
      setState(() => _hover = 0);
      _addSelected();
      return;
    }
    if (_hover >= 0 && _hover < list.length) {
      _focusQty();
      return;
    }
    if (list.isNotEmpty) {
      setState(() => _hover = 0);
      _scrollToHover();
      _focusQty();
    }
  }

  Future<void> _confirmSend() async {
    final cart = ref.read(returnCartProvider);
    if (cart.lines.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Warehouse ko bhejein?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          '${cart.lines.length} items, ${_money.format(cart.totalQty)} qty '
          '(${_rs(cart.totalCost)}).\n\n'
          'Branch stock abhi minus ho jayega. Warehouse reject kare to '
          'stock wapis aa jayega.',
          style: const TextStyle(fontSize: 13, color: AppColor.textSecondary),
        ),
        actions: [
          Row(children: [
            Expanded(
              child: OutlinedButton(
                  onPressed: () => Navigator.pop(d, false),
                  child: const Text('Cancel')),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(d, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    elevation: 0),
                child: const Text('Send Return'),
              ),
            ),
          ]),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final no = cart.returnNo;
    final sent = await ref.read(returnCartProvider.notifier).send();
    if (!mounted) return;
    if (sent) {
      _notes.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColor.success,
          content: Text('Return $no warehouse ko bhej diya')));
      widget.onSent();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cart = ref.watch(returnCartProvider);
    final products = _products();

    ref.listen<String?>(returnActionProvider, (_, a) {
      if (a == null) return;
      Future.microtask(
          () => ref.read(returnActionProvider.notifier).state = null);
      if (a == 'send' && !cart.isSending) _confirmSend();
      if (a == 'clear' && !cart.isSending) _clearAll();
    });

    return LayoutBuilder(builder: (context, box) {
    final leftW = (box.maxWidth * 0.32).clamp(240.0, 400.0).toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Products ──────────────────────────────────────────
        SizedBox(
          width: leftW,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                  child: Row(children: [
                    Expanded(
                      child: KeyboardListener(
                        focusNode: _searchKb,
                        onKeyEvent: _onSearchKey,
                        child: TextField(
                          controller: _search,
                          focusNode: ref.read(returnSearchFocusProvider),
                          autofocus: true,
                          onChanged: (v) => setState(() {
                            _q = v;
                            _hover = -1;
                          }),
                          onSubmitted: _onSubmitted,
                          decoration: InputDecoration(
                            hintText: 'Search / barcode...',
                            suffixIcon: const Padding(
                                padding: EdgeInsets.all(10),
                                child: _KeyChip('F1')),
                            suffixIconConstraints: const BoxConstraints(),
                            prefixIcon:
                                const Icon(Icons.search_rounded, size: 20),
                            isDense: true,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 68,
                      child: KeyboardListener(
                        focusNode: _qtyKb,
                        onKeyEvent: _onQtyKey,
                        child: TextField(
                          controller: _qtyCtrl,
                          focusNode: _qtyFocus,
                          onSubmitted: (_) => _addSelected(),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'))
                          ],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColor.primary),
                          decoration: InputDecoration(
                            labelText: 'Qty',
                            isDense: true,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 2, 16, 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        'Barcode → auto add  |  ↑↓ select → Enter → Qty → Enter add',
                        style: TextStyle(
                            fontSize: 10.5, color: AppColor.textSecondary)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  child: Row(children: [
                    Expanded(
                        child: Text('Product',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700))),
                    SizedBox(
                        width: 50,
                        child: Text('Stock',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700))),
                    SizedBox(
                        width: 60,
                        child: Text('Cost',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700))),
                  ]),
                ),
                const Divider(height: 1),
                Expanded(
                  child: products.isEmpty
                      ? const Center(
                          child: Text('Koi product nahi mila',
                              style: TextStyle(color: AppColor.textSecondary)))
                      : ListView.builder(
                          controller: _scroll,
                          itemCount: products.length,
                          itemBuilder: (_, i) {
                            final p = products[i];
                            final inCart = cart.lines
                                .any((l) => l.productId == p.productId);
                            final hovered = i == _hover;
                            return InkWell(
                              key: _itemKeys.putIfAbsent(i, () => GlobalKey()),
                              onTap: () {
                                setState(() => _hover = i);
                                _focusQty();
                              },
                              onDoubleTap: () {
                                setState(() => _hover = i);
                                _addSelected();
                              },
                              child: Container(
                                color: hovered
                                    ? AppColor.primary.withValues(alpha: .16)
                                    : inCart
                                        ? AppColor.primary
                                            .withValues(alpha: .06)
                                        : null,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                                child: Row(children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                        Text(p.sku,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppColor.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                      width: 50,
                                      child: Text(_money.format(p.quantity),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600))),
                                  SizedBox(
                                      width: 60,
                                      child: Text(_money.format(p.costPrice),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                              fontSize: 13))),
                                ]),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        // ── Return invoice ───────────────────────────────────
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(
                      flex: 3,
                      child: _InfoBox(
                          label: 'Return No',
                          value: cart.returnNo,
                          icon: Icons.receipt_long_rounded)),
                  const SizedBox(width: 12),
                  Expanded(
                      flex: 2,
                      child: _InfoBox(
                          label: 'Date',
                          value: DateFormat('dd-MM-yyyy').format(DateTime.now()),
                          icon: Icons.calendar_today_rounded)),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _notes,
                      focusNode: ref.read(returnNoteFocusProvider),
                      onChanged:
                          ref.read(returnCartProvider.notifier).setNotes,
                      decoration: InputDecoration(
                        labelText: 'Note',
                        hintText: 'Return note (optional)...  Ctrl+N',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ]),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(children: [
                  SizedBox(width: 24, child: _H('#')),
                  Expanded(child: _H('Product')),
                  SizedBox(width: 56, child: _H('Stock', right: true)),
                  SizedBox(width: 84, child: _H('Qty', right: true)),
                  SizedBox(width: 64, child: _H('Cost', right: true)),
                  SizedBox(width: 80, child: _H('Total', right: true)),
                  SizedBox(width: 36),
                ]),
              ),
              Expanded(
                child: cart.lines.isEmpty
                    ? const Center(
                        child: Text(
                            'Left list se product par tap karo (ya barcode scan karo)',
                            style: TextStyle(color: AppColor.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: cart.lines.length,
                        itemBuilder: (_, i) => _CartRow(
                          key: ValueKey(cart.lines[i].productId),
                          index: i + 1,
                          line: cart.lines[i],
                        ),
                      ),
              ),
              if (cart.error != null)
                Container(
                  width: double.infinity,
                  color: AppColor.errorLight,
                  padding: const EdgeInsets.all(10),
                  child: Text(cart.error!,
                      style: const TextStyle(
                          color: AppColor.error, fontSize: 13)),
                ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _SumRow('Items', '${cart.lines.length}'),
                  _SumRow('Total Qty', _money.format(cart.totalQty)),
                  _SumRow('Total Sale Value', _rs(cart.totalSale)),
                  const SizedBox(height: 4),
                  _SumRow('Total Cost', _rs(cart.totalCost), big: true),
                  const SizedBox(height: 12),
                  Row(children: [
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: cart.lines.isEmpty || cart.isSending
                            ? null
                            : _clearAll,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Clear'),
                          SizedBox(width: 6),
                          _KeyChip('Ctrl+D', color: AppColor.error),
                        ]),
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            foregroundColor: AppColor.error),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: cart.lines.isEmpty || cart.isSending
                              ? null
                              : _confirmSend,
                          icon: cart.isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.outbox_rounded, size: 18),
                          label: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Flexible(
                                child: Text('Send to Warehouse',
                                    overflow: TextOverflow.ellipsis)),
                            SizedBox(width: 8),
                            _KeyChip('Ctrl+S', color: Colors.white),
                          ]),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            backgroundColor: AppColor.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
    });
  }
}

class _H extends StatelessWidget {
  final String t;
  final bool right;
  const _H(this.t, {this.right = false});
  @override
  Widget build(BuildContext context) => Text(t,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700, color: AppColor.primary));
}

class _InfoBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _InfoBox(
      {required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColor.textSecondary)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
                color: AppColor.grey100,
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(icon, size: 16, color: AppColor.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13))),
            ]),
          ),
        ],
      );
}

class _SumRow extends StatelessWidget {
  final String l, v;
  final bool big;
  const _SumRow(this.l, this.v, {this.big = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l,
                style: TextStyle(
                    fontSize: big ? 18 : 13,
                    fontWeight: big ? FontWeight.w800 : FontWeight.w500,
                    color: big ? AppColor.primary : null)),
            Text(v,
                style: TextStyle(
                    fontSize: big ? 18 : 13,
                    fontWeight: big ? FontWeight.w800 : FontWeight.w600,
                    color: big ? AppColor.primary : null)),
          ],
        ),
      );
}

class _CartRow extends ConsumerStatefulWidget {
  final int index;
  final ReturnCartLine line;
  const _CartRow({super.key, required this.index, required this.line});

  @override
  ConsumerState<_CartRow> createState() => _CartRowState();
}

class _CartRowState extends ConsumerState<_CartRow> {
  late final TextEditingController _c =
      TextEditingController(text: _fmt(widget.line.qty));

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void didUpdateWidget(covariant _CartRow old) {
    super.didUpdateWidget(old);
    // Bahar se qty badli (+1 on re-tap / clamp) to field sync karo.
    final typed = double.tryParse(_c.text) ?? 0;
    if (typed != widget.line.qty) {
      _c.text = _fmt(widget.line.qty);
      _c.selection = TextSelection.collapsed(offset: _c.text.length);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.line;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Row(children: [
        SizedBox(width: 24, child: Text('${widget.index}')),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              Text(l.sku,
                  style: const TextStyle(
                      fontSize: 11, color: AppColor.textSecondary)),
            ],
          ),
        ),
        SizedBox(
            width: 56,
            child: Text(_money.format(l.available),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13))),
        SizedBox(
          width: 84,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextField(
              controller: _c,
              textAlign: TextAlign.right,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  isDense: true, border: OutlineInputBorder()),
              onChanged: (v) {
                final n = double.tryParse(v) ?? 0;
                ref.read(returnCartProvider.notifier).setQty(l.productId, n);
                if (n > l.available) {
                  _c.text = _fmt(l.available);
                  _c.selection =
                      TextSelection.collapsed(offset: _c.text.length);
                }
              },
            ),
          ),
        ),
        SizedBox(
            width: 64,
            child: Text(_money.format(l.costPrice),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13))),
        SizedBox(
            width: 80,
            child: Text(_money.format(l.totalCost),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700))),
        SizedBox(
          width: 36,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: AppColor.error),
            onPressed: () =>
                ref.read(returnCartProvider.notifier).remove(l.productId),
          ),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Pending / Accepted / Rejected lists
// ═════════════════════════════════════════════════════════════════
class _ReturnListTab extends ConsumerWidget {
  final String status;
  const _ReturnListTab({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(returnListProvider(status));
    return async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColor.primary)),
      error: (e, _) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$e', style: const TextStyle(color: AppColor.error)),
          const SizedBox(height: 8),
          OutlinedButton(
              onPressed: () => ref.invalidate(returnListProvider(status)),
              child: const Text('Retry')),
        ]),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
              child: Text('Koi $status return nahi',
                  style: const TextStyle(color: AppColor.textSecondary)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) => _ReturnCard(ret: list[i]),
        );
      },
    );
  }
}

class _ReturnCard extends StatelessWidget {
  final StockReturn ret;
  const _ReturnCard({required this.ret});

  @override
  Widget build(BuildContext context) {
    final color = ret.isAccepted
        ? AppColor.success
        : ret.isRejected
            ? AppColor.error
            : AppColor.warningDark;
    final label = ret.isAccepted
        ? 'Accepted'
        : ret.isRejected
            ? 'Rejected'
            : 'Pending';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColor.grey200)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Row(children: [
            Text(ret.returnNumber,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
          ]),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${DateFormat('dd MMM yyyy, hh:mm a').format(ret.returnedAt)}  •  '
              '${ret.items.length} items  •  ${_money.format(ret.totalItems)} qty  •  '
              '${_rs(ret.totalCost)}',
              style: const TextStyle(
                  fontSize: 12, color: AppColor.textSecondary),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: [
            if (ret.isRejected) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColor.errorLight,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'Warehouse ne reject kiya'
                  '${ret.rejectReason == null ? '' : ': ${ret.rejectReason}'}'
                  '${ret.stockRestored ? '\nStock branch mein wapis add ho gaya.' : '\nStock wapis add hona baqi hai (Refresh karo).'}',
                  style:
                      const TextStyle(fontSize: 12, color: AppColor.error),
                ),
              ),
            ],
            if (ret.isAccepted)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColor.successLight,
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('Warehouse ne accept kiya — stock warehouse mein add ho gaya.',
                    style: TextStyle(fontSize: 12, color: AppColor.success)),
              ),
            if ((ret.notes ?? '').isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Note: ${ret.notes}',
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
            const Row(children: [
              Expanded(flex: 3, child: _H('Product')),
              SizedBox(width: 80, child: _H('Qty', right: true)),
              SizedBox(width: 90, child: _H('Cost', right: true)),
              SizedBox(width: 100, child: _H('Total', right: true)),
            ]),
            const Divider(height: 12),
            for (final it in ret.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(
                      flex: 3,
                      child: Text(it.productName,
                          style: const TextStyle(fontSize: 13))),
                  SizedBox(
                      width: 80,
                      child: Text(_money.format(it.quantityReturned),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 13))),
                  SizedBox(
                      width: 90,
                      child: Text(_money.format(it.purchasePrice),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 13))),
                  SizedBox(
                      width: 100,
                      child: Text(_money.format(it.totalCost),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700))),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
