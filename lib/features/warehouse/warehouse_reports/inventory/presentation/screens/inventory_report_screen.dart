import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/providers/assign_stock_report_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/presentation/widgets/warehouse_dashboard_widgets/warehouse_dashboard_widgets.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/inventory/presentation/providers/inventory_report_provider.dart';

// ─────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────

class InventoryReportScreen extends ConsumerWidget {
  const InventoryReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invData = ref.watch(inventoryReportProvider);

    if (invData.isLoading) {
      return const Scaffold(
        backgroundColor: AppColor.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColor.background,
      body: Column(
        children: [
          const _TopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Inventory summary cards ──────────────
                  _SummaryCardsRow(data: invData),
                  const SizedBox(height: 16),

                  // ── Category pie + stock health ──────────
                  _ChartsRow(data: invData),
                  const SizedBox(height: 16),

                  // ── Stock Transfers Report ───────────────
                  const _StockTransferSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.bar_chart_rounded, size: 18, color: AppColor.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Inventory Report',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColor.textPrimary)),
              Text('As of $dateStr  •  Active products only',
                  style: const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColor.primary.withOpacity(0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined, size: 13, color: AppColor.primary),
                SizedBox(width: 5),
                Text('Stock Report', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColor.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUMMARY CARDS — 4 inventory stats
// ─────────────────────────────────────────────────────────────

class _SummaryCardsRow extends StatelessWidget {
  final InventoryReportData data;
  const _SummaryCardsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DashStatCard(
          label: 'Total products',
          value: '${data.totalActive}',
          badge: 'Active',
          icon: Icons.inventory_2_outlined,
          color: AppColor.primary,
          barPercent: (data.totalActive / 500).clamp(0.0, 1.0),
        ),
        const SizedBox(width: 12),
        DashStatCard(
          label: 'Inventory value',
          value: 'Rs ${data.totalPurchaseValue.pkrFormat}',
          badge: 'Purchase cost',
          icon: Icons.currency_rupee_rounded,
          color: AppColor.success,
          barPercent: 1.0,
        ),
        const SizedBox(width: 12),
        DashStatCard(
          label: 'Reorder needed',
          value: '${data.needsReorderCount}',
          badge: data.needsReorderCount > 0 ? 'Order now' : 'All good',
          icon: Icons.shopping_cart_outlined,
          color: data.needsReorderCount > 0 ? AppColor.warning : AppColor.success,
          barPercent: data.totalActive > 0
              ? (data.needsReorderCount / data.totalActive).clamp(0.0, 1.0)
              : 0.0,
        ),
        const SizedBox(width: 12),
        DashStatCard(
          label: 'Out of stock',
          value: '${data.outOfStockCount}',
          badge: data.outOfStockCount > 0 ? 'Urgent' : 'All good',
          icon: Icons.remove_shopping_cart_outlined,
          color: data.outOfStockCount > 0 ? AppColor.error : AppColor.success,
          barPercent: data.totalActive > 0
              ? (data.outOfStockCount / data.totalActive).clamp(0.0, 1.0)
              : 0.0,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHARTS ROW — Pie (left) + Stock health (right)
// ─────────────────────────────────────────────────────────────

class _ChartsRow extends StatelessWidget {
  final InventoryReportData data;
  const _ChartsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _CategoryPieChart(data: data)),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: _StockHealthPanel(data: data)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CATEGORY PIE CHART
// ─────────────────────────────────────────────────────────────

class _CategoryPieChart extends StatefulWidget {
  final InventoryReportData data;
  const _CategoryPieChart({required this.data});

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int _touchedIndex = -1;

  static const _pieColors = [
    AppColor.primary,
    AppColor.info,
    AppColor.success,
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    AppColor.grey400,
  ];

  @override
  Widget build(BuildContext context) {
    final cats = widget.data.categoryBreakdown;
    final totalVal = widget.data.totalPurchaseValue;

    List<InventoryCategoryData> displayCats;
    if (cats.length <= 5) {
      displayCats = cats;
    } else {
      final top5 = cats.take(5).toList();
      final othersVal = cats.skip(5).fold<double>(0.0, (s, c) => s + c.totalValue);
      final othersCount = cats.skip(5).fold<int>(0, (s, c) => s + c.productCount);
      displayCats = [
        ...top5,
        InventoryCategoryData(categoryName: 'Others', totalValue: othersVal, productCount: othersCount),
      ];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(color: AppColor.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                alignment: Alignment.center,
                child: const Icon(Icons.pie_chart_outline_rounded, size: 14, color: AppColor.primary),
              ),
              const SizedBox(width: 8),
              const Text('Category-wise stock value',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColor.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('Rs ${totalVal.pkrFormat}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColor.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (displayCats.isEmpty || totalVal == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.pie_chart_outline_rounded, size: 36, color: AppColor.grey300),
                SizedBox(height: 8),
                Text('Koi category data nahi', style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
              ])),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 190, width: 190,
                  child: PieChart(PieChartData(
                    sections: displayCats.asMap().entries.map((e) {
                      final isTouched = e.key == _touchedIndex;
                      final pct = totalVal > 0 ? (e.value.totalValue / totalVal * 100) : 0.0;
                      return PieChartSectionData(
                        value: e.value.totalValue,
                        color: _pieColors[e.key % _pieColors.length],
                        radius: isTouched ? 72 : 62,
                        title: pct >= 6 ? '${pct.toStringAsFixed(0)}%' : '',
                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                      );
                    }).toList(),
                    centerSpaceRadius: 38,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                        setState(() {
                          if (!event.isInterestedForInteractions || response?.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = response!.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                  )),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: displayCats.asMap().entries.map((e) {
                      final isTouched = e.key == _touchedIndex;
                      final pct = totalVal > 0 ? (e.value.totalValue / totalVal * 100) : 0.0;
                      final color = _pieColors[e.key % _pieColors.length];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10,
                                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(e.value.categoryName,
                                    style: TextStyle(fontSize: 11,
                                        fontWeight: isTouched ? FontWeight.w700 : FontWeight.w500,
                                        color: isTouched ? AppColor.textPrimary : AppColor.textSecondary),
                                    overflow: TextOverflow.ellipsis),
                                Text('${e.value.productCount} products',
                                    style: const TextStyle(fontSize: 9, color: AppColor.textHint)),
                              ]),
                            ),
                            const SizedBox(width: 4),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('Rs ${e.value.totalValue.pkrFormat}',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                              Text('${pct.toStringAsFixed(1)}%',
                                  style: const TextStyle(fontSize: 9, color: AppColor.textHint)),
                            ]),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STOCK HEALTH PANEL
// ─────────────────────────────────────────────────────────────

class _StockHealthPanel extends StatelessWidget {
  final InventoryReportData data;
  const _StockHealthPanel({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.totalActive;
    final good = (total - data.lowStockCount - data.outOfStockCount).clamp(0, total);

    return SectionCard(
      headerIcon: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(color: AppColor.successLight, borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: const Icon(Icons.health_and_safety_outlined, size: 14, color: AppColor.success),
      ),
      title: 'Stock health',
      headerTrailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColor.successLight, borderRadius: BorderRadius.circular(10)),
        child: Text('$total products',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColor.success)),
      ),
      children: [
        _HealthRow(label: 'Good stock', count: good, total: total, color: AppColor.success, icon: Icons.check_circle_outline_rounded),
        _HealthRow(label: 'Low stock', count: data.lowStockCount, total: total, color: AppColor.warning, icon: Icons.warning_amber_rounded),
        _HealthRow(label: 'Out of stock', count: data.outOfStockCount, total: total, color: AppColor.error, icon: Icons.remove_shopping_cart_outlined),
        _HealthRow(label: 'Needs reorder', count: data.needsReorderCount, total: total, color: AppColor.info, icon: Icons.shopping_cart_outlined, isLast: true),
      ],
      footerLeft: 'Based on min stock levels',
    );
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final IconData icon;
  final bool isLast;

  const _HealthRow({
    required this.label, required this.count, required this.total,
    required this.color, required this.icon, this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: AppColor.grey100))),
      child: Column(children: [
        Row(children: [
          Container(width: 26, height: 26,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              alignment: Alignment.center,
              child: Icon(icon, size: 13, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColor.textPrimary))),
          Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 4),
          Text(total > 0 ? '(${(pct * 100).toStringAsFixed(0)}%)' : '',
              style: const TextStyle(fontSize: 10, color: AppColor.textSecondary)),
        ]),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct, minHeight: 5,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// STOCK TRANSFERS SECTION
// ═════════════════════════════════════════════════════════════

class _StockTransferSection extends ConsumerWidget {
  const _StockTransferSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transferReportProvider);

    if (state.isLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColor.grey200),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final transfers = state.transfers;
    final totalCost = transfers.fold<double>(0.0, (s, t) => s + t.totalCost);
    final totalSale = transfers.fold<double>(0.0, (s, t) => s + t.totalSalePrice);
    final totalItems = transfers.fold<int>(0, (s, t) => s + t.totalItems);
    final pendingCount = transfers.where((t) => t.status == 'pending').length;
    final acceptedCount = transfers.where((t) => t.status == 'accepted').length;

    // Store-wise breakdown
    final storeMap = <String, _StoreData>{};
    for (final t in transfers) {
      final s = storeMap[t.toStoreName];
      storeMap[t.toStoreName] = _StoreData(
        name: t.toStoreName,
        totalCost: (s?.totalCost ?? 0) + t.totalCost,
        totalItems: (s?.totalItems ?? 0) + t.totalItems,
        count: (s?.count ?? 0) + 1,
      );
    }
    final stores = storeMap.values.toList()
      ..sort((a, b) => b.totalCost.compareTo(a.totalCost));

    // Monthly trend — last 6 months
    final now = DateTime.now();
    final monthlyData = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i), 1);
      final inMonth = transfers.where((t) => t.assignedAt.year == m.year && t.assignedAt.month == m.month).toList();
      return _MonthData(
        label: _shortMonth(m.month),
        count: inMonth.length,
        cost: inMonth.fold(0.0, (s, t) => s + t.totalCost),
      );
    });
    final maxCount = monthlyData.map((m) => m.count).fold(0, (a, b) => a > b ? a : b);

    // Recent transfers (last 8)
    final recent = transfers.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section title ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            border: Border.all(color: AppColor.grey200),
          ),
          child: Row(
            children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(color: AppColor.info.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                alignment: Alignment.center,
                child: const Icon(Icons.local_shipping_outlined, size: 14, color: AppColor.info),
              ),
              const SizedBox(width: 8),
              const Text('Stock Transfers Report',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColor.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColor.infoLight, borderRadius: BorderRadius.circular(10)),
                child: Text('${transfers.length} total transfers',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColor.info)),
              ),
            ],
          ),
        ),

        // ── 4 Transfer stats ──────────────────────────────────
        Container(
          decoration: BoxDecoration(
            border: Border.symmetric(horizontal: BorderSide(color: AppColor.grey200)),
          ),
          child: Row(
            children: [
              _TransferStatTile(label: 'Total Transfers', value: '${transfers.length}', icon: Icons.swap_horiz_rounded, color: AppColor.info),
              _vDivider(),
              _TransferStatTile(label: 'Total Cost', value: 'Rs ${totalCost.pkrFormat}', icon: Icons.currency_rupee_rounded, color: AppColor.primary),
              _vDivider(),
              _TransferStatTile(label: 'Items Transferred', value: '$totalItems', icon: Icons.inventory_2_outlined, color: AppColor.success),
              _vDivider(),
              _TransferStatTile(label: 'Pending', value: '$pendingCount', icon: Icons.hourglass_empty_rounded, color: AppColor.warning),
            ],
          ),
        ),

        // ── Charts Row ────────────────────────────────────────
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColor.grey200))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store-wise bars
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: AppColor.grey200)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.storefront_outlined, size: 14, color: AppColor.info),
                        SizedBox(width: 6),
                        Text('Store-wise transfer value',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
                      ]),
                      const SizedBox(height: 14),
                      if (stores.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('Koi transfer nahi', style: TextStyle(fontSize: 12, color: AppColor.textSecondary))))
                      else
                        ...stores.take(6).map((s) => _StoreBar(store: s, maxCost: stores.first.totalCost)),
                    ],
                  ),
                ),
              ),

              // Monthly trend
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.bar_chart_rounded, size: 14, color: AppColor.primary),
                        SizedBox(width: 6),
                        Text('Monthly trend (transfers)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
                      ]),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 160,
                        child: _MonthlyBarChart(data: monthlyData, maxCount: maxCount),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Status row ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColor.grey100.withOpacity(0.4),
            border: Border(bottom: BorderSide(color: AppColor.grey200)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 13, color: AppColor.grey500),
              const SizedBox(width: 6),
              _StatusPill('Pending', pendingCount, AppColor.warning),
              const SizedBox(width: 8),
              _StatusPill('Accepted', acceptedCount, AppColor.success),
              const SizedBox(width: 8),
              _StatusPill('Other', transfers.length - pendingCount - acceptedCount, AppColor.grey500),
              const Spacer(),
              Text('Sale value: Rs ${totalSale.pkrFormat}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
            ],
          ),
        ),

        // ── Recent transfers table ─────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
            border: Border.all(color: AppColor.grey200),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
            child: Column(
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  color: AppColor.grey100,
                  child: const Row(
                    children: [
                      Expanded(flex: 2, child: _TblHeader('Transfer #')),
                      Expanded(flex: 2, child: _TblHeader('Store')),
                      Expanded(flex: 1, child: _TblHeader('Date')),
                      Expanded(flex: 1, child: _TblHeader('Items', align: TextAlign.center)),
                      Expanded(flex: 2, child: _TblHeader('Cost (Rs)', align: TextAlign.right)),
                      Expanded(flex: 1, child: _TblHeader('Status', align: TextAlign.center)),
                    ],
                  ),
                ),

                if (recent.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Koi transfer record nahi',
                        style: TextStyle(fontSize: 12, color: AppColor.textSecondary))),
                  )
                else
                  ...recent.asMap().entries.map((e) => _TransferRow(
                    item: e.value,
                    isLast: e.key == recent.length - 1,
                  )),

                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColor.grey100.withOpacity(0.5),
                    border: const Border(top: BorderSide(color: AppColor.grey100)),
                  ),
                  child: Row(
                    children: [
                      Text('Showing ${recent.length} of ${transfers.length} transfers',
                          style: const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
                      const Spacer(),
                      Text('Total: Rs ${totalCost.pkrFormat}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _vDivider() => Container(width: 1, height: 70, color: AppColor.grey200);
  static String _shortMonth(int m) =>
      ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

// Transfer stat tile
class _TransferStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _TransferStatTile({
    required this.label, required this.value,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: AppColor.surface,
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
                Text(label, style: const TextStyle(fontSize: 10, color: AppColor.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Store bar row
class _StoreData {
  final String name;
  final double totalCost;
  final int totalItems;
  final int count;
  const _StoreData({required this.name, required this.totalCost, required this.totalItems, required this.count});
}

class _StoreBar extends StatelessWidget {
  final _StoreData store;
  final double maxCost;
  const _StoreBar({required this.store, required this.maxCost});

  @override
  Widget build(BuildContext context) {
    final pct = maxCost > 0 ? (store.totalCost / maxCost).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(color: AppColor.infoLight, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(_initials(store.name),
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppColor.info)),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(store.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColor.textPrimary),
                    overflow: TextOverflow.ellipsis),
              ),
              Text('Rs ${store.totalCost.pkrFormat}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColor.info)),
              const SizedBox(width: 8),
              Text('${store.count} TRF  •  ${store.totalItems} items',
                  style: const TextStyle(fontSize: 10, color: AppColor.textSecondary)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct, minHeight: 7,
              backgroundColor: AppColor.infoLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColor.info),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
  }
}

// Monthly bar chart data
class _MonthData {
  final String label;
  final int count;
  final double cost;
  const _MonthData({required this.label, required this.count, required this.cost});
}

class _MonthlyBarChart extends StatelessWidget {
  final List<_MonthData> data;
  final int maxCount;
  const _MonthlyBarChart({required this.data, required this.maxCount});

  @override
  Widget build(BuildContext context) {
    if (maxCount == 0) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.bar_chart_rounded, size: 32, color: AppColor.grey300),
          SizedBox(height: 6),
          Text('Koi transfer data nahi', style: TextStyle(fontSize: 11, color: AppColor.textSecondary)),
        ]),
      );
    }

    return BarChart(
      BarChartData(
        maxY: (maxCount + 1).toDouble(),
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.count.toDouble(),
                color: e.value.count > 0 ? AppColor.primary : AppColor.grey200,
                width: 22,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColor.grey100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(data[idx].label,
                      style: const TextStyle(fontSize: 9, color: AppColor.textSecondary)),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColor.textPrimary,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final m = data[group.x];
              return BarTooltipItem(
                '${m.count} transfers\nRs ${m.cost.pkrFormat}',
                const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Status pill
class _StatusPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatusPill(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text('$label: $count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

// Table header cell
class _TblHeader extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _TblHeader(this.text, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), textAlign: align,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColor.grey600, letterSpacing: 0.4));
  }
}

// Transfer table row
class _TransferRow extends StatelessWidget {
  final TransferReportItem item;
  final bool isLast;
  const _TransferRow({required this.item, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final date = '${item.assignedAt.day} ${months[item.assignedAt.month - 1]}';

    final statusColor = item.status == 'accepted'
        ? AppColor.success
        : item.status == 'pending'
            ? AppColor.warning
            : AppColor.grey500;
    final statusBg = item.status == 'accepted'
        ? AppColor.successLight
        : item.status == 'pending'
            ? AppColor.warningLight
            : AppColor.grey100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColor.grey100)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2,
            child: Text(item.transferNumber,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColor.primary),
                overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2,
            child: Row(children: [
              const Icon(Icons.storefront_outlined, size: 12, color: AppColor.info),
              const SizedBox(width: 4),
              Expanded(child: Text(item.toStoreName,
                  style: const TextStyle(fontSize: 11, color: AppColor.textPrimary),
                  overflow: TextOverflow.ellipsis)),
            ])),
          Expanded(flex: 1,
            child: Text(date,
                style: const TextStyle(fontSize: 11, color: AppColor.textSecondary))),
          Expanded(flex: 1,
            child: Text('${item.totalItems}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColor.textPrimary))),
          Expanded(flex: 2,
            child: Text(item.totalCost.pkrFormat,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColor.textPrimary))),
          Expanded(flex: 1,
            child: Align(alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  item.status[0].toUpperCase() + item.status.substring(1),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
            )),
        ],
      ),
    );
  }
}
