import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../provider/customer_detail_provider.dart';
import '../invoice_card_widget.dart';

class SaleReturnTab extends ConsumerWidget {
  final String customerId;
  final String customerName;

  const SaleReturnTab({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(customerDetailProvider(customerId).notifier);
    final returns  = notifier.filteredReturns;

    if (returns.isEmpty) {
      return const Center(
        child: Text('Koi return nahi mila',
            style: TextStyle(color: AppColor.textSecondary, fontSize: 14)),
      );
    }

    // ✅ shrinkWrap aur NeverScrollableScrollPhysics hata diye
    return ListView.separated(
      padding:          const EdgeInsets.only(bottom: 20),
      itemCount:        returns.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final ret = returns[i];

        return InvoiceDocumentCard(
          headerLabel:    'Return No: ',
          documentNumber: ret.returnNumber,
          numberColor:    AppColor.error,
          refNumber:      ret.refInvoiceNumber, // return mein ref invoice show hoti hai
          date:           ret.date,
          customerName:   customerName,
          borderColor:    AppColor.errorLight,

          items: ret.items.map((item) => DocumentItem(
            productName:    item.productName,
            unitPrice:      item.unitPrice,
            discountAmount: item.discountAmount,
            taxAmount:      item.taxAmount,
            qty:            item.qty,
            subtotal:       item.returnSubtotal,
            subtotalColor:  AppColor.error, // return amount red mein
            qtyColor:       AppColor.error, // return qty bhi red
          )).toList(),

          totals: [
            DocumentTotal(
              label:  'Total Return Amount',
              value:  '- Rs ${ret.totalReturnAmount.toStringAsFixed(0)}',
              color:  AppColor.error,
              isBold: true,
            ),
          ],
        );
      },
    );
  }
}