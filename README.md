# Jan Ghani — Flutter POS & Inventory Management System

**Developer (Next One Reading This):** Yeh document tumhe batata hai ke humne kya banaya hai, kaise banaya hai, aur ab tak kya kaam complete ho chuka hai. Shuru se padho.

---

## Project Kya Hai?

Jan Ghani ek **Flutter desktop application** hai jo ek wholesale/retail business ke liye bani hai. Is app mein teen alag user types hain aur har ek ka apna alag interface hai:

| User Type   | App Mode     | Description |
|-------------|--------------|-------------|
| **Branch**  | `store`      | Retail branch pe kaam karne wale (owner, manager, cashier, stock user) |
| **Accountant** | `store`   | Ek hi app — lekin accountant ka alag login aur alag dashboard jahan wo sirf reports dekh sakta hai |
| **Warehouse** | `warehouse` | Godam wale — stock assign karna aur inventory manage karna |

App mode `assets/json/config.json` se decide hota hai (`app_mode: "store"` ya `"warehouse"`).

---

## Tech Stack

| Technology | Use |
|------------|-----|
| **Flutter** | UI framework (Desktop — Windows/Mac/Linux + Web) |
| **Riverpod 2.6** | State Management (StateNotifierProvider + StateNotifier) |
| **PostgreSQL (local)** | Branch ka main local database |
| **Supabase** | Cloud database — warehouse aur accountant data yahan se aata hai |
| **Sync Service** | Local PostgreSQL ↔ Supabase har 120 second mein sync hota hai |
| **pdf + printing** | Invoice print karne ke liye |
| **SharedPreferences** | Session save karne ke liye (login persist) |
| **fl_chart** | Dashboard charts ke liye |

---

## Architecture — Clean Architecture

Humne **Clean Architecture** follow ki hai. Har feature teen layers mein divided hai:

```
feature/
├── data/
│   ├── datasource/      ← Supabase ya PostgreSQL se seedha data fetch
│   ├── model/           ← Data classes (fromMap / toMap)
│   └── repository/      ← Interface ko implement karta hai
├── domain/
│   ├── repository/      ← Abstract interface (contract)
│   └── usecase/         ← Ek kaam karne wali class (AddCustomerUseCase etc.)
└── presentation/
    ├── provider/        ← Riverpod StateNotifier + StateNotifierProvider
    ├── screen/          ← UI screens
    ├── widget/          ← Screen ke andar chhote reusable widgets
    └── state/           ← State class (sirf accountant feature mein alag hai)
```

**Note:** Kuch simple features mein domain layer nahi hai — seedha `data → presentation` jata hai. Wahan usecase nahi banaya.

---

## State Management — Riverpod Pattern

Poore project mein **StateNotifier + StateNotifierProvider** use kiya gaya hai.

### Pattern kuch aisa hai:

```dart
// 1. State Class (immutable, copyWith hoti hai)
class CustomerState {
  final List<CustomerModel> customers;
  final bool isLoading;
  final String? errorMessage;

  const CustomerState({...});

  CustomerState copyWith({...}) => CustomerState(...);
}

// 2. Notifier (business logic yahan hoti hai)
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

### Screen mein use kaise karte hain:

```dart
// Data read karna
final state = ref.watch(customerProvider);

// Method call karna
ref.read(customerProvider.notifier).loadCustomers();
```

### Accountant Authentication ka pattern thoda different hai:

Accountant feature mein **usecase + repository + notifier** poora clean architecture implement kiya gaya hai:

```
accountant_auth_providers.dart  →  providers (dependency injection)
accountant_auth_notifier.dart   →  StateNotifier (login/logout logic)
accountant_auth_state.dart      →  State class (AuthStatus enum: initial/loading/success/error)
```

---

## Folder Structure

### `lib/features/branch/` — Branch (Store) Feature

Yeh folder branch users (owner, manager, cashier, stock user) ke liye hai.

```
lib/features/branch/
│
├── authentication/
│   ├── data/datasource/auth_remote_datasource.dart     ← PostgreSQL se login
│   └── presentation/
│       ├── provider/auth_provider.dart                 ← AuthNotifier (login/logout/session restore)
│       └── screen/login_screen.dart
│
├── dashboard/
│   ├── data/
│   │   ├── datasource/dashboard_datasource.dart        ← Daily stats fetch
│   │   └── model/dashboard_model.dart
│   └── presentation/
│       ├── provider/dashboard_provider.dart
│       └── screen/dashboard_screen.dart                ← Charts, summary cards, low stock banner
│       └── widget/                                     ← banner_row, chip, counter_badge, etc.
│
├── sale_invoice/                                       ← MAIN FEATURE — POS screen
│   ├── data/
│   │   ├── datasource/
│   │   │   ├── sale_invoice_datasource.dart            ← Invoice save, invoice no generate
│   │   │   ├── held_invoice_datasource.dart            ← Hold/resume invoices
│   │   │   └── sale_return_datasource.dart             ← Sale return
│   │   └── model/
│   │       ├── sale_invoice_model.dart                 ← CartItem, PaymentEntry, SaleInvoiceState
│   │       ├── held_invoice_model.dart
│   │       └── sale_return_model.dart
│   └── presentation/
│       ├── provider/
│       │   ├── sale_invoice_provider.dart              ← SaleInvoiceNotifier (cart + payment logic)
│       │   ├── held_invoice_provider.dart              ← Hold invoice manage karna
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
├── branch_stock_inventory/                             ← Branch ka stock
│   ├── data/
│   │   ├── datasource/branch_stock_remote_datasource.dart
│   │   └── model/
│   │       ├── branch_stock_inventory_model.dart       ← Full inventory model
│   │       └── branch_stock_model.dart                 ← POS mein use hone wala model
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
├── customer_ledger/                                    ← Customer ka udhar ledger (Clean Architecture)
│   ├── data/ domain/ presentation/                     ← Same pattern as customer
│   └── presentation/screen/
│       ├── all_customer_ledger_screen.dart             ← Poore branch ka ledger
│       └── counter_customer_ledger_screen.dart         ← Sirf is counter ka ledger
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
├── counter/                                            ← Branch counters manage karna
│   └── presentation/widget/                           ← counter_table, add_counter_dialog, etc.
│
├── expense/                                            ← Branch expenses (Clean Architecture)
│   ├── data/ domian/ presentation/
│   └── presentation/screen/all_expense_screen.dart
│
├── branch_stock_damage/                                ← Damage hone wala stock record
│   └── presentation/widget/add_damage_dialog.dart
│
├── branch_transcation/                                 ← Branch se warehouse ko cash transfer
│   └── presentation/screen/branch_transaction_screen.dart
│   └── presentation/widget/cash_out_dilog.dart
│
├── cash_store/                                         ← Store ka overall cash summary
│   └── presentation/screen/store_summary_screen.dart
│
├── store_user/                                         ← Branch users manage karna (Clean Architecture)
│   ├── domain/usecase/                                 ← add, get, update, delete usecases
│   └── presentation/screen/user_screen.dart
│
├── assign_stock_to_branch/                             ← Warehouse se stock accept karna
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

Accountant ka apna **alag login system** hai. Wo Supabase se data fetch karta hai — **read-only view** hai, koi edit nahi hota. Accountant branch reports, warehouse data, investments aur suppliers dekh sakta hai.

```
lib/features/accountant/
│
├── authentication/                                     ← POORA Clean Architecture implement hai
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── accountant_auth_remote_datasource.dart  ← Supabase se login
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
├── dashboard/                                          ← Accountant ka main dashboard (Supabase)
│   ├── data/ domain/ presentation/
│   └── presentation/screen/dashboard_screen.dart       ← Overall stats
│
├── branch_reports/                                     ← BADA SECTION — har branch ki report
│   │
│   ├── branch_report_list_screen.dart                  ← Branches ki list, select karke report dekho
│   ├── ai_chatbot_screen.dart                          ← AI chatbot (abhi development mein)
│   │
│   ├── accountant_branch/                              ← Branch info
│   │   └── presentation/screen/accountant_branch_screen.dart
│   │
│   ├── accountant_dashboard/                           ← Branch-wise dashboard
│   │   └── presentation/screen/accountant_dashboard_screen.dart
│   │
│   ├── accountant_sale_report/                         ← Branch ki sales
│   │   └── presentation/screen/accountant_sale_report_screen.dart
│   │
│   ├── accountant_sale_return_report/                  ← Branch ki sale returns
│   │   └── presentation/screen/sale_return_report_screen.dart
│   │
│   ├── accountant_profit_loss_report/                  ← Profit/Loss report
│   │   └── presentation/screen/accountant_profit_loss_report_screen.dart
│   │
│   ├── accountant_customer/                            ← Branch ke customers
│   │   └── presentation/screen/accountant_customer_report_screen.dart
│   │
│   ├── accountant_customer_ledger/                     ← Customer ka udhar ledger
│   │   └── presentation/screen/accountant_customer_ledger_screen.dart
│   │
│   ├── customer_report/                                ← Specific customer ki detail
│   │   ├── data/model/
│   │   │   ├── customer_invoice_model.dart
│   │   │   ├── customer_return_model.dart
│   │   │   └── specific_customer_ledger_model.dart
│   │   └── presentation/screen/customer_report_screen.dart
│   │
│   ├── account_branch_stock_inventory_report/          ← Branch ka stock (read-only)
│   │   └── presentation/screen/accountant_branch_stock_inventory_report_screen.dart
│   │
│   ├── accountant_branch_summary/                      ← Branch ka cash summary
│   │   └── presentation/screen/accountant_branch_summary_report_screen.dart
│   │
│   ├── accountant_branch_transaction/                  ← Branch se warehouse cash transfers
│   │   └── presentation/screen/accountant_branch_transaction_report_screen.dart
│   │
│   ├── accountant_category_wise_sale_report/           ← Category ke hisaab se sales
│   │   └── presentaion/screen/category_sale_report_screen.dart   ← (typo: presentaion)
│   │
│   └── branch_cash_counter_report/                     ← Counter-wise cash report
│       └── presentation/screen/branch_cash_counter_screen.dart
│
├── accountant_all_orders/                              ← Warehouse ke sare orders (Supabase)
│   └── presentation/screen/accountant_all_orders_screen.dart
│
├── accountant_all_warehouses/                          ← Sare warehouses ki list
│   └── presentation/screen/accountant_all_warehouses_screen.dart
│
├── accountant_warehouse_dashboard/                     ← Warehouse-wise dashboard + net amount
│   ├── presentation/provider/
│   │   ├── accountant_warehouse_dashboard_provider.dart
│   │   └── janghani_net_amount_provider.dart           ← Jan Ghani ka total net amount
│   └── presentation/
│       ├── screen/accountant_warehouse_dashboard_screen.dart
│       └── widget/send_cash_dialog.dart                ← Cash transfer dialog
│
├── accountant_warehouse_inventory/                     ← Warehouse ka stock (read-only)
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
├── investment/                                         ← Investors ka record (Clean Architecture)
│   └── presentation/screen/investment_screen.dart
│
├── supplier/                                           ← Suppliers aur unke invoices
│   ├── data/model/
│   │   ├── accountant_supplier_model.dart
│   │   └── accountant_supplier_detail_models.dart      ← Supplier ki details
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

- **Local PostgreSQL** database pe kaam karta hai (`127.0.0.1:5432`, database: `store_db`)
- Saari transactions pehle local DB mein save hoti hain
- Ek background **Sync Service** har 120 second mein local → Supabase sync karta hai

### Sync Tables (dependency order mein):

```
branch → branch_counter → customer → branch_stock_inventory →
branch_expense → branch_users → branch_cash_counter →
branch_cash_transaction → branch_stock_damage →
sale_invoices → sale_invoice_items → sale_invoice_payments →
sale_returns → sale_return_items → sale_return_payments →
customer_ledger → branch_summary → branch_transaction_to_janghani
```

### Accountant / Warehouse

- Seedha **Supabase** se data fetch karta hai (local DB nahi)
- Read-only access — koi INSERT/UPDATE nahi karta (sirf send_cash aur investment mein write hoti hai)

---

## Authentication — Teen Alag Systems

### 1. Branch Auth (`lib/features/branch/authentication/`)
- Local PostgreSQL `branch_users` table se login
- `SharedPreferences` mein session save hoti hai
- `AuthState` mein: `userId`, `storeId`, `role`, `counterId`, `username`
- Roles: `owner`, `manager`, `cashier`, `stock`
- `authProvider` (StateNotifierProvider) — poore branch feature mein use hota hai

### 2. Accountant Auth (`lib/features/accountant/authentication/`)
- Supabase se login karta hai
- Poora Clean Architecture: `RemoteDatasource → Repository → UseCase → Notifier`
- `sessionProvider` mein user session store hota hai
- `accountantAuthNotifierProvider` — accountant feature mein use hota hai

### 3. Warehouse Auth (`lib/features/warehouse/auth/`)
- Alag system hai warehouse users ke liye

---

## Important Providers — Quick Reference

| Provider | File | Kaam |
|----------|------|------|
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

| Service | Kaam |
|---------|------|
| `sync/sync_service.dart` | Local PostgreSQL → Supabase sync (har 120s) |
| `print/print_service.dart` | Invoice print |
| `print/sale_invoice_printer_service.dart` | Sale invoice ka printer service |
| `stock_assign_services/` | Stock transfer sync |
| `warehouse_supabase_sync_service/` | Warehouse specific sync |

---

## Known Issues / Typos in Codebase

Agle developer ke liye — yeh cheezein code mein hain, galti se nahi:

- `accountant/branch_reports/accountant_category_wise_sale_report/presentaion/` — **"presentaion"** (typo, "presentation" hona chahiye tha)
- `accountant/warehouse_transaction/presentationpresentation/` — **"presentationpresentation"** (double word)
- `lib/features/branch/expense/domian/` — **"domian"** (typo, "domain" hona chahiye tha)
- `accoutant_session_provider.dart` — **"accoutant"** (typo, "accountant" hona chahiye tha)

In folders ko rename mat karna jab tak poori team aware na ho — Flutter imports inhi paths pe hain.

---

## Ab Tak Jo Kaam Complete Hua

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

## Abhi Kya Chal Raha Hai / Incomplete

- `ai_chatbot_screen.dart` — accountant/branch_reports/ mein hai, **abhi development mein hai**
- Warehouse transaction screen ka folder path mein typo hai, check karna
- Print service (`sale_invoice_printer_service.dart`) — naya file hai, testing ho rahi hai

---

*Last updated: June 2026 — Shahab Mustafa*
