// Accountant web app ke URL paths (go_router).
// Router: lib/core/routes/accountant_router.dart
//
//   /                                    (public website — login popup)
//   /login
//   /dashboard
//   /branches
//   /branches/:branchId
//   /branches/:branchId/:report          (sale-summary, profit-loss, ...)
//   /warehouses
//   /warehouses/:warehouseId?name=...
//   /warehouses/:warehouseId/finance | suppliers | suppliers/:supplierId
//                          | inventory | orders | stock-transfers
//                          | cash-transfers | reports | salary
//   /cash-transfers
//   /inventory-review
//   /investment
//   /inventory-counting                  (inventory_counter role)
//   /customer/:customerId                (customer portal)
class AccPaths {
  AccPaths._();

  static const home            = '/';
  static const splash          = '/splash';
  static const login           = '/login';
  static const dashboard       = '/dashboard';
  static const branches        = '/branches';
  static const warehouses      = '/warehouses';
  static const cashTransfers   = '/cash-transfers';
  static const inventoryReview = '/inventory-review';
  static const investment      = '/investment';
  static const inventoryCount  = '/inventory-counting';
  static const customerPrefix  = '/customer';

  static String customer(String id) => '$customerPrefix/${Uri.encodeComponent(id)}';

  static String branch(String branchId) =>
      '$branches/${Uri.encodeComponent(branchId)}';

  static String branchReport(String branchId, String report) =>
      '${branch(branchId)}/$report';

  /// Warehouse ka naam query mein — refresh par bhi title sahi rahe.
  static String warehouse(String warehouseId, {String? name, String sub = ''}) {
    final path = '$warehouses/${Uri.encodeComponent(warehouseId)}'
        '${sub.isEmpty ? '' : '/$sub'}';
    return Uri(
      path: path,
      queryParameters: (name == null || name.isEmpty) ? null : {'name': name},
    ).toString();
  }
}
