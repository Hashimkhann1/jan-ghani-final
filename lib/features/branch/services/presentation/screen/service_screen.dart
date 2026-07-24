// lib/features/branch/service/presentation/screen/service_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/color/app_color.dart';
import '../../../../../core/widget/dropwdown/app_drop_down.dart';
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
          TextButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const ServiceFormDialog(existing: null),
            ),
            icon:  const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Add Service'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: isWide
          ? _WideLayout(formatter: formatter)
          : _NarrowLayout(formatter: formatter),
    );
  }
}

// ── Wide Layout: Services list (left) | Cart panel (right, big) ──
class _WideLayout extends ConsumerWidget {
  final NumberFormat formatter;
  const _WideLayout({required this.formatter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 480, child: _ServiceListPanel()),
        const VerticalDivider(width: 1),
        Expanded(child: _CartPanel(formatter: formatter)),
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
        SizedBox(height: 260, child: _ServiceListPanel()),
        const Divider(height: 1),
        Expanded(child: _CartPanel(formatter: formatter)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SERVICE LIST PANEL (left side — like the Products list)
//  Tap a service -> adds it to the cart on the right.
// ════════════════════════════════════════════════════════════
class _ServiceListPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(serviceListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.miscellaneous_services_outlined,
                  size: 18, color: AppColor.primary),
              const SizedBox(width: 6),
              const Text(
                'Services',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: servicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (services) {
              final active = services.where((s) => s.isActive).toList();

              if (active.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.miscellaneous_services_outlined,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text(
                        'No services yet.\nTap "Add Service" to create one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: active.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (_, i) {
                  final s = active[i];
                  return ListTile(
                    onTap: () => ref
                        .read(serviceInvoiceProvider.notifier)
                        .addService(s),
                    leading: CircleAvatar(
                      backgroundColor: AppColor.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.miscellaneous_services_outlined,
                        color: AppColor.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      s.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${s.serviceType.replaceAll('_', ' ').toUpperCase()}'
                          '  •  Rs ${s.feeAmount.toStringAsFixed(0)}'
                          ' per Rs ${s.perAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => ServiceFormDialog(existing: s),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 18, color: Colors.red.shade300),
                          onPressed: () => _confirmDelete(context, ref, s),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ServiceModel s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Delete Service?'),
        content: Text('"${s.name}" will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(serviceListProvider.notifier).delete(s.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CART PANEL (right side — big, full height)
//  Customer selector on top, cart items in the middle (scrollable),
//  totals + payment + save sticky at the bottom.
// ════════════════════════════════════════════════════════════
class _CartPanel extends ConsumerWidget {
  final NumberFormat formatter;
  const _CartPanel({required this.formatter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceInvoiceProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _CustomerSelector(),
        ),
        const Divider(height: 1),

        Expanded(
          child: state.cartItems.isEmpty
              ? _EmptyCart()
              : ListView.separated(
            padding:          const EdgeInsets.all(16),
            itemCount:        state.cartItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
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

        if (!state.isCartEmpty) ...[
          const Divider(height: 1),
          _CartFooter(formatter: formatter),
        ],
      ],
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
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Cart is empty',
            style: TextStyle(
              color:      Colors.grey.shade600,
              fontSize:   18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a service on the left to add it',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CART FOOTER — totals + payment + save (sticky bottom)
// ════════════════════════════════════════════════════════════
class _CartFooter extends ConsumerWidget {
  final NumberFormat formatter;
  const _CartFooter({required this.formatter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceInvoiceProvider);

    return Container(
      width:   double.infinity,
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

          const SizedBox(height: 14),

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
                  onTap:    () => _showPaymentDialog(context, ref, 'cash'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PayBtn(
                  label:    'Credit',
                  icon:     Icons.person_outline,
                  selected: state.payment?.method == 'credit',
                  enabled:  state.hasCustomer,
                  onTap:    () => _showPaymentDialog(context, ref, 'credit'),
                ),
              ),
            ],
          ),

          if (state.payment != null) ...[
            const SizedBox(height: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed:
                  state.isSaving ? null : () => _save(context, ref),
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
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () =>
                      ref.read(serviceInvoiceProvider.notifier).clearCart(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Clear'),
                ),
              ),
            ],
          ),
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
          content:         Text('Please select a customer for credit'),
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
    final ok = await ref.read(serviceInvoiceProvider.notifier).saveInvoice();
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Service invoice saved!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// ── Customer Selector ────────────────────────────────────────────
class _CustomerSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state     = ref.watch(serviceInvoiceProvider);
    final customers = ref.watch(customerProvider).allCustomers;
    final fmt       = NumberFormat('#,##0.00');

    final CustomerModel? selected = state.customerId != null
        ? customers.cast<CustomerModel?>().firstWhere(
          (c) => c?.id == state.customerId,
      orElse: () => null,
    )
        : null;

    final items = <DropdownItem<CustomerModel?>>[
      const DropdownItem<CustomerModel?>(
        value: null,
        label: 'Walk-in (Cash)',
        icon:  Icons.person_outline,
      ),
      ...customers.map(
            (c) => DropdownItem<CustomerModel?>(
          value: c,
          label: '${c.name}  •  Bal: ${fmt.format(c.balance)}',
          icon:  Icons.person,
        ),
      ),
    ];

    return Row(
      children: [
        Expanded(
          child: AppSearchableDropdown<CustomerModel?>(
            label:      'Customer',
            items:      items,
            value:      selected,
            hint:       'Walk-in (Cash)',
            prefixIcon: Icons.person_outline,
            onChanged: (c) => ref
                .read(serviceInvoiceProvider.notifier)
                .selectCustomer(c),
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
    );
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
                : (enabled ? Colors.grey.shade300 : Colors.grey.shade200),
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
                  : (enabled ? AppColor.textSecondary : Colors.grey.shade300),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : (enabled ? AppColor.textPrimary : Colors.grey.shade300),
              ),
            ),
          ],
        ),
      ),
    );
  }
}