import 'package:flutter/material.dart';

/// Ek single action jo kisi module par ho sakta hai.
enum PermAction { view, create, edit, delete, export }

extension PermActionX on PermAction {
  String get label {
    switch (this) {
      case PermAction.view:   return 'View';
      case PermAction.create: return 'Add';
      case PermAction.edit:   return 'Edit';
      case PermAction.delete: return 'Delete';
      case PermAction.export: return 'Export';
    }
  }

  IconData get icon {
    switch (this) {
      case PermAction.view:   return Icons.visibility_outlined;
      case PermAction.create: return Icons.add_circle_outline;
      case PermAction.edit:   return Icons.edit_outlined;
      case PermAction.delete: return Icons.delete_outline;
      case PermAction.export: return Icons.download_outlined;
    }
  }
}

/// Ek module = sidebar ka ek screen / feature.
class PermModule {
  final String            key;
  final String            label;
  final IconData          icon;
  final List<PermAction>  actions;

  const PermModule({
    required this.key,
    required this.label,
    required this.icon,
    required this.actions,
  });

  /// Is module ki har action ki permission-key: `<module>.<action>`
  String actionKey(PermAction a) => '$key.${a.name}';
}

/// Modules ke logical groups (UI mein sections banane ke liye).
class PermGroup {
  final String            title;
  final IconData          icon;
  final List<PermModule>  modules;

  const PermGroup({
    required this.title,
    required this.icon,
    required this.modules,
  });
}

/// ── Poora permission catalog ──────────────────────────────────
/// `BranchSideBar` har `NavItem.permKey` ko yahan check karta hai
/// (`<key>.view`) taake sirf granted modules hi sidebar me dikhein.
class PermissionCatalog {
  PermissionCatalog._();

  static const _viewOnly = [PermAction.view, PermAction.export];
  static const _full = [
    PermAction.view,
    PermAction.create,
    PermAction.edit,
    PermAction.delete,
  ];

  static const List<PermGroup> groups = [
    PermGroup(
      title: 'Overview',
      icon:  Icons.dashboard_rounded,
      modules: [
        PermModule(
          key: 'dashboard', label: 'Dashboard',
          icon: Icons.dashboard_rounded, actions: [PermAction.view],
        ),
      ],
    ),
    PermGroup(
      title: 'Sales',
      icon:  Icons.point_of_sale_rounded,
      modules: [
        PermModule(
          key: 'sale_invoice', label: 'Sale Invoice',
          icon: Icons.point_of_sale_rounded, actions: _full,
        ),
        PermModule(
          key: 'sale_return', label: 'Sale Return',
          icon: Icons.assignment_return_outlined, actions: _full,
        ),
        PermModule(
          key: 'held_invoice', label: 'Held Invoices',
          icon: Icons.pause_circle_outline, actions: [
            PermAction.view, PermAction.edit, PermAction.delete,
          ],
        ),
        PermModule(
          key: 'service', label: 'Service',
          icon: Icons.build_outlined, actions: _full,
        ),
      ],
    ),
    PermGroup(
      title: 'Customers',
      icon:  Icons.people_alt_rounded,
      modules: [
        PermModule(
          key: 'customer', label: 'Customers',
          icon: Icons.people_alt_rounded, actions: _full,
        ),
        PermModule(
          key: 'customer_account', label: 'Customer Account',
          icon: Icons.account_box_outlined,
          actions: [PermAction.view, PermAction.create, PermAction.edit],
        ),
        PermModule(
          key: 'customer_ledger', label: 'Customer Ledger',
          icon: Icons.account_balance_wallet_rounded, actions: _viewOnly,
        ),
      ],
    ),
    PermGroup(
      title: 'Cash & Counter',
      icon:  Icons.savings_rounded,
      modules: [
        PermModule(
          key: 'cash_counter', label: 'Cash Counter',
          icon: Icons.savings_rounded,
          actions: [PermAction.view, PermAction.create, PermAction.edit],
        ),
        PermModule(
          key: 'cash_difference', label: 'Difference',
          icon: Icons.receipt_long_rounded,
          actions: [PermAction.view, PermAction.create],
        ),
        PermModule(
          key: 'branch_transaction', label: 'Branch Transactions',
          icon: Icons.compare_arrows_rounded,
          actions: [PermAction.view, PermAction.create],
        ),
        PermModule(
          key: 'counter', label: 'Counters',
          icon: Icons.point_of_sale_outlined, actions: _full,
        ),
      ],
    ),
    PermGroup(
      title: 'Stock',
      icon:  Icons.inventory_2_rounded,
      modules: [
        PermModule(
          key: 'branch_stock', label: 'Branch Stock',
          icon: Icons.inventory_2_rounded,
          actions: [PermAction.view, PermAction.edit, PermAction.export],
        ),
        PermModule(
          key: 'stock_transfer', label: 'Assign Stock to Branch',
          icon: Icons.local_shipping_rounded,
          actions: [PermAction.view, PermAction.edit],
        ),
        PermModule(
          key: 'stock_damage', label: 'Stock Damage',
          icon: Icons.report_gmailerrorred_outlined,
          actions: [PermAction.view, PermAction.create, PermAction.delete],
        ),
      ],
    ),
    PermGroup(
      title: 'Reports',
      icon:  Icons.bar_chart_rounded,
      modules: [
        PermModule(
          key: 'report_sale_invoice', label: 'Sale Invoice Report',
          icon: Icons.bar_chart_rounded, actions: _viewOnly,
        ),
        PermModule(
          key: 'report_sale_return', label: 'Sale Return Report',
          icon: Icons.bar_chart_rounded, actions: _viewOnly,
        ),
        PermModule(
          key: 'report_csr', label: 'CS&R Report',
          icon: Icons.bar_chart_rounded, actions: _viewOnly,
        ),
      ],
    ),
    PermGroup(
      title: 'Administration',
      icon:  Icons.admin_panel_settings_outlined,
      modules: [
        PermModule(
          key: 'users', label: 'Users',
          icon: Icons.manage_accounts_rounded, actions: _full,
        ),
        PermModule(
          key: 'permissions', label: 'Permissions',
          icon: Icons.verified_user_outlined,
          actions: [PermAction.view, PermAction.edit],
        ),
        PermModule(
          key: 'backup', label: 'Backup',
          icon: Icons.backup_outlined,
          actions: [PermAction.view, PermAction.create],
        ),
      ],
    ),
  ];

  /// Flatten helper.
  static List<PermModule> get allModules =>
      groups.expand((g) => g.modules).toList();

  /// Har (module.action) permission-key ki poori list.
  static List<String> get allKeys => [
        for (final m in allModules)
          for (final a in m.actions) m.actionKey(a),
      ];

  /// ── Role → default granted keys ──────────────────────────────
  /// Naya user select karne par yeh baseline dikhayi jati hai.
  static Set<String> defaultsForRole(String role) {
    switch (role) {
      case 'store_owner':
        return allKeys.toSet(); // owner ke paas sab kuch

      case 'store_manager':
        return allKeys
            .where((k) => !k.startsWith('permissions.'))
            .toSet();

      case 'stock_officer':
        return _keysFor([
          'dashboard', 'sale_invoice', 'sale_return', 'customer',
          'customer_account', 'customer_ledger', 'cash_counter',
          'cash_difference', 'branch_transaction', 'branch_stock',
          'stock_transfer', 'stock_damage', 'report_sale_invoice',
          'report_sale_return', 'report_csr',
        ]);

      case 'cashier':
      default:
        return _keysFor([
          'sale_invoice', 'customer', 'customer_account',
          'customer_ledger', 'cash_counter', 'branch_stock',
          'stock_transfer', 'report_csr',
        ], readOnlyStock: true);
    }
  }

  static Set<String> _keysFor(List<String> moduleKeys,
      {bool readOnlyStock = false}) {
    final wanted = moduleKeys.toSet();
    final out = <String>{};
    for (final m in allModules) {
      if (!wanted.contains(m.key)) continue;
      for (final a in m.actions) {
        if (readOnlyStock &&
            m.key == 'branch_stock' &&
            a != PermAction.view) {
          continue;
        }
        out.add(m.actionKey(a));
      }
    }
    return out;
  }
}
