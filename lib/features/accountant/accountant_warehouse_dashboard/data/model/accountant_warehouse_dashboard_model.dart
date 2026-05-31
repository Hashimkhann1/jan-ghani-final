// =============================================================
// warehouse_dashboard_model.dart
// Accountant ke warehouse dashboard ka data model
// Supabase RPC: accountant_warehouse_dashboard_stats()
// =============================================================

class WarehouseDashboardModel {
  final int    totalSuppliers;
  final double totalOutstanding;
  final int    totalProducts;
  final double totalInventoryQty;
  final double totalInventoryValue;
  final double cashInHand;
  final int    totalOrders;
  final double totalOrdersValue;
  final int    totalTransfers;
  final double totalTransfersValue;
  final int    totalCashTransfers;
  final double totalCashTransfersValue;

  const WarehouseDashboardModel({
    required this.totalSuppliers,
    required this.totalOutstanding,
    required this.totalProducts,
    required this.totalInventoryQty,
    required this.totalInventoryValue,
    required this.cashInHand,
    required this.totalOrders,
    required this.totalOrdersValue,
    required this.totalTransfers,
    required this.totalTransfersValue,
    required this.totalCashTransfers,
    required this.totalCashTransfersValue,
  });

  factory WarehouseDashboardModel.fromMap(Map<String, dynamic> map) {
    return WarehouseDashboardModel(
      totalSuppliers:      _toInt(map['total_suppliers']),
      totalOutstanding:    _toDouble(map['total_outstanding']),
      totalProducts:       _toInt(map['total_products']),
      totalInventoryQty:   _toDouble(map['total_inventory_qty']),
      totalInventoryValue: _toDouble(map['total_inventory_value']),
      cashInHand:          _toDouble(map['cash_in_hand']),
      totalOrders:         _toInt(map['total_orders']),
      totalOrdersValue:    _toDouble(map['total_orders_value']),
      totalTransfers:      _toInt(map['total_transfers']),
      totalTransfersValue: _toDouble(map['total_transfers_value']),
      totalCashTransfers:      _toInt(map['total_cash_transfers']),
      totalCashTransfersValue: _toDouble(map['total_cash_transfers_value']),
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
