import 'package:flutter/material.dart';
import 'package:jan_ghani_final/model/customer_model/customer_model.dart';
import 'package:jan_ghani_final/res/dummy/dummy_data.dart';
import 'package:jan_ghani_final/utils/app_colors/app_colors.dart';
import 'package:jan_ghani_final/utils/dialogs/customer_dialogs/add_customer_dialog/add_customer_dialog.dart';
import 'package:jan_ghani_final/utils/dialogs/customer_dialogs/customer_detail_dialogs.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOMERS VIEW
// ─────────────────────────────────────────────────────────────────────────────

class CustomersView extends StatefulWidget {
  const CustomersView({super.key});

  @override
  State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
  static const _bg = Color(0xFFF8F9FA);
  static const _border = Color(0xFFE9ECEF);
  static const _subText = Color(0xFF6C757D);
  static const _headerText = Color(0xFF212529);
  static const _tableHeader = Color(0xFF495057);

  final List<CustomerModel> _customers = List.from(DummyData.dummyCustomers);
  final Set<int> _selectedRows = {};
  String _searchQuery = '';
  String _groupFilter = 'All Customers';

  List<CustomerModel> get _filtered {
    return _customers.where((c) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.phone.contains(q);
    }).toList();
  }

  // ── Stats ─────────────────────────────────────────────────────────────────
  int get _total => _customers.length;
  double get _totalSales => _customers.fold(0, (s, c) => s + c.totalPurchases);
  double get _outstanding => _customers.fold(0, (s, c) => s + c.balance);
  int get _withCredit => _customers.where((c) => c.creditLimit > 0).length;
  int get _totalPoints => _customers.fold(0, (s, c) => s + c.points);
  double get _avgPurchase => _total == 0 ? 0 : _totalSales / _total;

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
        color: AppColors.whiteColor,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFF0FDF4),
            ),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryColors, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('Main Store', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: _subText),
            ]),
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
            Text('Online', style: TextStyle(fontSize: 12, color: AppColors.primaryColors, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(width: 16),
          Stack(clipBehavior: Clip.none, children: [
            const Icon(Icons.notifications_outlined, size: 22, color: _subText),
            Positioned(
              top: -4, right: -4,
              child: Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(color: AppColors.redColors, shape: BoxShape.circle),
                child: const Center(child: Text('9+', style: TextStyle(color: AppColors.whiteColor, fontSize: 8, fontWeight: FontWeight.bold))),
              ),
            ),
          ]),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.greenColor,
            child: const Text('JG', style: TextStyle(color: AppColors.whiteColor, fontSize: 11, fontWeight: FontWeight.bold)),
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
              Text('Customers',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _headerText)),
              SizedBox(height: 2),
              Text('Manage your customer database',
                  style: TextStyle(fontSize: 13, color: _subText)),
            ],
          ),
        ),
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
        ElevatedButton.icon(
          onPressed: () => showAddCustomerDialog(context),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Customer'),
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

  // ── Stat Cards ────────────────────────────────────────────────────────────
  Widget _buildStatCards() {
    final cards = [
      _StatCardData(
        icon: Icons.people_outline,
        iconBg: const Color(0xFFECFDF5),
        iconColor: AppColors.primaryColors,
        label: 'Total',
        value: '$_total',
      ),
      _StatCardData(
        icon: Icons.trending_up,
        iconBg: const Color(0xFFECFDF5),
        iconColor: AppColors.primaryColors,
        label: 'Total Sales',
        value: 'Rs${_formatCurrency(_totalSales)}',
      ),
      _StatCardData(
        icon: Icons.credit_card_outlined,
        iconBg: const Color(0xFFFFFBEB),
        iconColor: const Color(0xFFF59E0B),
        label: 'Outstanding',
        value: 'Rs${_formatCurrency(_outstanding)}',
      ),
      _StatCardData(
        icon: Icons.credit_score_outlined,
        iconBg: const Color(0xFFEEF2FF),
        iconColor: const Color(0xFF6366F1),
        label: 'With Credit',
        value: '$_withCredit',
      ),
      _StatCardData(
        icon: Icons.star_outline,
        iconBg: const Color(0xFFFFFBEB),
        iconColor: const Color(0xFFF59E0B),
        label: 'Total Points',
        value: '$_totalPoints',
      ),
    ];

    return Row(
      children: cards.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: e.key < cards.length - 1 ? 12 : 0),
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
          // Search + filter bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 500,
                  height: 40,
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, phone...',
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
                const SizedBox(width: 12),
                // Group filter
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.whiteColor,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.filter_alt_outlined, size: 16, color: _subText),
                      const SizedBox(width: 6),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _groupFilter,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: _subText),
                          style: const TextStyle(fontSize: 13, color: _tableHeader),
                          items: const [
                            DropdownMenuItem(value: 'All Customers', child: Text('All Customers')),
                            DropdownMenuItem(value: 'With Credit', child: Text('With Credit')),
                            DropdownMenuItem(value: 'With Balance', child: Text('With Balance')),
                            DropdownMenuItem(value: 'Top Buyers', child: Text('Top Buyers')),
                          ],
                          onChanged: (v) => setState(() => _groupFilter = v!),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Table Header
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
                      if (v == true) _selectedRows.addAll(List.generate(_filtered.length, (i) => i));
                      else _selectedRows.clear();
                    }),
                    activeColor: AppColors.primaryColors,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    side: BorderSide(color: Colors.grey.shade400),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(flex: 4, child: _TH('Customer')),
                const Expanded(flex: 3, child: _TH('Contact')),
                const Expanded(flex: 2, child: _TH('Credit Limit')),
                const Expanded(flex: 2, child: _TH('Balance')),
                const Expanded(flex: 2, child: _TH('Purchases')),
                const Expanded(flex: 1, child: _TH('Points')),
                const SizedBox(width: 32),
              ],
            ),
          ),
          // Rows
          ..._filtered.asMap().entries.map((e) => _CustomerRow(
            index: e.key,
            customer: e.value,
            isSelected: _selectedRows.contains(e.key),
            onSelect: (v) => setState(() {
              if (v == true) _selectedRows.add(e.key);
              else _selectedRows.remove(e.key);
            }),
          )),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE9ECEF))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${_filtered.length} of $_total customers',
                  style: const TextStyle(fontSize: 12, color: _subText),
                ),
                Text(
                  'Avg. purchase: Rs${_formatCurrency(_avgPurchase)}',
                  style: const TextStyle(fontSize: 12, color: _subText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    return v.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _StatCardData {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  const _StatCardData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: data.iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(data.icon, color: data.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.label, style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D))),
              const SizedBox(height: 2),
              Text(data.value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF212529))),
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
  const _TH(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF495057)));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOMER ROW
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerRow extends StatefulWidget {
  final int index;
  final CustomerModel customer;
  final bool isSelected;
  final ValueChanged<bool?> onSelect;

  const _CustomerRow({
    required this.index,
    required this.customer,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<_CustomerRow> createState() => _CustomerRowState();
}

class _CustomerRowState extends State<_CustomerRow> {
  bool _isHovered = false;

  Color get _rowBg {
    if (_isHovered) return const Color(0xFFECFDF5);
    if (widget.isSelected) return const Color(0xFFF0FDF4);
    return widget.index.isEven ? AppColors.whiteColor : const Color(0xFFFAFAFA);
  }

  String _formatCurrency(double v) {
    return 'Rs${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => showCustomerDetailDialog(context, widget.customer),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  side: BorderSide(color: Colors.grey.shade400),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 12),
              // Customer name + avatar
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColors.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.customer.initials,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryColors),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.customer.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF212529)),
                    ),
                  ],
                ),
              ),
              // Contact
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.email_outlined, size: 12, color: Color(0xFFADB5BD)),
                      const SizedBox(width: 4),
                      Text(widget.customer.email,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF495057))),
                    ]),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.phone_outlined, size: 12, color: Color(0xFFADB5BD)),
                      const SizedBox(width: 4),
                      Text(widget.customer.phone,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF495057))),
                    ]),
                  ],
                ),
              ),
              // Credit Limit
              Expanded(
                flex: 2,
                child: Text(
                  _formatCurrency(widget.customer.creditLimit),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF212529)),
                ),
              ),
              // Balance
              Expanded(
                flex: 2,
                child: Text(
                  _formatCurrency(widget.customer.balance),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: widget.customer.balance > 0
                        ? AppColors.redColors
                        : const Color(0xFF495057),
                  ),
                ),
              ),
              // Purchases
              Expanded(
                flex: 2,
                child: Text(
                  _formatCurrency(widget.customer.totalPurchases),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF212529)),
                ),
              ),
              // Points
              Expanded(
                flex: 1,
                child: Text(
                  widget.customer.points > 0 ? '${widget.customer.points}' : '-',
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.customer.points > 0
                        ? const Color(0xFF212529)
                        : const Color(0xFFADB5BD),
                  ),
                ),
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