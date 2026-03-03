import 'package:flutter/material.dart';
import 'package:jan_ghani_final/utils/constant/enum_constant/enum_constant.dart';


class _NavItem {
  final String label;
  final IconData icon;
  final SidebarRoute route;
  final bool showActiveBadge;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
    this.showActiveBadge = false,
  });
}

// ─────────────────────────────────────────────
// SIDEBAR WIDGET
// ─────────────────────────────────────────────

class AppSidebar extends StatefulWidget {
  final SidebarRoute selectedRoute;
  final ValueChanged<SidebarRoute> onRouteChanged;
  final bool collapsed;
  final VoidCallback onToggleCollapse;

  const AppSidebar({
    super.key,
    required this.selectedRoute,
    required this.onRouteChanged,
    this.collapsed = false,
    required this.onToggleCollapse,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar>
    with SingleTickerProviderStateMixin {
  static const Color _bg = Color(0xFF1A1D23);
  static const Color _inactiveText = Color(0xFFADB5BD);
  static const Color _divider = Color(0xFF2A2D35);
  static const Color _avatarBg = Color(0xFF2ECC71);

  late AnimationController _controller;
  late Animation<double> _widthAnim;

  // Track the "logical" collapsed state used for building widgets.
  // We flip this only after the animation is mostly done so that
  // widgets never try to render in a too-narrow space.
  bool _buildCollapsed = false;

  static const double _expandedWidth = 220;
  static const double _collapsedWidth = 70;

  static const _mainItems = <_NavItem>[
    _NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, route: SidebarRoute.dashboard),
    _NavItem(label: 'POS Terminal', icon: Icons.point_of_sale_outlined, route: SidebarRoute.posTerminal, showActiveBadge: true),
    _NavItem(label: 'Products', icon: Icons.inventory_2_outlined, route: SidebarRoute.products),
    _NavItem(label: 'Inventory', icon: Icons.warehouse_outlined, route: SidebarRoute.inventory),
    _NavItem(label: 'Batch Management', icon: Icons.layers_outlined, route: SidebarRoute.batchManagement),
    _NavItem(label: 'Purchase Orders', icon: Icons.shopping_cart_outlined, route: SidebarRoute.purchaseOrders),
    _NavItem(label: 'Warehouse', icon: Icons.store_outlined, route: SidebarRoute.warehouse),
    _NavItem(label: 'Customers', icon: Icons.people_outline, route: SidebarRoute.customers),
    _NavItem(label: 'Suppliers', icon: Icons.local_shipping_outlined, route: SidebarRoute.suppliers),
    _NavItem(label: 'Product Tracking', icon: Icons.track_changes_outlined, route: SidebarRoute.productTracking),
    _NavItem(label: 'Todo Notes', icon: Icons.sticky_note_2_outlined, route: SidebarRoute.todoNotes),
  ];

  static const _financeItems = <_NavItem>[
    _NavItem(label: 'Sales', icon: Icons.bar_chart_outlined, route: SidebarRoute.sales),
    _NavItem(label: 'Refunds', icon: Icons.replay_outlined, route: SidebarRoute.refunds),
    _NavItem(label: 'Invoices', icon: Icons.receipt_long_outlined, route: SidebarRoute.invoices),
    _NavItem(label: 'Expenses', icon: Icons.account_balance_wallet_outlined, route: SidebarRoute.expenses),
    _NavItem(label: 'Cash Drawer', icon: Icons.local_atm_outlined, route: SidebarRoute.cashDrawer),
    _NavItem(label: 'Reports', icon: Icons.assessment_outlined, route: SidebarRoute.reports),
  ];

  static const _systemItems = <_NavItem>[
    _NavItem(label: 'Team & Roles', icon: Icons.group_outlined, route: SidebarRoute.teamAndRoles),
    _NavItem(label: 'Employees', icon: Icons.badge_outlined, route: SidebarRoute.employees),
  ];

  @override
  void initState() {
    super.initState();
    _buildCollapsed = widget.collapsed;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: widget.collapsed ? 1.0 : 0.0,
    );
    _widthAnim = Tween<double>(
      begin: _expandedWidth,
      end: _collapsedWidth,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(AppSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collapsed != widget.collapsed) {
      if (widget.collapsed) {
        // Collapsing: switch build layout to collapsed BEFORE animating
        // so the wide Row is gone before the container shrinks.
        setState(() => _buildCollapsed = true);
        _controller.forward();
      } else {
        // Expanding: animate first, switch layout to expanded AFTER
        // the container is wide enough to hold the Row.
        _controller.reverse().then((_) {
          if (mounted) setState(() => _buildCollapsed = false);
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnim,
      builder: (context, child) {
        return SizedBox(
          width: _widthAnim.value,
          child: child,
        );
      },
      child: Container(
        width: _buildCollapsed ? _collapsedWidth : _expandedWidth,
        color: _bg,
        child: Column(
          children: [
            _buildHeader(_buildCollapsed),
            const Divider(color: _divider, height: 1, thickness: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ..._mainItems.map((item) => _NavTile(
                    item: item,
                    isSelected: widget.selectedRoute == item.route,
                    collapsed: _buildCollapsed,
                    onTap: () => widget.onRouteChanged(item.route),
                  )),
                  _SectionHeader(label: 'FINANCE', collapsed: _buildCollapsed),
                  ..._financeItems.map((item) => _NavTile(
                    item: item,
                    isSelected: widget.selectedRoute == item.route,
                    collapsed: _buildCollapsed,
                    onTap: () => widget.onRouteChanged(item.route),
                  )),
                  _SectionHeader(label: 'SYSTEM', collapsed: _buildCollapsed),
                  ..._systemItems.map((item) => _NavTile(
                    item: item,
                    isSelected: widget.selectedRoute == item.route,
                    collapsed: _buildCollapsed,
                    onTap: () => widget.onRouteChanged(item.route),
                  )),
                ],
              ),
            ),
            const Divider(color: _divider, height: 1, thickness: 1),
            _buildFooter(_buildCollapsed),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(bool collapsed) {
    if (collapsed) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 6),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: _avatarBg, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: const Text('Y',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ),
          const SizedBox(height: 2),
          const Divider(),
          GestureDetector(
            onTap: widget.onToggleCollapse,
            child: const Icon(Icons.chevron_right, color: _inactiveText, size: 16),
          ),
          const Divider(),
        ],
      );
    }

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: _avatarBg, borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: const Text('Y',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Jan Ghani',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Text('Jan Ghani',
                      style: TextStyle(color: _inactiveText, fontSize: 11)),
                ],
              ),
            ),
            GestureDetector(
              onTap: widget.onToggleCollapse,
              child: const Icon(Icons.chevron_left, color: _inactiveText, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────
  Widget _buildFooter(bool collapsed) {
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _avatarBg,
              child: const Text('JG',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
            if (!collapsed) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Jan Ghani',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    Text('Hashim Khan',
                        style: TextStyle(color: _inactiveText, fontSize: 10)),
                  ],
                ),
              ),
              const Icon(Icons.logout, color: _inactiveText, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool collapsed;

  const _SectionHeader({required this.label, required this.collapsed});

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Divider(
            color: Color(0xFF2A2D35),
            height: 1,
            thickness: 1,
            indent: 12,
            endIndent: 12),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
            color: Color(0xFF6C757D),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// INDIVIDUAL NAV TILE
// ─────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final bool collapsed;
  final VoidCallback onTap;

  static const Color _activeBg = Color(0xFF2ECC71);
  static const Color _inactiveText = Color(0xFFADB5BD);

  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = isSelected ? Colors.white : _inactiveText;
    final Color iconColor = isSelected ? Colors.white : _inactiveText;

    return Tooltip(
      message: collapsed ? item.label : '',
      preferBelow: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 0 : 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: collapsed
              ? Center(child: Icon(item.icon, color: iconColor, size: 20))
              : Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(item.icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.showActiveBadge)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white24
                        : _activeBg.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      color: isSelected ? Colors.white : _activeBg,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
