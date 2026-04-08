import 'package:flutter/material.dart';
import 'package:jan_ghani_final/features/branch_stock_inventory/presentation/screen/branch_stock_inventory_screen.dart';
import 'package:jan_ghani_final/features/cashier_dashboard/presentation/screen/cashier_dashboard_screen.dart';
import 'package:jan_ghani_final/features/counter/presentation/screen/counter_screen.dart';
import 'package:jan_ghani_final/features/customer/presentation/screen/all_customer_screen.dart';
import 'package:jan_ghani_final/features/purchase_invoice/presentation/screens/purchase_order_screen.dart';
import 'package:jan_ghani_final/features/sale_invoice/presentation/screen/sale_invoice_screen.dart';
import 'package:jan_ghani_final/features/supplier/presentation/screens/all_supplier_screen/all_supplier_screen.dart';
import '../../../features/assign_stock_to_branch/presentation/screen/branch_transfer_list_screen.dart';
import '../../../features/dashboard/presentation/screen/dashboard_screen.dart';
import '../../../features/warehouse_stock_inventory/presentation/screen/warehouse_stock_inventory_screen.dart';
import 'nav_tile_widget.dart';


const _kGrey     = Color(0xFFD3D3D3);
const _kBg       = Color(0xFFF8F8F8);
const _kDark     = Color(0xFF333333);
const _kMid      = Color(0xFF666666);
const _kSelected = Color(0xFF455A64);


class NavItem {
  final String svg;
  final String label;
  final Widget screen;

  const NavItem({
    required this.svg,
    required this.label,
    required this.screen,
  });
}


class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  int _index = 0;
  bool _settingsOpen = false;

  late final List<NavItem> _items = [
    NavItem(
      svg: 'assets/images/sale_invoice.svg',
      label: 'Dashboard',
      screen: const DashboardScreen(),
    ),
    NavItem(
      svg: 'assets/images/sale_invoice.svg',
      label: 'Cashier Dashboard',
      screen: const CashierDashboardScreen(),
    ),
    NavItem(
      svg: 'assets/images/sale_invoice.svg',
      label: 'Sale Invoice',
      screen: const SaleInvoiceScreen(),
    ),
    NavItem(
      svg: 'assets/images/user-bag.svg',
      label: 'Customer',
      screen: const AllCustomerScreen(),
    ),
    NavItem(
      svg: 'assets/images/dolly-flatbed-alt.svg',
      label: 'Warehouse Stock Inventory',
      screen: const WarehouseStockInventoryScreen(),
    ),
    NavItem(
      svg: 'assets/images/dolly-flatbed-alt.svg',
      label: 'Counter',
      screen: const AllCounterScreen(),
    ),
    NavItem(
      svg: 'assets/images/dolly-flatbed-alt.svg',
      label: 'Branch Stock Inventory',
      screen: const BranchStockInventoryScreen(),
    ),
    NavItem(
      svg: 'assets/images/dolly-flatbed-alt.svg',
      label: 'Assign Stock to My Branch',
      screen: const BranchTransferListScreen(),
    ),
    NavItem(
      svg: 'assets/images/dolly-flatbed-alt.svg',
      label: 'Po',
      screen: const PurchaseOrderScreen(),
    ),

    NavItem(
      svg: 'assets/images/dolly-flatbed-alt.svg',
      label: 'Supplier',
      screen: const AllSupplierScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Row(
        children: [

          Container(
            width: 90,
            color: Colors.white,
            child: Column(
              children: [

                // Logo
                Container(
                  height: 56,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: _kGrey)),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'POS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _kDark,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                // Nav Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _items.length,
                    itemBuilder: (_, i) => NavTile(
                      item: _items[i],
                      selected: !_settingsOpen && _index == i,
                      onTap: () => setState(() {
                        _index = i;
                        _settingsOpen = false;
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, color: _kGrey),
          Expanded(
            child: _items[_index].screen,
          ),
        ],
      ),
    );
  }
}

