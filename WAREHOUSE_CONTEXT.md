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
- **Schema location**: `/Users/hashimkhan/Desktop/janghani pos resourses/db releated/schema v3/zero_start_schema/warehouse_zero_start_schema_v3.8.sql`

### Key Tables (Warehouse)
| Table | Description |
|---|---|
| `warehouse_products` | Products (barcode `text[]`, sku, prices, stock levels) |
| `warehouse_inventory` | Stock quantities per product (qty, reserved_quantity) |
| `warehouse_stock_movements` | Movement log (purchase_in, transfer_out, return_in, **return_out**, adjustment, opening) |
| `warehouse_categories` | Product categories |
| `purchase_orders` | POs (status: draft/ordered/partial/received/cancelled; **`po_type`: purchase/return**) |
| `purchase_order_items` | PO line items |
| `suppliers` | Suppliers (outstanding_balance auto-updated via trigger) |
| `supplier_ledger` | Supplier payment ledger |
| `stock_transfers` | Stock sent to stores (status: pending/accepted) |
| `stock_transfer_items` | Transfer line items |
| `linked_stores` | Stores linked to this warehouse |
| `warehouse_cash_transactions` | Cash entries (cash_in, purchase, supplier_payment, expense, **salary** ← Session 7) |
| `warehouse_companies` | ⭐ Session 7 — Product companies (name-only master); `warehouse_products.company_id` FK |
| `warehouse_employees` | ⭐ Session 7 — Employees (name, phone, address, monthly_salary, max_advance_percent) |
| `warehouse_salary_payments` | ⭐ Session 7 — Salary/advance payments (payment_type salary/advance, salary_month, cash_transaction_id link) |
| `warehouse_finance` | Cash in hand (auto-updated via trigger) |
| `warehouse_expenses` | Expense records |
| `warehouse_users` | Users (roles: warehouse_owner, warehouse_manager, warehouse_staff, data_entry) |

### Key DB Views
- `v_reorder_needed` — products below reorder point
- `v_supplier_balances` — supplier outstanding balances
- `v_daily_summary` — today's cash summary
- `v_warehouse_stock` — stock with available quantity

### Reports — Supabase READ-ONLY objects (Session 3, web support ke liye)
> Sirf Supabase par (web fetch ke liye). Local schema unchanged. Table/data ko touch nahi karte.
- **Views:** `warehouse_inventory_summary_v` (per-warehouse: total/low/out/reorder counts + purchase/selling value), `warehouse_inventory_category_v` (per-warehouse, per-category value + count)
- **RPC functions (7):** `purchase_report_summary`, `purchase_report_status_dist`, `purchase_report_top_suppliers`, `purchase_report_monthly_trend`, `purchase_report_supplier_completion`, `purchase_report_recent_pos`, `purchase_report_pending_pos` — params `(p_wid, p_from, p_to[, p_limit])`, `LANGUAGE sql STABLE`

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
    │   ├── company/                  ← ⭐ Session 7 — Product companies (Category ka FULL mirror: model/datasource/repo/usecases/provider/screen/dialog)
    │   ├── employee/                 ← ⭐ Session 7 — Employees + Salary tracking
    │   │   ├── domain/  (employee_model, salary_payment_model, employee_month_status)
    │   │   ├── data/employee_repository.dart   ← CRUD + paySalary + monthly status (Expense-repo pattern, singleton)
    │   │   └── presentation/
    │   │       ├── provider/ (employee_provider, salary_provider)
    │   │       ├── screens/  (salary_tracking_screen ← MAIN sidebar target, employees_screen)
    │   │       └── widgets/  (add_employee_dialog, pay_salary_dialog, employee_history_dialog)
    │   └── warehouse_reports/        ← *** NAYA FEATURE (humne banaya) ***
    │       ├── presentation/screens/
    │       │   └── warehouse_reports_shell.dart        ← Reports shell (drawer + routing)
    │       ├── inventory/
    │       │   ├── data/datasources/inventory_report_remote_datasource.dart  ← WEB (Supabase views)
    │       │   └── presentation/
    │       │       ├── providers/inventory_report_provider.dart   ← kIsWeb branch + reportsWarehouseIdProvider
    │       │       └── screens/inventory_report_screen.dart
    │       ├── supplier/
    │       │   ├── data/datasources/
    │       │   │   ├── supplier_report_models.dart            ← models (shared)
    │       │   │   ├── supplier_report_source.dart            ← interface (local+remote follow)
    │       │   │   ├── supplier_report_local_datasource.dart  ← local postgres
    │       │   │   └── supplier_report_remote_datasource.dart ← WEB (raw fetch + Dart compute)
    │       │   └── presentation/
    │       │       ├── providers/supplier_report_provider.dart
    │       │       └── screens/supplier_report_screen.dart
    │       ├── purchase/
    │       │   ├── data/datasources/
    │       │   │   ├── purchase_report_models.dart
    │       │   │   ├── purchase_report_source.dart
    │       │   │   ├── purchase_report_local_datasource.dart
    │       │   │   └── purchase_report_remote_datasource.dart ← WEB (Supabase RPC functions)
    │       │   └── presentation/
    │       │       ├── providers/purchase_report_provider.dart
    │       │       └── screens/purchase_report_screen.dart
    │       └── cash_flow/
    │           ├── data/datasources/
    │           │   ├── cash_flow_report_models.dart
    │           │   ├── cash_flow_report_source.dart
    │           │   ├── cash_flow_report_local_datasource.dart
    │           │   └── cash_flow_report_remote_datasource.dart ← WEB (raw fetch + Dart compute)
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
SideBar (90px wide sidebar) — Session 7: har role mein "Company" (Category ke baad) + "Salary" (Expense ke baad) add hue
├── Role: warehouse_manager → Full nav (Dashboard, Stock, Purchase, Supplier, Assign Stock, Category, Company, Finance, Expense, Salary, Link Stores, User, Reports)
├── Role: warehouse_owner / default → (Stock, Purchase, Supplier, Category, Company, Finance, Expense, Salary, Reports)
└── Role: data_entry → (Stock, Supplier, Category, Company, Finance, Expense, Salary)
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
  5. Cash Flow  — ACTIVE ✅ (`CashFlowReportScreen`) — Session 7 mein SIMPLIFIED (dekho Session 7)
  6. Expenses   — ACTIVE ✅ (`ExpenseReportScreen`) — ⭐ Session 7 naya (platform-aware: desktop=local, web=Supabase raw+compute)

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

## Reports — Web vs Desktop (Platform-aware Data Sources)

> **Session 3 addition.** Charon reports ab **dono platforms** par chalti hain. Data source `kIsWeb` ke hisaab se switch hota hai — UI/screen bilkul SAME rehta hai, sirf data kahan se aata hai woh badalta hai.

| Platform | Data source | Warehouse ID |
|---|---|---|
| **Windows / Mac / mobile** | Local postgres (`DatabaseService`) | `AppConfig.warehouseId` (config.json) — **unchanged** |
| **Website (`kIsWeb`)** | Supabase | **selected** warehouse (accountant ne jo choose kiya) |

### Architecture (Supplier / Purchase / Cash Flow)
Har report ke paas ab ek **interface + 2 implementations** hain (clean swap ke liye):
- `*_report_models.dart` — models alag file (dono datasources + interface share karte hain; local datasource inhe **re-export** karta hai taake provider/screen ke purane imports waise hi chalein)
- `*_report_source.dart` — abstract interface (`PurchaseReportSource`, `SupplierReportSource`, `CashFlowReportSource`)
- `*_report_local_datasource.dart` — local postgres, `implements <Source>` — **behaviour bilkul unchanged**
- `*_report_remote_datasource.dart` — Supabase, `implements <Source>`

Provider platform ke hisaab se source pick karta hai:
```dart
final xReportProvider = StateNotifierProvider.autoDispose<XNotifier, XState>((ref) {
  final XReportSource source = kIsWeb
      ? XReportRemoteDatasource(Supabase.instance.client,
          ref.watch(reportsWarehouseIdProvider) ?? AppConfig.warehouseId)
      : XReportLocalDatasource.instance;
  return XReportNotifier(source);
});
```
> **Inventory thoda alag hai** — uska koi `Source` interface nahi; provider khud `kIsWeb` par branch karta hai (desktop = `productProvider`, web = Supabase views).

### `reportsWarehouseIdProvider` (web par selected warehouse)
**Defined in:** `inventory_report_provider.dart` (shared — baaki report providers isko import karte hain)
```dart
final reportsWarehouseIdProvider = StateProvider<String?>((ref) => null);
```
- **null** → config warehouse (desktop / warehouse app)
- **value** → selected warehouse id; accountant ke **Reports card** par tap karte hi set hota hai
- Provider `autoDispose` + `ref.watch(reportsWarehouseIdProvider)` → warehouse badle to rebuild + reload

> **Kyun zaroori:** config.json ka `warehouse_id` LOCAL DB ki warehouse hai. Supabase par data alag warehouse id ke under hota hai → web par config-id se 0 results aate the. Ab selected warehouse use hota hai.

### Per-report web approach
| Report | Web approach | Supabase objects (READ-ONLY) |
|---|---|---|
| **Inventory** | Aggregate **VIEWS** (1396+ products → server-side exact + fast) + Stock-Health drill-down **on-demand** | ✅ `warehouse_inventory_summary_v`, `warehouse_inventory_category_v` |
| **Purchase** | **RPC functions** (date-filtered aggregates, local SQL ka exact mirror) | ✅ 7 functions: `purchase_report_summary/_status_dist/_top_suppliers/_monthly_trend/_supplier_completion/_recent_pos/_pending_pos` |
| **Suppliers** | **Raw fetch + Dart compute** (data chhota ~47, future ~600) | ❌ koi DB object nahi |
| **Cash Flow** | **Raw fetch + Dart compute** (data chhota ~250 txns) | ❌ koi DB object nahi |

> Inventory & Purchase ne DB objects banaye kyunki data bada/aggregate-heavy tha. Suppliers & Cash Flow chhote the → client-side compute, koi view/RPC nahi.

### Accountant se Reports kholna
**File:** `accountant/accountant_warehouse_dashboard/.../accountant_warehouse_dashboard_screen.dart`
- Dashboard mein **"Reports" card** — tap par `reportsWarehouseIdProvider = selected warehouseId` set karke `WarehouseReportsShell` kholta hai
- Shell ke sidebar back-button web par **"Back"** dikhata hai (Dashboard nahi) — `WarehouseReportsShell` ke naye `backLabel` / `backIcon` params se — tap par wapas accountant dashboard par pop

### ⚠️ 1000-row cap (PostgREST)
Supabase REST ek request mein max **~1000 rows** deta hai. Saare raw-fetch (`suppliers` / `purchase_orders` / `warehouse_cash_transactions` / `warehouse_products`) **`.range()` se paginated** hain (1000-1000 chunks), warna data cut ho jata. Date boundary `created_at::date <= to` ka mirror: `.gte(from-midnight)` + `.lt(to + 1 din)`.

### ⚠️ Supabase objects (schema rule exception)
Pehle "Supabase schema change nahi karna" rule tha. Reports ke web support ke liye **read-only** objects banaye gaye (table/data ko haath nahi lagaya):
- 2 views: `warehouse_inventory_summary_v`, `warehouse_inventory_category_v`
- 7 functions: `purchase_report_*`

---

## Inventory Report (`inventoryReportProvider` + `InventoryReportScreen`)

**Provider file:** `lib/features/warehouse/warehouse_reports/inventory/presentation/providers/inventory_report_provider.dart`
- `inventoryReportProvider` → `Provider<InventoryReportData>` — **platform-aware:**
  - **Desktop:** `productProvider` se derive hota hai, koi DB call nahi (pehle jaisा)
  - **Web (`kIsWeb`):** `_remoteReportProvider` (FutureProvider) → Supabase aggregate views (`warehouse_inventory_summary_v` + `warehouse_inventory_category_v`) — exact numbers, saari rows fetch nahi hoti
- Computes: totalActive, lowStockCount, outOfStockCount, needsReorderCount, totalPurchaseValue, totalSellingValue, categoryBreakdown, reorderProducts, activeProducts
- **Stock-Health drill-down (web):** `stockHealthProductsProvider` — products **on-demand** (user ke tap par) Supabase se fetch hote hain (`getProducts`, paginated)
- Shared: `reportsWarehouseIdProvider` yahin define hai (baaki report providers import karte hain)

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
| `inventoryReportProvider` | `warehouse_reports/inventory/.../inventory_report_provider.dart` | `Provider<InventoryReportData>` | **Platform-aware:** desktop=productProvider, web=Supabase views |
| `reportsWarehouseIdProvider` | `warehouse_reports/inventory/.../inventory_report_provider.dart` | `StateProvider<String?>` | Web par reports kis warehouse ka data dikhayein (selected) |
| `supplierReportProvider` | `warehouse_reports/supplier/.../supplier_report_provider.dart` | `StateNotifierProvider.autoDispose<...>` | 6 queries; desktop=local, web=Supabase raw+compute |
| `purchaseReportProvider` | `warehouse_reports/purchase/.../purchase_report_provider.dart` | `StateNotifierProvider.autoDispose<...>` | 7 queries; desktop=local, web=Supabase RPC |
| `cashFlowReportProvider` | `warehouse_reports/cash_flow/.../cash_flow_report_provider.dart` | `StateNotifierProvider.autoDispose<...>` | 5 queries; desktop=local, web=Supabase raw+compute |
| `expenseReportProvider` | `warehouse_reports/expense/.../expense_report_provider.dart` | `StateNotifierProvider.autoDispose<...>` | ⭐ S7 — summary(+prev period)+category breakdown; desktop=local, web=Supabase raw+compute |
| `companyProvider` | `company/presentation/provider/company_provider.dart` | `StateNotifierProvider<CompanyNotifier, CompanyState>` | ⭐ S7 — companies CRUD (Category pattern) |
| `employeeProvider` | `employee/presentation/provider/employee_provider.dart` | `StateNotifierProvider<EmployeeNotifier, EmployeeState>` | ⭐ S7 — employees master CRUD |
| `salaryProvider` | `employee/presentation/provider/salary_provider.dart` | `StateNotifierProvider<SalaryNotifier, SalaryState>` | ⭐ S7 — monthly salary tracking + pay/delete (month state) |
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
- **Supabase tables/data change nahi karna** — sirf read/reference. **Exception (reports web support):** read-only **views** + **RPC functions** banaye gaye hain (`warehouse_inventory_*_v`, `purchase_report_*`) — yeh sirf SELECT karte hain, kisi table/column/data ko touch nahi karte
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

## Purchase Return (Purchase Invoice) — Session 4

> **Maqsad:** Purchase Invoice screen mein Type dropdown se **"Purchase Return"** select karke supplier ko goods wapas bhejna. Pehle yeh dropdown sirf cosmetic tha (rang/label badalta tha) — koi business logic nahi tha; save karne par normal purchase ki tarah stock ADD ho jata tha. Ab poora return logic implement hai.

### Behaviour (Purchase ka ULTA)
| | Purchase | Purchase Return |
|---|---|---|
| Stock | `+` (purchase_in) | `-` (`return_out`) — `GREATEST(0, qty - x)` |
| Supplier balance | `+` (`purchase` ledger) | `-` (`return` ledger, **negative** amount) |
| Record | `po_type = 'purchase'` | `po_type = 'return'`, `status = 'received'` |
| Number series | `PO-...` | `PR-...` (alag — collision se bachne ke liye) |
| Cash | (paid amount flow) | **Koi cash nahi** — sirf supplier balance adjust |
| Editable? | Haan | **Nahi — read-only** (list mein edit icon hide) |

### Schema changes (v3.7 → v3.8)
```sql
-- 1. purchase_orders: po_type column
ALTER TABLE purchase_orders ADD COLUMN po_type text NOT NULL DEFAULT 'purchase';
ALTER TABLE purchase_orders ADD CONSTRAINT purchase_orders_po_type_check
  CHECK (po_type = ANY (ARRAY['purchase','return']));
-- 2. warehouse_stock_movements: 'return_out' added to movement_type CHECK
-- 3. supplier_ledger: 'return' confirmed in entry_type CHECK (pehle se tha)
```
> ⚠️ **Sync note:** Sync service poori row (`toColumnMap()`) Supabase par upsert karti hai — isliye yeh teen schema changes **local + Supabase dono** par run kiye gaye (warna `po_type` column / `return_out` value par sync/insert fail hoti).

### Files
| File | Change |
|---|---|
| `purchase_invoice/domain/purchase_order_model.dart` | `poType` field + `isReturn` getter; `canEdit`/`canCancel` mein `!isReturn`; `fromMap` mein `po_type` |
| `purchase_invoice/data/datasource/purchase_order_remote_datasource.dart` | Naya **`createReturn()`** (inventory minus + `return_out` movement + `supplier_ledger` negative `return`, sab ek transaction); `getAll`/`getById`/`_mapToModel` mein `po_type` |
| `.../provider/purchase_invoice_provider/purchase_invoice_provider.dart` | `saveInvoice()` mein return branch → `_saveReturn()`; `_generateReturnNo()` (`PR-` series); `loadFromExistingOrder()` mein `poType = purchase` safety reset |
| `.../widgets/purchase_invoice_widgets/po_cart_summary_widget.dart` | Return ke liye `canSave`/validation relax (sale price + delivery date zaroori nahi) |
| `.../widgets/purchase_order_widgets.dart` | List mein laal **"Return" badge** (PO number ke saath) |
| `.../provider/purchase_order_provider.dart` | `updateStatus` rebuild mein `poType` preserve |

### Zaroori design points
- **New PO / Edit PO untouched** — `create()`/`updatePO()` ka core logic bilkul nahi badla. Naya PO `po_type` DB `DEFAULT 'purchase'` se khud bharta hai. `saveInvoice()` ka purchase path **else-branch** mein. Return read-only isliye edit mode hamesha `po_type='purchase'` load karta hai.
- **`PR-` number alag kyun:** `_saveReturn()` save ke waqt fresh `PR-...` number banata hai — `state.poNumber` (jo purchase ka stale number ho sakta hai) reuse karne se `(warehouse_id, po_number)` unique constraint `23505 duplicate` aata tha.
- **Note:** Return screen par disabled "PO Number" field abhi `PO-...` dikhata hai, lekin save hone par record `PR-...` se banta hai (cosmetic mismatch only).

---

## Stock Transfer — Reserve-on-Create Model (Session 5) ⭐

> **Maqsad:** Stock assign (warehouse → store) karte waqt product ka stock **minus (negative)** ja raha tha. Is poore flow ko reservation-based bana diya taake stock kabhi galat tareeqe se minus na ho.

### Pehle masla kya tha (root cause)
- Transfer **create** par stock na minus hota tha na reserve hota tha — deduction sirf store ke **accept** karne par hoti thi (`StockTransferSyncService`).
- Oversell ka akela check UI button par tha, jo ek **purane snapshot** (`availableStock = p.quantity` add-to-cart ke waqt) par chalta tha.
- Nateeja **double-assign:** ek hi product ko do alag pending transfers mein daal diya jata (dono ko stale stock 40 dikhta), dono accept hone par `40 − 40 − 40 = −40`.
- Accept par deduction mein `GREATEST(0,…)` guard bhi nahi tha → DB khulle-aam negative chala jata. (Koi DB trigger stock ko touch nahi karta — pura logic Dart code mein hai.)

### Naya model: Reserve on create
DB mein `warehouse_inventory` ke do columns istemal hote hain:
- `quantity` = **physical stock** (godam mein asal maal). Sirf **accept** par kam hota hai.
- `reserved_quantity` = pending transfers ke liye **lock** kiya hua stock.
- **Available (assign karne layak) = `quantity − reserved_quantity`** → `ProductModel.availableQty`.

| Event | `quantity` | `reserved_quantity` | available (qty − res) |
|---|---|---|---|
| Stock 40 | 40 | 0 | 40 |
| **Create** transfer (40) | 40 *(same)* | 0 → **40** | **0** (doosra transfer block) |
| **Accept** (store) | 40 → **0** | 40 → **0** | 0 |
| **Reject** (store) | 40 *(same)* | 40 → **0** | **40 wapas** |

- **Create par:** validate + reserve **ek hi DB transaction** mein, har item ki inventory row `FOR UPDATE` se lock. Available kam ho to **throw** (kuch save nahi hota). `quantity` ko haath nahi lagta, sirf `reserved_quantity += quantity_sent`.
- **Accept par:** `quantity = GREATEST(0, quantity − sent)` **aur** `reserved_quantity = GREATEST(0, reserved_quantity − sent)`. Status update atomic (`WHERE status='pending' RETURNING id`) → double-sync/race se sirf ek baar deduct.
- **Reject par:** sirf `reserved_quantity = GREATEST(0, reserved_quantity − sent)` release (quantity untouched), idempotent.
- Reserved inventory **background sync** (`is_synced=false`) se Supabase par khud chala jata hai — alag se remote update nahi karte.

### Files (Session 5)
| File | Change |
|---|---|
| `assign_stock/data/datasources/assign_stock_local_datasource.dart` | `hasEnoughStock` → `(quantity − reserved) >= qty`; naya **`insertTransferWithReservation()`** (validate `FOR UPDATE` + insert transfer/items + reserve, sab `db.runTx` mein) |
| `assign_stock/data/repositories/assign_stock_repository.dart` | Order badla: **pehle local** atomic (validate+insert+reserve), **phir** Supabase mirror |
| `assign_stock/data/models/assign_stock_item_model.dart` | `fromProduct`: `availableStock = p.availableQty` (pehle `p.quantity`) |
| `core/service/stock_assign_services/stock_transfer_sync_service.dart` | Accept: `GREATEST(0,…)` + reserved release + atomic status race-guard; naya **`_syncRejectedTransfer()`**; missed-sync ab `accepted` + `rejected` dono handle karta hai |
| `assign_stock/presentation/widgets/assign_stock_product_list_panel.dart` | Left product list ab `p.availableQty` dikhata hai (cart "Max" + Inventory screen ke saath consistent) |

### Display consistency
Teeno jagah ab **`availableQty` (reserve-aware)** dikhati hain: Assign left list, Assign cart "Max", Stock Inventory screen.

### ⚠️ Abhi bhi dhyan dene wali baatein
- **Manual product edit/add** (`stock_inventory_dialog` → `product_remote_datasource` `SET quantity = @quantity`) par **koi 0-floor nahi** — user negative type kare to minus set ho sakta hai. (Transfer/return flows ab safe hain.)
- **DB par `CHECK (quantity >= 0)` constraint NAHI lagaya** — kyunki mojooda minus data (jaise −40) us constraint ko violate karega. Yeh constraint **purane minus data ki cleanup ke baad** lagana chahiye.
- Agar product minus mein ho to UI us minus value ko hi dikhata hai (0 par floor nahi karta).

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

## Session 3 — Kya Kiya (Reports → Web/Supabase support)

> Maqsad: charon reports website par bhi chalein (Supabase se), desktop (Win/Mac) par local DB se — UI same, sirf data source platform ke hisaab se switch.

1. **Platform-aware architecture** — har report ke liye `*_report_models.dart` (shared) + `*_report_source.dart` (interface) + `*_report_local_datasource.dart` (`implements`) + `*_report_remote_datasource.dart` (Supabase). Provider `kIsWeb` par branch (`autoDispose`).
2. **`reportsWarehouseIdProvider`** (`inventory_report_provider.dart`) — web par accountant ka **selected warehouse** use hota hai (config-id nahi). Accountant dashboard ka **Reports card** ise set karke shell kholta hai.
3. **Inventory** — 2 Supabase **views** (`warehouse_inventory_summary_v`, `warehouse_inventory_category_v`) summary+category ke liye; Stock-Health drill-down **on-demand** fetch.
4. **Purchase** — 7 Supabase **RPC functions** (`purchase_report_*`, date-filtered, local SQL ka exact mirror).
5. **Suppliers + Cash Flow** — **raw fetch + Dart compute** (data chhota; no RPC/view).
6. **`WarehouseReportsShell`** — naye `backLabel`/`backIcon` params; accountant se kholne par sidebar back button **"Back"** (→ accountant dashboard pop).
7. **1000-row cap fixes** — saare raw fetch `.range()` se paginated (suppliers/POs/transactions/products); date boundary `gte(from)` + `lt(to+1)`.
8. **Accountant warehouse dashboard** — web par metrics **card grid** (mobile par rows same); Cash-in-Hand card width capped; "Reports" card added.

## Session 4 — Kya Kiya (Purchase Return)

> Maqsad: Purchase Invoice ke "Purchase Return" type ko sirf cosmetic se asli kaam karne wala banaya — supplier ko goods wapas, stock minus, supplier balance kam. New PO / Edit PO ko bilkul touch nahi kiya.

1. **Schema v3.8** — `purchase_orders.po_type` column (purchase/return) + `warehouse_stock_movements` mein `return_out` movement type (local + Supabase dono par run).
2. **`createReturn()` datasource method** — ek transaction mein: inventory minus (`return_out` movement) + `supplier_ledger` `return` (negative amount → trigger se balance kam). `po_type` `getAll`/`getById`/`_mapToModel` mein add.
3. **`saveInvoice()` return branch** — `poType == purchaseReturn` par `_saveReturn()` chalta hai; purchase path else-branch mein untouched. Return ke liye `PR-` number series (`_generateReturnNo()`) — duplicate constraint se bachne ke liye.
4. **Return read-only** — `canEdit`/`canCancel` mein `!isReturn`; list mein laal **"Return" badge**; `loadFromExistingOrder` `poType=purchase` reset.
5. **Validation relax** — return ke liye sale price + delivery date zaroori nahi (`po_cart_summary_widget` mein `canSave` branch).

> Tafseel: upar **"Purchase Return (Purchase Invoice) — Session 4"** section dekho.

## Session 5 — Kya Kiya (Stock Transfer Negative-Stock Fix)

> Maqsad: Stock assign par product minus chala jata tha (double-assign). Reservation-based model laga kar jad se theek kiya.

1. **Reserve-on-create** — transfer banate hi `reserved_quantity` lock hoti hai (`quantity` untouched), validate + reserve ek hi `runTx` transaction mein `FOR UPDATE` lock ke saath → double-assign rok diya.
2. **Accept** par `GREATEST(0,…)` deduction + reserved release + atomic status race-guard (double-sync safe).
3. **Reject** par reservation release (`_syncRejectedTransfer`), missed-sync ab accepted+rejected dono handle karta hai.
4. **Display consistency** — Assign left list ab `availableQty` (cart "Max" + Inventory screen ke saath match).

> Tafseel: upar **"Stock Transfer — Reserve-on-Create Model (Session 5)"** section dekho.

---

## Stock Movement Ledger + Negative Stock (Session 6) ⭐

> **Maqsad:** `warehouse_stock_movements` ek **adhoora ledger** tha (opening/adjustment kabhi log hi nahi hote the), aur transfer accept par stock **chup-chaap `GREATEST(0,…)` se 0 par floor** ho jata tha — kami chhup jati thi. Teen additive fixes se ledger complete + kami visible.

### Allowed movement types (schema — local + Supabase dono confirmed)
- `movement_type` CHECK: `purchase_in, transfer_out, return_in, return_out, adjustment, opening`
- `reference_type` CHECK: `purchase, transfer, adjustment`
- `warehouse_inventory.quantity` par **koi `>= 0` constraint nahi** (negative DB-level allowed — jaan-bujh kar, constraint lagana hi nahi).

### Fix A — Opening movement (product create)
`product_remote_datasource.dart` → `add()`: inventory set ke baad `initialQty != 0` ho to `opening` movement insert (`reference_type='adjustment'`).

### Fix B — Adjustment movement (manual edit)
Same file → `update()`: `qtyDiff = newQty − oldQty` != 0 → `adjustment` movement (signed diff, negative allow, 0-floor nahi).

### Fix C — Floor hatao (transfer accept) — negative visible
`stock_transfer_sync_service.dart` → `_syncAcceptedTransfer()` Step 2: `quantity = quantity - sent` (**GREATEST(0,…) HATA diya** — real minus visible), `reserved_quantity = GREATEST(0, reserved - sent)` (reserved ab bhi capped). Reserve-on-create naye transfers ko phir bhi block karta hai.

---

## Stock Status — Available-based, har jagah consistent (Session 6) ⭐

- **ProductModel getters available-based:** `isOutOfStock => availableQty <= 0` (naya), `isLowStock => availableQty <= minStockLevel`, `needsReorder => availableQty <= reorderPoint` — poore app mein use hote hain (dashboard + reports counts bhi).
- **Inventory screen:** Stock column = **physical `quantity`** + grey sub-label `X free · Y reserved` (jab reserved > 0); `itemExtent 58`; badge/summary-card/`out_stock` filter ab `p.isOutOfStock`.
- **Inventory report (desktop)** bhi `isOutOfStock`.
- **Baqi flagged (nahi kiye):** PO product picker abhi physical `quantity > 0`; web inventory report Supabase views ka out-of-stock count server-side SQL (Dart getter apply nahi hota).

---

## PO Edit Sync + Supplier Ledger Reconcile (Session 6) ⭐

### Sync ka core rule (yaad rakho)
`warehouse_supabase_sync_service.dart` **sirf upsert karti hai (by `id`), DELETE bilkul nahi.** Koi bhi **delete+insert-with-new-id** pattern Supabase par **orphan/duplicate** chhodta hai. Hal: same-id UPDATE, ya sync-side explicit delete.

### Fix #2-a — PO items duplicate (sync replace per PO)
`updatePO()` items DELETE-all + naye-id INSERT karta hai → sync upsert-only → Supabase orphans. Fix: `purchase_order_items` generic loop se nikaal kar naya **`_syncPurchaseOrderItemsReplace(conn)`** (Step 1b): distinct un-synced po_ids → har PO ke remote items delete → local poora set upsert → is_synced=true. Per-PO atomic, offline-safe. Log: `🧾 purchase_order_items (replace per PO): N`.

### Fix #2-b — Supplier ledger/balance reconcile on edit
`updatePO()` ka ledger block sirf `becomingReceived` par tha — already-received PO edit par skip. Fix: naya `else if (alreadyReceived...)` block → `UPDATE supplier_ledger SET amount = @remaining WHERE po_id=@poId AND entry_type='purchase'` (same-id UPDATE, orphan nahi) → `fn_update_supplier_balance` trigger balance full-SUM recompute. **Self-heal:** purane out-of-sync PO ko edit→Save karne se ledger theek.

---

## Session 6 — Kya Kiya (Stock ledger + Status consistency + PO edit sync/ledger)

1. **Stock movement ledger + negative stock** — opening/adjustment movements + transfer-accept floor hataya (negative visible; reserved 0-capped).
2. **Stock status available-based** — `isOutOfStock` + getters availableQty par; screen/report/filters consistent.
3. **PO items duplicate** — sync `_syncPurchaseOrderItemsReplace` (delete-then-upsert per PO).
4. **Supplier ledger reconcile** — `updatePO` alreadyReceived block (same-id UPDATE, self-heal).

### ⚠️ Session 6 ke baad BAAQI
- Purana corrupt data cleanup (Supabase duplicate PO items, galat negative stock/`reserved_quantity`, out-of-sync ledger).
- **#5:** duplicate `transfer_out` movements (sync 2-3 baar likhta) + pre-fix pending transfers `reserved_quantity` mein count nahi.
- PO product picker physical qty; web inventory report views ka out-of-stock count.
- Naya product turant search mein nahi dikhta (refresh/sync timing).

### Files chhui (Session 6)
`product_remote_datasource.dart` (opening+adjustment) · `stock_transfer_sync_service.dart` (floor) · `product_model.dart` (getters) · `warehouse_stock_inventory_screen.dart` + `product_provider.dart` (UI/filter) · inventory report provider+screen · `warehouse_supabase_sync_service.dart` (PO items replace) · `purchase_order_remote_datasource.dart` (ledger reconcile)

---

## Session 7 — Kya Kiya (Assign fixes · In-Stock filter · Expense polish · Expense Report · Reports simplify · Company · Salary/Employee) ⭐

### 1. Assign Stock — fixes & 0-qty info-update transfers
- **Duplicate `transfer_number` (23505) friendly message** — `assign_stock_provider.dart` catch mein `isDuplicateTransferNo` detect (23505 / constraint-name / duplicate+transfer_number) → "Yeh transfer ID database mein pehle se mojood hai... restart karein". (Root cause: number sirf success par rotate hota hai; rare, restart workaround.)
- **Offline transfer = SUCCESS treat** — `assign_stock_repository.assignStock()` ab `bool` return karta hai; remote insert **best-effort** with **6s `.timeout()`** + `_isNetworkError()` (offline mein Supabase HTTP client throw nahi karta, HANG karta hai — isliye timeout zaroori). Offline par: local saved (background sync baad mein push) → cart clear + number rotate + **blue snackbar right-bottom 380px** ("Internet nahi — transfer save ho gayi, sync ho jayegi"). `lastSaveOffline` flag `AssignStockState` mein.
- **Transfer report** — store dropdown mein `store_name · store_code`; **default filter = last 7 din** (`_initialFilter()`), refresh par filter qaim, Reset → wapas last-week (all-time nahi).
- **0-qty transfer (product info-update to store)** — store accept `branch_stock_inventory` par prices/barcode/sku/min-max/category UPSERT karta hai (name/unit sirf INSERT par) → 0-qty transfer se store ka product master update hota hai bina stock hilaye. Rules: transfer qty **>= 0** (negative block — `assign_stock_cart_row.dart` `val >= 0`), product available stock **>= 0** ho to add (negative block — `addToCart` `checkStock(...,0)`). Assign par agar koi qty-0 item ho → pehle **`_ZeroQtyWarningDialog`** (product naam + "sirf info update") → Confirm → purana confirm dialog. Reserve/accept math par 0 ka koi asar nahi.

### 2. Stock Inventory
- **"In Stock" filter** — `in_stock` (physical `quantity > 0`) — provider `_computeFiltered` + green button screen par. ⚠️ Yeh PHYSICAL qty hai (available nahi) — reserved-out product In Stock + Out of Stock dono mein aa sakta hai (user ne yehi manga).
- **Duplicate barcode friendly error + product NAAM** — `product_provider._friendlyError()` (async): jo barcodes add/update ho rahe the unhi ko DB mein check karke owner ka naam laata hai (`productNameByBarcode(..., excludeId)` datasource mein) → "Barcode 'X' pehle se 'Coca Cola' par mojood hai". Regex sirf fallback (Postgres `toString()` parse unreliable tha). Error snackbar: right-side 420px card, font 16 w600.

### 3. Warehouse Expense polish
- Quick-select chips: `Electricity` → **`Bills`**; naye chips: **Wawra, Feed, Bike Fuel**. Ab: Rent · Bills · Salary · Transport · Maintenance · Grocery · Wawra · Feed · Bike Fuel · Miscellaneous.
- **Description ab REQUIRED, min 10 chars** (`add_expense_dialog.dart` validator).

### 4. Expense Report (naya — `warehouse_reports/expense/`)
- Cash-flow pattern: `expense_report_models/source/local_datasource/remote_datasource` + provider (kIsWeb switch + `reportsWarehouseIdProvider`) + screen. Shell mein **'Expenses'** registered.
- **Hero card (responsive Row):** left = TOTAL <MONTH> EXPENSE + bada PKR + "Rozana average ≈ X / active day"; right = "N entries · M active days" + **vs-pichla-period chip** (↑red/↓green, equal-length prev period) + "Sabse zyada: <top category> — %". Narrow par stack.
- **Category breakdown** (head/amount/entries/share-bar, wide=table narrow=stacked) + **"HAR RUPYA KAHAN GAYA" proportion stacked bar** + legend. Filter pills: Overall/This Month(default)/Custom range.
- Summary mein `prevTotal`/`hasPrev`/`changePct` — local extra query, remote extra fetch.

### 5. Cash Flow Report — SIMPLIFIED (1519 → ~780 lines)
- **Removed:** Triple Line (Cash Flow Trend), Net Flow per Month, Recent Transactions (+ drill-down sheet/rows), Transaction Type Breakdown — classes DELETE ki gayeen.
- **Ab layout:** (1) **6 summary cards** — Cash In Hand · In · Out · Net Flow · **Total Expense** · **Paid to Supplier** (naye do `typeBreakdown` ke expense/supplier_payment se derive; isliye `typeBreakdown` data ab bhi fetch hota hai) — responsive `_cardGrid` (≥880→3/row, ≥520→2, else 1). (2) **Monthly In vs Out + Expense Breakdown by Category (donut)** — wide(≥700) side-by-side, narrow stacked.
- ⚠️ **`_cardGrid` Row par `crossAxisAlignment.stretch` MAT lagana** — scroll view (unbounded height) mein infinite-height crash. `start` use karo.

### 6. Supplier Report — SIMPLIFIED
- **Removed:** Monthly Purchase Trend (line), Top by Purchase Volume (bar). `fl_chart` import bhi gaya.
- **Pie → `_TopOutstandingChart`:** Top 5 by Outstanding horizontal bars (naam + Rs + width∝outstanding, `_kChartColors`).
- Summary cards responsive `_cardGrid` (≥760→4/row, ≥480→2, else 1). Layout: cards → TopOutstanding → Supplier Balance Table.
- Note: provider abhi bhi `topByPurchase`/`monthlyTrend` fetch karta hai (unused — cleanup pending).

### 7. Company Feature (naya — Category ka FULL mirror)
- **DB (local + Supabase):** `warehouse_companies` (id, warehouse_id FK CASCADE, name, is_active, timestamps, sync fields) + `warehouse_products.company_id` (FK, ON DELETE SET NULL) + indexes. ⚠️ Supabase par `gen_random_uuid()` (BINA `public.` prefix); local par `public.uuid_generate_v4()`.
- **11 files** `company/` — Category jaisa hi (name-only, no description/color).
- **Product integration:** `ProductModel.companyId/companyName`; datasource SELECT `LEFT JOIN warehouse_companies co` + INSERT/UPDATE/`_toMap`/audit-map; **product dialog** mein `_CompanyDropdown` (search + inline "New Company"); provider `filterCompany` + `onFilterCompanyChanged`; inventory screen **Company filter dropdown** (green) + table **"Company" column** (green chip).
- Sidebar "Company" nav (teeno roles), sync `_allTables` mein `warehouse_companies` (products se PEHLE — FK order).

### 8. Salary / Employee Feature (naya) ⭐⭐
> Salary ab dedicated section se track hoti hai — per-employee, per-month, advance ke saath. **Salary EXPENSE BHI hai** (total expense mein + hoti hai).

- **DB (local + Supabase):** `warehouse_employees` + `warehouse_salary_payments` (upar tables mein dekho) + `cash_transactions_entry_type_check` mein **'salary'** + **`fn_update_cash_in_hand()` trigger REPLACE** (salary → -amount, warna cash minus na hota!). Supabase version: DO-block se KOI BHI entry_type check drop karke naya add (naam-mismatch safe).
- **Har payment = 3 records (cash EK baar minus):**
  1. `warehouse_cash_transactions` (entry_type='salary', `WarehouseFinanceRepository.addSalaryEntry()`) → trigger se cash minus + finance row
  2. `warehouse_expenses` row (head='Salary', **usi** cash_txn se linked, apna cash_txn NAHI) → **total expense mein count** (Expense screen/report)
  3. `warehouse_salary_payments` row → per-employee tracking
- **Logic:** monthly cycle (`salary_month` = 1st of month); **advance auto-adjust** (advance bhi month-total mein count → remaining = salary − sab paid); **advance cap** = salary × `max_advance_percent`%; **partial allowed**; month status = pending/partial/paid (computed `EmployeeMonthStatus`).
- **AUTO type (koi manual toggle nahi):** selected month **FUTURE** → **Advance**; current/past → **Salary**. (Current=Salary isliye ke month-end full salary advance-cap par block na ho.) Dialog mein colored read-only badge. Future month ka advance = month navigator se aage jao → Pay.
- **Delete payment:** cash_txn `amount=0` UPDATE (trigger recompute → cash wapas; cash_txn HARD-DELETE kabhi nahi — trigger DELETE par `NEW` null hone se recompute nahi karta) + expense row + payment soft-delete.
- **UI:** Salary Tracking (sidebar "Salary"): month navigator (‹ July 2026 ›) + summary cards (Paid x/y, Pending, Total Paid, Remaining) + employee rows (status badge, Pay button, is-month payments **dates ke saath**) + **Refresh button** + Employees button (**wapsi par auto-reload** `.then((_) => load())`). **Row TAP → `EmployeeHistoryDialog`** (poora record: totals + month-wise groups + har payment date/time). Employees screen: master CRUD.
- **Finance:** `addSalaryEntry()`, model label 'salary'→'Salary', finance screen "Salary" filter tab.
- Sync `_allTables`: `warehouse_employees` (companies ke baad), `warehouse_salary_payments` (expenses ke baad).

### ⚠️ Session 7 ke LAYOUT/TIME lessons (bohat zaroori)
1. **`.icon` Material buttons unbounded-width mein CRASH** ("BoxConstraints forces infinite width") — jab bhi button AppBar `actions`, `mainAxisSize.min` Row, ya center-aligned Column ke top-bar mein ho → **`SizedBox(width: N)` mein wrap karo**, YA parent Container `width: double.infinity`, YA body Column par `crossAxisAlignment: stretch`. (Salary tracking + Employees dono mein yehi tha.)
2. **Custom top-bar wali screens:** Scaffold body Column par `crossAxisAlignment: CrossAxisAlignment.stretch` do (default `center` children ko intrinsic width deta hai → Row+Expanded/Spacer = infinite).
3. **Scroll view ke andar Row par `crossAxisAlignment.stretch` MAT** (infinite HEIGHT crash — cash flow cards mein hua).
4. **`timestamptz` display** — DB UTC store karta hai, driver UTC deta hai → display par **`.toLocal()`** lazmi (salary dates mein fix kiya). `purchase_orders.order_date` bhi DB default now() UTC hai — app pass nahi karta (documented, abhi fix NAHI kiya).
5. **Supabase uuid:** `gen_random_uuid()` bina prefix; local: `public.uuid_generate_v4()`.

---

## Project Path
```
/Users/hashimkhan/Desktop/programming/jan_ghani_final/
```

## Schema Path
```
/Users/hashimkhan/Desktop/janghani pos resourses/db releated/schema v3/zero_start_schema/warehouse_zero_start_schema_v3.8.sql
```
