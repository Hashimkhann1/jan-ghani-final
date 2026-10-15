// Updated on 2026-10-15 10:24 AM

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/warehouse_color.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/screens/assign_stock_report_screen.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/widgets/assign_stock_cart_panel.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/widgets/assign_stock_product_list_panel.dart';

class AssignStockScreen extends ConsumerWidget {
  const AssignStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: WarehouseAppColor.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top bar
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: WarehouseAppColor.surface,
              border: Border(
                  bottom: BorderSide(color: WarehouseAppColor.grey200)),
            ),
            child: Row(
              children: [
                // InkWell(
                //   onTap: () {
                //     ref
                //         .read(assignStockProvider.notifier)
                //         .clearCart();
                //     Navigator.of(context).pop();
                //   },
                //   borderRadius: BorderRadius.circular(8),
                //   child: Container(
                //     padding: const EdgeInsets.all(8),
                //     decoration: BoxDecoration(
                //       color: WarehouseAppColor.grey100,
                //       borderRadius: BorderRadius.circular(8),
                //       border: Border.all(color: WarehouseAppColor.grey200),
                //     ),
                //     child: const Icon(Icons.arrow_back_rounded,
                //         size: 18, color: WarehouseAppColor.textPrimary),
                //   ),
                // ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Assign Stock to Store',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: WarehouseAppColor.textPrimary),
                    ),
                    Text(
                      'Store select karo aur products add karo',
                      style: TextStyle(
                          fontSize: 13,
                          color: WarehouseAppColor.textSecondary),
                    ),
                  ],
                ),
                Spacer(),

                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AssignStockReportScreen()));
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12,vertical: 5),
                    decoration: BoxDecoration(
                      color: WarehouseAppColor.primary,
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Text("Assigned Stock Report",style: TextStyle(fontSize: 15,color: Colors.white),)
                  ),
                )

              ],
            ),
          ),

          // Main content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                SizedBox(
                  width: 300,
                  child: AssignStockProductListPanel(),
                ),
                Expanded(
                  child: AssignStockCartPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}