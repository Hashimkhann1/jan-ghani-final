// lib/features/branch/sale_invoice/presentation/screen/sale_invoice_screen.dart

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/color/app_color.dart';
import '../../../../../core/service/hardware/cash_drawer_service.dart';
import '../../../customer/data/model/customer_model.dart';
import '../../data/model/sale_invoice_model.dart';
import '../provider/held_invoice_provider.dart';
import '../provider/cart_nav_provider.dart';
import '../provider/sale_invoice_provider.dart';
import '../widget/cart_panel.dart';
import '../widget/held_invoices_sheet.dart';
import '../widget/payment_dialog.dart';
import '../widget/product_list_panel.dart';

// ── FocusNode providers ────────────────────────────────────────────
final posSearchFocusProvider = Provider<FocusNode>((ref) {
  final fn = FocusNode(debugLabel: 'POS_Search');
  ref.onDispose(fn.dispose);
  return fn;
});

final posCustomerFocusProvider = Provider<FocusNode>((ref) {
  final fn = FocusNode(debugLabel: 'POS_Customer');
  ref.onDispose(fn.dispose);
  return fn;
});

final searchFocusCallbackProvider = StateProvider<VoidCallback?>((ref) => null);

// Sale Type FocusNode — Ctrl+T se focus karo
final saleTypeFocusProvider = Provider<FocusNode>((ref) {
  final fn = FocusNode(debugLabel: 'SaleType');
  ref.onDispose(fn.dispose);
  return fn;
});

final customerDropdownKeyProvider =
Provider<GlobalKey<DropdownSearchState<CustomerModel?>>>(
      (ref) => GlobalKey<DropdownSearchState<CustomerModel?>>(),
);

// ── Pay Now trigger ────────────────────────────────────────────────
final _payNowTriggerProvider = StateProvider<bool>((ref) => false);
final payNowTriggerProvider  = _payNowTriggerProvider;

// ═════════════════════════════════════════════════════════════════
class SaleInvoiceScreen extends ConsumerStatefulWidget {
  const SaleInvoiceScreen({super.key});

  @override
  ConsumerState<SaleInvoiceScreen> createState() => _SaleInvoiceScreenState();
}

class _SaleInvoiceScreenState extends ConsumerState<SaleInvoiceScreen> {

  FocusNode get _searchFocusNode => ref.read(posSearchFocusProvider);

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  // ── Shortcut handler ───────────────────────────────────────────
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final key     = event.logicalKey;
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final ctrl    = pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);

    // Ctrl+F / F1 — Search focus
    if (key == LogicalKeyboardKey.f1 ||
        (ctrl && key == LogicalKeyboardKey.keyF)) {
      _searchFocusNode.requestFocus();
      return true;
    }

    // Ctrl+K — Customer dropdown
    if (ctrl && key == LogicalKeyboardKey.keyK) {
      ref.read(customerDropdownKeyProvider).currentState?.openDropDownSearch();
      return true;
    }

    // ✅ FIX: Ctrl+S — Payment dialog
    // Agar koi dialog/sheet already open hai toh parent ignore kare
    // ModalRoute.isCurrent == false matlab koi aur route upar hai
    if (ctrl && key == LogicalKeyboardKey.keyS) {
      if (ModalRoute.of(context)?.isCurrent == false) return true; // ✅ KEY FIX
      final st = ref.read(saleInvoiceProvider);
      if (st.cartItems.isNotEmpty && st.saleType == SaleType.sale) {
        _triggerPayNow();
        return true;
      }
    }

    // ── Ctrl+C — Cart edit mode toggle ──────────────────────
    if (ctrl && key == LogicalKeyboardKey.keyC) {
      if (ModalRoute.of(context)?.isCurrent == false) return true; // guard
      final st  = ref.read(saleInvoiceProvider);
      final nav = ref.read(cartNavProvider);
      if (nav.isActive) {
        ref.read(cartNavProvider.notifier).deactivate();
        FocusScope.of(context).unfocus();
      } else if (st.cartItems.isNotEmpty) {
        ref.read(cartNavProvider.notifier).activate(st.cartItems.length);
      }
      return true;
    }

    // ── Arrow keys — cart row/col navigation ─────────────────
    final nav = ref.read(cartNavProvider);
    if (nav.isActive) {
      final st = ref.read(saleInvoiceProvider);
      if (key == LogicalKeyboardKey.arrowDown) {
        ref.read(cartNavProvider.notifier).moveDown(st.cartItems.length);
        return true;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        ref.read(cartNavProvider.notifier).moveUp();
        return true;
      }
      if (key == LogicalKeyboardKey.arrowRight) {
        ref.read(cartNavProvider.notifier).moveRight();
        return true;
      }
      if (key == LogicalKeyboardKey.arrowLeft) {
        ref.read(cartNavProvider.notifier).moveLeft();
        return true;
      }
      // ESC exits cart mode (override clear cart)
      if (key == LogicalKeyboardKey.escape) {
        ref.read(cartNavProvider.notifier).deactivate();
        return true;
      }
    }

    // ── Ctrl+T — Sale Type toggle ──────────────────────────────
    if (ctrl && key == LogicalKeyboardKey.keyT) {
      if (ModalRoute.of(context)?.isCurrent == false) return true; // guard
      ref.read(saleTypeFocusProvider).requestFocus();
      final st   = ref.read(saleInvoiceProvider);
      final next = st.saleType == SaleType.sale
          ? SaleType.saleReturn
          : SaleType.sale;
      ref.read(saleInvoiceProvider.notifier).setSaleType(next);
      return true;
    }

    // ── Ctrl+H / F3 — Hold invoice ────────────────────────────
    if ((ctrl && key == LogicalKeyboardKey.keyH) ||
        key == LogicalKeyboardKey.f3) {
      if (ModalRoute.of(context)?.isCurrent == false) return true; // guard
      _holdCurrentInvoice();
      return true;
    }

    // F4 — Held invoices list
    if (key == LogicalKeyboardKey.f4) {
      if (ModalRoute.of(context)?.isCurrent == false) return true; // guard
      showHeldInvoicesSheet(context, ref);
      return true;
    }

    // Ctrl+N / F5 — New invoice
    if (key == LogicalKeyboardKey.f5 ||
        (ctrl && key == LogicalKeyboardKey.keyN)) {
      if (ModalRoute.of(context)?.isCurrent == false) return true; // guard
      _confirmNewInvoice();
      return true;
    }

    // F8 / Ctrl+D — Cash drawer
    if (key == LogicalKeyboardKey.f8 ||
        (ctrl && key == LogicalKeyboardKey.keyD)) {
      if (CashDrawerService.isSupported) _openCashDrawer();
      return true;
    }

    // ESC — Clear cart
    if (key == LogicalKeyboardKey.escape) {
      if (ModalRoute.of(context)?.isCurrent == false) return true; // guard
      _confirmClearCart();
      return true;
    }

    return false;
  }

  // ── Actions ────────────────────────────────────────────────────
  void _triggerPayNow() {
    ref.read(_payNowTriggerProvider.notifier).state = true;
  }

  void _holdCurrentInvoice() {
    final state = ref.read(saleInvoiceProvider);
    if (state.cartItems.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => _HoldLabelDialog(
        onConfirm: (label) => ref
            .read(saleInvoiceProvider.notifier)
            .holdCurrentInvoice(label: label.isNotEmpty ? label : null),
      ),
    );
  }

  void _confirmNewInvoice() {
    final state = ref.read(saleInvoiceProvider);
    if (state.cartItems.isEmpty) {
      ref.read(saleInvoiceProvider.notifier).clearCart();
      return;
    }
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('New Invoice?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content:
        const Text('Cart clear ho jayega. Pehle hold karna chahte ho?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(d);
              ref.read(saleInvoiceProvider.notifier).holdCurrentInvoice();
            },
            child: const Text('Hold karke naya karo',
                style: TextStyle(color: AppColor.warning)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(d);
              ref.read(saleInvoiceProvider.notifier).clearCart();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _openCashDrawer() async {
    if (!CashDrawerService.isSupported) return;
    final ok = await CashDrawerService.openDrawer();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        ok
            ? '💵 Cash drawer khul gaya'
            : '⚠️ Drawer nahi khula — port check karein',
        style: const TextStyle(fontSize: 13),
      ),
      backgroundColor: ok ? AppColor.success : AppColor.warning,
      behavior:        SnackBarBehavior.floating,
      duration:        const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _confirmClearCart() {
    final state = ref.read(saleInvoiceProvider);
    if (state.cartItems.isEmpty) return;
    ref.read(saleInvoiceProvider.notifier).clearCart();
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(saleInvoiceProvider);
    final holds    = ref.watch(heldInvoicesProvider);
    final isReturn = state.saleType == SaleType.saleReturn;
    final accent   = isReturn ? AppColor.error : AppColor.primary;

    ref.listen<SaleInvoiceState>(saleInvoiceProvider, (prev, next) {
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.successMessage!,
              style: const TextStyle(fontSize: 14)),
          backgroundColor: AppColor.success,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        ref.read(saleInvoiceProvider.notifier).clearSuccess();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        titleSpacing:     16,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withOpacity(0.7)],
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isReturn
                  ? Icons.assignment_return_outlined
                  : Icons.point_of_sale_outlined,
              color: Colors.white,
              size:  18,
            ),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isReturn ? 'Sale Return' : 'Sale Invoice',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColor.textPrimary),
            ),
            Text(
              isReturn ? 'Return process karein' : 'New sale record karein',
              style: const TextStyle(
                  fontSize: 11, color: AppColor.textSecondary),
            ),
          ]),
        ]),
        actions: [
          // Shortcut hint button
          _ShortcutHintButton(),
          const SizedBox(width: 4),

          // Held invoices badge
          if (holds.isNotEmpty) ...[
            SizedBox(
              width: 86,
              child: Stack(clipBehavior: Clip.none, children: [
                SizedBox(
                  width:  80,
                  height: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => showHeldInvoicesSheet(context, ref),
                    icon: const Icon(Icons.pause_circle_outline_rounded,
                        size: 14, color: AppColor.warning),
                    label: const Text('Hold',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColor.warning,
                            fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side:    const BorderSide(color: AppColor.warning),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape:   RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                Positioned(
                  top: 6, right: 0,
                  child: Container(
                    width:  16,
                    height: 16,
                    decoration: BoxDecoration(
                        color:  AppColor.warning,
                        shape:  BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5)),
                    child: Center(
                      child: Text('${holds.length}',
                          style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 4),
          ],

          // Cash Drawer button
          if (CashDrawerService.isSupported) ...[
            SizedBox(
              width:  90,
              height: double.infinity,
              child: Tooltip(
                message: 'Cash Drawer (F8)',
                child: OutlinedButton.icon(
                  onPressed: _openCashDrawer,
                  icon: const Icon(Icons.point_of_sale_outlined,
                      size: 14, color: AppColor.primary),
                  label: const Text('Drawer',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColor.primary,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side:    BorderSide(color: AppColor.primary.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    shape:   RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],

          // Double tap hint
          if (!isReturn)
            Container(
              margin:  const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color:        AppColor.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border:       Border.all(color: AppColor.primary.withOpacity(0.2)),
              ),
              child: const Row(children: [
                Icon(Icons.touch_app_outlined,
                    size: 13, color: AppColor.primary),
                SizedBox(width: 4),
                Text('Double tap to add',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColor.primary,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isReturn
                ? AppColor.error.withOpacity(0.3)
                : AppColor.grey200,
          ),
        ),
      ),
      body: const Row(
        children: [
          Expanded(flex: 28, child: ProductListPanel()),
          Expanded(flex: 72, child: CartPanel()),
        ],
      ),
    );
  }
} // ← _SaleInvoiceScreenState closes here

// ═════════════════════════════════════════════════════════════════
// ── Hold Label Dialog ─────────────────────────────────────────────
class _HoldLabelDialog extends StatefulWidget {
  final ValueChanged<String> onConfirm;
  const _HoldLabelDialog({required this.onConfirm});

  @override
  State<_HoldLabelDialog> createState() => _HoldLabelDialogState();
}

class _HoldLabelDialogState extends State<_HoldLabelDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    title: const Row(children: [
      Icon(Icons.pause_circle_outline_rounded,
          color: AppColor.warning, size: 20),
      SizedBox(width: 8),
      Text('Invoice Hold Karo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    ]),
    content: TextField(
      controller: _ctrl,
      autofocus:  true,
      decoration: const InputDecoration(
        hintText:  'Label (optional, e.g. Table 3)',
        hintStyle: TextStyle(fontSize: 13),
        border:    OutlineInputBorder(),
      ),
      onSubmitted: (_) {
        Navigator.pop(context);
        widget.onConfirm(_ctrl.text.trim());
      },
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          widget.onConfirm(_ctrl.text.trim());
        },
        icon:  const Icon(Icons.pause_rounded, size: 16),
        label: const Text('Hold Karo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.warning,
          foregroundColor: Colors.white,
          elevation:       0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ],
  );
}

// ── Shortcut Hint Button ───────────────────────────────────────────
class _ShortcutHintButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Keyboard Shortcuts',
    child: IconButton(
      icon: const Icon(Icons.keyboard_outlined,
          size: 20, color: AppColor.textSecondary),
      onPressed: () => showDialog(
        context: context,
        builder: (_) => const _ShortcutsDialog(),
      ),
    ),
  );
}

// ── Shortcuts Dialog ──────────────────────────────────────────────
class _ShortcutsDialog extends StatelessWidget {
  const _ShortcutsDialog();

  @override
  Widget build(BuildContext context) {
    const shortcuts = [
      ('Ctrl+C',      'Cart edit mode on/off',          Icons.edit_outlined),
      ('↑↓ ← →',     'Cart row / column navigate',      Icons.open_with_rounded),
      ('Ctrl+T',      'Sale type toggle (Sale/Return)',  Icons.swap_horiz_rounded),
      ('Ctrl+S',      'Payment dialog / Save',           Icons.payments_outlined),
      ('Ctrl+H / F3', 'Hold invoice',                   Icons.pause_circle_outline_rounded),
      ('Ctrl+K',      'Customer dropdown',               Icons.person_outline),
      ('Ctrl+F / F1', 'Search focus',                   Icons.search_rounded),
      ('F4',          'Held invoices',                   Icons.list_alt_rounded),
      ('Ctrl+N / F5', 'New invoice',                    Icons.add_circle_outline_rounded),
      ('F8 / Ctrl+D', 'Cash drawer',                    Icons.dashboard_customize_outlined),
      ('ESC',         'Cart mode off / Clear cart',      Icons.clear_all_rounded),
      ('↑↓ + Enter',  'Product select + qty',            Icons.keyboard_arrow_down_rounded),
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:       MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.keyboard_outlined, color: AppColor.primary, size: 22),
                SizedBox(width: 10),
                Text('Keyboard Shortcuts',
                    style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 16),
              ...shortcuts.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Icon(s.$3, size: 16, color: AppColor.primary),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:        AppColor.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(s.$1,
                        style: const TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color:      AppColor.primary)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.$2,
                        style: const TextStyle(
                            fontSize: 13,
                            color:    AppColor.textPrimary)),
                  ),
                ]),
              )),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    elevation:       0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}