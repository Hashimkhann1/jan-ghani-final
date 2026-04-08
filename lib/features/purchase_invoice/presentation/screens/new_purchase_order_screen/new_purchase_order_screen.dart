// =============================================================
// new_purchase_order_screen.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/purchase_invoice/domain/new_po_form_item/new_po_form_item.dart';
import 'package:jan_ghani_final/features/purchase_invoice/domain/purchase_order_model.dart';
import 'package:jan_ghani_final/features/purchase_invoice/presentation/provider/new_po_provider/new_po_provider.dart';
import 'package:jan_ghani_final/features/purchase_invoice/presentation/provider/purchase_order_provider.dart';
import 'package:jan_ghani_final/features/purchase_invoice/presentation/widgets/new_po_widgets/new_po_widgets.dart';
import 'package:uuid/uuid.dart';

class NewPurchaseOrderScreen extends ConsumerWidget {
  const NewPurchaseOrderScreen({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const NewPurchaseOrderScreen(),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(newPoProvider);

    return Scaffold(
      backgroundColor: AppColor.background,
      body: Column(
        children: [
          _TopBar(state: state, ref: ref),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _BasicInfoSection(state: state, ref: ref),
                  const SizedBox(height: 16),
                  _ProductsSection(state: state, ref: ref),
                  const SizedBox(height: 16),
                  _FinancialsSection(state: state, ref: ref),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final NewPoState state;
  final WidgetRef  ref;
  const _TopBar({required this.state, required this.ref});

  void _save(BuildContext context, String status) async {
    final s = state;

    if (s.supplierId == null) {
      _snack(context, 'Pehle supplier select karein');
      return;
    }
    if (s.items.isEmpty || !s.items.every((i) => i.isValid)) {
      _snack(context, 'Sab products ka naam aur quantity bharo');
      return;
    }

    final id    = const Uuid().v4();
    final items = s.items.map((i) => PurchaseOrderItem(
      id:               const Uuid().v4(),
      poId:             id,
      tenantId:         'tenant-jan-ghani',
      productId:        i.productId,
      productName:      i.productName,
      sku:              i.sku,
      quantityOrdered:  i.qty,
      quantityReceived: 0,
      unitCost:         i.unitCost,
      totalCost:        i.totalCost,
      salePrice:        i.salePrice > 0 ? i.salePrice : null,
    )).toList();

    final po = PurchaseOrderModel(
      id:                    id,
      tenantId:              'tenant-jan-ghani',
      poNumber:              'PO-${DateTime.now().year}-${id.substring(0, 6).toUpperCase()}',
      supplierId:            s.supplierId,
      supplierName:          s.supplierName,
      supplierCompany:       s.supplierCompany,
      supplierPaymentTerms:  s.supplierPaymentTerms,
      destinationLocationId: s.destinationId,
      destinationName:       s.destinationName.split(' — ').first,
      status:                status,
      orderDate:             s.orderDate,
      expectedDate:          s.expectedDate,
      receivedDate:          null,
      subtotal:              s.subtotal,
      discountAmount:        s.discount,
      taxAmount:             s.tax,
      totalAmount:           s.totalAmount,
      paidAmount:            0,
      notes:    s.notes.trim().isEmpty ? null : s.notes.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items:    items,
    );

    await ref.read(purchaseOrderProvider.notifier).addOrder(po);
    if (context.mounted) Navigator.of(context).pop();
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
      decoration: BoxDecoration(
        color:  AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap:        () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                border:       Border.all(color: AppColor.grey200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded,
                      size: 12, color: AppColor.textSecondary),
                  const SizedBox(width: 5),
                  Text('Purchase Orders',
                      style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 20, color: AppColor.grey200),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Purchase Order',
                  style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary)),
              Text('Supplier se naya maal order karo',
                  style: TextStyle(fontSize: 11, color: AppColor.textSecondary)),
            ],
          ),
          const Spacer(),
          InkWell(
            onTap:        () => _save(context, 'draft'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                border:       Border.all(color: AppColor.grey300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Save as Draft',
                  style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColor.textSecondary)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _save(context, 'ordered'),
            icon:      const Icon(Icons.check_rounded, size: 15),
            label:     const Text('Submit Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: AppColor.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              minimumSize:   Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SECTION 1 — BASIC INFO
// ─────────────────────────────────────────────────────────────

class _BasicInfoSection extends StatefulWidget {
  final NewPoState state;
  final WidgetRef  ref;
  const _BasicInfoSection({required this.state, required this.ref});

  @override
  State<_BasicInfoSection> createState() => _BasicInfoSectionState();
}

class _BasicInfoSectionState extends State<_BasicInfoSection> {
  // Controller zaroorat hai taake TextField initialValue issue na aaye
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.state.notes);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state    = widget.state;
    final notifier = widget.ref.read(newPoProvider.notifier);

    return NewPoSectionCard(
      stepNum:   '1',
      stepColor: AppColor.primary,
      icon:      Icons.person_outline_rounded,
      title:     'Basic Information',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Supplier
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const NewPoFieldLabel(label: 'Supplier', required: true),
                    const SizedBox(height: 6),
                    state.supplierId != null
                        ? NewPoSupplierChip(
                      name:    state.supplierName ?? '',
                      company: state.supplierCompany ?? '',
                      terms:   state.supplierPaymentTerms,
                      onTap:   () => _showSupplierDialog(context),
                    )
                        : InkWell(
                      onTap:        () => _showSupplierDialog(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          border:       Border.all(color: AppColor.grey300),
                          borderRadius: BorderRadius.circular(8),
                          color:        AppColor.grey100,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person_add_outlined,
                                size: 16, color: AppColor.grey400),
                            const SizedBox(width: 8),
                            Text('Supplier select karein',
                                style: TextStyle(fontSize: 13,
                                    color: AppColor.textHint)),
                            const Spacer(),
                            Icon(Icons.chevron_right_rounded,
                                size: 16, color: AppColor.grey400),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Suppliers list se select karo',
                        style: TextStyle(fontSize: 11,
                            color: AppColor.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Destination
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const NewPoFieldLabel(label: 'Destination', required: true),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        border:       Border.all(color: AppColor.grey300),
                        borderRadius: BorderRadius.circular(8),
                        color:        AppColor.grey100,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warehouse_outlined,
                              size: 15, color: AppColor.grey500),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(state.destinationName,
                                style: TextStyle(fontSize: 13,
                                    color: AppColor.textPrimary)),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              size: 16, color: AppColor.grey400),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('locations table se',
                        style: TextStyle(fontSize: 11,
                            color: AppColor.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const NewPoFieldLabel(label: 'Order Date', required: true),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context:     context,
                          initialDate: state.orderDate,
                          firstDate:   DateTime(2024),
                          lastDate:    DateTime(2030),
                        );
                        if (picked != null) notifier.setOrderDate(picked);
                      },
                      child: NewPoDateField(date: state.orderDate),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Expected date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const NewPoFieldLabel(label: 'Expected Date'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context:     context,
                          initialDate: state.expectedDate ??
                              DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime(2024),
                          lastDate:  DateTime(2030),
                        );
                        if (picked != null) notifier.setExpectedDate(picked);
                      },
                      child: NewPoDateField(date: state.expectedDate),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Notes — controller use karo, initialValue nahi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const NewPoFieldLabel(label: 'Notes'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesCtrl,
                      onChanged:  notifier.setNotes,
                      style: TextStyle(fontSize: 13, color: AppColor.textPrimary),
                      decoration: InputDecoration(
                        hintText:  'Koi note...',
                        hintStyle: TextStyle(fontSize: 13, color: AppColor.textHint),
                        filled:    true,
                        fillColor: AppColor.grey100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 11),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColor.grey300)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColor.grey300)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: AppColor.primary, width: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSupplierDialog(BuildContext context) {
    final suppliers = [
      {'id': 'sup-001', 'name': 'Ahmed Raza',
        'company': 'Raza Traders',     'terms': 30},
      {'id': 'sup-002', 'name': 'Bilal Khan',
        'company': 'Khan Brothers',    'terms': 15},
      {'id': 'sup-003', 'name': 'Tariq Mehmood',
        'company': 'TM Distributors',  'terms': 45},
      {'id': 'sup-004', 'name': 'Kamran Iqbal',
        'company': 'Iqbal & Sons',     'terms': 30},
      {'id': 'sup-005', 'name': 'Usman Farooq',
        'company': 'Farooq Wholesale', 'terms': 60},
    ];

    showDialog(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColor.surface,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: AppColor.grey200))),
                child: Row(
                  children: [
                    Text('Select Supplier',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary)),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color:        AppColor.grey100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 15, color: AppColor.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              ...suppliers.map((s) => InkWell(
                onTap: () {
                  widget.ref.read(newPoProvider.notifier).selectSupplier(
                    id:           s['id']      as String,
                    name:         s['name']    as String,
                    company:      s['company'] as String,
                    paymentTerms: s['terms']   as int,
                  );
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: AppColor.grey100))),
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color:        AppColor.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          (s['name'] as String)
                              .split(' ')
                              .take(2)
                              .map((w) => w[0])
                              .join()
                              .toUpperCase(),
                          style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColor.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['name'] as String,
                                style: TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.textPrimary)),
                            Text('${s['company']}  •  ${s['terms']} days',
                                style: TextStyle(fontSize: 11,
                                    color: AppColor.textSecondary)),
                          ],
                        ),
                      ),
                      if (widget.state.supplierId == s['id'])
                        Icon(Icons.check_circle_rounded,
                            color: AppColor.success, size: 18),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SECTION 2 — PRODUCTS
// ─────────────────────────────────────────────────────────────

class _ProductsSection extends StatelessWidget {
  final NewPoState state;
  final WidgetRef  ref;
  const _ProductsSection({required this.state, required this.ref});

  String _fmt(double v) {
    if (v >= 100000) return 'Rs ${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(newPoProvider.notifier);

    return NewPoSectionCard(
      stepNum:   '2',
      stepColor: AppColor.info,
      icon:      Icons.inventory_2_outlined,
      title:     'Products',
      trailing: Text(
        '${state.items.length} items  •  ${_fmt(state.subtotal)}',
        style: TextStyle(fontSize: 11, color: AppColor.textSecondary),
      ),
      child: Column(
        children: [
          // Sale price hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:        AppColor.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 13, color: AppColor.primary),
                const SizedBox(width: 6),
                Text(
                  'Sale Price optional hai — enter karo to margin calculate hoga',
                  style: TextStyle(fontSize: 11, color: AppColor.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Table header — const hataya, NewPoTableHeaderCell non-const hai
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:        AppColor.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SizedBox(width: 22),
                NewPoTableHeaderCell(label: 'Product',    flex: 3),
                NewPoTableHeaderCell(label: 'Qty',        right: true),
                NewPoTableHeaderCell(label: 'Unit Cost',  right: true),
                NewPoTableHeaderCell(label: 'Sale Price', right: true, purple: true),
                NewPoTableHeaderCell(label: 'Total',      right: true),
                NewPoTableHeaderCell(label: 'Margin',     center: true),
                const SizedBox(width: 30),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Product rows
          ...state.items.map((item) => _ProductRow(
            key:           ValueKey(item.id),
            item:          item,
            onRemove:      () => notifier.removeItem(item.id),
            onChanged:     notifier.onItemChanged,
            onNameChanged: (name) => notifier.updateItemName(item.id, name),
          )),

          const SizedBox(height: 4),

          // Add product button
          InkWell(
            onTap:        notifier.addItem,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                border:       Border.all(color: AppColor.grey300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      size: 16, color: AppColor.textSecondary),
                  const SizedBox(width: 6),
                  Text('Add Product',
                      style: TextStyle(fontSize: 13,
                          color: AppColor.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PRODUCT ROW
// ─────────────────────────────────────────────────────────────

class _ProductRow extends StatelessWidget {
  final NewPoFormItem        item;
  final VoidCallback         onRemove;
  final VoidCallback         onChanged;
  final ValueChanged<String> onNameChanged;

  const _ProductRow({
    required super.key,
    required this.item,
    required this.onRemove,
    required this.onChanged,
    required this.onNameChanged,
  });

  String _fmt(double v) {
    if (v >= 1000) return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final margin = item.marginPercent;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border:       Border.all(color: AppColor.grey200),
        borderRadius: BorderRadius.circular(8),
        color:        AppColor.surface,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text('•',
                style: TextStyle(fontSize: 14, color: AppColor.grey400),
                textAlign: TextAlign.center),
          ),
          const SizedBox(width: 4),

          // Product name
          Expanded(
            flex: 3,
            child: TextField(
              onChanged: onNameChanged,
              style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColor.textPrimary),
              decoration: InputDecoration(
                hintText:  'Product name...',
                hintStyle: TextStyle(fontSize: 12, color: AppColor.textHint),
                filled:    true,
                fillColor: AppColor.grey100,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: AppColor.grey200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: AppColor.grey200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                        color: AppColor.primary, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 6),

          Expanded(child: NewPoNumField(
              controller: item.qtyCtrl, hint: '0', onChanged: onChanged)),
          const SizedBox(width: 6),

          Expanded(child: NewPoNumField(
              controller: item.unitCostCtrl, hint: '0', onChanged: onChanged)),
          const SizedBox(width: 6),

          Expanded(child: NewPoNumField(
              controller: item.salePriceCtrl,
              hint:       'Optional',
              onChanged:  onChanged,
              isPurple:   true)),
          const SizedBox(width: 6),

          // Total — auto
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color:        AppColor.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(_fmt(item.totalCost),
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColor.textPrimary)),
            ),
          ),
          const SizedBox(width: 6),

          // Margin
          Expanded(
            child: Center(
              child: margin != null
                  ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color:        AppColor.successLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${margin.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColor.success)),
              )
                  : Text('—',
                  style: TextStyle(fontSize: 12,
                      color: AppColor.textSecondary),
                  textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(width: 6),

          // Delete
          InkWell(
            onTap:        onRemove,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color:        AppColor.errorLight,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.delete_outline_rounded,
                  size: 13, color: AppColor.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SECTION 3 — FINANCIALS
// ─────────────────────────────────────────────────────────────

class _FinancialsSection extends StatefulWidget {
  final NewPoState state;
  final WidgetRef  ref;
  const _FinancialsSection({required this.state, required this.ref});

  @override
  State<_FinancialsSection> createState() => _FinancialsSectionState();
}

class _FinancialsSectionState extends State<_FinancialsSection> {
  final _discountCtrl = TextEditingController();
  final _taxCtrl      = TextEditingController();

  @override
  void dispose() {
    _discountCtrl.dispose();
    _taxCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    if (v >= 100000) return 'Rs ${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final state    = widget.state;
    final notifier = widget.ref.read(newPoProvider.notifier);

    return NewPoSectionCard(
      stepNum:   '3',
      stepColor: AppColor.success,
      icon:      Icons.receipt_long_outlined,
      title:     'Financials & Profit Summary',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left — inputs + totals
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const NewPoFieldLabel(label: 'Discount (Rs)'),
                          const SizedBox(height: 6),
                          NewPoNumField(
                            controller: _discountCtrl,
                            hint:       '0',
                            onChanged:  () => notifier.setDiscount(_discountCtrl.text),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const NewPoFieldLabel(label: 'Tax (Rs)'),
                          const SizedBox(height: 6),
                          NewPoNumField(
                            controller: _taxCtrl,
                            hint:       '0',
                            onChanged:  () => notifier.setTax(_taxCtrl.text),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Container(
                  decoration: BoxDecoration(
                    border:       Border.all(color: AppColor.grey200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      NewPoTotalRow(
                          label: 'Subtotal',
                          value: _fmt(state.subtotal)),
                      NewPoTotalRow(
                          label:      'Discount',
                          value:      '- ${_fmt(state.discount)}',
                          valueColor: AppColor.success),
                      NewPoTotalRow(
                          label: 'Tax',
                          value: _fmt(state.tax)),
                      NewPoTotalRow(
                          label:      'Total Amount',
                          value:      _fmt(state.totalAmount),
                          isBold:     true,
                          valueColor: AppColor.primary,
                          isLast:     true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Right — profit cards
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PROFIT SUMMARY',
                    style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textSecondary,
                        letterSpacing: 0.4)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: NewPoProfitCard(
                        value: _fmt(state.totalProfit),
                        label: 'Total profit',
                        bg:    AppColor.successLight,
                        fg:    AppColor.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: NewPoProfitCard(
                        value: state.avgMargin != null
                            ? '${state.avgMargin!.toStringAsFixed(0)}%'
                            : '—',
                        label: 'Avg margin',
                        bg:    AppColor.infoLight,
                        fg:    AppColor.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: NewPoProfitCard(
                        value: '${state.itemsWithSalePrice} / ${state.items.length}',
                        label: 'Items with sale price',
                        bg:    AppColor.grey100,
                        fg:    AppColor.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: NewPoProfitCard(
                        value: _fmt(state.expectedRevenue),
                        label: 'Expected revenue',
                        bg:    AppColor.warningLight,
                        fg:    AppColor.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}