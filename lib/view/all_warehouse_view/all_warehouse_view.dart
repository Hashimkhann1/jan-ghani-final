import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/model/warehouse_model/warehouse_model.dart';
import 'package:jan_ghani_final/utils/app_colors/app_colors.dart';
import 'package:jan_ghani_final/utils/dialogs/warehouse_dialogs/warehouse_dialogs.dart';
import 'package:jan_ghani_final/view_model/warehouse_view_model/all_warehouse_provider/all_warehouse_provider.dart';

class AllWarehouseView extends ConsumerWidget {
  const AllWarehouseView({super.key});

  static const _border = Color(0xFFE9ECEF);
  static const _subText = Color(0xFF6C757D);
  static const _headerText = Color(0xFF212529);
  static const _green = AppColors.primaryColors;
  static const _bg = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(allWarehouseProvider);
    final notifier = ref.read(allWarehouseProvider.notifier);

    return Scaffold(
      backgroundColor: _bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(context, notifier),
            const SizedBox(height: 20),
            _buildStatCards(state),
            const SizedBox(height: 24),
            _buildWarehousesSection(context, state, notifier),
          ],
        ),
      ),
    );
  }

  // ── Page Header ───────────────────────────────────────────────────────────
  Widget _buildPageHeader(
      BuildContext context, AllWarehouseNotifier notifier) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon + title
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warehouse_outlined,
                  color: _green, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Warehouse Management',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _headerText)),
                SizedBox(height: 2),
                Text('Manage warehouses, stock levels, and transfers',
                    style: TextStyle(fontSize: 13, color: _subText)),
              ],
            ),
          ],
        ),
        const Spacer(),
        // Transfer Stock button
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.swap_horiz, size: 16),
          label: const Text('Transfer Stock'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _headerText,
            side: const BorderSide(color: _border),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ── Stat Cards ────────────────────────────────────────────────────────────
  Widget _buildStatCards(WarehouseState state) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.warehouse_outlined,
          iconColor: const Color(0xFF6C757D),
          label: 'Warehouses',
          value: '${state.warehouseCount}',
        ),
        const SizedBox(width: 14),
        _StatCard(
          icon: Icons.category_outlined,
          iconColor: const Color(0xFF6366F1),
          label: 'Unique Products',
          value: '${state.uniqueProducts}',
        ),
        const SizedBox(width: 14),
        _StatCard(
          icon: Icons.widgets_outlined,
          iconColor: const Color(0xFF6C757D),
          label: 'Total Units',
          value: '${state.totalUnits}',
        ),
        const SizedBox(width: 14),
        _StatCard(
          icon: Icons.trending_up,
          iconColor: const Color(0xFF6C757D),
          label: 'Low Stock',
          value: '${state.lowStockTotal}',
        ),
      ],
    );
  }

  // ── Warehouses Section ────────────────────────────────────────────────────
  Widget _buildWarehousesSection(BuildContext context,
      WarehouseState state, AllWarehouseNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title + Add button
        Row(
          children: [
            const Text('Warehouses',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _headerText)),
            const Spacer(),
            ElevatedButton.icon(
              // Add button:
              onPressed: () => showCreateWarehouseDialog(context, onSave: (w) {
                notifier.addWarehouse(w);
                _showSuccessSnack(context, 'Warehouse created successfully');
              }),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Empty state or grid
        state.warehouses.isEmpty
            ? _buildEmptyState(context, notifier)
            : _buildWarehouseGrid(context, state, notifier),
      ],
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState(
      BuildContext context, AllWarehouseNotifier notifier) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warehouse_outlined,
              size: 52, color: Color(0xFF9E9E9E)),
          const SizedBox(height: 16),
          const Text('No Warehouses Yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _headerText)),
          const SizedBox(height: 6),
          const Text(
              'Create your first warehouse to start tracking stock.',
              style: TextStyle(fontSize: 13, color: _subText)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => showCreateWarehouseDialog(context, onSave: (w) {
              notifier.addWarehouse(w);
              _showSuccessSnack(context, 'Warehouse created successfully');
            }),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Warehouse'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Warehouse Grid ────────────────────────────────────────────────────────
  Widget _buildWarehouseGrid(BuildContext context, WarehouseState state,
      AllWarehouseNotifier notifier) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        mainAxisExtent: 205,
      ),
      itemCount: state.warehouses.length,
      itemBuilder: (_, i) => _WarehouseCard(
        warehouse: state.warehouses[i],
        onDelete: () => notifier.removeWarehouse(state.warehouses[i].id),
        onEdit: () => showEditWarehouseDialog(context,
          warehouse: state.warehouses[i],
          onSave: (w) => notifier.updateWarehouse(w),
        ),
      ),
    );
  }


  void _showSuccessSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.greenColor,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 26, color: iconColor),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6C757D))),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF212529))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WAREHOUSE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _WarehouseCard extends StatefulWidget {
  final WarehouseModel warehouse;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _WarehouseCard({
    required this.warehouse,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_WarehouseCard> createState() => _WarehouseCardState();
}

class _WarehouseCardState extends State<_WarehouseCard> {
  static const _green = AppColors.primaryColors;
  static const _border = Color(0xFFE9ECEF);
  static const _subText = Color(0xFF6C757D);

  @override
  Widget build(BuildContext context) {
    final w = widget.warehouse;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warehouse_outlined,
                    color: _green, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF212529))),
                    Text(w.code,
                        style: const TextStyle(
                            fontSize: 12, color: _subText)),
                  ],
                ),
              ),
              // More options
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    size: 18, color: _subText),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                onSelected: (v) {
                  if (v == 'edit') widget.onEdit();
                  if (v == 'delete') _confirmDelete(context);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 15),
                        SizedBox(width: 8),
                        Text('Edit', style: TextStyle(fontSize: 13)),
                      ])),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline,
                            size: 15, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(
                                fontSize: 13, color: Colors.red)),
                      ])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Stats row ──────────────────────────────────────────────
          Row(
            children: [
              _MiniStat(label: 'Products', value: '${w.productCount}'),
              const SizedBox(width: 8),
              _MiniStat(label: 'Units', value: '${w.unitCount}'),
              const SizedBox(width: 8),
              _MiniStat(
                label: 'Low Stock',
                value: '${w.lowStockCount}',
                valueColor:
                w.lowStockCount > 0 ? _green : _green,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Address + phone ────────────────────────────────────────
          if (w.address != null && w.address!.isNotEmpty)
            Row(children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: _subText),
              const SizedBox(width: 4),
              Text(w.address!,
                  style: const TextStyle(
                      fontSize: 12, color: _subText)),
            ]),
          if (w.phone != null && w.phone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.phone_outlined,
                  size: 13, color: _subText),
              const SizedBox(width: 4),
              Text(w.phone!,
                  style: const TextStyle(
                      fontSize: 12, color: _subText)),
            ]),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Warehouse?',
            style:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to delete "${widget.warehouse.name}"? This cannot be undone.',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              widget.onDelete();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MINI STAT (inside warehouse card)
// ─────────────────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MiniStat(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF9E9E9E))),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? const Color(0xFF212529))),
          ],
        ),
      ),
    );
  }
}
