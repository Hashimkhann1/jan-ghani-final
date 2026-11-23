// Updated on 2026-11-23 12:33 PM
// =============================================================
// warehouse_permission_catalog.dart — WAREHOUSE permissions (S31)
//
// Branch ke `PermissionCatalog` jaisa, lekin warehouse ke modules +
// actions. Har permission-key = `<module>.<action>` (e.g. 'supplier.pay').
//
//   • Sidebar har NavItem ka `<permKey>.view` check karta hai.
//   • Screens apne buttons `WarehouseAccess.can('<module>.<action>')`
//     se chhupati / band karti hain.
//   • OWNER = hamesha full access (lock) — kisi ka bhi access de / le
//     sakta hai (Manager ka bhi). Manager default mein sab kuch, lekin
//     Owner us ka access kam kar sakta hai. Staff / Data Entry defaults =
//     S31 se pehle wale role menus.
// =============================================================

import 'package:flutter/material.dart';

/// Ek action jo kisi module par ho sakta hai.
class WhPermAction {
  final String   key;
  final String   label;
  final IconData icon;
  final bool     danger;   // Delete / Reverse — laal rang

  const WhPermAction(this.key, this.label, this.icon, {this.danger = false});

  static const view    = WhPermAction('view',    'View',    Icons.visibility_outlined);
  static const create  = WhPermAction('create',  'Add',     Icons.add_circle_outline);
  static const edit    = WhPermAction('edit',    'Edit',    Icons.edit_outlined);
  static const delete  = WhPermAction('delete',  'Delete',  Icons.delete_outline, danger: true);
  static const approve = WhPermAction('approve', 'Accept / Reject', Icons.fact_check_outlined);
  static const pay     = WhPermAction('pay',     'Pay',     Icons.payments_outlined);
  static const reverse = WhPermAction('reverse', 'Reverse', Icons.undo_rounded, danger: true);
  static const ret     = WhPermAction('return',  'Return',  Icons.assignment_return_outlined);
  static const password = WhPermAction('password', 'Password', Icons.key_rounded);
  // Stock: info edit aur qty edit ALAG (key 'edit' wahi rehti hai)
  static const editInfo = WhPermAction('edit', 'Edit info', Icons.edit_outlined);
  static const qty      = WhPermAction('qty', 'Qty edit', Icons.exposure_outlined);
}

/// Ek module = sidebar ka ek screen / feature.
class WhPermModule {
  final String             key;
  final String             label;
  final String             hint;     // chhoti si wazahat (editor mein)
  final IconData           icon;
  final List<WhPermAction> actions;  // pehla hamesha `view`

  const WhPermModule({
    required this.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.actions,
  });

  String actionKey(WhPermAction a) => '$key.${a.key}';
  String get viewKey => '$key.view';
}

class WhPermGroup {
  final String             title;
  final List<WhPermModule> modules;
  const WhPermGroup(this.title, this.modules);
}

class WarehousePermissionCatalog {
  WarehousePermissionCatalog._();

  // ── Module keys (screens / sidebar inhi ko use karte hain) ──
  static const dashboard        = 'dashboard';
  static const reports          = 'reports';
  static const stock            = 'stock';
  static const assignStock      = 'assign_stock';
  static const branchReturns    = 'branch_returns';
  static const inventoryBalance = 'inventory_balance';
  static const category         = 'category';
  static const company          = 'company';
  static const purchaseOrder    = 'purchase_order';
  static const supplier         = 'supplier';
  static const finance          = 'finance';
  static const cashRequest      = 'cash_request';
  static const expense          = 'expense';
  static const salary           = 'salary';
  static const employee         = 'employee';
  static const linkStores       = 'link_stores';
  static const users            = 'users';
  static const permissions      = 'permissions';
  static const backup           = 'backup';

  static const _v = WhPermAction.view;
  static const _c = WhPermAction.create;
  static const _e = WhPermAction.edit;
  static const _d = WhPermAction.delete;

  static const List<WhPermGroup> groups = [
    WhPermGroup('Overview', [
      WhPermModule(key: dashboard, label: 'Dashboard',
          hint: 'Cash, purchases, dues, low stock ka overview',
          icon: Icons.dashboard_outlined, actions: [_v]),
      WhPermModule(key: reports, label: 'Reports',
          hint: 'Inventory, purchase, supplier, cash flow, expense reports',
          icon: Icons.bar_chart_rounded, actions: [_v]),
    ]),
    WhPermGroup('Inventory', [
      WhPermModule(key: stock, label: 'Stock',
          hint: 'Add = naya product · Edit info = naam, barcode, price, category wagaira · Qty edit = stock ki miqdar',
          icon: Icons.inventory_2_outlined,
          actions: [_v, _c, WhPermAction.editInfo, WhPermAction.qty, _d]),
      WhPermModule(key: assignStock, label: 'Assign Stock',
          hint: 'Add = branch ko stock bhejna',
          icon: Icons.move_to_inbox_outlined, actions: [_v, _c]),
      WhPermModule(key: branchReturns, label: 'Branch Returns',
          hint: 'Branch se wapas aaya stock accept / reject',
          icon: Icons.assignment_return_outlined,
          actions: [_v, WhPermAction.approve]),
      WhPermModule(key: inventoryBalance, label: 'Inventory Balance',
          hint: 'Add = store counting se balance request banana',
          icon: Icons.rule_folder_outlined, actions: [_v, _c]),
      WhPermModule(key: category, label: 'Category',
          hint: 'Product categories',
          icon: Icons.category_outlined, actions: [_v, _c, _e]),
      WhPermModule(key: company, label: 'Company',
          hint: 'Product companies',
          icon: Icons.business_outlined, actions: [_v, _c, _e, _d]),
    ]),
    WhPermGroup('Purchasing', [
      WhPermModule(key: purchaseOrder, label: 'Purchase Order',
          hint: 'Add = naya PO, Edit = PO badalna, Return = supplier ko maal wapas',
          icon: Icons.receipt_long_outlined,
          actions: [_v, _c, _e, WhPermAction.ret]),
      WhPermModule(key: supplier, label: 'Supplier',
          hint: 'Pay = supplier ko payment, Reverse = galat payment ulti karna',
          icon: Icons.local_shipping_outlined,
          actions: [_v, _c, _e, _d, WhPermAction.pay, WhPermAction.reverse]),
    ]),
    WhPermGroup('Finance', [
      WhPermModule(key: finance, label: 'Finance',
          hint: 'Cash in hand + transactions, Add = Cash In',
          icon: Icons.account_balance_wallet_outlined, actions: [_v, _c]),
      WhPermModule(key: cashRequest, label: 'Cash Requests',
          hint: 'Accountant se aaya cash — accept / reject (har screen ka card bhi)',
          icon: Icons.request_quote_outlined,
          actions: [_v, WhPermAction.approve]),
      WhPermModule(key: expense, label: 'Expense',
          hint: 'Kharche — Add / Edit',
          icon: Icons.money_off_outlined, actions: [_v, _c, _e]),
      WhPermModule(key: salary, label: 'Salary',
          hint: 'Pay = salary / advance dena',
          icon: Icons.badge_outlined,
          actions: [_v, WhPermAction.pay]),
      WhPermModule(key: employee, label: 'Employees',
          hint: 'Salary screen ka Employees button — employee add / edit / delete',
          icon: Icons.groups_outlined, actions: [_v, _c, _e, _d]),
    ]),
    WhPermGroup('Admin', [
      WhPermModule(key: linkStores, label: 'Link Stores',
          hint: 'Add = naya store link karna',
          icon: Icons.store_outlined, actions: [_v, _c]),
      WhPermModule(key: users, label: 'Users',
          hint: 'Permissions screen se: Add = naya user · Edit = naam / role · Delete = user hatana · Password = password badlna',
          icon: Icons.person_outline,
          actions: [_v, _c, _e, _d, WhPermAction.password]),
      WhPermModule(key: permissions, label: 'Permissions',
          hint: 'Yahi screen — Edit = doosron ka access badalna',
          icon: Icons.verified_user_outlined, actions: [_v, _e]),
      WhPermModule(key: backup, label: 'Backup',
          hint: 'Add = naya backup lena',
          icon: Icons.backup_outlined, actions: [_v, _c]),
    ]),
  ];

  static List<WhPermModule> get allModules =>
      groups.expand((g) => g.modules).toList();

  static List<String> get allKeys => [
        for (final m in allModules)
          for (final a in m.actions) m.actionKey(a),
      ];

  static WhPermModule? moduleOf(String key) {
    for (final m in allModules) {
      if (m.key == key) return m;
    }
    return null;
  }

  // ── Roles ───────────────────────────────────────────────────
  static const roles = [
    'warehouse_owner', 'warehouse_manager', 'warehouse_staff', 'data_entry',
  ];

  static String roleLabel(String role) {
    switch (role) {
      case 'warehouse_owner':   return 'Owner';
      case 'warehouse_manager': return 'Manager';
      case 'warehouse_staff':   return 'Staff';
      case 'data_entry':        return 'Data Entry';
      default:                  return role;
    }
  }

  /// Is role ke paas HAMESHA sab kuch (editor mein lock) — Owner.
  static bool isFullAccessRole(String role) => role == 'warehouse_owner';

  /// Kya `editorRole` wala user `targetRole` wale ka access badal sakta hai?
  /// Owner → sab ka (Owner khud lock). Baaki → sirf Staff / Data Entry
  /// (Manager ka access sirf Owner badalta hai).
  /// Kya editor `target` ka password badal sakta hai?
  /// Owner → sab ka. Baaki → `users.password` chahiye, aur sirf apna
  /// ya Staff / Data Entry ka (Owner / doosre Manager ka NAHI).
  /// Manager default mein `users.password` rakhta hai; Owner hata sakta hai.
  static bool canChangePassword({
    required String      editorId,
    required String      editorRole,
    required Set<String> editorKeys,
    required String      targetId,
    required String      targetRole,
  }) {
    if (isFullAccessRole(editorRole)) return true;
    if (!editorKeys.contains('$users.password')) return false;
    if (editorId == targetId) return true;
    return canEditRole(editorRole, targetRole);
  }

  /// Kya editor `target` ka naam / role badal sakta hai? (Permissions
  /// screen ka "Naam / Role" button)
  /// Owner → sab ka (apna bhi). Baaki → `users.edit` + sirf Staff /
  /// Data Entry ka (apna, Owner, Manager ka NAHI).
  static bool canEditUser({
    required String      editorId,
    required String      editorRole,
    required Set<String> editorKeys,
    required String      targetId,
    required String      targetRole,
  }) {
    if (isFullAccessRole(editorRole)) return true;
    if (!editorKeys.contains('$users.edit')) return false;
    if (editorId == targetId) return false;
    return canEditRole(editorRole, targetRole);
  }

  /// Naya user — Owner hamesha; baaki `users.create` se (sirf Staff /
  /// Data Entry role de sakte — `assignableRoles`).
  static bool canCreateUser(String editorRole, Set<String> editorKeys) =>
      isFullAccessRole(editorRole) || editorKeys.contains('$users.create');

  /// User delete — apna kabhi nahi. Owner → baaki sab; dusre → `users.delete`
  /// + sirf Staff / Data Entry.
  static bool canDeleteUser({
    required String      editorId,
    required String      editorRole,
    required Set<String> editorKeys,
    required String      targetId,
    required String      targetRole,
  }) {
    if (editorId == targetId) return false;
    if (isFullAccessRole(editorRole)) return true;
    if (!editorKeys.contains('$users.delete')) return false;
    return canEditRole(editorRole, targetRole);
  }

  /// Editor kaun se role de sakta hai. Owner → sab; baaki → sirf Staff /
  /// Data Entry (apne se ooncha role nahi de sakte).
  static List<String> assignableRoles(String editorRole) =>
      isFullAccessRole(editorRole)
          ? roles
          : const ['warehouse_staff', 'data_entry'];

  static bool canEditRole(String editorRole, String targetRole) {
    if (isFullAccessRole(targetRole)) return false;
    if (isFullAccessRole(editorRole)) return true;
    return targetRole != 'warehouse_manager';
  }

  /// Role → default granted keys (us module ke saare actions).
  /// Owner + Manager = sab; Staff / Data Entry = S31 se pehle ke menus.
  static Set<String> defaultsForRole(String role) {
    switch (role) {
      case 'warehouse_owner':
      case 'warehouse_manager':
        return allKeys.toSet();
      case 'data_entry':
        return _keysFor(const [
          stock, branchReturns, category, company,
          supplier,
          finance, cashRequest, expense, salary, employee,
        ]);
      case 'warehouse_staff':
      default:
        return _keysFor(const [
          reports,
          stock, branchReturns, inventoryBalance, category, company,
          purchaseOrder, supplier,
          finance, cashRequest, expense, salary, employee,
          backup,
        ]);
    }
  }

  static Set<String> _keysFor(List<String> moduleKeys) {
    final wanted = moduleKeys.toSet();
    return {
      for (final m in allModules)
        if (wanted.contains(m.key))
          for (final a in m.actions) m.actionKey(a),
    };
  }
}
