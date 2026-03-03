import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/model/purchase_order_model.dart';
import 'package:jan_ghani_final/utils/app_colors/app_colors.dart';
import 'package:jan_ghani_final/view_model/purchase_order_view_model/place_order/place_order_provider/place_order_provider.dart';

class PlaceOrderView extends ConsumerStatefulWidget {
  /// Called with the created PO when submitted successfully
  final void Function(PurchaseOrderModel po)? onOrderPlaced;

  const PlaceOrderView({super.key, this.onOrderPlaced});

  @override
  ConsumerState<PlaceOrderView> createState() => _PlaceOrderViewState();
}

class _PlaceOrderViewState extends ConsumerState<PlaceOrderView> {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const _bg = Color(0xFFF8F9FA);
  static const _white = Colors.white;
  static const _border = Color(0xFFE9ECEF);
  static const _subText = Color(0xFF6C757D);
  static const _headText = Color(0xFF212529);
  static const _green = AppColors.primaryColors;
  static const _lightGreen = Color(0xFFECFDF5);

  final _notesCtrl = TextEditingController();
  final _taxCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _notesCtrl.dispose();
    _taxCtrl.dispose();
    super.dispose();
  }

  String _fmtCurrency(double v) {
    final s = v.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return 'Rs $s';
  }

  String _fmtDate(DateTime dt) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placeOrderProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(state),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Left column (main form) ───────────────────
                      Expanded(
                        flex: 7,
                        child: Column(
                          children: [
                            _buildOrderDetailsCard(state),
                            const SizedBox(height: 16),
                            _buildItemsCard(state),
                            const SizedBox(height: 16),
                            _buildNotesCard(state),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // ── Right column (summary) ────────────────────
                      SizedBox(
                        width: 300,
                        child: Column(
                          children: [
                            _buildSummaryCard(state),
                            const SizedBox(height: 16),
                            _buildStatusCard(state),
                            const SizedBox(height: 16),
                            _buildActionButtons(state),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: _white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                color: _green, borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.bolt, color: _white, size: 18),
          ),
          const SizedBox(width: 8),
          const Text('Jan Ghani',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          const Spacer(),
          const Icon(Icons.wifi, size: 15, color: _green),
          const SizedBox(width: 4),
          const Text('Online',
              style: TextStyle(
                  fontSize: 12,
                  color: _green,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 20),
          CircleAvatar(
            radius: 15,
            backgroundColor: _green,
            child: const Text('JG',
                style: TextStyle(
                    color: _white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Page Header ───────────────────────────────────────────────────────────
  Widget _buildPageHeader(PlaceOrderState state) {
    return Row(
      children: [
        // Back button
        GestureDetector(
          onTap: () {
            ref.read(placeOrderProvider.notifier).reset();
            Navigator.maybePop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(8),
              color: _white,
            ),
            child: Row(children: const [
              Icon(Icons.arrow_back, size: 15, color: _headText),
              SizedBox(width: 6),
              Text('Back',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _headText)),
            ]),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Place Purchase Order',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _headText)),
            SizedBox(height: 2),
            Text('Create a new order for one or more products',
                style: TextStyle(fontSize: 13, color: _subText)),
          ],
        ),
      ],
    );
  }

  // ── Order Details Card ────────────────────────────────────────────────────
  Widget _buildOrderDetailsCard(PlaceOrderState state) {
    final suppliers = ref.watch(availableSuppliersProvider);
    final locations = ref.watch(availableLocationsProvider);
    final notifier = ref.read(placeOrderProvider.notifier);

    return _Card(
      title: 'Order Details',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          // Supplier + Destination
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FieldGroup(
                  label: 'Supplier *',
                  child: _SearchDropdown<PoSupplierModel>(
                    hint: 'Select supplier...',
                    value: state.selectedSupplier,
                    items: suppliers,
                    itemLabel: (s) => s.name,
                    itemSubtitle: (s) => s.contactPerson,
                    onChanged: notifier.setSupplier,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FieldGroup(
                  label: 'Destination Location *',
                  child: _SearchDropdown<LocationModel>(
                    hint: 'Select location...',
                    value: state.selectedDestination,
                    items: locations,
                    itemLabel: (l) => l.name,
                    itemSubtitle: (l) =>
                    l.type == LocationType.warehouse
                        ? 'Warehouse'
                        : 'Store · ${l.code}',
                    onChanged: notifier.setDestination,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Order Date + Expected Date
          Row(
            children: [
              Expanded(
                child: _FieldGroup(
                  label: 'Order Date',
                  child: _DateBtn(
                    date: state.orderDate,
                    onTap: () async {
                      final d = await _pickDate(state.orderDate);
                      if (d != null) notifier.setOrderDate(d);
                    },
                    fmtDate: _fmtDate,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FieldGroup(
                  label: 'Expected Delivery Date',
                  child: _DateBtn(
                    date: state.expectedDate,
                    placeholder: 'Select date (optional)',
                    onTap: () async {
                      final d = await _pickDate(
                          state.expectedDate ?? DateTime.now());
                      notifier.setExpectedDate(d);
                    },
                    onClear: state.expectedDate != null
                        ? () => notifier.setExpectedDate(null)
                        : null,
                    fmtDate: _fmtDate,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Items Card ────────────────────────────────────────────────────────────
  Widget _buildItemsCard(PlaceOrderState state) {
    final notifier = ref.read(placeOrderProvider.notifier);

    return _Card(
      title: 'Order Items',
      icon: Icons.inventory_2_outlined,
      trailing: TextButton.icon(
        onPressed: notifier.addItem,
        icon: const Icon(Icons.add, size: 15, color: _green),
        label: const Text('Add Item',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _green)),
        style: TextButton.styleFrom(
          backgroundColor: _lightGreen,
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
      ),
      child: state.items.isEmpty
          ? _buildEmptyItems(notifier)
          : Column(
        children: [
          // Table header
          _buildItemsTableHeader(),
          const SizedBox(height: 4),
          // Item rows
          ...state.items.asMap().entries.map(
                (e) => _ItemRow(
              index: e.key,
              item: e.value,
              notifier: notifier,
              fmtCurrency: _fmtCurrency,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyItems(PlaceOrderNotifier notifier) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: _border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.add_box_outlined,
              size: 36, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 10),
          const Text('No items added yet',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _subText)),
          const SizedBox(height: 4),
          const Text('Click "Add Item" to start adding products',
              style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: notifier.addItem,
            icon: const Icon(Icons.add, size: 15),
            label: const Text('Add First Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: _white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: const [
          Expanded(flex: 4, child: _TH('Product')),
          Expanded(flex: 2, child: _TH('SKU')),
          Expanded(flex: 2, child: _TH('Qty')),
          Expanded(flex: 2, child: _TH('Unit Cost')),
          Expanded(
              flex: 2, child: _TH('Total', align: TextAlign.right)),
          SizedBox(width: 44),
        ],
      ),
    );
  }

  // ── Notes Card ────────────────────────────────────────────────────────────
  Widget _buildNotesCard(PlaceOrderState state) {
    final notifier = ref.read(placeOrderProvider.notifier);
    return _Card(
      title: 'Notes',
      icon: Icons.notes_outlined,
      child: TextField(
        controller: _notesCtrl,
        minLines: 3,
        maxLines: 5,
        style: const TextStyle(fontSize: 13),
        onChanged: notifier.setNotes,
        decoration: InputDecoration(
          hintText: 'Add any notes or instructions for this order...',
          hintStyle:
          const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _green)),
          filled: true,
          fillColor: _white,
        ),
      ),
    );
  }

  // ── Summary Card ──────────────────────────────────────────────────────────
  Widget _buildSummaryCard(PlaceOrderState state) {
    final notifier = ref.read(placeOrderProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.calculate_outlined,
                size: 16, color: _subText),
            SizedBox(width: 8),
            Text('Order Summary',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _headText)),
          ]),
          const SizedBox(height: 14),
          // Items count
          _SummaryRow(
            label: 'Items',
            value: '${state.items.length}',
          ),
          _SummaryRow(
            label: 'Subtotal',
            value: _fmtCurrency(state.subtotal),
          ),
          const SizedBox(height: 10),
          // Tax input
          Row(
            children: [
              const Text('Tax %',
                  style: TextStyle(fontSize: 13, color: _subText)),
              const Spacer(),
              SizedBox(
                width: 70,
                height: 32,
                child: TextField(
                  controller: _taxCtrl,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d{0,3}(\.\d{0,2})?'))
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) {
                    final d = double.tryParse(v) ?? 0;
                    notifier.setTaxPercent(d);
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: _border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: _border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: _green)),
                    filled: true,
                    fillColor: _white,
                    suffixText: '%',
                    suffixStyle: const TextStyle(
                        fontSize: 11, color: _subText),
                  ),
                ),
              ),
            ],
          ),
          if (state.taxAmount > 0)
            _SummaryRow(
              label: 'Tax Amount',
              value: _fmtCurrency(state.taxAmount),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: _border, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _headText)),
              Text(_fmtCurrency(state.totalAmount),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _green)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Status Card ───────────────────────────────────────────────────────────
  Widget _buildStatusCard(PlaceOrderState state) {
    final notifier = ref.read(placeOrderProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.tune_outlined, size: 16, color: _subText),
            SizedBox(width: 8),
            Text('Order Status',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _headText)),
          ]),
          const SizedBox(height: 12),
          const Text(
              'What status should this order start with?',
              style: TextStyle(fontSize: 12, color: _subText)),
          const SizedBox(height: 10),
          _StatusOption(
            label: 'Draft',
            subtitle: 'Save for later, not confirmed',
            isSelected:
            state.initialStatus == PurchaseOrderStatus.draft,
            onTap: () =>
                notifier.setInitialStatus(PurchaseOrderStatus.draft),
            color: const Color(0xFF6C757D),
            bg: const Color(0xFFF0F0F0),
          ),
          const SizedBox(height: 8),
          _StatusOption(
            label: 'Ordered',
            subtitle: 'Confirmed & sent to supplier',
            isSelected:
            state.initialStatus == PurchaseOrderStatus.ordered,
            onTap: () =>
                notifier.setInitialStatus(PurchaseOrderStatus.ordered),
            color: const Color(0xFF3B82F6),
            bg: const Color(0xFFEFF6FF),
          ),
        ],
      ),
    );
  }

  // ── Action Buttons ────────────────────────────────────────────────────────
  Widget _buildActionButtons(PlaceOrderState state) {
    final notifier = ref.read(placeOrderProvider.notifier);

    return Column(
      children: [
        // Error message
        if (state.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline,
                  size: 14, color: AppColors.redColors),
              const SizedBox(width: 6),
              Expanded(
                child: Text(state.errorMessage!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.redColors)),
              ),
            ]),
          ),
        // Submit
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: state.canSubmit
                ? () {
              final po = notifier.submit();
              if (po != null) {
                widget.onOrderPlaced?.call(po);
                _showSuccessDialog(po);
              }
            }
                : null,
            icon: const Icon(Icons.check_circle_outline, size: 17),
            label: Text(
              state.initialStatus == PurchaseOrderStatus.draft
                  ? 'Save as Draft'
                  : 'Place Order',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: state.canSubmit
                  ? _green
                  : _green.withOpacity(0.4),
              disabledBackgroundColor: _green.withOpacity(0.4),
              foregroundColor: _white,
              disabledForegroundColor: _white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Reset
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              notifier.reset();
              _notesCtrl.clear();
              _taxCtrl.text = '0';
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _subText,
              side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
            child: const Text('Reset Form'),
          ),
        ),
      ],
    );
  }

  // ── Success dialog ────────────────────────────────────────────────────────
  void _showSuccessDialog(PurchaseOrderModel po) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: const BoxDecoration(
                  color: _lightGreen, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle,
                  color: _green, size: 30),
            ),
            const SizedBox(height: 14),
            const Text('Order Placed!',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(po.poNumber,
                style: const TextStyle(
                    fontSize: 14,
                    color: _green,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
                '${po.items.length} item(s) · ${_fmtCurrency(po.totalAmount)}',
                style: const TextStyle(
                    fontSize: 13, color: _subText)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: _white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme:
        const ColorScheme.light(primary: _green),
      ),
      child: child!,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ITEM ROW  (each product line in the order)
// ─────────────────────────────────────────────────────────────────────────────

class _ItemRow extends ConsumerStatefulWidget {
  final int index;
  final DraftOrderItem item;
  final PlaceOrderNotifier notifier;
  final String Function(double) fmtCurrency;

  const _ItemRow({
    required this.index,
    required this.item,
    required this.notifier,
    required this.fmtCurrency,
  });

  @override
  ConsumerState<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends ConsumerState<_ItemRow> {
  static const _green = AppColors.primaryColors;
  static const _border = Color(0xFFE9ECEF);

  late final TextEditingController _qtyCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
        text: widget.item.quantity.toStringAsFixed(
            widget.item.quantity % 1 == 0 ? 0 : 2));
    _costCtrl = TextEditingController(
        text: widget.item.unitCost.toStringAsFixed(2));
    _nameCtrl = TextEditingController(text: widget.item.productName);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(availablePoProductsProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Product name / selector ────────────────────────────
          Expanded(
            flex: 4,
            child: widget.item.product != null
                ? Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.item.productName
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _green),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.productName,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                    if (widget.item.sku != null)
                      Text(widget.item.sku!,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF888888))),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => widget.notifier
                    .updateItemName(widget.index, ''),
                child: const Icon(Icons.close,
                    size: 14, color: Color(0xFFAAAAAA)),
              ),
            ])
                : _ProductDropdown(
              hint: 'Search or type product...',
              products: products,
              currentName: widget.item.productName,
              onSelected: (p) =>
                  widget.notifier.updateItemProduct(widget.index, p),
              onNameChanged: (n) =>
                  widget.notifier.updateItemName(widget.index, n),
            ),
          ),
          const SizedBox(width: 10),
          // ── SKU (read-only) ────────────────────────────────────
          Expanded(
            flex: 2,
            child: Text(
              widget.item.sku ?? widget.item.product?.sku ?? '—',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6C757D)),
            ),
          ),
          const SizedBox(width: 10),
          // ── Quantity ───────────────────────────────────────────
          Expanded(
            flex: 2,
            child: _NumberField(
              controller: _qtyCtrl,
              onChanged: (v) {
                final d = double.tryParse(v) ?? 0;
                widget.notifier.updateItemQty(widget.index, d);
              },
            ),
          ),
          const SizedBox(width: 10),
          // ── Unit Cost ──────────────────────────────────────────
          Expanded(
            flex: 2,
            child: _NumberField(
              controller: _costCtrl,
              prefix: 'Rs',
              onChanged: (v) {
                final d = double.tryParse(v) ?? 0;
                widget.notifier.updateItemCost(widget.index, d);
              },
            ),
          ),
          const SizedBox(width: 10),
          // ── Total ──────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Text(
              widget.fmtCurrency(widget.item.total),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _green),
            ),
          ),
          const SizedBox(width: 8),
          // ── Actions ────────────────────────────────────────────
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                size: 16, color: Color(0xFFAAAAAA)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            onSelected: (v) {
              if (v == 'dup')
                widget.notifier.duplicateItem(widget.index);
              if (v == 'del')
                widget.notifier.removeItem(widget.index);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'dup',
                  child: Row(children: [
                    Icon(Icons.copy_outlined, size: 14),
                    SizedBox(width: 8),
                    Text('Duplicate',
                        style: TextStyle(fontSize: 13)),
                  ])),
              const PopupMenuItem(
                  value: 'del',
                  child: Row(children: [
                    Icon(Icons.delete_outline,
                        size: 14, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Remove',
                        style: TextStyle(
                            fontSize: 13, color: Colors.red)),
                  ])),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _Card({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: const Color(0xFF6C757D)),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF212529))),
            const Spacer(),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldGroup({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212529))),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _TH(this.text, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        textAlign: align,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6C757D)));
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF6C757D))),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212529))),
        ],
      ),
    );
  }
}

class _DateBtn extends StatelessWidget {
  final DateTime? date;
  final String placeholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String Function(DateTime) fmtDate;

  static const _border = Color(0xFFE9ECEF);

  const _DateBtn({
    this.date,
    this.placeholder = 'Select date',
    required this.onTap,
    this.onClear,
    required this.fmtDate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined,
              size: 15, color: Color(0xFF6C757D)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              date != null ? fmtDate(date!) : placeholder,
              style: TextStyle(
                  fontSize: 13,
                  color: date != null
                      ? const Color(0xFF212529)
                      : const Color(0xFFBBBBBB)),
            ),
          ),
          if (onClear != null)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close,
                  size: 14, color: Color(0xFFAAAAAA)),
            ),
        ]),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String? prefix;
  final ValueChanged<String> onChanged;

  static const _border = Color(0xFFE9ECEF);
  static const _green = AppColors.primaryColors;

  const _NumberField({
    required this.controller,
    this.prefix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType:
      const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            RegExp(r'^\d*\.?\d{0,2}')),
      ],
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13),
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixText: prefix != null ? '$prefix ' : null,
        prefixStyle: const TextStyle(
            fontSize: 11, color: Color(0xFF888888)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _green, width: 1.5)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;
  final Color bg;

  const _StatusOption({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? bg : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE9ECEF),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: isSelected ? color : const Color(0xFFCCCCCC),
                  width: 2),
              color: isSelected ? color : Colors.white,
            ),
            child: isSelected
                ? const Icon(Icons.check,
                size: 10, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color:
                      isSelected ? color : const Color(0xFF444444))),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF888888))),
            ],
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH DROPDOWN  (generic)
// ─────────────────────────────────────────────────────────────────────────────

class _SearchDropdown<T> extends StatefulWidget {
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final String? Function(T)? itemSubtitle;
  final ValueChanged<T?> onChanged;

  const _SearchDropdown({
    required this.hint,
    this.value,
    required this.items,
    required this.itemLabel,
    this.itemSubtitle,
    required this.onChanged,
  });

  @override
  State<_SearchDropdown<T>> createState() => _SearchDropdownState<T>();
}

class _SearchDropdownState<T> extends State<_SearchDropdown<T>> {
  static const _green = AppColors.primaryColors;
  static const _border = Color(0xFFE9ECEF);

  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  List<T> _filtered = [];
  bool _isOpen = false;

  bool _selecting = false;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    if (widget.value != null) {
      _ctrl.text = widget.itemLabel(widget.value as T);
    }
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && !_selecting) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !_selecting) _close();
        });
      }
    });
  }

  @override
  void didUpdateWidget(_SearchDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == null && oldWidget.value != null) {
      _ctrl.clear();
    } else if (widget.value != null &&
        _ctrl.text != widget.itemLabel(widget.value as T)) {
      _ctrl.text = widget.itemLabel(widget.value as T);
    }
  }

  @override
  void dispose() {
    _close();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _open() {
    if (_isOpen) return;
    _isOpen = true;
    _filtered = List.from(widget.items);
    _overlay = _buildOverlay();
    Overlay.of(context).insert(_overlay!);
  }

  void _close() {
    if (!mounted) return;
    _overlay?.remove();
    _overlay = null;
    _isOpen = false;
  }

  void _select(T item) {
    _selecting = true;
    _close();
    _ctrl.text = widget.itemLabel(item);
    _ctrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _ctrl.text.length),
    );
    widget.onChanged(item);
    _focusNode.unfocus();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _selecting = false;
    });
  }

  void _filter(String q) {
    _filtered = widget.items
        .where((i) =>
        widget.itemLabel(i).toLowerCase().contains(q.toLowerCase()))
        .toList();
    _overlay?.markNeedsBuild();
  }

  OverlayEntry _buildOverlay() {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final size = box.size;

    return OverlayEntry(
      builder: (ctx) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints:
              const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: _filtered.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(14),
                child: Text('No results',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888))),
              )
                  : ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final item = _filtered[i];
                  final sub = widget.itemSubtitle?.call(item);
                  return InkWell(
                    onTap: () => _select(item),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(widget.itemLabel(item),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                  FontWeight.w500)),
                          if (sub != null && sub.isNotEmpty)
                            Text(sub,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color:
                                    Color(0xFF888888))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _ctrl,
        focusNode: _focusNode,
        style: const TextStyle(fontSize: 13),
        onTap: () {
          _ctrl.clear();
          _filter('');
          _open();
        },
        onChanged: (v) {
          _filter(v);
          if (!_isOpen) _open();
        },
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(
              fontSize: 13, color: Color(0xFFBBBBBB)),
          suffixIcon: widget.value != null
              ? GestureDetector(
            onTap: () {
              widget.onChanged(null);
              _ctrl.clear();
            },
            child: const Icon(Icons.close,
                size: 16, color: Color(0xFFAAAAAA)),
          )
              : const Icon(Icons.keyboard_arrow_down,
              size: 18, color: Color(0xFF6C757D)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              const BorderSide(color: _green, width: 1.5)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT DROPDOWN  (for item rows)
// ─────────────────────────────────────────────────────────────────────────────

class _ProductDropdown extends StatefulWidget {
  final String hint;
  final List<PoProductSnapshot> products;
  final String currentName;
  final ValueChanged<PoProductSnapshot> onSelected;
  final ValueChanged<String> onNameChanged;

  const _ProductDropdown({
    required this.hint,
    required this.products,
    required this.currentName,
    required this.onSelected,
    required this.onNameChanged,
  });

  @override
  State<_ProductDropdown> createState() => _ProductDropdownState();
}

class _ProductDropdownState extends State<_ProductDropdown> {
  static const _green = AppColors.primaryColors;
  static const _border = Color(0xFFE9ECEF);

  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _overlayOpen = false;
  List<PoProductSnapshot> _filtered = [];

  bool _selecting = false;

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.currentName;
    _filtered = widget.products;
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && !_selecting) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !_selecting) _close();
        });
      }
    });
  }

  @override
  void dispose() {
    _close();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _openOverlay() {
    if (_overlayOpen) return;
    _overlayOpen = true;
    _filtered = List.from(widget.products);
    _overlay = _buildOverlay();
    Overlay.of(context).insert(_overlay!);
  }

  void _close() {
    if (!mounted) return;
    _overlay?.remove();
    _overlay = null;
    _overlayOpen = false;
  }

  void _select(PoProductSnapshot p) {
    _selecting = true;
    _close();
    _ctrl.text = p.name;
    _ctrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _ctrl.text.length),
    );
    widget.onSelected(p);
    _focusNode.unfocus();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _selecting = false;
    });
  }

  void _filter(String q) {
    _filtered = widget.products
        .where((p) =>
    p.name.toLowerCase().contains(q.toLowerCase()) ||
        p.sku.toLowerCase().contains(q.toLowerCase()))
        .toList();
    _overlay?.markNeedsBuild();
  }

  OverlayEntry _buildOverlay() {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final size = box.size;

    return OverlayEntry(
      builder: (_) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: _filtered.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No products found',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888))),
              )
                  : ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final p = _filtered[i];
                  return InkWell(
                    onTap: () => _select(p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                      FontWeight.w500)),
                              Text(p.sku,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF888888))),
                            ],
                          ),
                        ),
                        Text(
                          'Rs ${p.costPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: _green,
                              fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _ctrl,
        focusNode: _focusNode,
        style: const TextStyle(fontSize: 13),
        onTap: () {
          _filter(_ctrl.text);
          _openOverlay();
        },
        onChanged: (v) {
          widget.onNameChanged(v);
          _filter(v);
          if (!_overlayOpen) _openOverlay();
        },
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(
              fontSize: 12, color: Color(0xFFBBBBBB)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              const BorderSide(color: _green, width: 1.5)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}