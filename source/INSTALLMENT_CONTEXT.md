# Jan Ghani — Installment Module Context

## Overview
**Installment** is a NEW top-level feature in the Jan Ghani app — sibling of `accountant`, `branch`, `warehouse`. Yeh module **sirf MOBILE** ke liye hai (accountant mobile app jaisa), **desktop/website nahi**. Maqsad: dukandaar customers ko products **qist (installment)** par bechta hai, aur unki qisten / paid / overdue / baqaya track karta hai.

> ⚠️ **Scope rule:** Sirf `lib/features/installment/` par kaam karna. `warehouse`, `branch`, `accountant` ko **bilkul touch nahi karna**.

> **Abhi tak sab kuch UI-only hai** — koi postgres / Supabase / SQL connection nahi. Data har feature ke `data/` mein **mock** se aata hai. DB baad mein aayega.

---

## Design (Stitch se)
UI pehle **Google Stitch** mein design hua (project: "JanGhani Installment Management Module"), phir Flutter mein banaya gaya.

| | |
|---|---|
| **Font** | Inter |
| **Primary** | Purple `#6C63FF` (= `AppColor.primary`) |
| **Canvas bg** | `#F7F7F9` (screens ka background) |
| **Surface** | White cards (`AppColor.surface`) |
| **Status colors** | Active = purple, Overdue = red, Completed = green |
| **Cards** | `14px` radius, `AppColor.grey200` border |
| **Currency** | `Rs` (PKR) — kabhi `$` nahi |

---

## Folder Structure

Same project convention: har **screen = apna folder**, har folder mein `data / domain / presentation`. Mobile app jaisa singular naming (`screen`, `provider`, `widget`).

```
lib/features/installment/
├── installment_dashboard/                ← main list screen
│   ├── data/
│   │   └── installment_dashboard_mock.dart        ← summary + customers (mock)
│   ├── domain/
│   │   ├── installment_customer.dart              ← InstallmentCustomer + InstallmentPlan + InstallmentStatus
│   │   └── installment_summary.dart               ← top stat cards model
│   └── presentation/
│       ├── provider/
│       │   └── installment_dashboard_provider.dart  ← filter + search state, derived list
│       ├── screen/
│       │   └── installment_dashboard_screen.dart
│       └── widget/
│           ├── installment_stat_card.dart
│           └── installment_customer_card.dart
│
├── register_installment_customer/        ← naya customer add (form)
│   ├── data/                                       (khali — DB baad mein)
│   ├── domain/
│   │   └── new_installment_customer.dart           ← form model (name, phone, cnic, address)
│   └── presentation/
│       └── screen/
│           └── register_installment_customer_screen.dart
│
├── installment_customer_detail/          ← ek customer ke saare plans (multi-plan)
│   ├── data/                                       (khali — DB baad mein)
│   ├── domain/
│   │   └── customer_detail_helpers.dart            ← next-due / monthly / date format (extensions)
│   └── presentation/
│       ├── screen/
│       │   └── installment_customer_detail_screen.dart
│       └── widget/
│           └── installment_plan_card.dart
│
└── installment_plan_detail/              ← ek product plan ki qisten + record payment
    ├── data/                                       (khali — DB baad mein)
    ├── domain/
    │   └── installment_schedule_item.dart          ← schedule item + ScheduleStatus + plan→schedule generator
    └── presentation/
        ├── screen/
        │   └── installment_plan_detail_screen.dart
        └── widget/
            └── installment_schedule_row.dart
```

---

## Navigation Flow (end-to-end)

```
Installment Dashboard
   │  app-bar "+"  →  Register New Customer
   │
   │  tap customer card  ▼
Customer Detail (Multi-Plan)         ← customer ke saare plans
   │  tap plan card / "View installments →"  ▼
Plan Detail                          ← us product ki qisten + Record Payment
```

- **Dashboard → Register:** app-bar `+` icon (`_openRegisterCustomer`).
- **Dashboard → Customer Detail:** customer card tap (`_openCustomerDetail`, customer pass).
- **Customer Detail → Plan Detail:** plan card tap (`plan` + `customerName` pass).

> Yeh screens abhi kahin **mount nahi** ki gayi (app ke `main.dart` mein nahi lagi). Standalone hain. `main.dart` shared infra hai — bina ijazat ke touch nahi kiya.

---

## Domain Models (key)

### `InstallmentStatus` (enum) — `installment_dashboard/domain/installment_customer.dart`
`active` / `overdue` / `completed`. Extension `InstallmentStatusX` deta hai: `label`, `color`, `bgColor`.

### `InstallmentPlan` — ek product ka plan
```dart
id, product, totalPayable, paidAmount, paidCount, totalCount, status, startDate
get remaining       // totalPayable - paidAmount (>= 0)
get progress        // amount-based: paidAmount / totalPayable
get paidLabel       // "06/12 paid"
```

### `InstallmentCustomer` — customer + uske multiple plans
```dart
id, name, plans: List<InstallmentPlan>, phone, cnic
get planCount
get totalPayable / totalPaid / totalRemaining   // saari plans ka sum
get progress          // AGGREGATE amount-based (totalPaid / totalPayable)
get progressPercent   // round %
get status            // PRIORITY: koi overdue→overdue; koi active→active; warna completed
get planSummary       // 1 plan→product naam; warna "Product +N more"
get productsSearchText, get initials
```

### `InstallmentSummary` — dashboard ke top stats
`totalCustomers, customersGrowthPct, activeCount, remainingTotal, collectedThisMonth`.

### Customer Detail helpers — `installment_customer_detail/domain/customer_detail_helpers.dart`
Extensions (shared model touch kiye bina):
- `InstallmentPlanDetailX`: `monthlyAmount`, `nextDueDate`
- `InstallmentCustomerDetailX`: `activePlanCount`, `nextDuePlan`, `nextDueDate`, `nextDueAmount`
- `formatDmy(DateTime)` → "15 Apr 2026"

### Plan Detail schedule — `installment_plan_detail/domain/installment_schedule_item.dart`
- `ScheduleStatus` (enum): `paid` (green) / `due` (amber) / `upcoming` (grey) + `label`/`color`/`bgColor`
- `InstallmentScheduleItem`: `number, dueDate, amount, status`
- `planDetailDmy(DateTime)` — local date format (feature self-contained)
- `buildScheduleFromPlan(plan)` — plan se qisten generate: `paidCount` tak Paid, agli ek Due, baaki Upcoming (UI mock).

---

## Providers (Riverpod) — `installment_dashboard_provider.dart`
| Provider | Type | Kaam |
|---|---|---|
| `installmentSummaryProvider` | `Provider<InstallmentSummary>` | top stats (mock) |
| `installmentSearchProvider` | `StateProvider<String>` | search query |
| `installmentFilterProvider` | `StateProvider<InstallmentFilter>` | All/Active/Completed/Overdue |
| `installmentCustomersProvider` | `Provider<List<InstallmentCustomer>>` | filter + search apply karke list |

`InstallmentFilter` enum + `InstallmentFilterX.label`.

---

## Key Design Decisions

### 1. Multi-plan per customer (IMPORTANT)
Ek customer ek se zyada products qist par le sakta hai (alag-alag waqt par) → har product ka **alag `InstallmentPlan`**. 3 levels:
```
Customer → Plans (har product) → Installments (har qist)
```

### 2. Dashboard card = **Approach B** (one card per customer)
- Ek customer = ek card (products ke alag cards NAHI).
- Progress bar = **amount-based AGGREGATE** (`totalPaid / totalPayable`) — count-based "6/12" nahi, kyunki plans alag lambai ke.
- Right side: `% paid`. Subtitle: `Product +N more` + purple `N plans` badge (jab >1).
- Status badge = **priority** (overdue > active > completed).

### 3. Plan Detail = alag folder
Customer Detail ka "hissa" hone ke bawajood, plan detail apna **alag folder** hai (har screen = apna folder convention). Iski apni schedule/data alag rehti hai.

---

## Screens — kya dikhati hain

### Installment Dashboard
- Top bar: "Installments" + `+`
- Stat cards (horizontal): Total Customers, Remaining, Collected (Mo) — *(Active card + FAB filhal commented hain user ke edit se)*
- Search bar (name/product filter, clear-X button)
- Filter chips: All / Active / Completed / Overdue (Riverpod state se list filter)
- Customer cards (aggregate progress, status accent)

### Register New Customer
- Top bar: `✕` · "New Customer" · Save
- Sirf 4 fields: **Customer Name, Phone Number, CNIC, Address** (koi product/price/installment field nahi)
- Bottom: full-width "Save Customer" button
- (Save abhi sirf SnackBar + pop — UI demo)

### Customer Detail (Multi-Plan)
- Top bar: back · "Customer Detail" · 3-dot
- Header: avatar (initials), naam, phone + CNIC, **Call / WhatsApp** outline buttons
- Summary card: `TOTAL OUTSTANDING` (bada) + Total Paid + Active Plans + **Next Due** (date + Rs)
- "Installment Plans" + count badge → har product ka **plan card** (status, started date, progress, remaining, paid label, "View installments →")

### Plan Detail
- Top bar: back · "Plan Details" · 3-dot
- Header card: product · customer naam · status badge · started date + **2×2 summary** (Total Price, Advance Paid, Paid Amount, **Remaining**=purple) + progress + "X of Y installments paid"
- **Record Payment** full-width purple button
- **Installment Schedule**: har qist row — Paid (green) / Due (amber, highlighted + left accent) / Upcoming (grey), date + amount
- **Contract Details**: Start/End date, Markup (mock 20%), Monthly installment

---

## Conventions Followed
- Sirf `AppColor.*` colors; currency `double.pkrFormat` / `int.compact`
- Riverpod (`Provider` / `StateProvider`); `ConsumerStatefulWidget` sirf jab `TextEditingController` ki zaroorat (dashboard, register)
- `data / domain / presentation` structure; singular `screen / provider / widget`
- Search field: `TextEditingController` + clear (X) button jab text ho
- `withOpacity()` deprecated hai — project mein consistent rakha (naye code mein bhi same)
- Spacing extensions: `16.hBox`, `8.wBox` etc.

---

## Known Lints (expected, OK)
- `withOpacity` deprecation **info** — jaan-boojh kar (project rule: consistency).
- `_Avatar isn't referenced` **warning** — `installment_customer_card.dart` mein avatar usage commented hai (user edit), is liye class unused. (Re-enable ya remove — pending decision.)

> Koi **error** nahi. `flutter analyze lib/features/installment` clean (sirf upar wale info/warning).

---

## Mock Data (`installment_dashboard_mock.dart`)
- `kInstallmentSummaryMock` — stats
- `kInstallmentCustomersMock` — 5 customers; **Arjun Sharma ke 2 plans** (iPhone + AirPods, alag start dates) → multi-plan test ke liye. Baqi 1-1 plan. Sab mein phone + cnic.

---

## Pending / Aage
- Screens app mein **mount** karna (entry point) — abhi standalone hain.
- DB layer (`data/` datasources) — postgres + Supabase, jab UI lock ho.
- Save / Record Payment ka asli logic (abhi no-op / SnackBar).
- `_Avatar` warning resolve (re-enable ya remove).
- Markup abhi Plan Detail mein mock `20%` — baad mein plan data se.

---

## Paths
```
Feature:  /Users/hashimkhan/Desktop/programming/jan_ghani_final/lib/features/installment/
Doc:      /Users/hashimkhan/Desktop/programming/jan_ghani_final/INSTALLMENT_CONTEXT.md
```
