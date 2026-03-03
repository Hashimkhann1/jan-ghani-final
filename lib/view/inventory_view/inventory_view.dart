

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/model/product_model/product_model.dart';
import 'package:jan_ghani_final/res/dummy/dummy_data.dart';
import 'package:jan_ghani_final/utils/app_colors/app_colors.dart';
import 'package:jan_ghani_final/utils/constant/enum_constant/enum_constant.dart';
import 'package:jan_ghani_final/utils/dialogs/add_products_dialog/add_products_dialog.dart';
import 'package:jan_ghani_final/view/inventory_view/inventroy_alert_view/inventroy_alert_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// INVENTORY VIEW
// ─────────────────────────────────────────────────────────────────────────────

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  int _selectedTab = 0;
  String _searchQuery = '';
  String _statusFilter = 'All Status';
  String _categoryFilter = 'All Categories';
  String _sortFilter = 'Name (A-Z)';
  final Set<int> _selectedRows = {};

  static const _bg = Color(0xFFF8F9FA);
  static const _cardBg = AppColors.whiteColor;
  static const _border = Color(0xFFE9ECEF);
  static const _headerText = Color(0xFF212529);
  static const _subText = Color(0xFF6C757D);
  static const _tableHeader = Color(0xFF495057);

  final List<ProductModel> products = DummyData.inventoryProducts;

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
                  _buildTabsAndTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      height: 52,

      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.whiteColor,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: Row(
        children: [
          // Store selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFF0FDF4),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColors,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Main Store',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: _subText),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Date
          Row(
            children: const [
              Icon(Icons.calendar_today_outlined, size: 14, color: _subText),
              SizedBox(width: 6),
              Text('Wed, Feb 25',
                  style: TextStyle(fontSize: 13, color: _tableHeader)),
            ],
          ),
          const SizedBox(width: 16),
          // Time

          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.greenColor
            ),onPressed: () => showAddProductDialog(context), child: Row(
            children: const [
              Icon(Icons.add_circle_outline_rounded, size: 14, color: AppColors.whiteColor),
              SizedBox(width: 6),
              Text('Add Product',
                  style: TextStyle(fontSize: 13, color: AppColors.whiteColor)),
            ],
          )),

          const Spacer(),
          // Right icons
          const Icon(Icons.dark_mode_outlined, size: 20, color: _subText),
          const SizedBox(width: 16),
          Row(
            children: const [
              Icon(Icons.wifi, size: 16, color: AppColors.primaryColors),
              SizedBox(width: 4),
              Text('Online',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryColors,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(width: 16),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, size: 22, color: _subText),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.redColors,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('9+',
                        style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: 8,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryColors,
            child: const Text('YD',
                style: TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Page Header ──────────────────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Inventory',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _headerText)),
              SizedBox(height: 2),
              Text('Manage stock for Main Store',
                  style: TextStyle(fontSize: 13, color: _subText)),
            ],
          ),
        ),
        // Transfer button
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.swap_horiz, size: 16),
          label: const Text('Transfer'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _tableHeader,
            side: const BorderSide(color: _border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 10),
        // Export button
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.upload_outlined, size: 16),
          label: const Text('Export'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _tableHeader,
            side: const BorderSide(color: _border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  // ── Stat Cards ───────────────────────────────────────────────────────────
  Widget _buildStatCards() {
    final row1 = [
      _StatCardData(
        icon: Icons.inventory_2_outlined,
        iconBg: const Color(0xFFECFDF5),
        iconColor: AppColors.primaryColors,
        title: 'Total Products',
        value: '8',
        subtitle: '49,991 total units',
      ),
      _StatCardData(
        icon: Icons.check_circle_outline,
        iconBg: const Color(0xFFECFDF5),
        iconColor: AppColors.primaryColors,
        title: 'In Stock',
        value: '7',
        subtitle: '88% healthy',
      ),
      _StatCardData(
        icon: Icons.warning_amber_outlined,
        iconBg: const Color(0xFFFFFBEB),
        iconColor: const Color(0xFFF59E0B),
        title: 'Low Stock',
        value: '0',
        subtitle: 'Needs reorder',
      ),
      _StatCardData(
        icon: Icons.trending_down,
        iconBg: const Color(0xFFFFF1F2),
        iconColor: AppColors.redColors,
        title: 'Out of Stock',
        value: '1',
        subtitle: 'Urgent attention',
      ),
    ];

    final row2 = [
      _StatCardData(
        icon: Icons.attach_money,
        iconBg: const Color(0xFFECFDF5),
        iconColor: AppColors.primaryColors,
        title: 'Inventory Value',
        value: 'Rs31,083,205.00',
        subtitle: 'Retail: Rs69,790,090.00',
        valueFontSize: 18,
      ),
      _StatCardData(
        icon: Icons.trending_up,
        iconBg: const Color(0xFFECFDF5),
        iconColor: AppColors.primaryColors,
        title: 'Potential Profit',
        value: 'Rs38,706,885.00',
        subtitle: '125% margin',
        valueFontSize: 18,
      ),
      _StatCardData(
        icon: Icons.error_outline,
        iconBg: const Color(0xFFFFF1F2),
        iconColor: AppColors.redColors,
        title: 'Critical Alerts',
        value: '1',
        subtitle: '0 warnings',
      ),
      _StatCardData(
        icon: Icons.bar_chart,
        iconBg: const Color(0xFFFFFBEB),
        iconColor: const Color(0xFFF59E0B),
        title: 'Stock Health',
        value: '88%',
        subtitle: 'Availability rate',
      ),
    ];

    return Column(
      children: [
        _buildCardRow(row1),
        const SizedBox(height: 12),
        _buildCardRow(row2),
      ],
    );
  }

  Widget _buildCardRow(List<_StatCardData> cards) {
    return Row(
      children: cards
          .map((c) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(
              right: cards.last == c ? 0 : 12),
          child: _StatCard(data: c),
        ),
      ))
          .toList(),
    );
  }

  // ── Tabs + Table ─────────────────────────────────────────────────────────
  Widget _buildTabsAndTable() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs
          Container(
            width: 420,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            margin: const EdgeInsets.only(left: 6, top: 10),
            decoration: BoxDecoration(
              color: AppColors.greyColor.withOpacity(0.14),
              border: Border(bottom: BorderSide(color: _border)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                _TabButton(
                  icon: Icons.list_outlined,
                  label: 'Store Inventory',
                  isSelected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
                const SizedBox(width: 4),
                _TabButton(
                  icon: Icons.warning_amber_outlined,
                  label: 'Alerts',
                  isSelected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                  badge: 1,
                ),
                const SizedBox(width: 4),
                _TabButton(
                  icon: Icons.bar_chart_outlined,
                  label: 'Analytics',
                  isSelected: _selectedTab == 2,
                  onTap: () => setState(() => _selectedTab = 2),
                ),
              ],
            ),
          ),

          // ── Tab Content ──────────────────────────────────────────────
          if (_selectedTab == 0) ...[
            // Search + Filters
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by name, SKU, or barcode...',
                          hintStyle: const TextStyle(fontSize: 13, color: _subText),
                          prefixIcon: const Icon(Icons.search, size: 18, color: _subText),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primaryColors),
                          ),
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: AppColors.whiteColor,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _FilterDropdown(
                    value: _statusFilter,
                    items: const ['All Status', 'In Stock', 'Out of Stock', 'Overstock', 'Low Stock'],
                    onChanged: (v) => setState(() => _statusFilter = v!),
                  ),
                  const SizedBox(width: 10),
                  _FilterDropdown(
                    value: _categoryFilter,
                    items: const ['All Categories', 'Beverages', 'DBR', 'unileveer'],
                    onChanged: (v) => setState(() => _categoryFilter = v!),
                  ),
                  const SizedBox(width: 10),
                  _FilterDropdown(
                    value: _sortFilter,
                    items: const ['Name (A-Z)', 'Name (Z-A)', 'Stock (Low-High)', 'Stock (High-Low)', 'Value (Low-High)', 'Value (High-Low)'],
                    onChanged: (v) => setState(() => _sortFilter = v!),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: _border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.tune, size: 18, color: _subText),
                  ),
                ],
              ),
            ),
            _buildTable(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _border)),
              ),
              child: const Center(
                child: Text(
                  'Showing 14 of 14 products · Value: Rs31,083,205.00',
                  style: TextStyle(fontSize: 12, color: _subText),
                ),
              ),
            ),
          ] else if (_selectedTab == 1) ...[
            const InventoryAlertView(),   // ← shows alert view
          ] else if (_selectedTab == 2) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Text('Analytics coming soon...', style: TextStyle(color: _subText)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTable() {
    final filtered = products.where((p) {
      final matchSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchStatus = _statusFilter == 'All Status' ||
          (_statusFilter == 'In Stock' && p.status == StockStatus.inStock) ||
          (_statusFilter == 'Out of Stock' &&
              p.status == StockStatus.outOfStock) ||
          (_statusFilter == 'Overstock' && p.status == StockStatus.overstock) ||
          (_statusFilter == 'Low Stock' && p.status == StockStatus.lowStock);
      final matchCat = _categoryFilter == 'All Categories' ||
          p.category == _categoryFilter;
      return matchSearch && matchStatus && matchCat;
    }).toList();

    return Column(
      children: [
        // Table header
        Container(
          color: const Color(0xFFF8F9FA),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Checkbox(
                  value: _selectedRows.length == filtered.length &&
                      filtered.isNotEmpty,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4,),
                  ),
                  side: BorderSide(
                    color: Colors.grey.shade500,
                    width: 1,
                  ),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedRows.addAll(
                            List.generate(filtered.length, (i) => i));
                      } else {
                        _selectedRows.clear();
                      }
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeColor: AppColors.primaryColors,
                ),
              ),
              const SizedBox(width: 24),
              const Expanded(
                  flex: 4,
                  child: Text('Product',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _tableHeader))),
              const Expanded(
                  flex: 2,
                  child: Text('SKU',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _tableHeader))),
              const Expanded(
                  flex: 2,
                  child: Text('Category',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _tableHeader))),
              const Expanded(
                  flex: 2,
                  child: Text('Stock',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _tableHeader))),
              const Expanded(
                  flex: 1,
                  child: Text('Min Stock',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _tableHeader))),
              const Expanded(
                  flex: 2,
                  child: Text('Value',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _tableHeader))),
              const Expanded(
                  flex: 2,
                  child: Text('Status',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _tableHeader))),
              const SizedBox(width: 26),
            ],
          ),
        ),
        // Rows
        ...filtered.asMap().entries.map((e) => _ProductRow(
          index: e.key,
          product: e.value,
          isSelected: _selectedRows.contains(e.key),
          onSelect: (v) {
            setState(() {
              if (v == true) {
                _selectedRows.add(e.key);
              } else {
                _selectedRows.remove(e.key);
              }
            });
          },
        )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _StatCardData {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final double valueFontSize;

  const _StatCardData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    this.valueFontSize = 24,
  });
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6C757D))),
                const SizedBox(height: 2),
                Text(data.value,
                    style: TextStyle(
                        fontSize: data.valueFontSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF212529))),
                Text(data.subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6C757D))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badge;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.whiteColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppColors.primaryColors.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: const Color(0xFF6C757D)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                    isSelected ? FontWeight.w500 : FontWeight.normal,
                    color: const Color(0xFF6C757D))),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.redColors,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER DROPDOWN
// ─────────────────────────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 16, color: Color(0xFF6C757D)),
          style: const TextStyle(fontSize: 13, color: Color(0xFF495057)),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT ROW
// ─────────────────────────────────────────────────────────────────────────────

class _ProductRow extends StatefulWidget {
  final int index;
  final ProductModel product;
  final bool isSelected;
  final ValueChanged<bool?> onSelect;

  const _ProductRow({
    required this.index,
    required this.product,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow> {
  bool _isHovered = false;

  Color get _rowBg {
    if (_isHovered) return const Color(0xFFECFDF5); // hover = light green
    if (widget.isSelected) return const Color(0xFFF0FDF4);
    return widget.index.isEven ? Colors.white : const Color(0xFFFAFAFA); // alternating
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _rowBg,
          border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Expand icon
            widget.product.variants > 0 ? const Icon(Icons.chevron_right, size: 16, color: Color(0xFFADB5BD)) : SizedBox(width: 16,),
            const SizedBox(width: 4),
            // Checkbox
            SizedBox(
              width: 20,
              child: Checkbox(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4,),
                ),
                side: BorderSide(
                  color: Colors.grey.shade500,
                  width: 1,
                ),
                value: widget.isSelected,
                onChanged: widget.onSelect,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: AppColors.primaryColors,
              ),
            ),
            const SizedBox(width: 20),
            // Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE9ECEF),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(widget.product.initials,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF495057))),
            ),
            const SizedBox(width: 8),
            // Product name + variants
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.product.name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF212529))),
                  if (widget.product.variants > 0) ...[
                    const SizedBox(height: 2),
                    // Row(
                    //   children: [
                    //     Container(
                    //       padding: const EdgeInsets.symmetric(
                    //           horizontal: 6, vertical: 2),
                    //       decoration: BoxDecoration(
                    //         color: AppColors.primaryColors,
                    //         borderRadius: BorderRadius.circular(10),
                    //       ),
                    //       child: Text(
                    //         '${widget.product.variants} variants',
                    //         style: const TextStyle(
                    //             color: AppColors.whiteColor,
                    //             fontSize: 10,
                    //             fontWeight: FontWeight.w600),
                    //       ),
                    //     ),
                    //     const SizedBox(width: 4),
                    //     Text(
                    //       '(${_formatNum(widget.product.stock + 550)} units)',
                    //       style: const TextStyle(
                    //           fontSize: 11, color: Color(0xFF6C757D)),
                    //     ),
                    //   ],
                    // ),
                  ],
                ],
              ),
            ),
            // SKU
            Expanded(
              flex: 2,
              child: Text(widget.product.sku,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6C757D))),
            ),
            // Category
            Expanded(
              flex: 2,
              child: Text(widget.product.category,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF495057))),
            ),
            // Stock
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  const Icon(Icons.monetization_on_outlined,
                      size: 14, color: Color(0xFFADB5BD)),
                  const SizedBox(width: 4),
                  Text(
                    _formatNum(widget.product.stock),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.product.stock == 0
                          ? AppColors.redColors
                          : AppColors.primaryColors,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.settings_outlined,
                      size: 14, color: Color(0xFFADB5BD)),
                ],
              ),
            ),
            // Min Stock
            Expanded(
              flex: 1,
              child: Text(
                widget.product.minStock.toString(),
                style: const TextStyle(fontSize: 13, color: Color(0xFF495057)),
              ),
            ),
            // Value
            Expanded(
              flex: 2,
              child: Text(
                'Rs${_formatCurrency(widget.product.value)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF212529)),
              ),
            ),
            // Status badge
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _StatusBadge(status: widget.product.status),
              ),
            ),
            // More icon
            const SizedBox(width: 8),
            const Icon(Icons.more_vert, size: 18, color: Color(0xFFADB5BD)),
          ],
        ),
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return n.toString();
  }

  String _formatCurrency(double v) {
    return v
        .toStringAsFixed(2)
        .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final StockStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case StockStatus.inStock:
        return _badge('In Stock', AppColors.primaryColors,
            const Color(0xFFECFDF5));
      case StockStatus.outOfStock:
        return _badge(
            'Out of Stock', AppColors.redColors, const Color(0xFFFFF1F2));
      case StockStatus.overstock:
        return _badge('Overstock', AppColors.primaryColors,
            const Color(0xFFECFDF5));
      case StockStatus.lowStock:
        return _badge('Low Stock', const Color(0xFFF59E0B),
            const Color(0xFFFFFBEB));
    }
  }

  Widget _badge(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}