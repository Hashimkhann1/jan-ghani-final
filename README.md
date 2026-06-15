# Jan Ghani — Flutter POS & Inventory Management System

**Developer (Next One Reading This):** This document explains what we built, how we built it, and what has been completed so far. Read from the beginning.

---

## What is this Project?

Jan Ghani is a **Flutter desktop application** built for a wholesale/retail business. The app has three distinct user types, each with their own separate interface:

| User Type   | App Mode     | Description |
|-------------|--------------|-------------|
| **Branch**  | `store`      | Retail branch staff (owner, manager, cashier, stock user) |
| **Accountant** | `store`   | Same app — but accountant has a separate login and separate dashboard where they can only view reports |
| **Warehouse** | `warehouse` | Warehouse staff — assign stock and manage inventory |

The app mode is determined from `assets/json/config.json` (`app_mode: "store"` or `"warehouse"`).

---

## Tech Stack

| Technology | Use |
|------------|-----|
| **Flutter** | UI framework (Desktop — Windows/Mac/Linux + Web) |
| **Riverpod 2.6** | State Management (StateNotifierProvider + StateNotifier) |
| **PostgreSQL (local)** | Branch's main local database |
| **Supabase** | Cloud database — warehouse and accountant data comes from here |
| **Sync Service** | Local PostgreSQL ↔ Supabase syncs every 120 seconds |
| **pdf + printing** | For printing invoices |
| **SharedPreferences** | For saving session (login persist) |
| **fl_chart** | For dashboard charts |

---

## Architecture — Clean Architecture

We have followed **Clean Architecture**. Each feature is divided into three layers:

```
feature/
├── data/
│   ├── datasource/      ← Directly fetches data from Supabase or PostgreSQL
│   ├── model/           ← Data classes (fromMap / toMap)
│   └── repository/      ← Implements the interface
├── domain/
│   ├── repository/      ← Abstract interface (contract)
│   └── usecase/         ← Single-responsibility class (AddCustomerUseCase etc.)
└── presentation/
    ├── provider/        ← Riverpod StateNotifier + StateNotifierProvider
    ├── screen/          ← UI screens
    ├── widget/          ← Small reusable widgets inside screens
    └── state/           ← State class (only separate in accountant feature)
```

**Note:** Some simple features do not have a domain layer — they go directly `data → presentation`. No usecase was created there.

---

## State Management — Riverpod Pattern

**StateNotifier + StateNotifierProvider** is used throughout the entire project.

### The pattern looks like this:

```dart
// 1. State Class (immutable, has copyWith)
class CustomerState {
  final List<CustomerModel> customers;
  final bool isLoading;
  final String? errorMessage;

  const CustomerState({...});

  CustomerState copyWith({...}) => CustomerState(...);
}

// 2. Notifier (business logic lives here)
class CustomerNotifier extends StateNotifier<CustomerState> {
  CustomerNotifier() : super(const CustomerState());

  Future<void> loadCustomers() async { ... }
  Future<void> addCustomer(CustomerModel c) async { ... }
}

// 3. Provider (global access point)
final customerProvider =
  StateNotifierProvider<CustomerNotifier, CustomerState>(
    (ref) => CustomerNotifier(),
  );
```

### How to use in a screen:

```dart
// Read data
final state = ref.watch(customerProvider);

// Call a method
ref.read(customerProvider.notifier).loadCustomers();
```

### Accountant Authentication pattern is slightly different:

The accountant feature has the full clean architecture implemented — **usecase + repository + notifier**:

```
accountant_auth_providers.dart  →  providers (dependency injection)
accountant_auth_notifier.dart   →  StateNotifier (login/logout logic)
accountant_auth_state.dart      →  State class (AuthStatus enum: initial/loading/success/error)
```

---

## Folder Structure

### `lib/features/branch/` — Branch (Store) Feature

This folder is for branch users (owner, manager, cashier, stock user).

```
lib/features/branch/
│
├── authentication/
│   ├── data/datasource/auth_remote_datasource.dart     ← Login from PostgreSQL
│   └── presentation/
│       ├── provider/auth_provider.dart                 ← AuthNotifier (login/logout/session restore)
│       └── screen/login_screen.dart
│
├── dashboard/
│   ├── data/
│   │   ├── datasource/dashboard_datasource.dart        ← Fetch daily stats
│   │   └── model/dashboard_model.dart
│   └── presentation/
│       ├── provider/dashboard_provider.dart
│       └── screen/dashboard_screen.dart                ← Charts, summary cards, low stock banner
│       └── widget/                                     ← banner_row, chip, counter_badge, etc.
│
├── sale_invoice/                                       ← MAIN FEATURE — POS screen
│   ├── data/
│   │   ├── datasource/
│   │   │   ├── sale_invoice_datasource.dart            ← Save invoice, generate invoice no
│   │   │   ├── held_invoice_datasource.dart            ← Hold/resume invoices
│   │   │   └── sale_return_datasource.dart             ← Sale return
│   │   └── model/
│   │       ├── sale_invoice_model.dart                 ← CartItem, PaymentEntry, SaleInvoiceState
│   │       ├── held_invoice_model.dart
│   │       └── sale_return_model.dart
│   └── presentation/
│       ├── provider/
│       │   ├── sale_invoice_provider.dart              ← SaleInvoiceNotifier (cart + payment logic)
│       │   ├── held_invoice_provider.dart              ← Manage held invoices
│       │   ├── sale_return_provider.dart
│       │   └── cart_nav_provider.dart                  ← Cart panel navigation state
│       ├── screen/
│       │   ├── sale_invoice_screen.dart                ← POS main screen
│       │   ├── payment_dialog.dart                     ← Payment screen
│       │   └── return_payment_dialog.dart
│       └── widget/
│           ├── product_list_panel.dart                 ← Left side — products
│           ├── cart_panel.dart                         ← Right side — cart
│           ├── cart_row_widget.dart
│           ├── cart_summary_widget.dart
│           ├── held_invoices_sheet.dart
│           └── ...
│
├── branch_stock_inventory/                             ← Branch stock
│   ├── data/
│   │   ├── datasource/branch_stock_remote_datasource.dart
│   │   └── model/
│   │       ├── branch_stock_inventory_model.dart       ← Full inventory model
│   │       └── branch_stock_model.dart                 ← Model used in POS
│   └── presentation/
│       ├── provider/branch_stock_inventory_provider.dart
│       └── screen/branch_stock_inventory_screen.dart
│       └── widget/edit_dilog_widget.dart, delete_dilog_widget.dart
│
├── customer/                                           ← Customer management (Clean Architecture)
│   ├── data/
│   │   ├── datasource/customer_remote_datasource.dart
│   │   ├── model/customer_model.dart
│   │   └── repository/customer_repository_impl.dart
│   ├── domain/
│   │   ├── repository/i_customer_repository.dart       ← Abstract interface
│   │   └── usecase/
│   │       ├── add_customer_usecase.dart
│   │       ├── get_customers_usecase.dart
│   │       ├── update_customer_usecase.dart
│   │       └── delete_customer_usecase.dart
│   └── presentation/
│       ├── provider/customer_provider.dart
│       └── screen/
│           ├── all_customer_screen.dart
│           └── customer_verification_screen.dart
│       └── widget/                                     ← badges, dialogs, filter chips etc.
│
├── customer_ledger/                                    ← Customer credit ledger (Clean Architecture)
│   ├── data/ domain/ presentation/                     ← Same pattern as customer
│   └── presentation/screen/
│       ├── all_customer_ledger_screen.dart             ← Entire branch ledger
│       └── counter_customer_ledger_screen.dart         ← Only this counter's ledger
│
├── cash_counter/                                       ← Counter-wise cash record
│   ├── data/
│   │   ├── datasource/
│   │   │   ├── cash_counter_remote_datasource.dart
│   │   │   └── cash_transaction_remote_datasource.dart
│   │   └── model/
│   │       ├── cash_counter_model.dart
│   │       └── cash_transaction_model.dart
│   └── presentation/
│       ├── provider/
│       │   ├── cash_counter_provider.dart
│       │   └── cash_transaction_provider.dart
│       └── screen/
│           ├── cash_counter_screen.dart
│           ├── all_cash_transaction_screen.dart
│           └── counter_cash_transaction_screen.dart
│
├── counter/                                            ← Manage branch counters
│   └── presentation/widget/                           ← counter_table, add_counter_dialog, etc.
│
├── expense/                                            ← Branch expenses (Clean Architecture)
│   ├── data/ domian/ presentation/
│   └── presentation/screen/all_expense_screen.dart
│
├── branch_stock_damage/                                ← Record of damaged stock
│   └── presentation/widget/add_damage_dialog.dart
│
├── branch_transcation/                                 ← Cash transfer from branch to warehouse
│   └── presentation/screen/branch_transaction_screen.dart
│   └── presentation/widget/cash_out_dilog.dart
│
├── cash_store/                                         ← Overall cash summary of store
│   └── presentation/screen/store_summary_screen.dart
│
├── store_user/                                         ← Manage branch users (Clean Architecture)
│   ├── domain/usecase/                                 ← add, get, update, delete usecases
│   └── presentation/screen/user_screen.dart
│
├── assign_stock_to_branch/                             ← Accept stock from warehouse
│   └── presentation/screen/
│       ├── branch_transfer_list_screen.dart            ← Pending/accepted transfers
│       └── stock_transfer_detail_screen.dart
│
└── reports/
    ├── data/datasource/
    │   ├── sale_invoice_report_datasource.dart
    │   ├── sale_return_report_datasource.dart
    │   └── csr_datasource.dart                         ← Counter Summary Report
    └── presentation/
        ├── provider/
        │   ├── sale_invoice_report_provider.dart
        │   ├── sale_return_report_provider.dart
        │   └── csr_provider.dart
        └── screen/
            ├── sale_invoice_report_screen.dart
            ├── sale_return_report_screen.dart
            └── csr_screen.dart                         ← Counter Summary Report screen
```

---

### `lib/features/accountant/` — Accountant Feature

The accountant has their own **separate login system**. They fetch data from Supabase — it is a **read-only view**, no editing is allowed. The accountant can view branch reports, warehouse data, investments, and suppliers.

```
lib/features/accountant/
│
├── authentication/                                     ← FULL Clean Architecture implemented
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── accountant_auth_remote_datasource.dart  ← Login from Supabase
│   │   │   └── accountant_auth_local_datasource.dart   ← SharedPreferences session
│   │   ├── model/accountant_user_model.dart
│   │   └── repositories/accountant_auth_repository_impl.dart
│   ├── domain/
│   │   ├── entities/accountant_user_entity.dart
│   │   ├── repositories/accountant_auth_repository.dart ← Abstract interface
│   │   └── usecases/
│   │       ├── login_accountant_usecase.dart
│   │       └── save_session_usecase.dart
│   └── presentation/
│       ├── notifier/accountant_auth_notifier.dart       ← StateNotifier (login/logout)
│       ├── state/accountant_auth_state.dart             ← AuthStatus enum: initial/loading/success/error
│       ├── providers/
│       │   ├── accountant_auth_providers.dart           ← Dependency injection (all providers)
│       │   └── accoutant_session_provider.dart          ← Session state provider
│       └── screen/login_screen.dart
│
├── dashboard/                                          ← Accountant's main dashboard (Supabase)
│   ├── data/ domain/ presentation/
│   └── presentation/screen/dashboard_screen.dart       ← Overall stats
│
├── branch_reports/                                     ← LARGE SECTION — report for each branch
│   │
│   ├── branch_report_list_screen.dart                  ← List of branches, select to view report
│   ├── ai_chatbot_screen.dart                          ← AI chatbot (currently in development)
│   │
│   ├── accountant_branch/                              ← Branch info
│   │   └── presentation/screen/accountant_branch_screen.dart
│   │
│   ├── accountant_dashboard/                           ← Branch-wise dashboard
│   │   └── presentation/screen/accountant_dashboard_screen.dart
│   │
│   ├── accountant_sale_report/                         ← Branch sales
│   │   └── presentation/screen/accountant_sale_report_screen.dart
│   │
│   ├── accountant_sale_return_report/                  ← Branch sale returns
│   │   └── presentation/screen/sale_return_report_screen.dart
│   │
│   ├── accountant_profit_loss_report/                  ← Profit/Loss report
│   │   └── presentation/screen/accountant_profit_loss_report_screen.dart
│   │
│   ├── accountant_customer/                            ← Branch customers
│   │   └── presentation/screen/accountant_customer_report_screen.dart
│   │
│   ├── accountant_customer_ledger/                     ← Customer credit ledger
│   │   └── presentation/screen/accountant_customer_ledger_screen.dart
│   │
│   ├── customer_report/                                ← Specific customer detail
│   │   ├── data/model/
│   │   │   ├── customer_invoice_model.dart
│   │   │   ├── customer_return_model.dart
│   │   │   └── specific_customer_ledger_model.dart
│   │   └── presentation/screen/customer_report_screen.dart
│   │
│   ├── account_branch_stock_inventory_report/          ← Branch stock (read-only)
│   │   └── presentation/screen/accountant_branch_stock_inventory_report_screen.dart
│   │
│   ├── accountant_branch_summary/                      ← Branch cash summary
│   │   └── presentation/screen/accountant_branch_summary_report_screen.dart
│   │
│   ├── accountant_branch_transaction/                  ← Cash transfers from branch to warehouse
│   │   └── presentation/screen/accountant_branch_transaction_report_screen.dart
│   │
│   ├── accountant_category_wise_sale_report/           ← Sales by category
│   │   └── presentaion/screen/category_sale_report_screen.dart   ← (typo: presentaion)
│   │
│   └── branch_cash_counter_report/                     ← Counter-wise cash report
│       └── presentation/screen/branch_cash_counter_screen.dart
│
├── accountant_all_orders/                              ← All warehouse orders (Supabase)
│   └── presentation/screen/accountant_all_orders_screen.dart
│
├── accountant_all_warehouses/                          ← List of all warehouses
│   └── presentation/screen/accountant_all_warehouses_screen.dart
│
├── accountant_warehouse_dashboard/                     ← Warehouse-wise dashboard + net amount
│   ├── presentation/provider/
│   │   ├── accountant_warehouse_dashboard_provider.dart
│   │   └── janghani_net_amount_provider.dart           ← Jan Ghani total net amount
│   └── presentation/
│       ├── screen/accountant_warehouse_dashboard_screen.dart
│       └── widget/send_cash_dialog.dart                ← Cash transfer dialog
│
├── accountant_warehouse_inventory/                     ← Warehouse stock (read-only)
│   └── presentation/screen/accountant_warehouse_inventory_screen.dart
│
├── accountant_warehouse_finance/                       ← Warehouse finance records
│   └── presentation/screen/accountant_warehouse_finance_screen.dart
│
├── accountant_cash_transfer/                           ← Branch to warehouse cash transfers
│   └── presentation/screen/cash_transfers_screen.dart
│
├── accountant_stock_transfer_record/                   ← Stock transfer records
│   └── presentation/screen/accountant_stock_transfer_record_screen.dart
│
├── investment/                                         ← Investor records (Clean Architecture)
│   └── presentation/screen/investment_screen.dart
│
├── supplier/                                           ← Suppliers and their invoices
│   ├── data/model/
│   │   ├── accountant_supplier_model.dart
│   │   └── accountant_supplier_detail_models.dart      ← Supplier details
│   └── presentation/screen/
│       ├── all_supplier_screen.dart
│       └── supplier_detail_screen.dart
│
└── warehouse_transaction/
    └── presentationpresentation/screen/               ← (typo in folder name — double "presentation")
        └── warehouse_transaction_screen.dart
```

---

## Database Architecture

### Branch (Store Mode)

- Works on a **local PostgreSQL** database (`127.0.0.1:5432`, database: `store_db`)
- All transactions are first saved in the local DB
- A background **Sync Service** syncs local → Supabase every 120 seconds

### Sync Tables (in dependency order):

```
branch → branch_counter → customer → branch_stock_inventory →
branch_expense → branch_users → branch_cash_counter →
branch_cash_transaction → branch_stock_damage →
sale_invoices → sale_invoice_items → sale_invoice_payments →
sale_returns → sale_return_items → sale_return_payments →
customer_ledger → branch_summary → branch_transaction_to_janghani
```

### Accountant / Warehouse

- Fetches data directly from **Supabase** (not local DB)
- Read-only access — no INSERT/UPDATE (only send_cash and investment have write operations)

---

## Authentication — Three Separate Systems

### 1. Branch Auth (`lib/features/branch/authentication/`)
- Login from local PostgreSQL `branch_users` table
- Session saved in `SharedPreferences`
- `AuthState` contains: `userId`, `storeId`, `role`, `counterId`, `username`
- Roles: `owner`, `manager`, `cashier`, `stock`
- `authProvider` (StateNotifierProvider) — used throughout the branch feature

### 2. Accountant Auth (`lib/features/accountant/authentication/`)
- Login from Supabase
- Full Clean Architecture: `RemoteDatasource → Repository → UseCase → Notifier`
- User session stored in `sessionProvider`
- `accountantAuthNotifierProvider` — used throughout the accountant feature

### 3. Warehouse Auth (`lib/features/warehouse/auth/`)
- Separate system for warehouse users

---

## Important Providers — Quick Reference

| Provider | File | Purpose |
|----------|------|---------|
| `authProvider` | `branch/authentication/presentation/provider/auth_provider.dart` | Branch login state + current user info |
| `saleInvoiceProvider` | `branch/sale_invoice/presentation/provider/sale_invoice_provider.dart` | POS cart, payments, invoice save |
| `heldInvoicesProvider` | `branch/sale_invoice/presentation/provider/held_invoice_provider.dart` | Hold/resume invoices |
| `saleReturnProvider` | `branch/sale_invoice/presentation/provider/sale_return_provider.dart` | Sale return flow |
| `branchStockProvider` | `branch/branch_stock_inventory/presentation/provider/branch_stock_inventory_provider.dart` | Branch stock list |
| `customerProvider` | `branch/customer/presentation/provider/customer_provider.dart` | Customer list + CRUD |
| `customerLedgerProvider` | `branch/customer_ledger/presentation/provider/customer_ledger_provider.dart` | Customer ledger |
| `cashCounterProvider` | `branch/cash_counter/presentation/provider/cash_counter_provider.dart` | Cash counter records |
| `dashboardProvider` | `branch/dashboard/presentation/provider/dashboard_provider.dart` | Dashboard stats |
| `accountantAuthNotifierProvider` | `accountant/authentication/presentation/providers/accountant_auth_providers.dart` | Accountant login |
| `sessionProvider` | `accountant/authentication/presentation/providers/accoutant_session_provider.dart` | Accountant session |

---

## App Config — `assets/json/config.json`

```json
{
  "app_mode": "store",
  "warehouse_id": "...",
  "warehouse_name": "...",
  "warehouse_code": "...",
  "db_host": "127.0.0.1",
  "db_port": 5432,
  "db_name": "store_db",
  "db_user": "storeuser",
  "db_password": "..."
}
```

`app_mode: "store"` → Branch + Accountant interface  
`app_mode: "warehouse"` → Warehouse interface

---

## Core Services (`lib/core/service/`)

| Service | Purpose |
|---------|---------|
| `sync/sync_service.dart` | Local PostgreSQL → Supabase sync (every 120s) |
| `print/print_service.dart` | Invoice print |
| `print/sale_invoice_printer_service.dart` | Sale invoice printer service |
| `stock_assign_services/` | Stock transfer sync |
| `warehouse_supabase_sync_service/` | Warehouse specific sync |

---

## Known Issues / Typos in Codebase

For the next developer — these things exist in the code, not by mistake but left as-is:

- `accountant/branch_reports/accountant_category_wise_sale_report/presentaion/` — **"presentaion"** (typo, should be "presentation")
- `accountant/warehouse_transaction/presentationpresentation/` — **"presentationpresentation"** (duplicate word)
- `lib/features/branch/expense/domian/` — **"domian"** (typo, should be "domain")
- `accoutant_session_provider.dart` — **"accoutant"** (typo, should be "accountant")

Do not rename these folders until the entire team is aware — Flutter imports depend on these exact paths.

---

## Work Completed So Far

- Branch POS (sale invoice, sale return, hold invoice) — complete
- Branch stock inventory — complete
- Customer + Customer Ledger — complete (Clean Architecture)
- Cash Counter — complete
- Dashboard — complete (charts + low stock banner)
- Branch reports (sale, return, CSR) — complete
- Expense management — complete
- Counter management — complete
- Store users management — complete
- Accountant authentication — complete (Clean Architecture)
- Accountant dashboard — complete
- Accountant branch reports (15+ reports) — complete
- Accountant warehouse view — complete (read-only)
- Supplier management — complete
- Investment records — complete
- Cash transfer records — complete
- Warehouse feature — separate folder, mostly complete
- Sync service (local ↔ Supabase) — complete

## Currently In Progress / Incomplete

- `ai_chatbot_screen.dart` — located in accountant/branch_reports/, **currently in development**
- Warehouse transaction screen has a typo in folder path, needs to be checked
- Print service (`sale_invoice_printer_service.dart`) — new file, testing in progress

---

*Last updated: June 2026 — Shahab Mustafa*
