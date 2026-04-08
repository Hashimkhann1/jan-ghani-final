import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../provider/customer_detail_provider.dart';
import '../invoice_card_widget.dart';

class SaleInvoiceTab extends ConsumerWidget {
  final String customerId;
  final String customerName;

  const SaleInvoiceTab({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(customerDetailProvider(customerId).notifier);
    final invoices = notifier.filteredInvoices;

    if (invoices.isEmpty) {
      return const Center(
        child: Text('Koi invoice nahi mila',
            style: TextStyle(color: AppColor.textSecondary, fontSize: 14)),
      );
    }

    // ✅ shrinkWrap aur NeverScrollableScrollPhysics hata diye
    return ListView.separated(
      padding:          const EdgeInsets.only(bottom: 20),
      itemCount:        invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final inv = invoices[i];

        return InvoiceDocumentCard(
          headerLabel:    'Invoice No: ',
          documentNumber: inv.invoiceNumber,
          numberColor:    AppColor.primary,
          date:           inv.date,
          customerName:   customerName,
          borderColor:    AppColor.grey200,

          items: inv.items.map((item) => DocumentItem(
            productName:    item.productName,
            unitPrice:      item.unitPrice,
            discountAmount: item.discountAmount,
            taxAmount:      item.taxAmount,
            qty:            item.qty,
            subtotal:       item.subtotal,
          )).toList(),

          totals: [
            DocumentTotal(
              label:  'Total Amount',
              value:  'Rs ${inv.totalAmount.toStringAsFixed(0)}',
              color:  AppColor.textPrimary,
              isBold: true,
            ),
            DocumentTotal(
              label: 'Received Amount',
              value: 'Rs ${inv.paidAmount.toStringAsFixed(0)}',
              color: AppColor.success,
            ),
            DocumentTotal(
              label:  'Due Amount',
              value:  'Rs ${inv.dueAmount.toStringAsFixed(0)}',
              color:  inv.dueAmount > 0 ? AppColor.error : AppColor.textSecondary,
              isBold: true,
            ),
          ],
        );
      },
    );
  }
}