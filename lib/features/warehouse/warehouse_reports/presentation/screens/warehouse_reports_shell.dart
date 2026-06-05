import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/inventory/presentation/screens/inventory_report_screen.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/cash_flow/presentation/screens/cash_flow_report_screen.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/purchase/presentation/screens/purchase_report_screen.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/supplier/presentation/screens/supplier_report_screen.dart';

// ─────────────────────────────────────────────────────────────
// Report item model
// ─────────────────────────────────────────────────────────────

class _ReportItem {
  final IconData icon;
  final String label;
  final String description;
  final Widget? screen;
  final bool isComingSoon;

  const _ReportItem({
    required this.icon,
    required this.label,
    required this.description,
    this.screen,
    this.isComingSoon = false,
  });
}

// ─────────────────────────────────────────────────────────────
// WAREHOUSE REPORTS SHELL
// ─────────────────────────────────────────────────────────────

class WarehouseReportsShell extends StatefulWidget {
  final VoidCallback onBack;
  const WarehouseReportsShell({super.key, required this.onBack});

  @override
  State<WarehouseReportsShell> createState() =>
      _WarehouseReportsShellState();
}

class _WarehouseReportsShellState extends State<WarehouseReportsShell> {
  int _selected = 0;
  bool _drawerOpen = false; // default: closed

  static const _reports = [
    _ReportItem(
      icon: Icons.inventory_2_outlined,
      label: 'Inventory',
      description: 'Stock value, categories, out of stock, transfers',
      screen: InventoryReportScreen(),
    ),
    _ReportItem(
      icon:        Icons.receipt_long_outlined,
      label:       'Purchases',
      description: 'Purchase orders, suppliers, received stock',
      screen:      PurchaseReportScreen(),
    ),
    _ReportItem(
      icon: Icons.local_shipping_outlined,
      label: 'Transfers',
      description: 'Store-wise dispatch, transfer history',
      isComingSoon: true,
    ),
    _ReportItem(
      icon:        Icons.people_outline,
      label:       'Suppliers',
      description: 'Outstanding dues, ledger, payments',
      screen:      SupplierReportScreen(),
    ),
    _ReportItem(
      icon:        Icons.account_balance_wallet_outlined,
      label:       'Cash Flow',
      description: 'Daily cash, expenses, finance summary',
      screen:      CashFlowReportScreen(),
    ),
  ];

  void _toggleDrawer() => setState(() => _drawerOpen = !_drawerOpen);
  void _selectReport(int i) => setState(() {
        _selected = i;
        _drawerOpen = false;
      });

  @override
  Widget build(BuildContext context) {
    final report = _reports[_selected];

    return Row(
      children: [
        // ── Animated drawer / collapsed rail ─────────────────
        // OverflowBox tells the child it always has its TARGET
        // width (192 or 44), regardless of the AnimatedContainer's
        // intermediate animated width. Clip.hardEdge clips the
        // visual output so nothing bleeds outside.
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: _drawerOpen ? 192 : 44,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: _drawerOpen ? 192 : 44,
            maxWidth: _drawerOpen ? 192 : 44,
            child: SizedBox(
              width: _drawerOpen ? 192 : 44,
              child: _drawerOpen
                  ? _ExpandedDrawer(
                      reports: _reports,
                      selectedIndex: _selected,
                      onSelect: _selectReport,
                      onClose: _toggleDrawer,
                      onBack: widget.onBack,
                    )
                  : _CollapsedRail(
                      reports: _reports,
                      selectedIndex: _selected,
                      onSelect: _selectReport,
                      onToggle: _toggleDrawer,
                      onBack: widget.onBack,
                    ),
            ),
          ),
        ),

        // ── Divider ──────────────────────────────────────────
        Container(width: 1, color: AppColor.grey200),

        // ── Report content ───────────────────────────────────
        Expanded(
          child: report.isComingSoon
              ? _ComingSoonScreen(report: report)
              : report.screen!,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// COLLAPSED RAIL — 44px
// ─────────────────────────────────────────────────────────────

class _CollapsedRail extends StatelessWidget {
  final List<_ReportItem> reports;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggle;
  final VoidCallback onBack;

  const _CollapsedRail({
    required this.reports,
    required this.selectedIndex,
    required this.onSelect,
    required this.onToggle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColor.white,
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Open drawer button
          _RailIcon(
            icon: Icons.menu_rounded,
            color: AppColor.grey600,
            tooltip: 'Open reports menu',
            onTap: onToggle,
          ),
          const SizedBox(height: 4),

          Container(height: 1, color: AppColor.grey100, margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8)),

          // Report icons
          ...reports.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _RailIcon(
                  icon: e.value.icon,
                  color: e.key == selectedIndex
                      ? AppColor.primary
                      : e.value.isComingSoon
                          ? AppColor.grey300
                          : AppColor.grey500,
                  tooltip: e.value.label,
                  selected: e.key == selectedIndex,
                  onTap: e.value.isComingSoon
                      ? null
                      : () => onSelect(e.key),
                ),
              )),

          const Spacer(),

          // Back to dashboard
          _RailIcon(
            icon: Icons.dashboard_outlined,
            color: AppColor.grey500,
            tooltip: 'Dashboard',
            onTap: onBack,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _RailIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final bool selected;
  final VoidCallback? onTap;

  const _RailIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? AppColor.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EXPANDED DRAWER — 192px
// ─────────────────────────────────────────────────────────────

class _ExpandedDrawer extends StatelessWidget {
  final List<_ReportItem> reports;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;
  final VoidCallback onBack;

  const _ExpandedDrawer({
    required this.reports,
    required this.selectedIndex,
    required this.onSelect,
    required this.onClose,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColor.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColor.grey200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + close row
                Row(
                  children: [
                    GestureDetector(
                      onTap: onBack,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColor.grey100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_ios_rounded,
                                size: 10, color: AppColor.grey600),
                            SizedBox(width: 3),
                            Text('Dashboard',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColor.grey600)),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Close drawer
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: AppColor.grey100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.chevron_left_rounded,
                            size: 15, color: AppColor.grey600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Title
                const Row(
                  children: [
                    Icon(Icons.bar_chart_rounded,
                        size: 15, color: AppColor.primary),
                    SizedBox(width: 7),
                    Text('Reports',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary)),
                  ],
                ),
              ],
            ),
          ),

          // ── Report tiles ──────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: reports.length,
              itemBuilder: (_, i) => _DrawerTile(
                item: reports[i],
                isSelected: i == selectedIndex,
                onTap: () => onSelect(i),
              ),
            ),
          ),

          // ── Footer ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColor.grey100)),
            ),
            child: const Text('Warehouse Reports',
                style: TextStyle(fontSize: 9, color: AppColor.textHint)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DRAWER TILE
// ─────────────────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  final _ReportItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.isComingSoon ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.primary.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: isSelected
              ? Border.all(color: AppColor.primary.withOpacity(0.2))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColor.primary.withOpacity(0.12)
                    : AppColor.grey100,
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: Icon(
                item.icon,
                size: 13,
                color: isSelected
                    ? AppColor.primary
                    : item.isComingSoon
                        ? AppColor.grey300
                        : AppColor.grey600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColor.primary
                          : item.isComingSoon
                              ? AppColor.grey400
                              : AppColor.textPrimary,
                    ),
                  ),
                  if (item.isComingSoon)
                    const Text('Soon',
                        style: TextStyle(
                            fontSize: 9, color: AppColor.textHint)),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 5, height: 5,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColor.primary),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// COMING SOON SCREEN
// ─────────────────────────────────────────────────────────────

class _ComingSoonScreen extends StatelessWidget {
  final _ReportItem report;
  const _ComingSoonScreen({required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Icon(report.icon, size: 30, color: AppColor.primary),
            ),
            const SizedBox(height: 16),
            Text('${report.label} Report',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary)),
            const SizedBox(height: 6),
            Text(report.description,
                style: const TextStyle(
                    fontSize: 13, color: AppColor.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColor.primary.withOpacity(0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.construction_rounded,
                      size: 13, color: AppColor.primary),
                  SizedBox(width: 6),
                  Text('Coming Soon',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColor.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
