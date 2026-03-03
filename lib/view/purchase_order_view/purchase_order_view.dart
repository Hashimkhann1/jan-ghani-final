import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/model/purchase_order_model.dart';
import 'package:jan_ghani_final/utils/app_colors/app_colors.dart';
import 'package:jan_ghani_final/view/purchase_order_view/place_order_view/place_order_view.dart';
import 'package:jan_ghani_final/view_model/purchase_order_view_model/purchase_order_provider/purchase_order_provider.dart';


class PurchaseOrderView extends ConsumerStatefulWidget {
  const PurchaseOrderView({super.key});

  @override
  ConsumerState<PurchaseOrderView> createState() =>
      _PurchaseOrderViewState();
}

class _PurchaseOrderViewState extends ConsumerState<PurchaseOrderView> {
  // ── Colors ────────────────────────────────────────────────────────────────
  static const _bg = Color(0xFFF8F9FA);
  static const _white = AppColors.whiteColor;
  static const _border = Color(0xFFE9ECEF);
  static const _subText = Color(0xFF6C757D);
  static const _headerText = Color(0xFF212529);
  static const _tableHeaderText = Color(0xFF495057);
  static const _green = AppColors.primaryColors;

  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Formatters ────────────────────────────────────────────────────────────
  String _fmtCurrency(double v) {
    // Format like Rs548,999,520.00
    final formatted = v.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return 'Rs $formatted';
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildPageHeader(),
                  const SizedBox(height: 20),
                  _buildStatCards(),
                  const SizedBox(height: 20),
                  _buildTableSection(),
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
          // Logo
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                color: _green, borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.bolt, color: _white, size: 18),
          ),
          const SizedBox(width: 8),
          const Text('Jan Ghani',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(width: 20),
          // Store badge
          Row(children: const [
            Icon(Icons.calendar_today_outlined, size: 13, color: _subText),
            SizedBox(width: 5),
            Text('Sat, Feb 28',
                style: TextStyle(fontSize: 13, color: _tableHeaderText)),
          ]),
          const Spacer(),
          const Icon(Icons.dark_mode_outlined, size: 19, color: _subText),
          const SizedBox(width: 16),
          Row(children: const [
            Icon(Icons.wifi, size: 15, color: _green),
            SizedBox(width: 4),
            Text('Online',
                style: TextStyle(
                    fontSize: 12,
                    color: _green,
                    fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(width: 16),
          Stack(clipBehavior: Clip.none, children: [
            const Icon(Icons.notifications_outlined,
                size: 21, color: _subText),
            Positioned(
              top: -4, right: -4,
              child: Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(
                    color: AppColors.redColors, shape: BoxShape.circle),
                child: const Center(
                  child: Text('8',
                      style: TextStyle(
                          color: _white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.greenColor,
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
  Widget _buildPageHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Purchase Orders',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: _headerText)),
              SizedBox(height: 2),
              Text('Manage supplier orders and stock receiving',
                  style: TextStyle(fontSize: 13, color: _subText)),
            ],
          ),
        ),
        // Export
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download_outlined, size: 15),
          label: const Text('Export'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _tableHeaderText,
            side: const BorderSide(color: _border),
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 10),
        // Create PO
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PlaceOrderView()));
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Create PO'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.greenColor,
            foregroundColor: _white,
            elevation: 0,
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ── Stat Cards ────────────────────────────────────────────────────────────
  Widget _buildStatCards() {
    final stats = ref.watch(purchaseOrderStatsProvider);

    return Row(
      children: [
        // Ordered
        _StatCard(
          icon: Icons.radio_button_checked_outlined,
          iconColor: const Color(0xFF3B82F6),
          iconBg: const Color(0xFFEFF6FF),
          label: 'Ordered',
          value: '${stats.ordered}',
        ),
        const SizedBox(width: 14),
        // Received
        _StatCard(
          icon: Icons.check_circle_outline,
          iconColor: _green,
          iconBg: const Color(0xFFECFDF5),
          label: 'Received',
          value: '${stats.received}',
        ),
        const SizedBox(width: 14),
        // Total Value — wide green card
        Container(
          width: 400,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_up,
                    color: _green, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fmtCurrency(stats.totalValue),
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: _green),
                  ),
                  const SizedBox(height: 2),
                  const Text('Total Value',
                      style:
                      TextStyle(fontSize: 12, color: _subText)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Table Section ─────────────────────────────────────────────────────────
  Widget _buildTableSection() {
    final filtered = ref.watch(filteredPurchaseOrdersProvider);
    final allOrders = ref.watch(allPurchaseOrdersProvider);
    final total =
    allOrders.fold<double>(0, (s, o) => s + o.totalAmount);

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters row
          _buildFiltersRow(),
          // Count + total
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${filtered.length} orders found',
                    style: const TextStyle(
                        fontSize: 12, color: _subText)),
                Text('Total: ${_fmtCurrency(total)}',
                    style: const TextStyle(
                        fontSize: 12, color: _subText)),
              ],
            ),
          ),
          // Table header
          _buildTableHeader(),
          // Rows
          ...filtered.asMap().entries.map(
                (e) => _PORow(
              po: e.value,
              isEven: e.key.isEven,
              fmtDate: _fmtDate,
              fmtCurrency: _fmtCurrency,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Filters Row ───────────────────────────────────────────────────────────
  Widget _buildFiltersRow() {
    final filters = ref.watch(purchaseOrderFilterProvider);
    final suppliers = ref.watch(supplierNamesProvider);
    final notifier = ref.read(purchaseOrderFilterProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 13),
                onChanged: notifier.setSearch,
                decoration: InputDecoration(
                  hintText: 'Search PO number, supplier...',
                  hintStyle:
                  const TextStyle(fontSize: 13, color: _subText),
                  prefixIcon: const Icon(Icons.search,
                      size: 17, color: _subText),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      const BorderSide(color: _green)),
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: _white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Status filter
          _DropdownFilter(
            value: filters.statusFilter,
            items: const [
              'All Statuses', 'Draft', 'Ordered', 'Partial',
              'Received', 'Cancelled'
            ],
            onChanged: notifier.setStatus,
          ),
          const SizedBox(width: 10),
          // Supplier filter
          _DropdownFilter(
            value: filters.supplierFilter,
            items: suppliers,
            onChanged: notifier.setSupplier,
          ),
          const SizedBox(width: 10),
          // Date from
          _DatePickerBtn(
            label: filters.dateFrom != null
                ? _fmtDate(filters.dateFrom)
                : 'dd/mm/yyyy',
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: filters.dateFrom ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                        primary: _green),
                  ),
                  child: child!,
                ),
              );
              notifier.setDateFrom(d);
            },
            onClear: filters.dateFrom != null
                ? () => notifier.setDateFrom(null)
                : null,
          ),
          const SizedBox(width: 6),
          _DatePickerBtn(
            label: filters.dateTo != null
                ? _fmtDate(filters.dateTo)
                : 'dd/mm/yyyy',
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: filters.dateTo ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                        primary: _green),
                  ),
                  child: child!,
                ),
              );
              notifier.setDateTo(d);
            },
            onClear: filters.dateTo != null
                ? () => notifier.setDateTo(null)
                : null,
          ),
        ],
      ),
    );
  }

  // ── Table Header ──────────────────────────────────────────────────────────
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(
          top: BorderSide(color: _border),
          bottom: BorderSide(color: _border),
        ),
      ),
      child: Row(
        children: const [
          Expanded(flex: 3, child: _TH('PO Number')),
          Expanded(flex: 3, child: _TH('Supplier')),
          Expanded(flex: 2, child: _TH('Date ↑↓')),
          Expanded(flex: 2, child: _TH('Expected')),
          Expanded(flex: 2, child: _TH('Destination')),
          Expanded(flex: 2, child: _TH('Status')),
          Expanded(flex: 2, child: _TH('Total', align: TextAlign.right)),
          SizedBox(width: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PO TABLE ROW
// ─────────────────────────────────────────────────────────────────────────────

class _PORow extends StatefulWidget {
  final PurchaseOrderModel po;
  final bool isEven;
  final String Function(DateTime?) fmtDate;
  final String Function(double) fmtCurrency;

  const _PORow({
    required this.po,
    required this.isEven,
    required this.fmtDate,
    required this.fmtCurrency,
  });

  @override
  State<_PORow> createState() => _PORowState();
}

class _PORowState extends State<_PORow> {
  bool _hovered = false;

  Color get _destinationDot {
    switch (widget.po.destinationLocation) {
      case 'Warehouse':
        return const Color(0xFFF59E0B); // amber
      case 'Main Store':
        return const Color(0xFF3B82F6); // blue
      default:
        return const Color(0xFF3B82F6); // blue for eee/others
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hovered
              ? const Color(0xFFF0FDF4)
              : widget.isEven
              ? Colors.white
              : const Color(0xFFFAFAFA),
          border: const Border(
              bottom: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // PO Number — green link style
            Expanded(
              flex: 3,
              child: Text(
                widget.po.poNumber,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColors,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            // Supplier
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.po.supplier?.name ?? '—',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF212529)),
                  ),
                  if (widget.po.supplier?.contactPerson != null)
                    Text(
                      widget.po.supplier!.contactPerson!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6C757D)),
                    ),
                ],
              ),
            ),
            // Order Date
            Expanded(
              flex: 2,
              child: Text(
                widget.fmtDate(widget.po.orderDate),
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF495057)),
              ),
            ),
            // Expected Date
            Expanded(
              flex: 2,
              child: Text(
                widget.fmtDate(widget.po.expectedDate),
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF495057)),
              ),
            ),
            // Destination
            Expanded(
              flex: 2,
              child: Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                      color: _destinationDot,
                      shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.po.destinationLocationName,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF495057)),
                ),
              ]),
            ),
            // Status badge
            Expanded(
              flex: 2,
              child: _StatusBadge(status: widget.po.status),
            ),
            // Total
            Expanded(
              flex: 2,
              child: Text(
                widget.fmtCurrency(widget.po.totalAmount),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212529)),
              ),
            ),
            // More options
            const SizedBox(width: 8),
            const Icon(Icons.more_horiz,
                size: 18, color: Color(0xFFADB5BD)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final PurchaseOrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    switch (status) {
      case PurchaseOrderStatus.received:
        bg = const Color(0xFFECFDF5);
        text = AppColors.primaryColors;
        break;
      case PurchaseOrderStatus.ordered:
        bg = const Color(0xFFEFF6FF);
        text = const Color(0xFF3B82F6);
        break;
      case PurchaseOrderStatus.partial:
        bg = const Color(0xFFFFFBEB);
        text = const Color(0xFFF59E0B);
        break;
      case PurchaseOrderStatus.cancelled:
        bg = const Color(0xFFFFF1F2);
        text = AppColors.redColors;
        break;
      case PurchaseOrderStatus.draft:
        bg = const Color(0xFFF0F0F0);
        text = const Color(0xFF6C757D);
        break;
    }
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: text)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding:
      const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF212529))),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6C757D))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TABLE HEADER CELL
// ─────────────────────────────────────────────────────────────────────────────

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
            color: Color(0xFF495057)));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DROPDOWN FILTER
// ─────────────────────────────────────────────────────────────────────────────

class _DropdownFilter extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _DropdownFilter({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure value is in items list
    final safeValue = items.contains(value) ? value : items.first;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 16, color: Color(0xFF6C757D)),
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF495057)),
          items: items
              .map((i) =>
              DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATE PICKER BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _DatePickerBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DatePickerBtn({
    required this.label,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE9ECEF)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: Color(0xFF6C757D)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF495057))),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    size: 14, color: Color(0xFF9E9E9E)),
              ),
            ] else ...[
              const SizedBox(width: 4),
              const Icon(Icons.unfold_more,
                  size: 14, color: Color(0xFF9E9E9E)),
            ],
          ],
        ),
      ),
    );
  }
}