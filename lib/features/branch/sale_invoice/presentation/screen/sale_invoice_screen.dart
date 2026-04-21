// lib/features/branch/sale_invoice/presentation/screen/sale_invoice_screen.dart
// ── MODIFIED: Keyboard shortcuts + Cash Drawer + Hold badges ──

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../../core/color/app_color.dart';
import '../../../../../core/service/hardware/cash_drawer_service.dart';
import '../../../customer/data/model/customer_model.dart';
import '../../data/model/sale_invoice_model.dart';
import '../provider/held_invoice_provider.dart';
import '../provider/sale_invoice_provider.dart';
import '../widget/cart_panel.dart';
import '../widget/held_invoices_sheet.dart';
import '../widget/product_list_panel.dart';

/// ── Persistent FocusNode providers ─────────────────────────────
/// Provider<FocusNode> use karo — callback se zyada reliable hai.
/// Widget rebuild ya dispose ke baad bhi kaam karta hai.
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

/// Legacy — ab use nahi hota, sirf backward compat ke liye
final searchFocusCallbackProvider = StateProvider<VoidCallback?>((ref) => null);

/// Customer DropdownSearch key — Ctrl+K se programmatically open karo
final customerDropdownKeyProvider =
Provider<GlobalKey<DropdownSearchState<CustomerModel?>>>(
      (ref) => GlobalKey<DropdownSearchState<CustomerModel?>>(),
);

class SaleInvoiceScreen extends ConsumerStatefulWidget {
  const SaleInvoiceScreen({super.key});

  @override
  ConsumerState<SaleInvoiceScreen> createState() => _SaleInvoiceScreenState();
}

class _SaleInvoiceScreenState extends ConsumerState<SaleInvoiceScreen> {
  // Direct FocusNode — provider se reliable access
  FocusNode get _searchFocusNode   => ref.read(posSearchFocusProvider);
  FocusNode get _customerFocusNode => ref.read(posCustomerFocusProvider);

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

  // ── Keyboard shortcut handler ──────────────────────────────────
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final key      = event.logicalKey;
    // logicalKeysPressed use karo — isControlPressed Mac pe unreliable hota hai
    final pressed  = HardwareKeyboard.instance.logicalKeysPressed;
    final ctrl     = pressed.contains(LogicalKeyboardKey.controlLeft)  ||
        pressed.contains(LogicalKeyboardKey.controlRight);
    final shift    = pressed.contains(LogicalKeyboardKey.shiftLeft)    ||
        pressed.contains(LogicalKeyboardKey.shiftRight);

    // ── F1 / Ctrl+F / Ctrl+Shift+F — Search bar focus ─────────
    if (key == LogicalKeyboardKey.f1 ||
        (ctrl && key == LogicalKeyboardKey.keyF)) {
      _searchFocusNode.requestFocus();
      return true;
    }

    // ── Ctrl+K — Customer dropdown open karo ─────────────────
    if (ctrl && key == LogicalKeyboardKey.keyK) {
      ref.read(customerDropdownKeyProvider)
          .currentState
          ?.openDropDownSearch();
      return true;
    }

    // ── F2 — Pay Now ──────────────────────────────────────────
    if (key == LogicalKeyboardKey.f2) {
      final state = ref.read(saleInvoiceProvider);
      if (state.cartItems.isNotEmpty && state.saleType == SaleType.sale) {
        _triggerPayNow();
        return true;
      }
    }

    // ── F3 — Hold current invoice ──────────────────────────────
    if (key == LogicalKeyboardKey.f3) {
      _holdCurrentInvoice();
      return true;
    }

    // ── F4 — Show held invoices ────────────────────────────────
    if (key == LogicalKeyboardKey.f4) {
      showHeldInvoicesSheet(context, ref);
      return true;
    }

    // ── F5 / Ctrl+N — New invoice (clear cart) ─────────────────
    if (key == LogicalKeyboardKey.f5 ||
        (ctrl && key == LogicalKeyboardKey.keyN)) {
      _confirmNewInvoice();
      return true;
    }

    // ── F8 / Ctrl+D — Open cash drawer ────────────────────────
    if (key == LogicalKeyboardKey.f8 ||
        (ctrl && key == LogicalKeyboardKey.keyD)) {
      if (CashDrawerService.isSupported) _openCashDrawer();
      return true;
    }

    // ── Ctrl+Delete / Ctrl+Backspace — Clear cart ────────────
    // Mac pe Delete = Backspace, isliye dono check karo
    if (ctrl && (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace)) {
      _confirmClearCart();
      return true;
    }

    // ── Escape — Close dialogs / clear search ─────────────────
    if (key == LogicalKeyboardKey.escape) {
      // Focus hatao (dialogs Flutter khud handle karta hai)
      FocusScope.of(context).unfocus();
      return false; // Let Flutter handle Escape for dialogs
    }

    return false;
  }

  void _triggerPayNow() {
    // CartSummaryWidget mein Pay Now tap simulate karna
    // Riverpod event stream ya callback use karo — simplest: direct call
    // Yeh CartPanel ke andar showPaymentDialog ko trigger karta hai
    // We use a provider flag for this
    ref.read(_payNowTriggerProvider.notifier).state = true;
  }

  void _holdCurrentInvoice() {
    final state = ref.read(saleInvoiceProvider);
    if (state.cartItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => _HoldLabelDialog(
        onConfirm: (label) {
          ref.read(saleInvoiceProvider.notifier)
              .holdCurrentInvoice(label: label.isNotEmpty ? label : null);
        },
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
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('New Invoice?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content:
        const Text('Cart clear ho jayega. Pehle hold karna chahte ho?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ref.read(saleInvoiceProvider.notifier).holdCurrentInvoice();
            },
            child: const Text('Hold karke naya karo',
                style: TextStyle(color: AppColor.warning)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.error,
                foregroundColor: Colors.white,
                elevation:       0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(dialogCtx);
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
        ok ? '💵 Cash drawer khul gaya' : '⚠️ Drawer nahi khula — port check karein',
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

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(saleInvoiceProvider);
    final holds    = ref.watch(heldInvoicesProvider);
    final isReturn = state.saleType == SaleType.saleReturn;
    final accent   = isReturn ? AppColor.error : AppColor.primary;

    // ── Success message listener ─────────────────────────────────
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
          // ── Logo ──────────────────────────────────────────────
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
                  fontSize:   16,
                  fontWeight: FontWeight.w800,
                  color:      AppColor.textPrimary),
            ),
            Text(
              isReturn ? 'Return process karein' : 'New sale record karein',
              style: const TextStyle(
                  fontSize: 11, color: AppColor.textSecondary),
            ),
          ]),
        ]),
        actions: [
          // ── Shortcut cheat-sheet button ──────────────────────
          _ShortcutHintButton(),
          const SizedBox(width: 4),

          // ── Held invoices badge ──────────────────────────────
          // SizedBox(width) zaroor do — warna infinite width error aata hai
          if (holds.isNotEmpty) ...[
            SizedBox(
              width: 86,
              child: Stack(clipBehavior: Clip.none, children: [
                SizedBox(
                  width: 80,
                  height: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => showHeldInvoicesSheet(context, ref),
                    icon: const Icon(Icons.pause_circle_outline_rounded,
                        size: 14, color: AppColor.warning),
                    label: const Text('Hold',
                        style: TextStyle(
                            fontSize:   11,
                            color:      AppColor.warning,
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
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                        color:  AppColor.warning,
                        shape:  BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5)),
                    child: Center(
                      child: Text('${holds.length}',
                          style: const TextStyle(
                              fontSize:   8,
                              fontWeight: FontWeight.w800,
                              color:      Colors.white)),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 4),
          ],

          // ── Cash Drawer button ───────────────────────────────
          if (CashDrawerService.isSupported) ...[
            SizedBox(
              width: 90,
              height: double.infinity,
              child: Tooltip(
                message: 'Cash Drawer Kholo (F8)',
                child: OutlinedButton.icon(
                  onPressed: _openCashDrawer,
                  icon: const Icon(Icons.point_of_sale_outlined,
                      size: 14, color: AppColor.primary),
                  label: const Text('Drawer',
                      style: TextStyle(
                          fontSize:   11,
                          color:      AppColor.primary,
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

          // ── Double tap hint ──────────────────────────────────
          if (!isReturn)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 0),
              decoration: BoxDecoration(
                color:        AppColor.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border:       Border.all(
                    color: AppColor.primary.withOpacity(0.2)),
              ),
              child: const Row(children: [
                Icon(Icons.touch_app_outlined,
                    size: 13, color: AppColor.primary),
                SizedBox(width: 4),
                Text('Double tap to add',
                    style: TextStyle(
                        fontSize:   11,
                        color:      AppColor.primary,
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
                  : AppColor.grey200),
        ),
      ),
      body: Row(
        children: [
          Expanded(
              flex: 28,
              child: const ProductListPanel()),
          Expanded(flex: 72, child: const CartPanel()),
        ],
      ),
    );
  }
}

// ── Pay Now trigger provider ──────────────────────────────────────
// CartPanel is listen karta hai aur Pay Now dialog open karta hai
final _payNowTriggerProvider = StateProvider<bool>((ref) => false);
final payNowTriggerProvider  = _payNowTriggerProvider;

// ── Hold label dialog ─────────────────────────────────────────────
class _HoldLabelDialog extends StatefulWidget {
  final ValueChanged<String> onConfirm;
  const _HoldLabelDialog({required this.onConfirm});

  @override
  State<_HoldLabelDialog> createState() => _HoldLabelDialogState();
}

class _HoldLabelDialogState extends State<_HoldLabelDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

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
      controller:  _ctrl,
      autofocus:   true,
      decoration: const InputDecoration(
        hintText:    'Label (optional, jese: Table 3, Customer A)',
        hintStyle:   TextStyle(fontSize: 13),
        border:      OutlineInputBorder(),
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
                borderRadius: BorderRadius.circular(8))),
      ),
    ],
  );
}

// ── Shortcut hint button ─────────────────────────────────────────
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

class _ShortcutsDialog extends StatelessWidget {
  const _ShortcutsDialog();

  @override
  Widget build(BuildContext context) {
    const shortcuts = [
      ('F1 / Ctrl+F', 'Search bar focus',          Icons.search_rounded),
      ('F2',          'Pay Now (invoice)',           Icons.payments_outlined),
      ('F3',          'Hold current invoice',        Icons.pause_circle_outline_rounded),
      ('F4',          'Show held invoices',          Icons.list_alt_rounded),
      ('F5 / Ctrl+N', 'New invoice (clear cart)',    Icons.add_circle_outline_rounded),
      ('F8 / Ctrl+D', 'Open cash drawer',            Icons.dashboard_customize_outlined),
      ('Ctrl+Del',    'Clear cart',                  Icons.clear_all_rounded),
      ('Enter',       'Add barcode to cart',         Icons.qr_code_scanner_rounded),
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.keyboard_outlined,
                    color: AppColor.primary, size: 22),
                SizedBox(width: 10),
                Text('Keyboard Shortcuts',
                    style: TextStyle(
                        fontSize:   17,
                        fontWeight: FontWeight.w800)),
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
                            fontSize:    11,
                            fontWeight:  FontWeight.w700,
                            fontFamily:  'monospace',
                            color:       AppColor.primary)),
                  ),
                  const SizedBox(width: 10),
                  Text(s.$2,
                      style: const TextStyle(
                          fontSize: 13,
                          color:    AppColor.textPrimary)),
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
                          borderRadius: BorderRadius.circular(8))),
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

// ─────────────────────────────────────────────────────────────────────────────