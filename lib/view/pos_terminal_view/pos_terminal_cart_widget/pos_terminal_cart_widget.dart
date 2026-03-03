import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/utils/app_colors/app_colors.dart';
import 'package:jan_ghani_final/view_model/pos_terminal_view_model/provider/pos_terminal_provider.dart';

class PosTerminalCartWidget extends ConsumerStatefulWidget {
  const PosTerminalCartWidget({super.key});

  @override
  ConsumerState<PosTerminalCartWidget> createState() =>
      _PosTerminalCartWidgetState();
}

class _PosTerminalCartWidgetState
    extends ConsumerState<PosTerminalCartWidget> {
  static const _green = AppColors.primaryColors;
  static const _lightGreen = Color(0xFFD4EDDA);
  static const _bg = Color(0xFFF0FAF4);
  static const _textDark = Color(0xFF1A1A1A);
  static const _textMid = Color(0xFF4A4A4A);
  static const _textLight = Color(0xFF888888);
  static const _cardBg = Color(0xFFE8F5ED);

  bool _showDiscount = false;
  bool _showNotes = false;
  final _discountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _discountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      'PKR ${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Container(
      width: 400,
      color: AppColors.whiteColor,
      child: Column(
        children: [
          // ── Customer header ─────────────────────────────────────────────
          _buildCustomerHeader(cart, notifier),
          // ── Cart items ──────────────────────────────────────────────────
          Expanded(
            child: cart.items.isEmpty
                ? _buildEmptyCart()
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              itemCount: cart.items.length,
              itemBuilder: (_, i) =>
                  _CartItemTile(item: cart.items[i]),
            ),
          ),
          // ── Discount / Notes toggles ─────────────────────────────────────
          if (cart.items.isNotEmpty) ...[
            _buildActionRow(cart, notifier),
            // ── Totals ────────────────────────────────────────────────────
            _buildTotals(cart),
            // ── Pay buttons ───────────────────────────────────────────────
            _buildPayButtons(cart, notifier),
          ],
        ],
      ),
    );
  }

  // ── Customer Header ───────────────────────────────────────────────────────
  Widget _buildCustomerHeader(CartState cart, CartNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_outline, size: 18, color: Color(0xFF888888)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cart.customerName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: _textDark)),
                if (cart.items.isNotEmpty)
                  Text('${cart.totalItemCount} items',
                      style: const TextStyle(fontSize: 11, color: _textLight)),
              ],
            ),
          ),
          if (cart.items.isNotEmpty)
            GestureDetector(
              onTap: () => _showClearConfirm(notifier),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(children: const [
                  Icon(Icons.delete_outline, size: 18, color: AppColors.redColors),
                  SizedBox(width: 4),
                  Text('Clear',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.redColors)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  // ── Empty Cart ────────────────────────────────────────────────────────────
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5ED),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.shopping_cart_outlined,
                size: 28, color: AppColors.primaryColors),
          ),
          const SizedBox(height: 12),
          const Text('Cart is empty',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: _textMid)),
          const SizedBox(height: 4),
          const Text('Add products to start a sale',
              style: TextStyle(fontSize: 12, color: _textLight)),
        ],
      ),
    );
  }

  // ── Discount / Notes row ──────────────────────────────────────────────────
  Widget _buildActionRow(CartState cart, CartNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  icon: Icons.percent,
                  label: 'Discount',
                  onTap: () => setState(() => _showDiscount = !_showDiscount),
                  active: _showDiscount,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  icon: Icons.note_outlined,
                  label: 'Order Notes',
                  onTap: () => setState(() => _showNotes = !_showNotes),
                  active: _showNotes,
                ),
              ),
            ],
          ),
          if (_showDiscount) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _discountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Discount %',
                    hintStyle: const TextStyle(fontSize: 12),
                    suffixText: '%',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _green),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (v) {
                    final d = double.tryParse(v) ?? 0;
                    notifier.setDiscount(d.clamp(0, 100));
                  },
                ),
              ),
            ]),
          ],
          if (_showNotes) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Add order notes...',
                hintStyle: const TextStyle(fontSize: 12),
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _green),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: notifier.setOrderNotes,
            ),
          ],
        ],
      ),
    );
  }

  // ── Totals ────────────────────────────────────────────────────────────────
  Widget _buildTotals(CartState cart) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          _TotalRow('Subtotal', _fmt(cart.subtotal)),
          if (cart.discountPercent > 0)
            _TotalRow('Discount (${cart.discountPercent.toStringAsFixed(0)}%)',
                '-${_fmt(cart.discountValue)}',
                valueColor: AppColors.redColors),
          _TotalRow('Tax (${cart.taxRate.toStringAsFixed(1)}%)',
              _fmt(cart.taxAmount)),
          const Divider(height: 16, color: Color(0xFFEEEEEE)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: _textDark)),
              Text(_fmt(cart.total),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _green)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Pay Buttons ───────────────────────────────────────────────────────────
  Widget _buildPayButtons(CartState cart, CartNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: Column(
        children: [
          // Quick Pay
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _onQuickPay(cart, notifier),
              icon: const Icon(Icons.bolt, size: 16),
              label: Text('Quick Pay ${_fmt(cart.total)}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Hold Order
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textDark,
                    side: const BorderSide(color: Color(0xFFDDDDDD)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Hold Order'),
                ),
              ),
              const SizedBox(width: 8),
              // Pay
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _onPay(cart, notifier),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6B3C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  child: Text('Pay ${_fmt(cart.total)}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onQuickPay(CartState cart, CartNotifier notifier) {
    if (cart.items.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quick Pay ${_fmt(cart.total)} processed!'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    notifier.clearCart();
  }

  void _onPay(CartState cart, CartNotifier notifier) {
    if (cart.items.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment of ${_fmt(cart.total)} successful!'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    notifier.clearCart();
  }

  void _showClearConfirm(CartNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Clear Cart?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('All items will be removed from the cart.',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              notifier.clearCart();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.redColors,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CART ITEM TILE
// ─────────────────────────────────────────────────────────────────────────────

class _CartItemTile extends ConsumerWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  String _fmt(double v) =>
      'PKR ${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF8E7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image/initials
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.product.image != null
                ? Image.network(item.product.image!,
                width: 48, height: 56, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initial())
                : _initial(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 2),
                // Text('${_fmt(item.unitPrice)} each',
                //     style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                // const SizedBox(height: 8),
                // Qty controls
                Row(
                  children: [
                    _QtyBtn(
                      icon: Icons.remove,
                      onTap: () => notifier.decrement(item.product.sku),
                    ),
                    Container(
                      width: 36,
                      alignment: Alignment.center,
                      child: Text('${item.quantity}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                    _QtyBtn(
                      icon: Icons.add,
                      onTap: () => notifier.increment(item.product.sku),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // More / delete
              Row(children: [
                GestureDetector(
                  onTap: () {},
                  child: const Icon(Icons.percent, size: 14, color: Color(0xFF888888)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => notifier.removeProduct(item.product.sku),
                  child: const Icon(Icons.delete_forever,
                      size: 18, color: AppColors.redColors),
                ),
              ]),
              const SizedBox(height: 20),
              Text(_fmt(item.total),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColors)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _initial() {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFD4EDDA),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(item.product.initials,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColors)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QTY BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: AppColors.primaryColors,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BUTTON (Discount / Notes)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppColors.primaryColors : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 15,
                color: active ? AppColors.primaryColors : const Color(0xFF666666)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? AppColors.primaryColors
                        : const Color(0xFF444444))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOTAL ROW
// ─────────────────────────────────────────────────────────────────────────────

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _TotalRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? const Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}