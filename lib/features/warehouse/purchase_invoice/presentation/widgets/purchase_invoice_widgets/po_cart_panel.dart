// =============================================================
// po_cart_panel.dart
// FIX: _invoiceStatus aur _poType ab provider state se sync hote hain
// =============================================================

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/data/purchase_invoice_model.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/provider/purchase_invoice_provider/purchase_invoice_provider.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/widgets/add_supplier_dialog.dart';
import 'po_cart_row_widget.dart';
import 'po_cart_table_header.dart';
import 'po_cart_summary_widget.dart';
import 'po_disable_text_field.dart';
import 'po_type_dropdown.dart';

// ─────────────────────────────────────────────────────────────
// MAIN PANEL
// ─────────────────────────────────────────────────────────────

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
                              PoCartItemRow(cartItem: state.cartItems[index]),
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

class _PoInvoiceHeaderWidgetState extends ConsumerState<PoInvoiceHeaderWidget> {
  // ── Controllers + FocusNode ───────────────────────────────
  // _paidFocus: sirf tab skip karo jab user paid field type kar raha ho
  // hasFocus broad check hataya — dedicated FocusNode use karo
  final TextEditingController _paidCtrl = TextEditingController(text: '0');
  final FocusNode _paidFocus = FocusNode();

  void showPOAddSupplierDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => const AddSupplierDialog(),
    );
  }

  @override
  void dispose() {
    _paidCtrl.dispose();
    _paidFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context,
      {required bool isDelivery}) async {
    final state = ref.read(purchaseInvoiceProvider);
    final notifier = ref.read(purchaseInvoiceProvider.notifier);

    final initial = isDelivery
        ? (state.deliveryDate ?? state.orderDate.add(const Duration(days: 7)))
        : state.orderDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
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
    final state = ref.watch(purchaseInvoiceProvider);
    final notifier = ref.read(purchaseInvoiceProvider.notifier);

    // ── FIX: provider state se lo — local variable nahi ──
    final invoiceStatus = state.invoiceStatus;
    final poType = state.poType;

    // ── FIX: dedicated _paidFocus use karo, FocusScope.broad nahi ──
    // FocusScope.of(context).hasFocus any focused widget pe block karta tha
    // Ab sirf tab skip hoga jab user khud paid field type kar raha ho
    final paidFromState = state.paidAmount.toStringAsFixed(0);
    if (_paidCtrl.text != paidFromState && !_paidFocus.hasFocus) {
      _paidCtrl.text = paidFromState;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColor.white,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
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
                  icon: Icons.receipt_outlined,
                ),
              ),
              const SizedBox(width: 8),

              // Supplier dropdown
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Supplier',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColor.textSecondary)),
                        GestureDetector(
                          onTap: () => showPOAddSupplierDialog(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.add_circle_outline_rounded,
                                  size: 13, color: Color(0xFF6366F1)),
                              SizedBox(width: 3),
                              Text('New Supplier',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6366F1))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    DropdownSearch<PoSupplier>(
                      items: (f, _) => state.suppliers,
                      filterFn: (s, f) =>
                          s.name.toLowerCase().contains(f.toLowerCase()),
                      selectedItem: state.selectedSupplier,
                      compareFn: (a, b) => a.id == b.id,
                      itemAsString: (s) => s.name,
                      onSelected: (s) {
                        if (s != null) notifier.selectSupplier(s);
                      },
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          hintText: 'Select Supplier',
                          prefixIcon: Icon(Icons.person_outline,
                              size: 16, color: AppColor.grey500),
                          filled: true,
                          fillColor: AppColor.grey100,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
                            borderSide:
                                BorderSide(color: AppColor.primary, width: 1.5),
                          ),
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          cursorHeight: 14,
                          decoration: InputDecoration(
                            hintText: 'Search supplier...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            filled: true,
                            fillColor: AppColor.grey100,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                        itemBuilder: (ctx, s, isDisabled, isSelected) =>
                            ListTile(
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColor.primary.withOpacity(0.1),
                            child: Text(s.initials,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.primary)),
                          ),
                          title: Text(s.name,
                              style: TextStyle(
                                  fontSize: 12,
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
                                fontSize: 10, color: AppColor.textSecondary),
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

              // Type dropdown — FIX: poType provider se
              Expanded(
                flex: 2,
                child: PoTypeDropdown(
                  value: poType,
                  onChanged: (type) {
                    if (type != null) notifier.setPoType(type);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Row 2: Order Date | Delivery Date | Status ────
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: 'Order Date',
                  date: state.orderDate,
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _pickDate(context, isDelivery: false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DatePickerField(
                  label: 'Delivery Date',
                  date: state.deliveryDate,
                  icon: Icons.local_shipping_outlined,
                  placeholder: 'Select delivery date',
                  onTap: () => _pickDate(context, isDelivery: true),
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 10),

              // Invoice Status — FIX: invoiceStatus provider se
              Expanded(
                child: _InvoiceStatusDropdown(
                  value: invoiceStatus,
                  onChanged: (status) {
                    if (status != null) {
                      notifier.setInvoiceStatus(status);
                      // Agar completed nahi to paid zero karo
                      if (status != InvoiceStatus.completed) {
                        _paidCtrl.text = '0';
                      }
                    }
                  },
                  isLocked:  ref.read(purchaseInvoiceProvider.notifier).isReceivedLocked,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),


          // ees nnecha Pay Amount to Supplier ko esleya comment keya hai jab hum purchase invoice may
          // supplier ko payment karate hai woo supplier kay total outstanding
          // balance say cut jata hai.

          // yee ek bug hai future may solve karke add kareng gee abhi kalee ye zaroree nahi hai.

          // ── Row 3: Paid Amount — sirf Completed pe ────────
          // FIX: invoiceStatus provider se check karo
          // if (invoiceStatus == InvoiceStatus.completed)
          //   _PaidAmountField(
          //     controller: _paidCtrl,
          //     focusNode: _paidFocus,
          //     grandTotal: state.grandTotal,
          //     onChanged: (v) {
          //       final val = double.tryParse(v) ?? 0;
          //       notifier.setPaidAmount(val);
          //     },
          //   ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// INVOICE STATUS DROPDOWN
// ─────────────────────────────────────────────────────────────

class _InvoiceStatusDropdown extends StatelessWidget {
  final InvoiceStatus value;
  final ValueChanged<InvoiceStatus?> onChanged;
  final bool isLocked;

  const _InvoiceStatusDropdown({
    required this.value,
    required this.onChanged,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Invoice Status',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColor.textSecondary),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<InvoiceStatus>(
          value: value,
          onChanged: isLocked ? null : onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(value.icon, size: 16, color: value.color),
            filled: true,
            fillColor: value.color.withOpacity(0.07),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: value.color.withOpacity(0.35)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: value.color, width: 1.5),
            ),
          ),
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: value.color),
          dropdownColor: AppColor.white,
          icon: Icon(Icons.expand_more_rounded, size: 18, color: value.color),
          items: InvoiceStatus.values
              .where((s) => isLocked ? s == InvoiceStatus.completed : true)
              .map((status) {
            return DropdownMenuItem<InvoiceStatus>(
              value: status,
              child: Row(
                children: [
                  Icon(status.icon, size: 14, color: status.color),
                  const SizedBox(width: 8),
                  Text(status.label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: status.color)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DATE PICKER FIELD
// ─────────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final IconData icon;
  final String placeholder;
  final VoidCallback onTap;
  final bool isRequired;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.icon,
    required this.onTap,
    this.placeholder = 'Select date',
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd-MM-yyyy');
    final hasDate = date != null;
    final showWarn = isRequired && !hasDate;
    final borderColor =
        showWarn ? AppColor.warning.withOpacity(0.5) : AppColor.grey200;
    final iconColor = hasDate
        ? AppColor.primary
        : (showWarn ? AppColor.warning : AppColor.grey400);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textSecondary)),
            if (isRequired && !hasDate) ...[
              const SizedBox(width: 4),
              Text('*required',
                  style: TextStyle(
                      fontSize: 9,
                      color: AppColor.warning,
                      fontWeight: FontWeight.w500)),
            ],
          ],
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: showWarn
                  ? AppColor.warning.withOpacity(0.05)
                  : AppColor.grey100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasDate ? fmt.format(date!) : placeholder,
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            hasDate ? AppColor.textPrimary : AppColor.textHint),
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
// PAID AMOUNT FIELD
// ─────────────────────────────────────────────────────────────

class _PaidAmountField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final double grandTotal;
  final ValueChanged<String> onChanged;

  const _PaidAmountField({
    required this.controller,
    required this.focusNode,
    required this.grandTotal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final paid = double.tryParse(controller.text) ?? 0;
    final remaining = (grandTotal - paid).clamp(0.0, double.infinity);
    final isFullPay = paid >= grandTotal && grandTotal > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Paid Amount to Supplier',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textSecondary)),
            const Spacer(),
            if (grandTotal > 0)
              Text(
                isFullPay ? '✓ Fully Paid' : 'Remaining: Rs ${_fmt(remaining)}',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isFullPay ? AppColor.success : AppColor.warning),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                ],
                style:
                    const TextStyle(fontSize: 13, color: AppColor.textPrimary),
                cursorHeight: 14,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.payments_outlined,
                      size: 16, color: AppColor.grey500),
                  hintText: '0',
                  filled: true,
                  fillColor: AppColor.grey100,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.grey200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            if (grandTotal > 0) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: OutlinedButton(
                  onPressed: () {
                    controller.text = grandTotal.toStringAsFixed(0);
                    onChanged(controller.text);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.success,
                    side: BorderSide(color: AppColor.success),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Pay Full',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
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
              color: AppColor.primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 40, color: AppColor.primary),
          ),
          const SizedBox(height: 12),
          const Text('No items added',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColor.textSecondary)),
          const SizedBox(height: 4),
          const Text('Double tap a product to add it',
              style: TextStyle(fontSize: 12, color: AppColor.textHint)),
        ],
      ),
    );
  }
}

// // =============================================================
// // po_cart_panel.dart
// // FIX: _invoiceStatus aur _poType ab provider state se sync hote hain
// // =============================================================
//
// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// import 'package:jan_ghani_final/core/color/app_color.dart';
// import 'package:jan_ghani_final/features/warehouse/purchase_invoice/data/purchase_invoice_model.dart';
// import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/provider/purchase_invoice_provider/purchase_invoice_provider.dart';
// import 'package:jan_ghani_final/features/warehouse/supplier/presentation/widgets/add_supplier_dialog.dart';
// import 'po_cart_row_widget.dart';
// import 'po_cart_table_header.dart';
// import 'po_cart_summary_widget.dart';
// import 'po_disable_text_field.dart';
// import 'po_type_dropdown.dart';
//
// // ─────────────────────────────────────────────────────────────
// // MAIN PANEL
// // ─────────────────────────────────────────────────────────────
//
// class PoCartPanel extends ConsumerWidget {
//   const PoCartPanel({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final state = ref.watch(purchaseInvoiceProvider);
//
//     return Container(
//       color: AppColor.background,
//       child: Column(
//         children: [
//           const PoInvoiceHeaderWidget(),
//           Expanded(
//             child: state.cartItems.isEmpty
//                 ? const _EmptyCart()
//                 : Column(
//               children: [
//                 const PoCartTableHeader(),
//                 Expanded(
//                   child: ListView.separated(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 12, vertical: 4),
//                     itemCount: state.cartItems.length,
//                     separatorBuilder: (_, __) =>
//                     const SizedBox(height: 4),
//                     itemBuilder: (context, index) => PoCartItemRow(
//                         cartItem: state.cartItems[index]),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const PoCartSummaryWidget(),
//         ],
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// // HEADER WIDGET
// // ─────────────────────────────────────────────────────────────
//
//
//
// class PoInvoiceHeaderWidget extends ConsumerStatefulWidget {
//   const PoInvoiceHeaderWidget({super.key});
//
//   @override
//   ConsumerState<PoInvoiceHeaderWidget> createState() =>
//       _PoInvoiceHeaderWidgetState();
// }
//
// class _PoInvoiceHeaderWidgetState
//     extends ConsumerState<PoInvoiceHeaderWidget> {
//   // ── FIX: ye sirf controller ke liye hai ──────────────────
//   // _invoiceStatus aur _poType ab provider se directly lete hain
//   // local copy nahi rakhte — warna edit mode mein sync nahi hoga
//   final TextEditingController _paidCtrl =
//   TextEditingController(text: '0');
//
//   void showPOAddSupplierDialog(BuildContext context) {
//     showDialog(
//       context:     context,
//       barrierColor: Colors.black.withOpacity(0.35),
//       builder:     (_) => const AddSupplierDialog(),
//     );
//   }
//
//   @override
//   void dispose() {
//     _paidCtrl.dispose();
//     super.dispose();
//   }
//
//   // ── FIX: paidAmount bhi provider se sync karo ────────────
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final paid = ref.read(purchaseInvoiceProvider).paidAmount;
//     final txt  = paid > 0 ? paid.toStringAsFixed(0) : '0';
//     if (_paidCtrl.text != txt) {
//       _paidCtrl.text = txt;
//     }
//   }
//
//   Future<void> _pickDate(BuildContext context,
//       {required bool isDelivery}) async {
//     final state    = ref.read(purchaseInvoiceProvider);
//     final notifier = ref.read(purchaseInvoiceProvider.notifier);
//
//     final initial = isDelivery
//         ? (state.deliveryDate ??
//         state.orderDate.add(const Duration(days: 7)))
//         : state.orderDate;
//
//     final picked = await showDatePicker(
//       context:     context,
//       initialDate: initial,
//       firstDate:   DateTime(2024),
//       lastDate:    DateTime(2030),
//     );
//     if (picked == null) return;
//
//     if (isDelivery) {
//       notifier.setDeliveryDate(picked);
//     } else {
//       notifier.setOrderDate(picked);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final state    = ref.watch(purchaseInvoiceProvider);
//     final notifier = ref.read(purchaseInvoiceProvider.notifier);
//
//     // ── FIX: provider state se lo — local variable nahi ──
//     final invoiceStatus = state.invoiceStatus;
//     final poType        = state.poType;
//
//     // Paid controller sync — edit mode mein loaded value dikhao
//     // Sirf tab update karo jab focus nahi hai
//     final paidFromState = state.paidAmount.toStringAsFixed(0);
//     if (_paidCtrl.text != paidFromState &&
//         !FocusScope.of(context).hasFocus) {
//       _paidCtrl.text = paidFromState;
//     }
//
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: const BoxDecoration(
//         color:  AppColor.white,
//         border: Border(bottom: BorderSide(color: AppColor.grey200)),
//       ),
//       child: Column(
//         children: [
//           // ── Row 1: PO Number | Supplier | Type ────────────
//           Row(
//             children: [
//               // PO Number — disabled
//               Expanded(
//                 flex: 2,
//                 child: PoDisabledTextField(
//                   label: 'PO Number',
//                   value: state.poNumber,
//                   icon:  Icons.receipt_outlined,
//                 ),
//               ),
//               const SizedBox(width: 8),
//
//               // Supplier dropdown
//               Expanded(
//                 flex: 3,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text('Supplier',
//                             style: TextStyle(
//                                 fontSize:   10,
//                                 fontWeight: FontWeight.w600,
//                                 color:      AppColor.textSecondary)),
//                         GestureDetector(
//                           onTap: () => showPOAddSupplierDialog(context),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: const [
//                               Icon(Icons.add_circle_outline_rounded,
//                                   size: 13, color: Color(0xFF6366F1)),
//                               SizedBox(width: 3),
//                               Text('New Supplier',
//                                   style: TextStyle(
//                                       fontSize:   11,
//                                       fontWeight: FontWeight.w600,
//                                       color:      Color(0xFF6366F1))),
//                             ],
//                           ),
//                         ),
//
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     DropdownSearch<PoSupplier>(
//                       items:        (f, _) => state.suppliers,
//                       filterFn:     (s, f) => s.name
//                           .toLowerCase()
//                           .contains(f.toLowerCase()),
//                       selectedItem: state.selectedSupplier,
//                       compareFn:   (a, b) => a.id == b.id,
//                       itemAsString: (s) => s.name,
//                       onSelected:  (s) {
//                         if (s != null) notifier.selectSupplier(s);
//                       },
//                       decoratorProps: const DropDownDecoratorProps(
//                         decoration: InputDecoration(
//                           hintText:   'Select Supplier',
//                           prefixIcon: Icon(Icons.person_outline,
//                               size: 16, color: AppColor.grey500),
//                           filled:     true,
//                           fillColor:  AppColor.grey100,
//                           contentPadding: EdgeInsets.symmetric(
//                               horizontal: 8, vertical: 10),
//                           border: OutlineInputBorder(
//                             borderRadius:
//                             BorderRadius.all(Radius.circular(8)),
//                             borderSide: BorderSide.none,
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius:
//                             BorderRadius.all(Radius.circular(8)),
//                             borderSide:
//                             BorderSide(color: AppColor.grey200),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius:
//                             BorderRadius.all(Radius.circular(8)),
//                             borderSide: BorderSide(
//                                 color: AppColor.primary, width: 1.5),
//                           ),
//                         ),
//                       ),
//                       popupProps: PopupProps.menu(
//                         showSearchBox: true,
//                         searchFieldProps: TextFieldProps(
//                           cursorHeight: 14,
//                           decoration: InputDecoration(
//                             hintText:   'Search supplier...',
//                             prefixIcon:
//                             const Icon(Icons.search, size: 18),
//                             filled:    true,
//                             fillColor: AppColor.grey100,
//                             contentPadding:
//                             const EdgeInsets.symmetric(
//                                 horizontal: 12, vertical: 8),
//                             border:        InputBorder.none,
//                             enabledBorder: InputBorder.none,
//                             focusedBorder: InputBorder.none,
//                           ),
//                           style: const TextStyle(fontSize: 14),
//                         ),
//                         itemBuilder:
//                             (ctx, s, isDisabled, isSelected) =>
//                             ListTile(
//                               leading: CircleAvatar(
//                                 radius: 14,
//                                 backgroundColor:
//                                 AppColor.primary.withOpacity(0.1),
//                                 child: Text(s.initials,
//                                     style: const TextStyle(
//                                         fontSize:   11,
//                                         fontWeight: FontWeight.w700,
//                                         color:      AppColor.primary)),
//                               ),
//                               title: Text(s.name,
//                                   style: TextStyle(
//                                       fontSize:   12,
//                                       fontWeight: isSelected
//                                           ? FontWeight.w600
//                                           : FontWeight.w400,
//                                       color: isSelected
//                                           ? AppColor.primary
//                                           : AppColor.textPrimary)),
//                               subtitle: Text(
//                                 '${s.company}  •  '
//                                     '${s.paymentTerms} days',
//                                 style: const TextStyle(
//                                     fontSize: 10,
//                                     color: AppColor.textSecondary),
//                               ),
//                               trailing: isSelected
//                                   ? const Icon(Icons.check_circle,
//                                   size:  16,
//                                   color: AppColor.primary)
//                                   : null,
//                             ),
//                         fit:         FlexFit.loose,
//                         constraints: const BoxConstraints(maxHeight: 300),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 8),
//
//               // Type dropdown — FIX: poType provider se
//               Expanded(
//                 flex: 2,
//                 child: PoTypeDropdown(
//                   value: poType,
//                   onChanged: (type) {
//                     if (type != null) notifier.setPoType(type);
//                   },
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//
//           // ── Row 2: Order Date | Delivery Date | Status ────
//           Row(
//             children: [
//               Expanded(
//                 child: _DatePickerField(
//                   label: 'Order Date',
//                   date:  state.orderDate,
//                   icon:  Icons.calendar_today_outlined,
//                   onTap: () => _pickDate(context, isDelivery: false),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: _DatePickerField(
//                   label:       'Delivery Date',
//                   date:        state.deliveryDate,
//                   icon:        Icons.local_shipping_outlined,
//                   placeholder: 'Select delivery date',
//                   onTap: () => _pickDate(context, isDelivery: true),
//                   isRequired:  true,
//                 ),
//               ),
//               const SizedBox(width: 10),
//
//               // Invoice Status — FIX: invoiceStatus provider se
//               Expanded(
//                 child: _InvoiceStatusDropdown(
//                   value: invoiceStatus,
//                   onChanged: (status) {
//                     if (status != null) {
//                       notifier.setInvoiceStatus(status);
//                       // Agar completed nahi to paid zero karo
//                       if (status != InvoiceStatus.completed) {
//                         _paidCtrl.text = '0';
//                       }
//                     }
//                   },
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//
//           // ── Row 3: Paid Amount — sirf Completed pe ────────
//           // FIX: invoiceStatus provider se check karo
//           if (invoiceStatus == InvoiceStatus.completed)
//             _PaidAmountField(
//               controller: _paidCtrl,
//               grandTotal: state.grandTotal,
//               onChanged: (v) {
//                 final val = double.tryParse(v) ?? 0;
//                 notifier.setPaidAmount(val);
//               },
//             ),
//         ],
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// // INVOICE STATUS DROPDOWN
// // ─────────────────────────────────────────────────────────────
//
// class _InvoiceStatusDropdown extends StatelessWidget {
//   final InvoiceStatus               value;
//   final ValueChanged<InvoiceStatus?> onChanged;
//
//   const _InvoiceStatusDropdown({
//     required this.value,
//     required this.onChanged,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Invoice Status',
//           style: TextStyle(
//               fontSize:   10,
//               fontWeight: FontWeight.w600,
//               color:      AppColor.textSecondary),
//         ),
//         const SizedBox(height: 4),
//         DropdownButtonFormField<InvoiceStatus>(
//           value:     value,
//           onChanged: onChanged,
//           decoration: InputDecoration(
//             prefixIcon: Icon(value.icon, size: 16, color: value.color),
//             filled:    true,
//             fillColor: value.color.withOpacity(0.07),
//             contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 8, vertical: 8),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide:   BorderSide.none,
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide:
//               BorderSide(color: value.color.withOpacity(0.35)),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide:   BorderSide(color: value.color, width: 1.5),
//             ),
//           ),
//           style: TextStyle(
//               fontSize:   12,
//               fontWeight: FontWeight.w600,
//               color:      value.color),
//           dropdownColor: AppColor.white,
//           icon: Icon(Icons.expand_more_rounded,
//               size: 18, color: value.color),
//           items: InvoiceStatus.values.map((status) {
//             return DropdownMenuItem<InvoiceStatus>(
//               value: status,
//               child: Row(
//                 children: [
//                   Icon(status.icon, size: 14, color: status.color),
//                   const SizedBox(width: 8),
//                   Text(status.label,
//                       style: TextStyle(
//                           fontSize:   12,
//                           fontWeight: FontWeight.w600,
//                           color:      status.color)),
//                 ],
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// // DATE PICKER FIELD
// // ─────────────────────────────────────────────────────────────
//
// class _DatePickerField extends StatelessWidget {
//   final String       label;
//   final DateTime?    date;
//   final IconData     icon;
//   final String       placeholder;
//   final VoidCallback onTap;
//   final bool         isRequired;
//
//   const _DatePickerField({
//     required this.label,
//     required this.date,
//     required this.icon,
//     required this.onTap,
//     this.placeholder = 'Select date',
//     this.isRequired  = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final fmt       = DateFormat('dd-MM-yyyy');
//     final hasDate   = date != null;
//     final showWarn  = isRequired && !hasDate;
//     final borderColor = showWarn
//         ? AppColor.warning.withOpacity(0.5)
//         : AppColor.grey200;
//     final iconColor = hasDate
//         ? AppColor.primary
//         : (showWarn ? AppColor.warning : AppColor.grey400);
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text(label,
//                 style: const TextStyle(
//                     fontSize:   10,
//                     fontWeight: FontWeight.w600,
//                     color:      AppColor.textSecondary)),
//             if (isRequired && !hasDate) ...[
//               const SizedBox(width: 4),
//               Text('*required',
//                   style: TextStyle(
//                       fontSize:   9,
//                       color:      AppColor.warning,
//                       fontWeight: FontWeight.w500)),
//             ],
//           ],
//         ),
//         const SizedBox(height: 4),
//         InkWell(
//           onTap:        onTap,
//           borderRadius: BorderRadius.circular(8),
//           child: Container(
//             padding: const EdgeInsets.symmetric(
//                 horizontal: 8, vertical: 10),
//             decoration: BoxDecoration(
//               color: showWarn
//                   ? AppColor.warning.withOpacity(0.05)
//                   : AppColor.grey100,
//               borderRadius: BorderRadius.circular(8),
//               border:       Border.all(color: borderColor),
//             ),
//             child: Row(
//               children: [
//                 Icon(icon, size: 16, color: iconColor),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     hasDate ? fmt.format(date!) : placeholder,
//                     style: TextStyle(
//                         fontSize: 12,
//                         color: hasDate
//                             ? AppColor.textPrimary
//                             : AppColor.textHint),
//                   ),
//                 ),
//                 Icon(Icons.expand_more_rounded,
//                     size: 16, color: AppColor.grey400),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// // PAID AMOUNT FIELD
// // ─────────────────────────────────────────────────────────────
//
// class _PaidAmountField extends StatelessWidget {
//   final TextEditingController controller;
//   final double                grandTotal;
//   final ValueChanged<String>  onChanged;
//
//   const _PaidAmountField({
//     required this.controller,
//     required this.grandTotal,
//     required this.onChanged,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final paid      = double.tryParse(controller.text) ?? 0;
//     final remaining = (grandTotal - paid).clamp(0.0, double.infinity);
//     final isFullPay = paid >= grandTotal && grandTotal > 0;
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             const Text('Paid Amount to Supplier',
//                 style: TextStyle(
//                     fontSize:   10,
//                     fontWeight: FontWeight.w600,
//                     color:      AppColor.textSecondary)),
//             const Spacer(),
//             if (grandTotal > 0)
//               Text(
//                 isFullPay
//                     ? '✓ Fully Paid'
//                     : 'Remaining: Rs ${_fmt(remaining)}',
//                 style: TextStyle(
//                     fontSize:   10,
//                     fontWeight: FontWeight.w600,
//                     color: isFullPay
//                         ? AppColor.success
//                         : AppColor.warning),
//               ),
//           ],
//         ),
//         const SizedBox(height: 4),
//         Row(
//           children: [
//             Expanded(
//               flex: 2,
//               child: TextField(
//                 controller:   controller,
//                 onChanged:    onChanged,
//                 keyboardType: const TextInputType.numberWithOptions(
//                     decimal: true),
//                 inputFormatters: [
//                   FilteringTextInputFormatter.allow(
//                       RegExp(r'^\d*\.?\d*'))
//                 ],
//                 style: const TextStyle(
//                     fontSize: 13, color: AppColor.textPrimary),
//                 cursorHeight: 14,
//                 decoration: InputDecoration(
//                   prefixIcon: const Icon(Icons.payments_outlined,
//                       size: 16, color: AppColor.grey500),
//                   hintText:  '0',
//                   filled:    true,
//                   fillColor: AppColor.grey100,
//                   contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 8, vertical: 10),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide:   BorderSide.none,
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide:   BorderSide(color: AppColor.grey200),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide:   BorderSide(
//                         color: AppColor.primary, width: 1.5),
//                   ),
//                 ),
//               ),
//             ),
//             if (grandTotal > 0) ...[
//               const SizedBox(width: 8),
//               SizedBox(
//                 width: 80,
//                 child: OutlinedButton(
//                   onPressed: () {
//                     controller.text = grandTotal.toStringAsFixed(0);
//                     onChanged(controller.text);
//                   },
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: AppColor.success,
//                     side:    BorderSide(color: AppColor.success),
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 8, vertical: 10),
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8)),
//                   ),
//                   child: const Text('Pay Full',
//                       style: TextStyle(
//                           fontSize:   11,
//                           fontWeight: FontWeight.w600)),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ],
//     );
//   }
//
//   static String _fmt(double v) => v
//       .toStringAsFixed(0)
//       .replaceAllMapped(
//       RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
//           (m) => '${m[1]},');
// }
//
// // ─────────────────────────────────────────────────────────────
// // EMPTY CART
// // ─────────────────────────────────────────────────────────────
//
// class _EmptyCart extends StatelessWidget {
//   const _EmptyCart();
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: AppColor.primary.withOpacity(0.06),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.inventory_2_outlined,
//                 size: 40, color: AppColor.primary),
//           ),
//           const SizedBox(height: 12),
//           const Text('No items added',
//               style: TextStyle(
//                   fontSize:   14,
//                   fontWeight: FontWeight.w600,
//                   color:      AppColor.textSecondary)),
//           const SizedBox(height: 4),
//           const Text('Double tap a product to add it',
//               style: TextStyle(
//                   fontSize: 12, color: AppColor.textHint)),
//         ],
//       ),
//     );
//   }
// }
