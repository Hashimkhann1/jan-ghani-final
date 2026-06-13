import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/presentation/widgets/warehouse_dashboard_widgets/warehouse_dashboard_widgets.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/inventory/presentation/providers/inventory_report_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/data/model/product_model.dart';

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

class _StockHealthPanel extends ConsumerWidget {
  final InventoryReportData data;
  const _StockHealthPanel({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        _HealthRow(label: 'Low stock', count: data.lowStockCount, total: total, color: AppColor.warning, icon: Icons.warning_amber_rounded,
            onTap: () => _openStockHealth(context, ref, StockFilter.lowStock)),
        _HealthRow(label: 'Out of stock', count: data.outOfStockCount, total: total, color: AppColor.error, icon: Icons.remove_shopping_cart_outlined,
            onTap: () => _openStockHealth(context, ref, StockFilter.outOfStock)),
        _HealthRow(label: 'Needs reorder', count: data.needsReorderCount, total: total, color: AppColor.info, icon: Icons.shopping_cart_outlined, isLast: true,
            onTap: () => _openStockHealth(context, ref, StockFilter.needsReorder)),
      ],
      footerLeft: 'Tap a row to see products',
    );
  }

  // Stock Health row tap → products dikhana.
  //  • desktop → report ke activeProducts already memory mein (instant)
  //  • web     → products ON-DEMAND Supabase se (chhota loader, phir sheet)
  Future<void> _openStockHealth(
      BuildContext context, WidgetRef ref, StockFilter filter) async {
    if (!kIsWeb) {
      _showStockHealthSheet(context, data.activeProducts, filter);
      return;
    }

    // Web: agar pehle fetch ho chuke to turant, warna loader ke saath fetch
    final cached = ref.read(stockHealthProductsProvider);
    if (cached.hasValue) {
      _showStockHealthSheet(context, cached.value!, filter);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final products = await ref.read(stockHealthProductsProvider.future);
      if (context.mounted) Navigator.of(context).pop(); // loader band
      if (context.mounted) _showStockHealthSheet(context, products, filter);
    } catch (_) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Products load nahi hue')),
        );
      }
    }
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final IconData icon;
  final bool isLast;
  final VoidCallback? onTap;

  const _HealthRow({
    required this.label, required this.count, required this.total,
    required this.color, required this.icon, this.isLast = false, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    return InkWell(
      onTap: onTap,
      child: Container(
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
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 17, color: AppColor.grey400),
            ],
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
      ),
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
    // Platform-aware: web → Supabase, desktop/mobile → local (provider handle karta hai)
    final state = ref.watch(inventoryTransfersProvider);

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
    final totalItems = transfers.fold<int>(0, (s, t) => s + t.totalItems);
    final pendingCount = transfers.where((t) => t.status == 'pending').length;

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
          decoration: BoxDecoration(
            color: AppColor.surface,
            border: Border.all(color: AppColor.grey200),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
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

// ═════════════════════════════════════════════════════════════
// STOCK HEALTH DETAIL — BOTTOM SHEET
// ═════════════════════════════════════════════════════════════

enum StockFilter { all, outOfStock, lowStock, needsReorder }

extension _StockFilterX on StockFilter {
  String get label {
    switch (this) {
      case StockFilter.all:          return 'All';
      case StockFilter.outOfStock:   return 'Out of Stock';
      case StockFilter.lowStock:     return 'Low Stock';
      case StockFilter.needsReorder: return 'Needs Reorder';
    }
  }

  Color get color {
    switch (this) {
      case StockFilter.all:          return AppColor.primary;
      case StockFilter.outOfStock:   return AppColor.error;
      case StockFilter.lowStock:     return AppColor.warning;
      case StockFilter.needsReorder: return AppColor.info;
    }
  }

  bool matches(ProductModel p) {
    switch (this) {
      case StockFilter.all:          return true;
      case StockFilter.outOfStock:   return p.isTrackStock && p.quantity == 0;
      case StockFilter.lowStock:     return p.isLowStock;
      case StockFilter.needsReorder: return p.needsReorder;
    }
  }
}

void _showStockHealthSheet(
    BuildContext context, List<ProductModel> products, StockFilter initial) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StockHealthSheet(products: products, initial: initial),
  );
}

class _StockHealthSheet extends StatefulWidget {
  final List<ProductModel> products;
  final StockFilter initial;
  const _StockHealthSheet({required this.products, required this.initial});

  @override
  State<_StockHealthSheet> createState() => _StockHealthSheetState();
}

class _StockHealthSheetState extends State<_StockHealthSheet> {
  late StockFilter _filter = widget.initial;
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const _filters = [
    StockFilter.all,
    StockFilter.outOfStock,
    StockFilter.lowStock,
    StockFilter.needsReorder,
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int _count(StockFilter f) => widget.products.where(f.matches).length;

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtered = widget.products.where((p) {
      if (!_filter.matches(p)) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.quantity.compareTo(b.quantity)); // kam qty pehle

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColor.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Drag handle ─────────────────────────────────
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 42, height: 4,
                decoration: BoxDecoration(
                  color: AppColor.grey300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // ── Header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColor.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.inventory_2_outlined, size: 17, color: AppColor.success),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Stock Details',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.textPrimary)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColor.grey600),
                      splashRadius: 18,
                    ),
                  ],
                ),
              ),

              // ── Search ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search product name ya SKU...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColor.textHint),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColor.grey500),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16, color: AppColor.grey500),
                            splashRadius: 14,
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    filled: true,
                    fillColor: AppColor.surface,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColor.grey200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColor.primary),
                    ),
                  ),
                ),
              ),

              // ── Filter chips ────────────────────────────────
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final f = _filters[i];
                    final selected = f == _filter;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? f.color : AppColor.grey100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? f.color : AppColor.grey200),
                        ),
                        child: Row(
                          children: [
                            Text(f.label,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? AppColor.white : AppColor.grey600)),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: selected ? AppColor.white.withOpacity(0.25) : AppColor.grey200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${_count(f)}',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: selected ? AppColor.white : AppColor.grey600)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: AppColor.grey200),

              // ── Product list ────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined, size: 34, color: AppColor.grey300),
                            SizedBox(height: 8),
                            Text('Koi product nahi mila',
                                style: TextStyle(fontSize: 13, color: AppColor.textHint)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _ProductStockRow(product: filtered[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Single product row ──────────────────────────────────────
class _ProductStockRow extends StatelessWidget {
  final ProductModel product;
  const _ProductStockRow({required this.product});

  String _qtyStr(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final p = product;

    final String badge;
    final Color color;
    final Color bg;
    if (p.isTrackStock && p.quantity == 0) {
      badge = 'Out';     color = AppColor.error;   bg = AppColor.errorLight;
    } else if (p.isLowStock) {
      badge = 'Low';     color = AppColor.warning; bg = AppColor.warningLight;
    } else if (p.needsReorder) {
      badge = 'Reorder'; color = AppColor.info;    bg = AppColor.infoLight;
    } else {
      badge = 'OK';      color = AppColor.success;  bg = AppColor.successLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColor.grey100)),
      ),
      child: Row(
        children: [
          // Name + SKU
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('SKU: ${p.sku}',
                    style: const TextStyle(fontSize: 10, color: AppColor.textHint),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Qty / Min
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(children: [
                    TextSpan(text: _qtyStr(p.quantity),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                    TextSpan(text: ' ${p.unitOfMeasure}',
                        style: const TextStyle(fontSize: 10, color: AppColor.textHint)),
                  ]),
                ),
                const SizedBox(height: 2),
                Text('Min: ${p.minStockLevel}'
                    '${p.reorderPoint > 0 ? '  •  Reorder: ${p.reorderPoint}' : ''}',
                    style: const TextStyle(fontSize: 9, color: AppColor.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Text(badge,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}
