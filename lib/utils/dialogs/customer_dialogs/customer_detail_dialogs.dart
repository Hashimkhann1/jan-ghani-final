import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/model/customer_model/customer_model.dart';
import 'package:jan_ghani_final/utils/app_colors/app_colors.dart';
import 'package:jan_ghani_final/view/customers_view/customers_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ORDER MODEL
// ─────────────────────────────────────────────────────────────────────────────

class CustomerOrder {
  final String orderId;
  final DateTime date;
  final String paymentMethod;
  final double amount;
  final String status;

  const CustomerOrder({
    required this.orderId,
    required this.date,
    required this.paymentMethod,
    required this.amount,
    required this.status,
  });
}


// ─────────────────────────────────────────────────────────────────────────────
// SHOW HELPER
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showCustomerDetailDialog(BuildContext context, CustomerModel customer) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => CustomerDetailDialog(customer: customer),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class CustomerDetailDialog extends StatefulWidget {
  final CustomerModel customer;
  const CustomerDetailDialog({super.key, required this.customer});

  @override
  State<CustomerDetailDialog> createState() => _CustomerDetailDialogState();
}

class _CustomerDetailDialogState extends State<CustomerDetailDialog> {
  int _selectedTab = 0; // 0=Overview, 1=Purchases, 2=Credit & Loyalty

  static const _border = Color(0xFFE9ECEF);
  static const _subText = Color(0xFF6C757D);
  static const _headerText = Color(0xFF212529);
  static const _tabBg = Color(0xFFF0F0F0);

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return DateFormat('MMMM yyyy').format(dt);
  }

  String _formatOrderDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _currency(double v) =>
      'Rs ${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      child: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildTabs(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _buildTabContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              widget.customer.initials,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColors,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name + since
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.customer.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700, color: _headerText)),
                const SizedBox(height: 3),
                Text(
                  'Customer since ${_formatDate(widget.customer.customerSince)}',
                  style: const TextStyle(fontSize: 13, color: _subText),
                ),
              ],
            ),
          ),
          // Edit button
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: _headerText,
              side: const BorderSide(color: Color(0xFFE0E0E0)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            child: const Text('Edit'),
          ),
          const SizedBox(width: 8),
          // Close
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20, color: _subText),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: _tabBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _TabBtn(label: 'Overview', index: 0, selected: _selectedTab, onTap: (i) => setState(() => _selectedTab = i)),
            _TabBtn(label: 'Purchases', index: 1, selected: _selectedTab, onTap: (i) => setState(() => _selectedTab = i)),
            _TabBtn(label: 'Credit & Loyalty', index: 2, selected: _selectedTab, onTap: (i) => setState(() => _selectedTab = i)),
          ],
        ),
      ),
    );
  }

  // ── Tab Content ───────────────────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOverview();
      case 1:
        return _buildPurchases();
      case 2:
        return _buildCreditLoyalty();
      default:
        return const SizedBox();
    }
  }

  // ── Overview Tab ──────────────────────────────────────────────────────────
  Widget _buildOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Email + Phone row
        Row(
          children: [
            Expanded(
              child: _InfoBox(
                icon: Icons.email_outlined,
                label: 'Email',
                value: widget.customer.email,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoBox(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: widget.customer.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Address
        _InfoBox(
          icon: Icons.location_on_outlined,
          label: 'Address',
          value: widget.customer.address,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        // 4 stat mini-cards
        Row(
          children: [
            _MiniStatCard(
              icon: Icons.shopping_bag_outlined,
              iconBg: const Color(0xFFECFDF5),
              iconColor: AppColors.primaryColors,
              value: _currency(widget.customer.totalPurchases),
              label: 'Total Purchases',
            ),
            const SizedBox(width: 10),
            _MiniStatCard(
              icon: Icons.trending_up,
              iconBg: const Color(0xFFECFDF5),
              iconColor: AppColors.primaryColors,
              value: '${widget.customer.totalOrders}',
              label: 'Orders',
            ),
            const SizedBox(width: 10),
            // _MiniStatCard(
            //   icon: Icons.star_outline,
            //   iconBg: const Color(0xFFFFFBEB),
            //   iconColor: const Color(0xFFF59E0B),
            //   value: '${widget.customer.points}',
            //   label: 'Loyalty Points',
            // ),
            // const SizedBox(width: 10),
            _MiniStatCard(
              icon: Icons.credit_card_outlined,
              iconBg: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF6366F1),
              value: _currency(widget.customer.balance),
              label: 'Credit Balance',
            ),
          ],
        ),
        if (widget.customer.notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notes',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _headerText)),
                const SizedBox(height: 6),
                Text(widget.customer.notes,
                    style: const TextStyle(fontSize: 13, color: _subText)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Purchases Tab ─────────────────────────────────────────────────────────
  Widget _buildPurchases() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
                ),
                child: Row(
                  children: const [
                    Expanded(flex: 3, child: _OTH('Order')),
                    Expanded(flex: 2, child: _OTH('Date')),
                    Expanded(flex: 2, child: _OTH('Payment')),
                    Expanded(flex: 2, child: _OTH('Amount')),
                    Expanded(flex: 2, child: _OTH('Status')),
                  ],
                ),
              ),
              // Rows
              if (widget.customer.orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No purchases yet',
                        style: TextStyle(fontSize: 13, color: _subText)),
                  ),
                )
              else
                ...widget.customer.orders.asMap().entries.map((e) {
                  final o = e.value;
                  final isLast = e.key == widget.customer.orders.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : const Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(o.orderId,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _headerText)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(_formatOrderDate(o.date),
                              style: const TextStyle(fontSize: 13, color: _subText)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(o.paymentMethod,
                              style: const TextStyle(fontSize: 13, color: _subText)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(_currency(o.amount),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _headerText)),
                        ),
                        Expanded(
                          flex: 2,
                          child: _StatusBadge(status: o.status),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  // ── Credit & Loyalty Tab ──────────────────────────────────────────────────
  Widget _buildCreditLoyalty() {
    final usagePercent = widget.customer.creditUsagePercent;

    return Column(
      children: [
        const SizedBox(height: 16),
        // Credit Account card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.credit_card_outlined, size: 18, color: _headerText),
                  const SizedBox(width: 8),
                  const Text('Credit Account',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _headerText)),
                ],
              ),
              const SizedBox(height: 20),
              // 3 credit stats
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Credit Limit',
                            style: TextStyle(fontSize: 12, color: _subText)),
                        const SizedBox(height: 4),
                        Text(_currency(widget.customer.creditLimit),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _headerText)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Outstanding',
                            style: TextStyle(fontSize: 12, color: _subText)),
                        const SizedBox(height: 4),
                        Text(_currency(widget.customer.balance),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF59E0B))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Available',
                            style: TextStyle(fontSize: 12, color: _subText)),
                        const SizedBox(height: 4),
                        Text(_currency(widget.customer.available),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryColors)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Credit usage progress bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Credit Usage',
                      style: TextStyle(fontSize: 12, color: _subText)),
                  Text('${(usagePercent * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, color: _subText)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: usagePercent,
                  backgroundColor: const Color(0xFFE9ECEF),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    usagePercent > 0.8 ? AppColors.redColors : AppColors.primaryColors,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE9ECEF), height: 1),
              const SizedBox(height: 14),
              // View History
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: const [
                    Icon(Icons.history, size: 16, color: _headerText),
                    SizedBox(width: 8),
                    Text('View History',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _headerText)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Loyalty Program card
        // Container(
        //   padding: const EdgeInsets.all(20),
        //   decoration: BoxDecoration(
        //     border: Border.all(color: _border),
        //     borderRadius: BorderRadius.circular(12),
        //   ),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Row(
        //         children: const [
        //           Icon(Icons.star_outline, size: 18, color: _headerText),
        //           SizedBox(width: 8),
        //           Text('Loyalty Program',
        //               style: TextStyle(
        //                   fontSize: 15, fontWeight: FontWeight.w700, color: _headerText)),
        //         ],
        //       ),
        //       const SizedBox(height: 16),
        //       Row(
        //         children: [
        //           Container(
        //             width: 72, height: 72,
        //             decoration: BoxDecoration(
        //               color: const Color(0xFFFFFBEB),
        //               borderRadius: BorderRadius.circular(12),
        //             ),
        //             child: const Icon(Icons.star, size: 36, color: Color(0xFFF59E0B)),
        //           ),
        //           const SizedBox(width: 16),
        //           Column(
        //             crossAxisAlignment: CrossAxisAlignment.start,
        //             children: [
        //               Text(
        //                 '${widget.customer.points}',
        //                 style: const TextStyle(
        //                     fontSize: 28,
        //                     fontWeight: FontWeight.w700,
        //                     color: _headerText),
        //               ),
        //               const Text('Total Points Earned',
        //                   style: TextStyle(fontSize: 13, color: _subText)),
        //             ],
        //           ),
        //         ],
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  final String label;
  final int index;
  final int selected;
  final ValueChanged<int> onTap;

  const _TabBtn({
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.whiteColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: AppColors.primaryColors, width: 1.5)
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF212529)
                    : const Color(0xFF6C757D),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO BOX
// ─────────────────────────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  const _InfoBox({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF9E9E9E)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
              const SizedBox(height: 3),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212529))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MINI STAT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;

  const _MiniStatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE9ECEF)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF212529))),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6C757D))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER TABLE HEADER CELL
// ─────────────────────────────────────────────────────────────────────────────

class _OTH extends StatelessWidget {
  final String text;
  const _OTH(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF495057)));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    switch (status.toLowerCase()) {
      case 'completed':
        bg = const Color(0xFFECFDF5);
        text = AppColors.primaryColors;
        break;
      case 'pending':
        bg = const Color(0xFFFFFBEB);
        text = const Color(0xFFF59E0B);
        break;
      case 'cancelled':
        bg = const Color(0xFFFFF1F2);
        text = AppColors.redColors;
        break;
      default:
        bg = const Color(0xFFF0F0F0);
        text = const Color(0xFF6C757D);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toLowerCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: text)),
    );
  }
}