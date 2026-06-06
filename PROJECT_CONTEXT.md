# Jan Ghani POS — Project Context

## Overview
Flutter desktop POS (Point of Sale) system. Currently sirf **Warehouse module** develop ho raha hai. App macOS/Windows desktop per run karta hai. Teen features hain: **Warehouse**, **Branch (Store)**, aur **Accountant** — lekin abhi sirf **Warehouse per kaam kar rahe hain**, baaki koo bilkul touch nahi karna.

---

## Tech Stack

| | |
|---|---|
| **Framework** | Flutter (Desktop — macOS/Windows) |
| **State Management** | Riverpod (`flutter_riverpod: ^2.6.1`) — sirf `StateNotifierProvider` aur `Provider` use hote hain |
| **Local DB** | PostgreSQL via `postgres: ^3.5.9` — seedha local postgres se connect |
| **Remote DB** | Supabase (`supabase_flutter: ^2.12.4`) — local se sync hota hai |
| **Charts** | `fl_chart: ^1.2.0` |
| **PDF/Print** | `pdf`, `printing` |
| **Config** | `assets/json/config.json` se load hota hai `AppConfig` class ke through |

---

## App Configuration (`AppConfig`)
```dart
AppConfig.warehouseId   // current warehouse UUID
AppConfig.warehouseName // warehouse display name
AppConfig.warehouseCode
AppConfig.dbHost / dbPort / dbName / dbUser / dbPassword
AppConfig.appMode       // 'warehouse' ya 'store'
```

---

## Database
- **Local**: PostgreSQL (direct connection via `postgres` package, `DatabaseService.getConnection()` — async)
- **Remote**: Supabase (sync service chalti hai background mein)
- **Schema location**: `/Users/hashimkhan/Desktop/janghani pos resourses/db releated/schema v3/zero_start_schema/warehouse_zero_start_schema_v3.7.sql`

### Key Tables (Warehouse)
| Table | Description |
|---|---|
| `warehouse_products` | Products (barcode `text[]`, sku, prices, stock levels) |
| `warehouse_inventory` | Stock quantities per product (qty, reserved_quantity) |
| `warehouse_stock_movements` | Movement log (purchase_in, transfer_out, return_in, adjustment, opening) |
| `warehouse_categories` | Product categories |
| `purchase_orders` | POs (status: draft/ordered/partial/received/cancelled) |
| `purchase_order_items` | PO line items |
| `suppliers` | Suppliers (outstanding_balance auto-updated via trigger) |
| `supplier_ledger` | Supplier payment ledger |
| `stock_transfers` | Stock sent to stores (status: pending/accepted) |
| `stock_transfer_items` | Transfer line items |
| `linked_stores` | Stores linked to this warehouse |
| `warehouse_cash_transactions` | Cash entries (cash_in, purchase, supplier_payment, expense) |
| `warehouse_finance` | Cash in hand (auto-updated via trigger) |
| `warehouse_expenses` | Expense records |
| `warehouse_users` | Users (roles: warehouse_owner, warehouse_manager, warehouse_staff, data_entry) |

### Key DB Views
- `v_reorder_needed` — products below reorder point
- `v_supplier_balances` — supplier outstanding balances
- `v_daily_summary` — today's cash summary
- `v_warehouse_stock` — stock with available quantity

---

## Project Structure

```
lib/
├── core/
│   ├── color/app_color.dart          ← AppColor class (all colors)
│   ├── config/app_config.dart        ← AppConfig (loads config.json)
│   ├── extension/app_extention.dart  ← Extensions (pkrFormat, timeAgo, etc.)
│   ├── service/
│   │   ├── database_service/         ← DatabaseService.connection (postgres)
│   │   ├── stock_assign_services/    ← stock transfer sync
│   │   └── warehouse_supabase_sync_service/
│   └── widget/
│       ├── sidebar/
│       │   ├── sidebar_widget.dart       ← Warehouse sidebar (main nav)
│       │   └── branch_sidebar_widget.dart
│       └── nav_tile_widget.dart
│
└── features/
    ├── warehouse/                    ← HUM SIRF YAHAN KAM KARTE HAIN
    │   ├── auth/                     ← Login, AuthProvider
    │   ├── category/                 ← Product categories CRUD
    │   ├── assign_stock/             ← Stock assign to stores
    │   │   ├── data/datasources/
    │   │   │   ├── assign_stock_local_datasource.dart
    │   │   │   └── assign_stock_remote_datasource.dart
    │   │   └── presentation/providers/
    │   │       ├── assign_stock_provider.dart   ← cart state
    │   │       └── assign_stock_report_provider.dart  ← transferReportProvider
    │   ├── link_stores/              ← Link stores to warehouse
    │   ├── purchase_invoice/         ← Purchase Orders
    │   ├── supplier/                 ← Supplier management + ledger
    │   ├── warehouse_cash_requests/
    │   ├── warehouse_dashboard/      ← Dashboard screen + charts
    │   │   └── presentation/widgets/
    │   │       ├── warehouse_dashboard_widgets.dart  ← DashStatCard, SectionCard (REUSABLE)
    │   │       └── dashboard_chart_widgets.dart      ← PurchaseTrendChart, SupplierOutstandingChart
    │   ├── warehouse_expense/        ← Expenses
    │   ├── warehouse_finance/        ← Finance / Cash in hand
    │   ├── warehouse_stock_inventory/ ← Products + stock management
    │   │   └── presentation/provider/product_provider.dart  ← productProvider (ProductState)
    │   ├── warehouse_user/           ← User management
    │   └── warehouse_reports/        ← *** NAYA FEATURE (humne banaya) ***
    │       ├── presentation/screens/
    │       │   └── warehouse_reports_shell.dart        ← Reports shell (drawer + routing)
    │       ├── inventory/
    │       │   └── presentation/
    │       │       ├── providers/inventory_report_provider.dart
    │       │       └── screens/inventory_report_screen.dart
    │       ├── supplier/
    │       │   ├── data/datasources/supplier_report_local_datasource.dart
    │       │   └── presentation/
    │       │       ├── providers/supplier_report_provider.dart
    │       │       └── screens/supplier_report_screen.dart
    │       ├── purchase/
    │       │   ├── data/datasources/purchase_report_local_datasource.dart
    │       │   └── presentation/
    │       │       ├── providers/purchase_report_provider.dart
    │       │       └── screens/purchase_report_screen.dart
    │       └── cash_flow/
    │           ├── data/datasources/cash_flow_report_local_datasource.dart
    │           └── presentation/
    │               ├── providers/cash_flow_report_provider.dart
    │               └── screens/cash_flow_report_screen.dart
    │
    ├── accountant/                   ← TOUCH NAHI KARNA
    └── branch/                       ← TOUCH NAHI KARNA
```

---

## Core Colors (`AppColor`)
```dart
AppColor.primary       // #6C63FF (purple)
AppColor.success       // #4CAF50 (green)
AppColor.error         // #E53935 (red)
AppColor.warning       // #FFC107 (yellow)
AppColor.info          // #2196F3 (blue)
AppColor.successLight  // #E8F5E9
AppColor.errorLight    // #FFEBEE
AppColor.warningLight  // #FFF8E1
AppColor.infoLight     // #E3F2FD
AppColor.grey100-900   // greys
AppColor.textPrimary   // #212121
AppColor.textSecondary // #757575
AppColor.textHint      // #BDBDBD
AppColor.surface/white // #FFFFFF
AppColor.background    // white
```

---

## Navigation Structure (`sidebar_widget.dart`)

```
SideBar (90px wide sidebar)
├── Role: warehouse_manager → Full nav (Dashboard, Stock, Purchase, Supplier, Assign Stock, Category, Finance, Expense, Link Stores, User, Reports)
├── Role: warehouse_owner / default → (Stock, Purchase, Supplier, Category, Finance, Expense, Reports)
└── Role: data_entry → (Stock, Supplier, Category, Finance, Expense)
```

**Special handling for Reports:**
```dart
// Reports item mein screen: const SizedBox.shrink()
// Sidebar _buildContent() mein check:
if (item.label == 'Reports') {
  return WarehouseReportsShell(
    onBack: () => setState(() => _index = 0), // Dashboard par wapis
  );
}
```
Jab Reports select ho, main 90px sidebar HIDE ho jata hai, sirf shell full-screen show hoti hai.

---

## Reports Shell (`WarehouseReportsShell`)

**File:** `lib/features/warehouse/warehouse_reports/presentation/screens/warehouse_reports_shell.dart`

- Apna **collapsible left drawer** hai (44px collapsed, 192px expanded)
- Default: **drawer closed**
- **Back button** → Dashboard (`onBack` callback)
- **Reports list** (5 items):
  1. Inventory  — ACTIVE ✅ (`InventoryReportScreen`)
  2. Purchases  — ACTIVE ✅ (`PurchaseReportScreen`)
  3. Transfers  — Coming Soon (abhi tak nahi bana)
  4. Suppliers  — ACTIVE ✅ (`SupplierReportScreen`)
  5. Cash Flow  — ACTIVE ✅ (`CashFlowReportScreen`)

**Animation fix:** `OverflowBox` + `SizedBox` inside `AnimatedContainer` with `Clip.hardEdge` — ye zaroori hai warna layout overflow errors aate hain during animation.
```dart
AnimatedContainer(
  width: _drawerOpen ? 192 : 44,
  clipBehavior: Clip.hardEdge,
  decoration: const BoxDecoration(),
  child: OverflowBox(
    minWidth: _drawerOpen ? 192 : 44,
    maxWidth: _drawerOpen ? 192 : 44,
    child: SizedBox(
      width: _drawerOpen ? 192 : 44,
      child: _drawerOpen ? _ExpandedDrawer(...) : _CollapsedRail(...),
    ),
  ),
)
```

---

## Inventory Report (`inventoryReportProvider` + `InventoryReportScreen`)

**Provider file:** `lib/features/warehouse/warehouse_reports/inventory/presentation/providers/inventory_report_provider.dart`
- `inventoryReportProvider` → `Provider<InventoryReportData>` — `productProvider` se derive hota hai, koi DB call nahi
- Computes: totalActive, lowStockCount, outOfStockCount, needsReorderCount, totalPurchaseValue, totalSellingValue, categoryBreakdown, reorderProducts, activeProducts

**Screen file:** `lib/features/warehouse/warehouse_reports/inventory/presentation/screens/inventory_report_screen.dart`
- **4 Summary Cards** — Total products, Inventory value, Reorder needed, Out of stock
- **Pie Chart** — Category-wise stock value (fl_chart, touch interactive)
- **Stock Health Panel** — Good/Low/Out/Reorder counts with progress bars (`SectionCard` from dashboard)
- **Stock Transfers Section** — watches `transferReportProvider` (existing provider from assign_stock feature)
  - 4 stat tiles, store-wise horizontal bars, monthly bar chart (last 6 months), recent transfers table
- **Out of Stock Section** — sirf out-of-stock products (naam, SKU, category, reorder point, selling price)

---

## Supplier Report (`supplierReportProvider` + `SupplierReportScreen`)

**Datasource:** `lib/features/warehouse/warehouse_reports/supplier/data/datasources/supplier_report_local_datasource.dart`
- 6 queries: `getSummary()`, `getTopByBalance()`, `getTopByPurchase()`, `getMonthlyTrend()`, `getAllSuppliers()`, `getRecentLedger()`
- Models: `SupplierSummaryData`, `SupplierBalanceItem`, `SupplierPurchaseItem`, `MonthlyPurchaseData`, `RecentLedgerEntry`

**Provider:** `lib/features/warehouse/warehouse_reports/supplier/presentation/providers/supplier_report_provider.dart`
- `SupplierReportState` with `copyWith(clearError: bool)` pattern
- `Future.wait([...])` — 6 queries parallel

**Screen:** `lib/features/warehouse/warehouse_reports/supplier/presentation/screens/supplier_report_screen.dart`
- **4 Summary Cards** — Total active suppliers, Total outstanding, Cleared suppliers, Pending balance
- **PieChart** — Top 6 suppliers by outstanding balance (touch interactive, legend with amounts)
- **BarChart** — Top 6 suppliers by total purchase volume
- **LineChart** — Monthly purchase trend (last 6 months)
- **Suppliers Table** — All active suppliers (name, phone, code, orders, purchased, balance)
- **Recent Ledger** — Last 20 entries from `supplier_ledger` (type badge, amount, balance after)

---

## Purchase Report (`purchaseReportProvider` + `PurchaseReportScreen`)

**Datasource:** `lib/features/warehouse/warehouse_reports/purchase/data/datasources/purchase_report_local_datasource.dart`
- 7 queries: `getSummary()`, `getStatusDistribution()`, `getTopSuppliersByValue()`, `getMonthlyTrend()`, `getSupplierCompletion()`, `getRecentPos()`, `getPendingPos()`
- Models: `PurchaseSummaryData`, `PoStatusCount`, `SupplierPoValue`, `MonthlyPoData`, `SupplierCompletionData`, `RecentPoEntry`

**Provider:** `lib/features/warehouse/warehouse_reports/purchase/presentation/providers/purchase_report_provider.dart`

**Screen:** `lib/features/warehouse/warehouse_reports/purchase/presentation/screens/purchase_report_screen.dart`
- **4 Summary Cards** — Total POs, Total value, Received, Pending
- **PieChart** — PO status distribution (draft/ordered/partial/received/cancelled) with count + % legend
- **BarChart** — Top 6 suppliers by PO value
- **LineChart** — Monthly PO trend (last 6 months)
- **Progress bars** — Supplier delivery completion rate (green ≥90%, yellow ≥50%, red <50%)
- **Pending POs table** — All non-received POs with status badge
- **Recent POs table** — Last 10 POs

---

## Cash Flow Report (`cashFlowReportProvider` + `CashFlowReportScreen`)

**Datasource:** `lib/features/warehouse/warehouse_reports/cash_flow/data/datasources/cash_flow_report_local_datasource.dart`
- 4 queries: `getSummary()`, `getMonthlyData()`, `getExpenseBreakdown()`, `getTypeBreakdown()`
- Models: `CashFlowSummary`, `MonthlyCashFlowData`, `ExpenseCategoryData`, `TransactionTypeData`
- `_fillMissingMonths()` helper — 6 months guarantee even if DB has no data
- **SQL fix:** `getMonthlyData()` uses CTE + `DISTINCT ON` to avoid PostgreSQL error 42803

**SQL pattern (CTE + DISTINCT ON) — important:**
```sql
WITH monthly_stats AS (
  SELECT DATE_TRUNC('month', created_at)::date AS month,
    COALESCE(SUM(ABS(amount)) FILTER (WHERE entry_type = 'cash_in'), 0) AS cash_in,
    COALESCE(SUM(ABS(amount)) FILTER (WHERE entry_type != 'cash_in'), 0) AS cash_out
  FROM warehouse_cash_transactions
  WHERE warehouse_id = @wid
    AND created_at >= DATE_TRUNC('month', NOW()) - INTERVAL '5 months'
  GROUP BY DATE_TRUNC('month', created_at)
),
last_balance_per_month AS (
  SELECT DISTINCT ON (DATE_TRUNC('month', created_at))
    DATE_TRUNC('month', created_at)::date AS month,
    cash_in_hand_after AS end_balance
  FROM warehouse_cash_transactions
  WHERE warehouse_id = @wid
    AND created_at >= DATE_TRUNC('month', NOW()) - INTERVAL '5 months'
  ORDER BY DATE_TRUNC('month', created_at), created_at DESC
)
SELECT ms.month, ms.cash_in, ms.cash_out, COALESCE(lb.end_balance, 0) AS end_balance
FROM monthly_stats ms LEFT JOIN last_balance_per_month lb ON lb.month = ms.month
ORDER BY ms.month
```
> ⚠️ Correlated subquery inside GROUP BY `→` error 42803. CTE + DISTINCT ON se fix hota hai.

**Provider:** `lib/features/warehouse/warehouse_reports/cash_flow/presentation/providers/cash_flow_report_provider.dart`

**Screen:** `lib/features/warehouse/warehouse_reports/cash_flow/presentation/screens/cash_flow_report_screen.dart`
- **4 Summary Cards** — Cash in hand, Total in, Total out, Net flow
- **Triple LineChart** — 3 simultaneous `LineChartBarData`: Cash In (green), Cash Out (red), Balance (primary/purple)
- **Grouped BarChart** — 2 rods per group (In=green, Out=red), `barsSpace: 3`
- **Net Flow BarChart** — `fromY`/`toY` for negative bars, positive=green, negative=red
- **Donut PieChart** — `centerSpaceRadius: 52`, Stack overlay for center text (total amount)
- **Progress bars** — Transaction type breakdown
- ❌ No Recent Transactions section (removed per request)

---

## Key Reusable Widgets (Dashboard)
**File:** `lib/features/warehouse/warehouse_dashboard/presentation/widgets/warehouse_dashboard_widgets/warehouse_dashboard_widgets.dart`

```dart
DashStatCard(label, value, badge, icon, color, barPercent)  // top stat cards
SectionCard(headerIcon, title, headerTrailing, children, footerLeft, footerRight)  // card wrapper
PoStatusBadge(status)      // PO status
TransferStatusBadge(status)
StockProgressRow(item, isLast)  // low stock progress
SupplierDueRow(item, isLast)
MovementRow(entry, isLast)
```

---

## Key Providers

| Provider | File | Type | Description |
|---|---|---|---|
| `productProvider` | `warehouse_stock_inventory/presentation/provider/product_provider.dart` | `StateNotifierProvider<ProductNotifier, ProductState>` | All products + stock |
| `authProvider` | `warehouse/auth/presentation/provider/auth_provider.dart` | StateNotifier | Current user + login/logout |
| `inventoryReportProvider` | `warehouse_reports/inventory/.../inventory_report_provider.dart` | `Provider<InventoryReportData>` | Derived from productProvider, koi DB call nahi |
| `supplierReportProvider` | `warehouse_reports/supplier/.../supplier_report_provider.dart` | `StateNotifierProvider<SupplierReportNotifier, SupplierReportState>` | 6 DB queries parallel Future.wait |
| `purchaseReportProvider` | `warehouse_reports/purchase/.../purchase_report_provider.dart` | `StateNotifierProvider<PurchaseReportNotifier, PurchaseReportState>` | 7 DB queries parallel Future.wait |
| `cashFlowReportProvider` | `warehouse_reports/cash_flow/.../cash_flow_report_provider.dart` | `StateNotifierProvider<CashFlowReportNotifier, CashFlowReportState>` | 4 DB queries parallel Future.wait |
| `transferReportProvider` | `assign_stock/presentation/providers/assign_stock_report_provider.dart` | `StateNotifierProvider<TransferReportNotifier, TransferReportState>` | Stock transfers data |
| `assignStockProvider` | `assign_stock/presentation/providers/assign_stock_provider.dart` | StateNotifier | Cart state for assigning stock |
| `warehouseDashboardProvider` | `warehouse_dashboard/presentation/provider/` | StateNotifier | Dashboard data |

---

## ProductModel (Key Fields)
```dart
class ProductModel {
  String id, warehouseId, sku, name;
  List<String> barcodes;          // text[] from DB
  String? categoryId, categoryName, description;
  String unitOfMeasure;           // default 'pcs'
  double purchasePrice, sellingPrice;
  double? wholesalePrice;
  double taxRate;
  int minStockLevel, reorderPoint;
  int? maxStockLevel;
  bool isActive, isTrackStock;
  double quantity, reservedQty;
  double get availableQty => quantity - reservedQty;

  // Business logic
  bool get isLowStock => isTrackStock && quantity <= minStockLevel;
  bool get needsReorder => isTrackStock && reorderPoint > 0 && quantity <= reorderPoint;
  String? get primaryBarcode => barcodes.isNotEmpty ? barcodes.first : null;
}
```

---

## Coding Conventions (Follow Karo)

1. **State Management:** sirf Riverpod — `StateNotifierProvider` ya `Provider`
2. **No setState in ConsumerWidget** — providers use karo
3. **Stateful widgets sirf jab local UI state zaroor ho** (e.g., TextEditingController, animation controller, touch index for charts)
4. **Local DB queries:** `DatabaseService.connection.execute(Sql.named(...), parameters: {...})`
5. **Extension use karo:** `double.pkrFormat` for Pakistani rupee formatting, `.timeAgo` for dates
6. **Colors:** sirf `AppColor.*` use karo, koi hardcoded color nahi
7. **Overflow fix pattern:** `OverflowBox + SizedBox` inside `AnimatedContainer` with `Clip.hardEdge`
8. **Search fields:** always `TextEditingController` + clear (X) button jab text ho
9. **New feature add karna:** `lib/features/warehouse/<feature_name>/` mein banao, `data/`, `presentation/providers/`, `presentation/screens/`, `presentation/widgets/` structure follow karo
10. **Sidebar:** `sidebar_widget.dart` mein NavItem add karo, Reports jaise special case mein `_buildContent()` override karo

---

## UI Design Patterns

- **Screens:** TopBar (border bottom) + `SingleChildScrollView` with `padding: EdgeInsets.all(20)`
- **TopBar:** Left icon + title/subtitle + Spacer + right badge
- **Cards:** `borderRadius: 14`, `border: Border.all(color: AppColor.grey200)`, `color: AppColor.surface`
- **Section headers:** 26x26 icon container + title text + Spacer + trailing badge
- **Rows with dividers:** `Border(bottom: BorderSide(color: AppColor.grey100))` on all except last
- **Status badges:** small container with dot + text, color-coded
- **Progress bars:** `LinearProgressIndicator` with `minHeight: 4-6`, `ClipRRect(borderRadius: 3)`
- **Charts:** fl_chart — `PieChart`, `BarChart`, `LineChart`

---

## Rules (Important)
- **Sirf warehouse par kaam karna** — accountant aur branch features bilkul touch nahi karne
- **Supabase schema change nahi karna** — sirf read/reference ke liye dekh sakte ho
- **New reports:** `warehouse_reports_shell.dart` mein `_reports` list mein add karo, `isComingSoon: false` karo aur `screen:` pass karo
- **`withOpacity()` deprecated hai** — project mein sab jagah use ho raha hai, existing code mein mat change karo, naye code mein bhi same rakho for consistency
- **`DashStatCard` already `Expanded` return karta hai** — kabhi bhi `Expanded(child: DashStatCard(...))` mat karo, seedha `DashStatCard(...)` use karo `Row` mein
- **`SectionCard.headerIcon` expects `Widget`** — `IconData` nahi dena, wrap karo: `Container(width:26, height:26, decoration: BoxDecoration(color: colorLight, borderRadius: BorderRadius.circular(6)), alignment: Alignment.center, child: Icon(icon, size:14, color: color))`

---

## warehouse_stock_movements Fix (Purchase Invoice)

**File:** `lib/features/warehouse/purchase_invoice/data/datasource/purchase_order_remote_datasource.dart`
**Function:** `_handleReceivedInventory()` → `for` loop mein har item ke liye

**Problem:** PO receive hone par `warehouse_inventory` aur `warehouse_products` update hote the lekin `warehouse_stock_movements` mein koi log entry nahi hoti thi.

**Fix:** `UPDATE warehouse_products` ke baad `INSERT INTO warehouse_stock_movements` add kiya:
```dart
await conn.execute(
  Sql.named('''
    INSERT INTO warehouse_stock_movements (
      id, warehouse_id, product_id,
      movement_type, quantity, unit_cost,
      reference_type, reference_id, notes
    ) VALUES (
      @id, @warehouseId, @productId,
      'purchase_in', @quantity, @unitCost,
      'purchase', @referenceId, @notes
    )
  '''),
  parameters: {
    'id':          const Uuid().v4(),
    'warehouseId': warehouseId,
    'productId':   item.productId,
    'quantity':    item.quantityOrdered,
    'unitCost':    double.parse(item.unitCost.toStringAsFixed(2)),
    'referenceId': poId,
    'notes':       'PO receive — \${item.productName}',
  },
);
```
**Safe kyun hai:**
- Additive only — koi existing code nahi toota
- Same `conn` transaction — fail ho toh sab rollback
- Multiple items bhi sahi kaam karta hai (`for` loop mein hai)
- Valid CHECK constraint values: `movement_type = 'purchase_in'`, `reference_type = 'purchase'`

---

## Session 1 — Kya Kiya

1. `assign_stock` search field mein **clear (X) button** add kiya
2. **`warehouse_reports` feature** banaya from scratch:
   - `WarehouseReportsShell` — collapsible drawer (44/192px), back to dashboard
   - `InventoryReportScreen` + `inventoryReportProvider` — derived from productProvider
3. **Sidebar** update — Reports par main sidebar hide, shell full-screen
4. **Overflow fix** — `OverflowBox + SizedBox + Clip.hardEdge` pattern for animated drawer

## Session 2 — Kya Kiya

1. **Supplier Report** — complete (`SupplierReportScreen` + `supplierReportProvider` + `SupplierReportLocalDatasource`)
   - PieChart, BarChart, LineChart, supplier table, recent ledger
2. **Purchase Report** — complete (`PurchaseReportScreen` + `purchaseReportProvider` + `PurchaseReportLocalDatasource`)
   - PieChart, BarChart, LineChart, progress bars, pending/recent tables
3. **Cash Flow Report** — complete (`CashFlowReportScreen` + `cashFlowReportProvider` + `CashFlowReportLocalDatasource`)
   - Triple LineChart, Grouped BarChart, Net Flow BarChart (negative bars), Donut PieChart
   - SQL error 42803 fix: CTE + DISTINCT ON pattern
   - Recent Transactions section removed per request
4. **`warehouse_reports_shell.dart`** — Purchases, Suppliers, Cash Flow `isComingSoon: false`, screens connected
5. **`warehouse_stock_movements` fix** — `_handleReceivedInventory()` mein INSERT log add kiya (production-safe)

---

## Project Path
```
/Users/hashimkhan/Desktop/programming/jan_ghani_final/
```

## Schema Path
```
/Users/hashimkhan/Desktop/janghani pos resourses/db releated/schema v3/zero_start_schema/warehouse_zero_start_schema_v3.7.sql
```
