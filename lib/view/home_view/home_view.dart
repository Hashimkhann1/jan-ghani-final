import 'package:flutter/material.dart';
import 'package:jan_ghani_final/utils/componets/app_sidebar/app_sidebar_component.dart';
import 'package:jan_ghani_final/utils/constant/enum_constant/enum_constant.dart';
import 'package:jan_ghani_final/view/all_warehouse_view/all_warehouse_view.dart';
import 'package:jan_ghani_final/view/customers_view/customers_view.dart';
import 'package:jan_ghani_final/view/dashboard_view/dashboard_view.dart';
import 'package:jan_ghani_final/view/inventory_view/inventory_view.dart';
import 'package:jan_ghani_final/view/pos_terminal_view/pos_terminal_view.dart';
import 'package:jan_ghani_final/view/purchase_order_view/purchase_order_view.dart';
import 'package:jan_ghani_final/view/supplier_view/supplier_view.dart';
import 'package:jan_ghani_final/view/todo_note_view/todo_note_view.dart';
import 'package:jan_ghani_final/view/working_view/working_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  SidebarRoute _current = SidebarRoute.dashboard;
  bool _collapsed = false;

  // ── Map each route to its screen widget ──────────────────────────────
  Widget _buildScreen(SidebarRoute route) {
    switch (route) {
      case SidebarRoute.dashboard:
        return const DashboardView();
      case SidebarRoute.posTerminal:
        return const PosTerminalView();
      case SidebarRoute.products:
        return const PosTerminalView();
      case SidebarRoute.inventory:
        return const InventoryView();
      case SidebarRoute.batchManagement:
        return const WorkingView(screenTitle: "Batch Management");
      case SidebarRoute.purchaseOrders:
        return PurchaseOrderView();
      case SidebarRoute.warehouse:
        return AllWarehouseView();
      case SidebarRoute.customers:
        return CustomersView();
      case SidebarRoute.suppliers:
        return SupplierView();
      case SidebarRoute.productTracking:
        return const WorkingView(screenTitle: "Product Tracking");
      case SidebarRoute.todoNotes:
        return TodoNoteView();
      case SidebarRoute.sales:
      return const WorkingView(screenTitle: "Sales");
      case SidebarRoute.refunds:
        return const WorkingView(screenTitle: "Refunds");
      case SidebarRoute.invoices:
        return const WorkingView(screenTitle: "Invoices");
      case SidebarRoute.expenses:
        return const WorkingView(screenTitle: "Expenses");
      case SidebarRoute.cashDrawer:
        return const WorkingView(screenTitle: "Cash Drawer");
      case SidebarRoute.reports:
        return const WorkingView(screenTitle: "Reports");
      case SidebarRoute.teamAndRoles:
        return const WorkingView(screenTitle: "Team And Roles");
      case SidebarRoute.employees:
        return const WorkingView(screenTitle: "Employees");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            selectedRoute: _current,
            onRouteChanged: (r) => setState(() => _current = r),
            collapsed: _collapsed,
            onToggleCollapse: () => setState(() => _collapsed = !_collapsed),
          ),
          Expanded(
            child: _buildScreen(_current), // ← renders the active screen
          ),
        ],
      ),
    );
  }
}