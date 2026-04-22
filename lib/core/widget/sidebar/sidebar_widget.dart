import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/branch/assign_stock_to_branch/presentation/screen/branch_transfer_list_screen.dart';

import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/screens/assign_stock_screen.dart';
import 'package:jan_ghani_final/features/warehouse/auth/presentation/provider/auth_provider.dart';
import 'package:jan_ghani_final/features/warehouse/auth/presentation/screens/login_screen.dart';
import 'package:jan_ghani_final/features/warehouse/category/presentation/screens/all_category_screen.dart';
import 'package:jan_ghani_final/features/warehouse/link_stores/presentation/screens/linked_stores_screen.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/screens/purchase_order_screen.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/screens/all_supplier_screen/all_supplier_screen.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/presentation/screens/warehouse_dashboard_screen.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_expense/presentation/screens/warehouse_expense_screen.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/presentation/screens/warehouse_finance_screen/warehouse_finance_screen.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/presentation/screen/warehouse_stock_inventory_screen.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_user/presentation/screens/user_screen.dart';

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


class SideBar extends ConsumerStatefulWidget {
  const SideBar({super.key});

  @override
  ConsumerState<SideBar> createState() => _SideBarState();
}

class _SideBarState extends ConsumerState<SideBar> {
  int _index = 0;
  bool _settingsOpen = false;

  late final List<NavItem> _allOthers = [
    NavItem(
      svg: 'assets/images/dolly-flatbed-alt.svg',
      label: 'Warehouse Stock Inventory',
      screen: const WarehouseStockInventoryScreen(),
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


    NavItem(
      svg: 'assets/images/sale_invoice.svg',
      label: 'Category',
      screen: const AllCategoryScreen(),
    ),

    NavItem(
      svg: 'assets/images/sale_invoice.svg',
      label: 'WA Finance',
      screen: const WarehouseFinanceScreen(),
    ),

    NavItem(
      svg: 'assets/images/sale_invoice.svg',
      label: 'Expense',
      screen: const WarehouseExpenseScreen(),
    ),

  ];

  // data entry
  late final List<NavItem> _dataEntry = [
    NavItem(
      svg: 'assets/images/dolly-flatbed-alt.svg',
      label: 'Warehouse Stock Inventory',
      screen: const WarehouseStockInventoryScreen(),
    ),


    NavItem(
      svg: 'assets/images/dolly-flatbed-alt.svg',
      label: 'Supplier',
      screen: const AllSupplierScreen(),
    ),


    NavItem(
      svg: 'assets/images/sale_invoice.svg',
      label: 'Category',
      screen: const AllCategoryScreen(),
    ),

    NavItem(
      svg: 'assets/images/sale_invoice.svg',
      label: 'WA Finance',
      screen: const WarehouseFinanceScreen(),
    ),

    NavItem(
      svg: 'assets/images/sale_invoice.svg',
      label: 'Expense',
      screen: const WarehouseExpenseScreen(),
    ),

  ];

  // warehouse manager
  late final List<NavItem> _warehouseManager = [
    NavItem(
      svg: 'assets/images/sale_invoice.svg',
      label: 'Dashboard',
      screen: const WarehouseDashboardScreen(),
    ),
    NavItem(
      svg: 'assets/images/dolly-flatbed-alt.svg',
      label: 'Warehouse Stock Inventory',
      screen: const WarehouseStockInventoryScreen(),
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
    NavItem(
      svg: 'assets/images/dolly-flatbed-alt.svg',
      label: 'User',
      screen: const AllUserScreen(),
    ),

    NavItem(
      svg: 'assets/images/dolly-flatbed-alt.svg',
      label: 'Assign Stock',
      screen: const AssignStockScreen(),
    ),


    NavItem(
      svg: 'assets/images/sale_invoice.svg',
      label: 'Category',
      screen: const AllCategoryScreen(),
    ),

    NavItem(
      svg: 'assets/images/sale_invoice.svg',
      label: 'WA Finance',
      screen: const WarehouseFinanceScreen(),
    ),

    NavItem(
      svg: 'assets/images/sale_invoice.svg',
      label: 'Expense',
      screen: const WarehouseExpenseScreen(),
    ),

    NavItem(
      svg: 'assets/images/sale_invoice.svg',
      label: 'Link Stores',
      screen:  LinkedStoresScreen(warehouseId: AppConfig.warehouseId,),
    ),

  ];



  List<NavItem> _getItemsByRole(String? role) {
    switch (role) {
      case 'data_entry':
        return _dataEntry;
      case 'warehouse_manager':
        return _warehouseManager;
      default:
        return _allOthers;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final items = _getItemsByRole(user?.role);

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
                    itemCount: items.length,
                    itemBuilder: (_, i) => NavTile(
                      item: items[i],
                      selected: !_settingsOpen && _index == i,
                      onTap: () => setState(() {
                        _index = i;
                        _settingsOpen = false;
                      }),
                    ),
                  ),
                ),

                // Logout button
                IconButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                ),
              ],
            ),
          ),

          Container(width: 1, color: _kGrey),

          Expanded(
            child: items[_index].screen,
          ),
        ],
      ),
    );
  }
}

