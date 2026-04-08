import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/features/sale_invoice/presentation/widget/payment_dropdown_widget.dart';
import 'package:jan_ghani_final/features/sale_invoice/presentation/widget/sale_type_dropdown.dart';
import '../../../../core/color/app_color.dart';
import '../../data/model/sale_invoice_model.dart';
import '../provider/sale_invoice_provider.dart';
import 'cart_row_widget.dart';
import 'cart_summary_widget.dart';
import 'cart_table_header_widget.dart';
import 'disable_text_field_widget.dart';


class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saleInvoiceProvider);
    return Container(
      color: AppColor.background,
      child: Column(
        children: [
          const InvoiceHeaderWidget(),
          Expanded(
            child: state.cartItems.isEmpty ? const _EmptyCart() : Column(children: [
              const CartTableHeader(),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: state.cartItems.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 4),
                  itemBuilder: (context, index) => CartItemRow(cartItem: state.cartItems[index]),
                ),
              ),
            ]),
          ),
          const CartSummaryWidget(),
        ],
      ),
    );
  }
}


class InvoiceHeaderWidget extends ConsumerStatefulWidget {
  const InvoiceHeaderWidget({super.key});

  @override
  ConsumerState<InvoiceHeaderWidget> createState() =>
      _InvoiceHeaderWidgetState();
}

class _InvoiceHeaderWidgetState
    extends ConsumerState<InvoiceHeaderWidget> {
  SaleType _saleType = SaleType.sale;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleInvoiceProvider);
    final notifier = ref.read(saleInvoiceProvider.notifier);
    final bool isReturn = _saleType == SaleType.saleReturn;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.white,
        border: const Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              flex: 2,
              child: DisabledTextField(
                label: 'Invoice No',
                value: state.invoiceNo,
                icon: Icons.receipt_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DisabledTextField(
                label: 'Date',
                value: DateFormat('dd-MM-yyyy').format(state.date),
                icon: Icons.calendar_today_outlined,
              ),
            ),
            const SizedBox(width: 8),
            // Change 4: Sale / Sale Return dropdown
            Expanded(
              flex: 2,
              child: SaleTypeDropdown(
                value: _saleType,
                onChanged: (type) {
                  if (type != null) {
                    setState(() => _saleType = type);
                    notifier.setSaleType(type);
                  }
                },
              ),
            ),
          ]),

          const SizedBox(height: 8),

          Row(children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownSearch<Customer>(
                    items: (filter, _) => state.customers,
                    filterFn: (customer, filter) =>
                    customer.name.toLowerCase().contains(filter.toLowerCase()),
                    selectedItem: state.selectedCustomer,
                    compareFn: (a, b) => a.id == b.id,
                    itemAsString: (c) => c.name,
                    onSelected: (c) {
                      if (c != null) notifier.selectCustomer(c);
                    },
                    decoratorProps: const DropDownDecoratorProps(
                      decoration: InputDecoration(
                        hintText: 'Customer',
                        prefixIcon: Icon(Icons.person_outline, size: 16, color: AppColor.grey500),
                        filled: true,
                        fillColor: AppColor.grey100,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(color: AppColor.grey200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(color: AppColor.primary, width: 1.5),
                        ),

                      ),
                    ),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        cursorHeight: 14,
                        decoration: InputDecoration(
                          hintText: 'Search customer...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          filled: true,
                          fillColor: AppColor.grey100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                        )
                      ),
                      itemBuilder: (context, customer, isDisabled,
                          isSelected) =>
                          ListTile(
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColor.primary.withOpacity(
                                  0.1),
                              child: Text(
                                customer.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.primary,
                                ),
                              ),
                            ),
                            title: Text(
                              customer.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected
                                    ? AppColor.primary
                                    : AppColor.textPrimary,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                size: 16, color: AppColor.primary)
                                : null,
                          ),
                      fit: FlexFit.loose,
                      constraints: const BoxConstraints(maxHeight: 300),
                    ),

                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownField<PaymentType>(
                label: 'Payment',
                icon: Icons.payment_outlined,
                value: state.paymentType,
                items: PaymentType.values,
                itemLabel: (p) => p.label,
                onChanged: (p) {
                  if (p != null) notifier.setPaymentType(p);
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }
}



class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.06),
                    shape: BoxShape.circle),
                child: const Icon(Icons.shopping_cart_outlined,
                    size: 40, color: AppColor.primary),
              ),
              const SizedBox(height: 12),
              const Text('Cart is empty',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textSecondary)),
              const SizedBox(height: 4),
              const Text('Double tap a product to add it',
                  style: TextStyle(fontSize: 12, color: AppColor.textHint)),
            ]));
  }
}

