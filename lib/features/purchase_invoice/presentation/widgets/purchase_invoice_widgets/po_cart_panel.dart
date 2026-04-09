// =============================================================
// po_cart_panel.dart
// Row 1: PO Number | Supplier | Type
// Row 2: Order Date | Delivery Date
// Save → Confirmation Dialog
// =============================================================

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/purchase_invoice/data/purchase_invoice_model.dart';
import 'package:jan_ghani_final/features/purchase_invoice/presentation/provider/purchase_invoice_provider/purchase_invoice_provider.dart';
import 'po_cart_row_widget.dart';
import 'po_cart_table_header.dart';
import 'po_cart_summary_widget.dart';
import 'po_disable_text_field.dart';
import 'po_type_dropdown.dart';

class PoCartPanel extends ConsumerWidget {
  const PoCartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchaseInvoiceProvider);

    return Container(
      color: AppColor.background,
      child: Column(
        children: [
          const PoInvoiceHeaderWidget(),
          Expanded(
            child: state.cartItems.isEmpty
                ? const _EmptyCart()
                : Column(
                    children: [
                      const PoCartTableHeader(),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          itemCount: state.cartItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, index) =>
                              PoCartItemRow(
                                  cartItem:
                                      state.cartItems[index]),
                        ),
                      ),
                    ],
                  ),
          ),
          const PoCartSummaryWidget(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HEADER WIDGET
// ─────────────────────────────────────────────────────────────

class PoInvoiceHeaderWidget extends ConsumerStatefulWidget {
  const PoInvoiceHeaderWidget({super.key});

  @override
  ConsumerState<PoInvoiceHeaderWidget> createState() =>
      _PoInvoiceHeaderWidgetState();
}

class _PoInvoiceHeaderWidgetState
    extends ConsumerState<PoInvoiceHeaderWidget> {
  PoType _poType = PoType.purchase;

  Future<void> _pickDate(BuildContext context,
      {required bool isDelivery}) async {
    final state    = ref.read(purchaseInvoiceProvider);
    final notifier = ref.read(purchaseInvoiceProvider.notifier);

    final initial = isDelivery
        ? (state.deliveryDate ??
            state.orderDate.add(const Duration(days: 7)))
        : state.orderDate;

    final picked = await showDatePicker(
      context:     context,
      initialDate: initial,
      firstDate:   DateTime(2024),
      lastDate:    DateTime(2030),
    );
    if (picked == null) return;

    if (isDelivery) {
      notifier.setDeliveryDate(picked);
    } else {
      notifier.setOrderDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(purchaseInvoiceProvider);
    final notifier = ref.read(purchaseInvoiceProvider.notifier);

    final fmt = DateFormat('dd-MM-yyyy');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:  AppColor.white,
        border: const Border(
            bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Column(
        children: [
          // ── Row 1: PO Number | Supplier | Type ────────────
          Row(
            children: [
              // PO Number — disabled
              Expanded(
                flex: 2,
                child: PoDisabledTextField(
                  label: 'PO Number',
                  value: state.poNumber,
                  icon:  Icons.receipt_outlined,
                ),
              ),
              const SizedBox(width: 8),

              // Supplier dropdown
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Supplier',
                        style: TextStyle(
                            fontSize:   10,
                            fontWeight: FontWeight.w600,
                            color:      AppColor.textSecondary)),
                    const SizedBox(height: 4),
                    DropdownSearch<PoSupplier>(
                      items:        (f, _) => state.suppliers,
                      filterFn:     (s, f) => s.name
                          .toLowerCase()
                          .contains(f.toLowerCase()),
                      selectedItem: state.selectedSupplier,
                      compareFn:   (a, b) => a.id == b.id,
                      itemAsString: (s) => s.name,
                      onSelected:  (s) {
                        if (s != null) notifier.selectSupplier(s);
                      },
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          hintText:   'Select Supplier',
                          prefixIcon: Icon(Icons.person_outline,
                              size: 16, color: AppColor.grey500),
                          filled:     true,
                          fillColor:  AppColor.grey100,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                                Radius.circular(8)),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                                Radius.circular(8)),
                            borderSide: BorderSide(
                                color: AppColor.grey200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                                Radius.circular(8)),
                            borderSide: BorderSide(
                                color: AppColor.primary,
                                width: 1.5),
                          ),
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          cursorHeight: 14,
                          decoration: InputDecoration(
                            hintText:   'Search supplier...',
                            prefixIcon: const Icon(
                                Icons.search, size: 18),
                            filled:     true,
                            fillColor:  AppColor.grey100,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                            border:        InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                        itemBuilder: (ctx, s, isDisabled,
                                isSelected) =>
                            ListTile(
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                AppColor.primary.withOpacity(0.1),
                            child: Text(s.initials,
                                style: const TextStyle(
                                    fontSize:   11,
                                    fontWeight: FontWeight.w700,
                                    color:      AppColor.primary)),
                          ),
                          title: Text(s.name,
                              style: TextStyle(
                                  fontSize:   12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? AppColor.primary
                                      : AppColor.textPrimary)),
                          subtitle: Text(
                            '${s.company}  •  '
                            '${s.paymentTerms} days',
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColor.textSecondary),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  size: 16, color: AppColor.primary)
                              : null,
                        ),
                        fit:         FlexFit.loose,
                        constraints: const BoxConstraints(
                            maxHeight: 300),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Type dropdown
              Expanded(
                flex: 2,
                child: PoTypeDropdown(
                  value: _poType,
                  onChanged: (type) {
                    if (type != null) {
                      setState(() => _poType = type);
                      notifier.setPoType(type);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Row 2: Order Date | Delivery Date ─────────────
          Row(
            children: [
              // Order Date — selectable
              Expanded(
                child: _DatePickerField(
                  label:   'Order Date',
                  date:    state.orderDate,
                  icon:    Icons.calendar_today_outlined,
                  onTap:   () => _pickDate(context,
                      isDelivery: false),
                ),
              ),
              const SizedBox(width: 8),

              // Delivery Date — selectable + optional
              Expanded(
                child: _DatePickerField(
                  label:       'Delivery Date',
                  date:        state.deliveryDate,
                  icon:        Icons.local_shipping_outlined,
                  placeholder: 'Select delivery date',
                  onTap:       () => _pickDate(context,
                      isDelivery: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DATE PICKER FIELD
// ─────────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final String     label;
  final DateTime?  date;
  final IconData   icon;
  final String     placeholder;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.icon,
    required this.onTap,
    this.placeholder = 'Select date',
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd-MM-yyyy');
    final hasDate = date != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize:   10,
                fontWeight: FontWeight.w600,
                color:      AppColor.textSecondary)),
        const SizedBox(height: 4),
        InkWell(
          onTap:        onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: AppColor.grey100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColor.grey200),
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 16,
                    color: hasDate
                        ? AppColor.primary : AppColor.grey400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasDate ? fmt.format(date!) : placeholder,
                    style: TextStyle(
                        fontSize: 12,
                        color: hasDate
                            ? AppColor.textPrimary
                            : AppColor.textHint),
                  ),
                ),
                Icon(Icons.expand_more_rounded,
                    size: 16, color: AppColor.grey400),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY CART
// ─────────────────────────────────────────────────────────────

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
              color:  AppColor.primary.withOpacity(0.06),
              shape:  BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 40, color: AppColor.primary),
          ),
          const SizedBox(height: 12),
          const Text('No items added',
              style: TextStyle(
                  fontSize:   14,
                  fontWeight: FontWeight.w600,
                  color:      AppColor.textSecondary)),
          const SizedBox(height: 4),
          const Text('Double tap a product to add it',
              style: TextStyle(
                  fontSize: 12, color: AppColor.textHint)),
        ],
      ),
    );
  }
}
