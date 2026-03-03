import 'package:flutter/material.dart';
import 'package:jan_ghani_final/model/supplier_model/supplier_model.dart';
import 'package:jan_ghani_final/utils/app_colors/app_colors.dart';
import 'package:jan_ghani_final/utils/dialogs/supplier_dialogs/add_supplier_dialog.dart';
import 'package:jan_ghani_final/utils/dialogs/supplier_dialogs/supplier_detail_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DUMMY DATA
// ─────────────────────────────────────────────────────────────────────────────

const _activeSuppliers = [
  SupplierModel(
    name: 'Asad Mukhtar',
    address: 'House no 15/c, Hameed Town,...',
    contact: 'Asad Mukhtar',
    email: 'asad0002332@gmail....',
    phone: '+923280127399',
  ),
  SupplierModel(
    name: 'DBR Cosmetics',
    address: '24 Main Boulevard, Lahore',
    contact: 'Bilal Raza',
    email: 'dbr.cosmetics@gmail.com',
    phone: '+923001234567',
    paymentTerms: 'Net 30',
    rating: 4.5,
  ),
  SupplierModel(
    name: 'Unilever Pakistan',
    address: 'Plot 45, Industrial Zone, Karachi',
    contact: 'Sara Khan',
    email: 'sara.khan@unilever.com',
    phone: '+922134567890',
    paymentTerms: 'Net 15',
    rating: 4.8,
  ),
];

const _archivedSuppliers = [
  SupplierModel(
    name: 'Old Vendor Co.',
    address: '12 Street, Old Town',
    contact: 'Ahmed Ali',
    email: 'ahmed@oldvendor.com',
    phone: '+923331234567',
    isArchived: true,
  ),
  SupplierModel(
    name: 'Legacy Supplies',
    address: '88 Commerce Road, Faisalabad',
    contact: 'Usman Tariq',
    email: 'usman@legacy.com',
    phone: '+923451234567',
    isArchived: true,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SUPPLIER VIEW
// ─────────────────────────────────────────────────────────────────────────────

class SupplierView extends StatefulWidget {
  const SupplierView({super.key});

  @override
  State<SupplierView> createState() => _SupplierViewState();
}

class _SupplierViewState extends State<SupplierView> {
  int _selectedTab = 0; // 0 = Active, 1 = Archived
  String _searchQuery = '';
  String _sortFilter = 'Name (A-Z)';
  String _termsFilter = 'All Terms';
  final Set<int> _selectedRows = {};

  static const _bg = Color(0xFFF8F9FA);
  static const _border = Color(0xFFE9ECEF);
  static const _headerText = Color(0xFF212529);
  static const _subText = Color(0xFF6C757D);
  static const _tableHeader = Color(0xFF495057);

  List<SupplierModel> get _currentList =>
      _selectedTab == 0 ? _activeSuppliers : _archivedSuppliers;

  List<SupplierModel> get _filtered {
    return _currentList.where((s) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.contact.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q) ||
          s.phone.contains(q);
    }).toList();
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
          const SizedBox(width: 20),
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
                  width: 8, height: 8,
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
          Row(children: const [
            Icon(Icons.calendar_today_outlined, size: 14, color: _subText),
            SizedBox(width: 6),
            Text('Thu, Feb 26', style: TextStyle(fontSize: 13, color: _tableHeader)),
          ]),
          const SizedBox(width: 16),
          const Spacer(),
          const Icon(Icons.dark_mode_outlined, size: 20, color: _subText),
          const SizedBox(width: 16),
          Row(children: const [
            Icon(Icons.wifi, size: 16, color: AppColors.primaryColors),
            SizedBox(width: 4),
            Text('Online',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryColors,
                    fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(width: 16),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, size: 22, color: _subText),
              Positioned(
                top: -4, right: -4,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                      color: AppColors.redColors, shape: BoxShape.circle),
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
            backgroundColor: AppColors.greenColor,
            child: const Text('JG',
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
              Text('Suppliers',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _headerText)),
              SizedBox(height: 2),
              Text('Manage your vendors and supply chain',
                  style: TextStyle(fontSize: 13, color: _subText)),
            ],
          ),
        ),
        // Import
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.upload_outlined, size: 16),
          label: const Text('Import'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _tableHeader,
            side: const BorderSide(color: _border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 10),
        // Export
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download_outlined, size: 16),
          label: const Text('Export'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _tableHeader,
            side: const BorderSide(color: _border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 10),
        // Add Supplier
        ElevatedButton.icon(
          onPressed: () => showAddSupplierDialog(context),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Supplier'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.greenColor,
            foregroundColor: AppColors.whiteColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  // ── Stat Cards ───────────────────────────────────────────────────────────
  Widget _buildStatCards() {
    final stats = [
      _StatData(
        icon: Icons.people_outline,
        iconBg: const Color(0xFFECFDF5),
        iconColor: AppColors.primaryColors,
        value: '${_activeSuppliers.length}',
        label: 'Total Suppliers',
      ),
      _StatData(
        icon: Icons.calendar_today_outlined,
        iconBg: const Color(0xFFECFDF5),
        iconColor: AppColors.primaryColors,
        value: '1',
        label: 'New (30d)',
      ),
      _StatData(
        icon: Icons.star_outline,
        iconBg: const Color(0xFFFFFBEB),
        iconColor: const Color(0xFFF59E0B),
        value: 'N/A',
        label: 'Avg Rating',
      ),
      _StatData(
        icon: Icons.trending_up,
        iconBg: const Color(0xFFECFDF5),
        iconColor: AppColors.primaryColors,
        value: '0',
        label: 'With Products',
      ),
    ];

    return Row(
      children: stats.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: e.key < stats.length - 1 ? 12 : 0),
            child: _StatCard(data: e.value),
          ),
        );
      }).toList(),
    );
  }

  // ── Table Section ─────────────────────────────────────────────────────────
  Widget _buildTableSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active / Archived tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                _TabChip(
                  icon: Icons.check_circle_outline,
                  label: 'Active',
                  isSelected: _selectedTab == 0,
                  onTap: () => setState(() {
                    _selectedTab = 0;
                    _selectedRows.clear();
                  }),
                ),
                const SizedBox(width: 8),
                _TabChip(
                  icon: Icons.archive_outlined,
                  label: 'Archived',
                  count: _archivedSuppliers.length,
                  isSelected: _selectedTab == 1,
                  onTap: () => setState(() {
                    _selectedTab = 1;
                    _selectedRows.clear();
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE9ECEF)),
          // Search + filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 600,
                  height: 40,
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name, contact, email, phone...',
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
                  ),
                ),
                const SizedBox(width: 10),
                _FilterDropdown(
                  value: _sortFilter,
                  items: const ['Name (A-Z)', 'Name (Z-A)', 'Rating (High-Low)', 'Newest First'],
                  onChanged: (v) => setState(() => _sortFilter = v!),
                ),
                const SizedBox(width: 10),
                _FilterDropdown(
                  value: _termsFilter,
                  items: const ['All Terms', 'Net 15', 'Net 30', 'Net 60', 'COD'],
                  onChanged: (v) => setState(() => _termsFilter = v!),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 40, width: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tune, size: 18, color: _subText),
                ),
              ],
            ),
          ),
          // Count
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              '${_filtered.length} supplier${_filtered.length != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 12, color: _subText),
            ),
          ),
          // Table header
          Container(
            color: const Color(0xFFF8F9FA),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Checkbox(
                    value: _selectedRows.length == _filtered.length && _filtered.isNotEmpty,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selectedRows.addAll(List.generate(_filtered.length, (i) => i));
                      } else {
                        _selectedRows.clear();
                      }
                    }),
                    activeColor: AppColors.primaryColors,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    side: BorderSide(color: Colors.grey.shade400),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(flex: 4, child: _TH('Supplier')),
                const Expanded(flex: 2, child: _TH('Contact')),
                const Expanded(flex: 3, child: _TH('Email / Phone')),
                const Expanded(flex: 2, child: _TH('Payment Terms')),
                const Expanded(flex: 1, child: _TH('Rating')),
                const SizedBox(width: 32),
              ],
            ),
          ),
          // Rows
          ..._filtered.asMap().entries.map((e) => _SupplierRow(
            index: e.key,
            supplier: e.value,
            isSelected: _selectedRows.contains(e.key),
            onSelect: (v) => setState(() {
              if (v == true) {
                _selectedRows.add(e.key);
              } else {
                _selectedRows.remove(e.key);
              }
            }),
          )),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE9ECEF))),
            ),
            child: Center(
              child: Text(
                'Showing ${_filtered.length} of ${_currentList.length} suppliers',
                style: const TextStyle(fontSize: 12, color: _subText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _StatData {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;

  const _StatData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              color: data.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.value,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212529))),
              Text(data.label,
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
// TAB CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  const _TabChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count,
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
              ? Border.all(color: AppColors.primaryColors.withOpacity(0.4))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 15,
                color: isSelected
                    ? AppColors.primaryColors
                    : const Color(0xFF6C757D)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primaryColors
                        : const Color(0xFF6C757D))),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9ECEF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF495057))),
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
        color: AppColors.whiteColor,
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
// TABLE HEADER CELL
// ─────────────────────────────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF495057)));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUPPLIER ROW
// ─────────────────────────────────────────────────────────────────────────────

class _SupplierRow extends StatefulWidget {
  final int index;
  final SupplierModel supplier;
  final bool isSelected;
  final ValueChanged<bool?> onSelect;

  const _SupplierRow({
    required this.index,
    required this.supplier,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<_SupplierRow> createState() => _SupplierRowState();
}

class _SupplierRowState extends State<_SupplierRow> {
  bool _isHovered = false;

  Color get _rowBg {
    if (_isHovered) return const Color(0xFFECFDF5);
    if (widget.isSelected) return const Color(0xFFF0FDF4);
    return widget.index.isEven ? AppColors.whiteColor : const Color(0xFFFAFAFA);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () => showSupplierDetailDialog(context,widget.supplier),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _rowBg,
            border: const Border(top: BorderSide(color: Color(0xFFF0F0F0))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Checkbox
              SizedBox(
                width: 36,
                child: Checkbox(
                  value: widget.isSelected,
                  onChanged: widget.onSelect,
                  activeColor: AppColors.primaryColors,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  side: BorderSide(color: Colors.grey.shade400),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 12),
              // Supplier name + address
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColors.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.supplier.initials,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColors),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.supplier.name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF212529))),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 12, color: Color(0xFFADB5BD)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  widget.supplier.address,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6C757D)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Contact
              Expanded(
                flex: 2,
                child: Text(widget.supplier.contact,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF495057))),
              ),
              // Email / Phone
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 12, color: Color(0xFFADB5BD)),
                        const SizedBox(width: 4),
                        Text(widget.supplier.email,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF495057))),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 12, color: Color(0xFFADB5BD)),
                        const SizedBox(width: 4),
                        Text(widget.supplier.phone,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF495057))),
                      ],
                    ),
                  ],
                ),
              ),
              // Payment Terms
              Expanded(
                flex: 2,
                child: Text(
                  widget.supplier.paymentTerms ?? '—',
                  style: TextStyle(
                      fontSize: 13,
                      color: widget.supplier.paymentTerms != null
                          ? const Color(0xFF495057)
                          : const Color(0xFFADB5BD)),
                ),
              ),
              // Rating
              Expanded(
                flex: 1,
                child: widget.supplier.rating != null
                    ? Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 3),
                    Text(widget.supplier.rating!.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212529))),
                  ],
                )
                    : const Text('—',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFFADB5BD))),
              ),
              // More options
              const SizedBox(width: 8),
              const Icon(Icons.more_vert, size: 18, color: Color(0xFFADB5BD)),
            ],
          ),
        ),
      ),
    );
  }
}