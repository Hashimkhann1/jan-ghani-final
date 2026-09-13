// =============================================================
// branch_inventory_balance_screen.dart
// Branch's main shell — 2 tabs:
//   1. Pending Requests — accept (apply to live stock) / reject
//   2. History          — all statuses read-only
//
// Closes the loop described in INVENTORY_BALANCE.md §12.1 —
// the last open item of the 3-role workflow.
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

import '../provider/branch_inventory_balance_provider.dart';
import '../widget/branch_balance_history_panel.dart';
import '../widget/branch_balance_queue_panel.dart';

class BranchInventoryBalanceScreen extends ConsumerStatefulWidget {
  const BranchInventoryBalanceScreen({super.key});

  @override
  ConsumerState<BranchInventoryBalanceScreen> createState() =>
      _BranchInventoryBalanceScreenState();
}

class _BranchInventoryBalanceScreenState
    extends ConsumerState<BranchInventoryBalanceScreen>
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
    final queueState = ref.watch(branchBalanceQueueProvider);
    final pendingCount = queueState.items.length;

    return Column(
      children: [
        // Top bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.sync_alt_rounded,
                  size: 18, color: AppColor.primary),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stock Balance Requests',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textDark)),
                Text('Reviewer-approved stock adjustments accept/reject karo',
                    style: TextStyle(fontSize: 11, color: AppColor.textMuted)),
              ],
            ),
          ]),
        ),

        // Tab bar — pill segmented control
        _BalanceTabBar(
          controller: _tabs,
          tabs: [
            _BalanceTabSpec(
              icon:  Icons.pending_actions_rounded,
              label: 'Pending Requests',
              color: AppColor.warning,
              count: pendingCount,
            ),
            const _BalanceTabSpec(
              icon:  Icons.history_rounded,
              label: 'History',
              color: AppColor.primary,
              count: 0,
            ),
          ],
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // Content
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              BranchBalanceQueuePanel(),
              BranchBalanceHistoryPanel(),
            ],
          ),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Tab Bar — pill segmented control, each tab keeps its own status
// color instead of a flat underline (same pattern as
// branch_transfer_list_screen.dart's _TransferTabBar).
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _BalanceTabSpec {
  final IconData icon;
  final String   label;
  final Color    color;
  final int      count;
  const _BalanceTabSpec({
    required this.icon,
    required this.label,
    required this.color,
    required this.count,
  });
}

class _BalanceTabBar extends StatefulWidget {
  final TabController controller;
  final List<_BalanceTabSpec> tabs;
  const _BalanceTabBar({required this.controller, required this.tabs});

  @override
  State<_BalanceTabBar> createState() => _BalanceTabBarState();
}

class _BalanceTabBarState extends State<_BalanceTabBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color:        AppColor.grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: List.generate(widget.tabs.length, (i) {
            final spec     = widget.tabs[i];
            final selected = widget.controller.index == i;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap:    () => widget.controller.animateTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve:    Curves.easeOut,
                  margin:   const EdgeInsets.symmetric(horizontal: 2),
                  padding:  const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color:        selected ? spec.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color:      spec.color.withOpacity(0.35),
                              blurRadius: 8,
                              offset:     const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(spec.icon,
                          size: 16, color: selected ? Colors.white : AppColor.textSecondary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          spec.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize:   13,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                            color:      selected ? Colors.white : AppColor.textSecondary,
                          ),
                        ),
                      ),
                      if (spec.count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withOpacity(0.25)
                                : spec.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${spec.count}',
                            style: TextStyle(
                              fontSize:   10.5,
                              fontWeight: FontWeight.w800,
                              color:      selected ? Colors.white : spec.color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
