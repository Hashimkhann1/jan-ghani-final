// =============================================================
// accountant_inventory_review_screen.dart
// Reviewer's main shell — 2 tabs:
//   1. Pending Review — accept/reject
//   2. History        — all statuses read-only
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

import '../provider/inventory_review_provider.dart';
import '../widget/review_history_panel.dart';
import '../widget/review_queue_panel.dart';

class AccountantInventoryReviewScreen extends ConsumerStatefulWidget {
  const AccountantInventoryReviewScreen({super.key});

  @override
  ConsumerState<AccountantInventoryReviewScreen> createState() =>
      _AccountantInventoryReviewScreenState();
}

class _AccountantInventoryReviewScreenState
    extends ConsumerState<AccountantInventoryReviewScreen>
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
    final queueState = ref.watch(reviewQueueProvider);
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
              child: const Icon(Icons.rule_folder_outlined,
                  size: 18, color: AppColor.primary),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inventory Review',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textDark)),
                Text('Warehouse ki balance requests review karo',
                    style: TextStyle(fontSize: 11, color: AppColor.textMuted)),
              ],
            ),
          ]),
        ),

        // Tab bar with badge for pending count
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabs,
            indicatorColor: AppColor.primary,
            indicatorWeight: 3,
            labelColor: AppColor.primary,
            unselectedLabelColor: AppColor.textMuted,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Pending Review'),
                    if (pendingCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColor.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$pendingCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'History'),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // Content
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              ReviewQueuePanel(),
              ReviewHistoryPanel(),
            ],
          ),
        ),
      ],
    );
  }
}
