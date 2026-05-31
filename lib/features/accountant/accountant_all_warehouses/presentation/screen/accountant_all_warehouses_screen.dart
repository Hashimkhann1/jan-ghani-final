import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../../accountant_warehouse_dashboard/presentation/screen/accountant_warehouse_dashboard_screen.dart';
import '../../data/model/accountant_warehouse_model.dart';
import '../provider/accountant_warehouse_provider.dart';

// =============================================================
// Accountant → All Warehouses (read-only)
// Sirf warehouses list. Warehouse tap → us warehouse ka dashboard
// (sirf usi warehouse ka inventory, suppliers, orders, transfers)
// =============================================================
class AccountantAllWarehousesScreen extends ConsumerStatefulWidget {
  const AccountantAllWarehousesScreen({super.key});

  @override
  ConsumerState<AccountantAllWarehousesScreen> createState() =>
      _AccountantAllWarehousesScreenState();
}

class _AccountantAllWarehousesScreenState
    extends ConsumerState<AccountantAllWarehousesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final warehousesAsync = ref.watch(accAllWarehousesProvider);

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Warehouses',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textDark,
                    ),
                  ),
                  const Text(
                    'Kisi warehouse ko tap karke uska data dekhein',
                    style: TextStyle(fontSize: 13, color: AppColor.textMuted),
                  ),
                ],
              ),
            ),

            // ── Search ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Warehouse dhoondein...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColor.textMuted),
                  filled: true,
                  fillColor: AppColor.grey100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ── List ──────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColor.primary,
                onRefresh: () async =>
                    ref.invalidate(accAllWarehousesProvider),
                child: warehousesAsync.when(
                  data: (all) {
                    final list = _query.isEmpty
                        ? all
                        : all
                            .where((w) =>
                                w.name.toLowerCase().contains(_query) ||
                                (w.code ?? '').toLowerCase().contains(_query))
                            .toList();

                    if (list.isEmpty) {
                      return ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text(
                              'Koi warehouse nahi mila',
                              style: TextStyle(color: AppColor.textMuted),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: list.length,
                      itemBuilder: (_, i) =>
                          _WarehouseTile(warehouse: list[i]),
                    );
                  },
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 6,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: _ShimmerBox(height: 76),
                    ),
                  ),
                  error: (e, _) => ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'Warehouses load nahi hue — pull to refresh',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Warehouse Tile ────────────────────────────────────────────────────────────
class _WarehouseTile extends StatelessWidget {
  final AccountantWarehouseModel warehouse;
  const _WarehouseTile({required this.warehouse});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AccountantWarehouseDashboardScreen(
            warehouseId: warehouse.id,
            warehouseName: warehouse.name,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warehouse_rounded,
                  color: AppColor.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warehouse.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColor.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (warehouse.code?.isNotEmpty == true) warehouse.code,
                      if (warehouse.address?.isNotEmpty == true)
                        warehouse.address,
                    ].whereType<String>().join('  •  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColor.textMuted),
                  ),
                ],
              ),
            ),
            if (!warehouse.isActive)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColor.cashOut.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  'Inactive',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColor.cashOut,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColor.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────
class _ShimmerBox extends StatelessWidget {
  final double height;
  const _ShimmerBox({required this.height});

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
      );
}
