// =============================================================
// inventory_balance_screen.dart
// Warehouse-side Inventory Balance shell — 2 tabs:
//   1. Create Balance Request
//   2. Report / History
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

import '../widgets/balance_report_panel.dart';
import '../widgets/create_batch_panel.dart';

class InventoryBalanceScreen extends StatefulWidget {
  const InventoryBalanceScreen({super.key});

  @override
  State<InventoryBalanceScreen> createState() => _InventoryBalanceScreenState();
}

class _InventoryBalanceScreenState extends State<InventoryBalanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Top bar ───────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: AppColor.surface,
            border: Border(bottom: BorderSide(color: AppColor.grey200)),
          ),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color:        AppColor.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.rule_folder_outlined,
                    size: 18, color: AppColor.primary),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Inventory Balance',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary,
                      )),
                  Text('Weekly balance requests · owner-only',
                      style: TextStyle(fontSize: 11, color: AppColor.textSecondary)),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),

        // ── Tab bar ───────────────────────────────
        Container(
          color: AppColor.surface,
          child: TabBar(
            controller: _tabs,
            indicatorColor: AppColor.primary,
            indicatorWeight: 3,
            labelColor:      AppColor.primary,
            unselectedLabelColor: AppColor.textSecondary,
            labelStyle:      const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Create Request'),
              Tab(text: 'History / Report'),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColor.grey200),

        // ── Content ───────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              CreateBatchPanel(),
              BalanceReportPanel(),
            ],
          ),
        ),
      ],
    );
  }
}
