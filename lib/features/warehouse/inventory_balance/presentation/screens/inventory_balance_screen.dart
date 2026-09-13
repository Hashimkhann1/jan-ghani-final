// Updated on 2026-09-11 07:48 AM
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
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
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
        // ── Top bar (title + segmented tabs on right) ─────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: AppColor.surface,
            border: Border(bottom: BorderSide(color: AppColor.grey200)),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color:        AppColor.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.rule_folder_outlined,
                    size: 19, color: AppColor.primary),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Inventory Balance',
                      style: TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w800,
                        color: AppColor.textPrimary,
                      )),
                  SizedBox(height: 2),
                  Text('Weekly balance requests · owner-only',
                      style: TextStyle(fontSize: 11, color: AppColor.textSecondary)),
                ],
              ),
              const Spacer(),
              _SegmentedTabs(
                controller: _tabs,
                tabs: const [
                  _TabSpec(label: 'Create Request', icon: Icons.add_circle_outline_rounded),
                  _TabSpec(label: 'History / Report', icon: Icons.history_rounded),
                ],
              ),
            ],
          ),
        ),

        // ── Content ───────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabs,
            physics: const NeverScrollableScrollPhysics(),
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

// ─────────────────────────────────────────────────────────────
// SEGMENTED TABS  (custom pill-style)
// ─────────────────────────────────────────────────────────────
class _TabSpec {
  final String label;
  final IconData icon;
  const _TabSpec({required this.label, required this.icon});
}

class _SegmentedTabs extends StatelessWidget {
  final TabController controller;
  final List<_TabSpec> tabs;
  const _SegmentedTabs({required this.controller, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(tabs.length, (i) {
          final active = controller.index == i;
          return Padding(
            padding: EdgeInsets.only(right: i == tabs.length - 1 ? 0 : 4),
            child: _SegmentButton(
              spec: tabs[i],
              active: active,
              onTap: () => controller.animateTo(i),
            ),
          );
        }),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final _TabSpec spec;
  final bool active;
  final VoidCallback onTap;
  const _SegmentButton({
    required this.spec, required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: active ? AppColor.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: active
            ? [BoxShadow(
                color: AppColor.primary.withOpacity(0.25),
                blurRadius: 8, offset: const Offset(0, 2),
              )]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  spec.icon,
                  size: 15,
                  color: active ? Colors.white : AppColor.textSecondary,
                ),
                const SizedBox(width: 7),
                Text(
                  spec.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColor.textPrimary,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
