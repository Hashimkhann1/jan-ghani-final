import 'package:flutter/material.dart';
import 'package:jan_ghani_final/utils/app_colors/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

enum AlertType { outOfStock, overstock, lowStock }

class _AlertItem {
  final String name;
  final String sku;
  final String message;
  final AlertType type;

  const _AlertItem({
    required this.name,
    required this.sku,
    required this.message,
    required this.type,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// INVENTORY ALERT VIEW
// ─────────────────────────────────────────────────────────────────────────────

class InventoryAlertView extends StatelessWidget {
  const InventoryAlertView({super.key});

  static const _border = Color(0xFFE9ECEF);
  static const _subText = Color(0xFF6C757D);
  static const _headerText = Color(0xFF212529);

  static const List<_AlertItem> _alerts = [
    _AlertItem(
      name: 'Coke',
      sku: 'ctp',
      message: 'Coke is out of stock\nCurrent: 0 | Min: 10',
      type: AlertType.outOfStock,
    ),
    _AlertItem(
      name: 'DBR Herbal Soap',
      sku: 'DBR-NFPU7C',
      message: 'DBR Herbal Soap has excess stock (14233 units)',
      type: AlertType.overstock,
    ),
    _AlertItem(
      name: 'DBR Whitening Cream',
      sku: 'DBR-DQLZD8',
      message: 'DBR Whitening Cream has excess stock (349 units)',
      type: AlertType.overstock,
    ),
    _AlertItem(
      name: 'DBR Zuni Seerum',
      sku: 'DBR-TWGMKH',
      message: 'DBR Zuni Seerum has excess stock (30759 units)',
      type: AlertType.overstock,
    ),
    _AlertItem(
      name: 'safeguard',
      sku: 'SAF-VSLFB0',
      message: 'safeguard has excess stock (1007 units)',
      type: AlertType.overstock,
    ),
    _AlertItem(
      name: 'Shampoo',
      sku: 'SHA-MWVDFF',
      message: 'Shampoo has excess stock (3596 units)',
      type: AlertType.overstock,
    ),
  ];

  int get _outOfStockCount =>
      _alerts.where((a) => a.type == AlertType.outOfStock).length;
  int get _lowStockCount =>
      _alerts.where((a) => a.type == AlertType.lowStock).length;
  int get _totalAlerts => _alerts.length;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: Inventory Alerts ──────────────────────────────────────
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 20, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        const Text(
                          'Inventory Alerts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _headerText,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.redColors,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_outOfStockCount} Critical',
                            style: const TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Alert items
                  ..._alerts.map((alert) => _AlertTile(alert: alert)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // ── Right: Alert Summary ────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Alert Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _headerText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    label: 'Out of Stock',
                    count: _outOfStockCount,
                    bg: const Color(0xFFFFF1F2),
                    countColor: AppColors.redColors,
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Low Stock',
                    count: _lowStockCount,
                    bg: const Color(0xFFFFFBEB),
                    countColor: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Warning Alerts',
                    count: 0,
                    bg: const Color(0xFFF8F9FA),
                    countColor: _headerText,
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Total Alerts',
                    count: _totalAlerts,
                    bg: const Color(0xFFF8F9FA),
                    countColor: _headerText,
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ALERT TILE
// ─────────────────────────────────────────────────────────────────────────────

class _AlertTile extends StatelessWidget {
  final _AlertItem alert;

  const _AlertTile({super.key, required this.alert});

  bool get _isCritical => alert.type == AlertType.outOfStock;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _isCritical ? const Color(0xFFFFF1F2) : AppColors.whiteColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isCritical
              ? AppColors.redColors.withOpacity(0.4)
              : const Color(0xFFE9ECEF),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Icon(
            _isCritical ? Icons.inventory_2_outlined : Icons.trending_up,
            size: 18,
            color: _isCritical
                ? AppColors.redColors
                : const Color(0xFF6C757D),
          ),
          const SizedBox(width: 10),
          // Name + SKU + message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      alert.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212529),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        alert.sku,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF495057),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6C757D),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Action button
          GestureDetector(
            onTap: () {},
            child: Text(
              _isCritical ? 'Reorder' : 'View',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _isCritical
                    ? AppColors.redColors
                    : const Color(0xFF495057),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY ROW
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final int count;
  final Color bg;
  final Color countColor;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.count,
    required this.bg,
    required this.countColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
                color: const Color(0xFF212529),
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: countColor,
            ),
          ),
        ],
      ),
    );
  }
}