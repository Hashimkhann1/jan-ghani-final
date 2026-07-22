// lib/features/branch/service/presentation/screen/service_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/color/app_color.dart';
import '../../../customer/data/model/customer_model.dart';
import '../../../customer/presentation/provider/customer_provider.dart';
import '../../data/model/service_model.dart';
import '../provideer/service_provider.dart';
import '../widget/service_widgets.dart';

class ServiceScreen extends ConsumerStatefulWidget {
  const ServiceScreen({super.key});

  @override
  ConsumerState<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends ConsumerState<ServiceScreen> {
  static const double _kWideBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(serviceInvoiceProvider);
    final isWide    = MediaQuery.of(context).size.width >= _kWideBreakpoint;
    final formatter = NumberFormat('#,##0.00');

    ref.listen(serviceInvoiceProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(serviceInvoiceProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Service  •  ${state.invoiceNo}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          // ── Add Service button (AppBar top right) ──
          TextButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => ServiceAddDialog(
                onServiceSelected: (service) {
                  ref.read(serviceInvoiceProvider.notifier).addService(service);
                },
              ),
            ),
            icon:  const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Add Service'),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ServiceManageScreen()),
            ),
            icon:  const Icon(Icons.settings_outlined, size: 18),
            label: const Text('Manage Services'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isWide
          ? _WideLayout(formatter: formatter)
          : _NarrowLayout(formatter: formatter),
    );
  }
}

// ── Wide Layout ────────────────────────────────────────────────
class _WideLayout extends ConsumerWidget {
  final NumberFormat formatter;
  const _WideLayout({required this.formatter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(flex: 3, child: _CartPanel(formatter: formatter)),
        const VerticalDivider(width: 1),
        SizedBox(width: 320, child: _SummaryPanel(formatter: formatter)),
      ],
    );
  }
}

// ── Narrow Layout ──────────────────────────────────────────────
class _NarrowLayout extends ConsumerWidget {
  final NumberFormat formatter;
  const _NarrowLayout({required this.formatter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(child: _CartPanel(formatter: formatter)),
        const Divider(height: 1),
        _SummaryPanel(formatter: formatter),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CART PANEL
// ════════════════════════════════════════════════════════════
class _CartPanel extends ConsumerWidget {
  final NumberFormat formatter;
  const _CartPanel({required this.formatter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceInvoiceProvider);

    return Column(
      children: [
        _CustomerBar(),
        const Divider(height: 1),

        Expanded(
          child: state.cartItems.isEmpty
              ? _EmptyCart()
              : ListView.separated(
            padding:          const EdgeInsets.all(12),
            itemCount:        state.cartItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => ServiceCartItemWidget(
              key:      ValueKey(state.cartItems[i].cartId),
              item:     state.cartItems[i],
              formatter: formatter,
              onRemove: () => ref
                  .read(serviceInvoiceProvider.notifier)
                  .removeService(state.cartItems[i].cartId),
              onAmountChanged: (val) => ref
                  .read(serviceInvoiceProvider.notifier)
                  .updateAmount(state.cartItems[i].cartId, val),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Customer Bar ───────────────────────────────────────────────
class _CustomerBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state     = ref.watch(serviceInvoiceProvider);
    final customers = ref.watch(customerProvider).allCustomers;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.person_outline,
              size: 18, color: AppColor.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CustomerModel?>(
                value: state.customerId != null
                    ? customers.cast<CustomerModel?>().firstWhere(
                      (c) => c?.id == state.customerId,
                  orElse: () => null,
                )
                    : null,
                hint: const Text('Walk-in (Cash)',
                    style: TextStyle(fontSize: 13)),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<CustomerModel?>(
                    value: null,
                    child: Text('Walk-in (Cash)',
                        style: TextStyle(fontSize: 13)),
                  ),
                  ...customers.map((c) => DropdownMenuItem<CustomerModel?>(
                    value: c,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize:       MainAxisSize.min,
                      children: [
                        Text(c.name,
                            style: const TextStyle(fontSize: 13)),
                        Text(
                          'Balance: ${NumberFormat('#,##0.00').format(c.balance)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: c.balance > 0
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
                onChanged: (c) => ref
                    .read(serviceInvoiceProvider.notifier)
                    .selectCustomer(c),
              ),
            ),
          ),
          if (state.hasCustomer)
            IconButton(
              icon:      const Icon(Icons.close, size: 18),
              onPressed: () => ref
                  .read(serviceInvoiceProvider.notifier)
                  .selectCustomer(null),
              tooltip: 'Remove customer',
            ),
        ],
      ),
    );
  }
}

// ── Empty Cart ─────────────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Koi service add nahi ki',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Uper "Add Service" button dabao',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SUMMARY PANEL
// ════════════════════════════════════════════════════════════
class _SummaryPanel extends ConsumerWidget {
  final NumberFormat formatter;
  const _SummaryPanel({required this.formatter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceInvoiceProvider);

    return Container(
      color:   Colors.grey.shade50,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize:       MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryRow(
            label: 'Service Amount',
            value: formatter.format(state.totalAmount),
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Service Fee',
            value: formatter.format(state.totalFee),
            color: AppColor.primary,
          ),
          const Divider(height: 20),
          _SummaryRow(
            label:  'Grand Total',
            value:  'Rs ${formatter.format(state.grandTotal)}',
            isBold: true,
          ),

          const SizedBox(height: 12),

          if (!state.isCartEmpty) ...[
            const Text(
              'Payment',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PayBtn(
                    label:    'Cash',
                    icon:     Icons.payments_outlined,
                    selected: state.payment?.method == 'cash',
                    onTap:    () =>
                        _showPaymentDialog(context, ref, 'cash'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PayBtn(
                    label:    'Credit',
                    icon:     Icons.person_outline,
                    selected: state.payment?.method == 'credit',
                    enabled:  state.hasCustomer,
                    onTap:    () =>
                        _showPaymentDialog(context, ref, 'credit'),
                  ),
                ),
              ],
            ),

            if (state.payment != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color:        Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border:       Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade600, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${state.payment!.method.toUpperCase()}  '
                          'Rs ${formatter.format(state.payment!.amount)}',
                      style: TextStyle(
                        color:      Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize:   13,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: state.isSaving ? null : () => _save(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: state.isSaving
                  ? const SizedBox(
                height: 20,
                width:  20,
                child:  CircularProgressIndicator(
                  strokeWidth: 2,
                  color:       Colors.white,
                ),
              )
                  : const Text(
                'Save Invoice',
                style: TextStyle(
                  color:      Colors.white,
                  fontSize:   15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: () =>
                  ref.read(serviceInvoiceProvider.notifier).clearCart(),
              child: const Text('Clear',
                  style: TextStyle(color: Colors.grey)),
            ),
          ],
        ],
      ),
    );
  }

  void _showPaymentDialog(
      BuildContext context, WidgetRef ref, String method) {
    final state = ref.read(serviceInvoiceProvider);
    if (method == 'credit' && !state.hasCustomer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Credit ke liye customer select karein'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => ServicePaymentDialog(
        method:     method,
        grandTotal: state.grandTotal,
        onConfirm:  (amount) => ref
            .read(serviceInvoiceProvider.notifier)
            .setPayment(method, amount),
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final ok =
    await ref.read(serviceInvoiceProvider.notifier).saveInvoice();
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Service invoice save ho gaya!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// ── Summary Row ────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool   isBold;
  final Color? color;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize:   isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color:      color ?? AppColor.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize:   isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color:      color,
          ),
        ),
      ],
    );
  }
}

// ── Payment Button ─────────────────────────────────────────────
class _PayBtn extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final bool         selected;
  final bool         enabled;
  final VoidCallback onTap;

  const _PayBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration:  const Duration(milliseconds: 150),
        padding:   const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color:        selected ? AppColor.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColor.primary
                : (enabled
                ? Colors.grey.shade300
                : Colors.grey.shade200),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size:  20,
              color: selected
                  ? Colors.white
                  : (enabled
                  ? AppColor.textSecondary
                  : Colors.grey.shade300),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : (enabled
                    ? AppColor.textPrimary
                    : Colors.grey.shade300),
              ),
            ),
          ],
        ),
      ),
    );
  }
}