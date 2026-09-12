# Inventory Balance — Feature Reference

> **Audience:** Naya developer jo pehli baar is feature ko dekh raha hai. Iss doc mein poora feature stand-alone samjhaya hai — tables, status lifecycle, files, aur design rules.
>
> **Repo:** `jan_ghani_final` (Flutter desktop POS + Supabase). Roman-Urdu + English inline (project convention).
>
> **Related doc:** `WAREHOUSE_CONTEXT.md` (poore warehouse module ka overview; Session 11/12 mein is feature ka summary hai).

---

## 1. Purpose (kya karta hai)

Branch (store) daily physical stock **counting** karta hai — is se pata chalta hai ke system mein stock kitni hai vs actual shelf par kitni hai. **Difference (delta)** ka record `inventory_counting` table mein daily save hota hai, lekin **kabhi branch ke live stock (`branch_stock_inventory.stock`) ko chhota nahi**.

**Inventory Balance** feature is gap ko fill karta hai: warehouse ek **batch** banata hai chuni hui counting rows ka, reviewer (accountant) verify karta hai, branch accept karta hai — phir **actual stock adjust** hoti hai (**delta apply**, not absolute).

**3-role, delta-based, auditable adjustment workflow.**

---

## 2. Roles (3 actors)

| Role | App | Kya karta hai |
|---|---|---|
| **Warehouse** | warehouse app | Chuni hui counting rows ka batch banata (Create Request) → reviewer ko send karta. Delta value edit kar sakta (adjustment override). |
| **Reviewer** | accountant app | Warehouse ne bheji requests ki queue → per-item **Accept** ya **Reject with reason**. Accept → branch ke paas jati; Reject → wapas warehouse ki history mein reason ke saath. |
| **Branch** | branch app | Reviewer-approved items ki queue → per-item **Accept** ya **Reject with reason**. Accept par actual `branch_stock_inventory.stock += delta` **(⚠️ implementation pending — see §9)**. |

**Note:** Reviewer role currently accountant app ke `accountant_inventory_review` folder mein hai — accountant hi dual-duty karta hai (koi dedicated reviewer role nahi banaya).

---

## 3. Lifecycle (state machine)

```
                          ┌────────────────────┐
       Warehouse creates  │                    │  Reviewer rejects
       ─────────────────► │  review_pending    │──────────────────► reviewer_rejected  (TERMINAL)
                          │                    │
                          └────────┬───────────┘
                                   │ Reviewer accepts
                                   ▼
                          ┌────────────────────┐
                          │                    │  Branch rejects
                          │  branch_pending    │──────────────────► branch_rejected    (TERMINAL)
                          │                    │
                          └────────┬───────────┘
                                   │ Branch accepts (⚠️ pending — §9)
                                   ▼
                          ┌────────────────────┐
                          │  applied           │  (TERMINAL — stock adjusted)
                          └────────────────────┘
```

Terminal states: `reviewer_rejected`, `branch_rejected`, `applied`. Rejected items retention: rows never deleted — history preserve.

---

## 4. Status codes (reference table)

**Column:** `inventory_balance_items.status`
**CHECK:** `('review_pending' | 'branch_pending' | 'reviewer_rejected' | 'branch_rejected' | 'applied')`

| DB code | Enum (Dart) | UI label | Meaning | Next possible transitions |
|---|---|---|---|---|
| `review_pending` | `BalanceStatus.reviewPending` | **Review Pending** | Warehouse ne bheja, reviewer ke paas queue mein hai | → `branch_pending` (reviewer accept) OR → `reviewer_rejected` |
| `branch_pending` | `BalanceStatus.branchPending` | **Pending** | Reviewer ne accept kiya, branch ke paas queue mein hai | → `applied` (branch accept + stock adjust) OR → `branch_rejected` |
| `reviewer_rejected` | `BalanceStatus.reviewerRejected` | **Reviewer Rejected** | Reviewer ne reject kar diya + reason liya | **TERMINAL** — koi transition nahi |
| `branch_rejected` | `BalanceStatus.branchRejected` | **Branch Rejected** | Branch ne reject kar diya + reason liya | **TERMINAL** — koi transition nahi |
| `applied` | `BalanceStatus.applied` | **Accepted** | Branch ne accept kiya, actual stock adjust ho gayi | **TERMINAL** — koi transition nahi |

**Default status** (naye row par): `'review_pending'` (DB column default).

**Enum utility** (`domain/balance_status.dart`):
- `BalanceStatus.fromCode(String)` / `.code` — round-trip
- `.label` — UI display text
- `.color` / `.bgColor` — theme colors
- `.isTerminal` — true for rejected + applied

---

## 5. High-variance flag (red-flag)

Not a status — a **derived boolean flag** per item, stored in `is_high_variance` column.

```dart
// domain/balance_status.dart
const double kHighVarianceRupeeThreshold = 5000;

bool isHighVariance(double delta, double unitPrice) =>
    (delta * unitPrice).abs() > kHighVarianceRupeeThreshold;
```

- Computed at batch create time from `|delta × sale_price| > Rs 5000`.
- Shown as red **HIGH** badge in UI (Create Request card + Reviewer queue).
- Warehouse warning: "N red-flag still unselected" in Create Request sticky footer.
- Doesn't block anything — purely UX prompt to double-check.

---

## 6. Database tables

### 6.1 `inventory_counting` (branch-side source)

Branch's daily counting entries — physical count vs system stock. **Feed for balance batches.**

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | `uuid` | NO | `gen_random_uuid()` | PK |
| `store_id` | `uuid` | YES | — | Branch that counted |
| `product_id` | `uuid` | NO | — | |
| `product_stock` | `numeric` | NO | — | System stock **snapshot at count time** |
| `counting_stock` | `numeric` | NO | — | Physical count entered by staff |
| `counted_date` | `date` | YES | `CURRENT_DATE` | Date only (for daily grouping) |
| `updated_at` | `timestamptz` | NO | — | Full timestamp (**UTC-stored** — see §10) |
| `created_at` | `timestamptz` | YES | `now()` | |

**Constraints:**
- `PRIMARY KEY (id)`
- `UNIQUE (store_id, product_id, counted_date)` — same product ek din mein ek hi baar count ho sakta

**Related DB objects:**
- `inventory_counting_batch (store_id, batch_date, product_id, created_at)` — daily 100/120-product batch tracker per store (RPC `get_daily_counting_products` manage karta hai; 7-day cooldown).
- **RPC `get_daily_counting_products(p_store_id, p_days, p_limit)`** — deleted-product filter includes `AND b.deleted_at IS NULL` (Session 12 fix).

### 6.2 `inventory_balance_batches` (warehouse batch header)

Warehouse ki ek "send to reviewer" request ka header — ismein multiple items ho sakte.

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | `uuid` | NO | — | PK |
| `warehouse_id` | `uuid` | NO | — | Warehouse that created batch |
| `store_id` | `uuid` | NO | — | Branch this batch is for |
| `batch_number` | `text` | NO | — | Human-readable ID, format: `IB-<WH_CODE>-YYYYMMDD-XXXXXXX` |
| `notes` | `text` | YES | — | Optional batch-level note |
| `total_items` | `integer` | NO | `0` | Count of linked `inventory_balance_items` rows |
| `created_by` | `uuid` | YES | — | Warehouse user ID |
| `created_by_name` | `text` | YES | — | Denormalized name (UI convenience) |
| `created_at` | `timestamptz` | NO | `now()` | UTC (see §10) |
| `is_synced` | `bool` | NO | `false` | Local→Supabase sync flag |
| `synced_at` | `timestamptz` | YES | — | |

### 6.3 `inventory_balance_items` (the actual line items)

Har row ek product ki adjustment request. **Ye main "workflow" table hai** — status ismein chalta hai.

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | `uuid` | NO | — | PK |
| `batch_id` | `uuid` | NO | — | FK → `inventory_balance_batches.id` **ON DELETE CASCADE** |
| `warehouse_id` | `uuid` | NO | — | Denormalized (query convenience) |
| `store_id` | `uuid` | NO | — | Denormalized |
| `product_id` | `uuid` | NO | — | |
| `product_name` | `text` | NO | — | Denormalized snapshot |
| `product_sku` | `text` | YES | — | |
| `counting_id` | `uuid` | YES | — | FK-like reference to `inventory_counting.id` (source of this delta) |
| `system_stock_at_count` | `numeric` | NO | — | Immutable snapshot from `inventory_counting.product_stock` |
| `physical_stock` | `numeric` | NO | — | Immutable snapshot from `inventory_counting.counting_stock` (branch's evidence) |
| `delta` | `numeric` | NO | — | Warehouse's adjustment amount (usually `physical - system`, but editable in Create Request) |
| `unit_price` | `numeric` | NO | `0` | `sale_price` from `warehouse_products` (for impact calc) |
| `is_high_variance` | `bool` | NO | `false` | Computed at create time: `|delta × unit_price| > 5000` |
| `status` | `text` | NO | `'review_pending'` | **CHECK constraint** — see §4 |
| **Reviewer stamps** | | | | Set on reviewer's action |
| `reviewer_id` | `uuid` | YES | — | |
| `reviewer_name` | `text` | YES | — | Denormalized |
| `reviewer_reviewed_at` | `timestamptz` | YES | — | UTC |
| `reviewer_reason` | `text` | YES | — | Rejection reason (required on reject) |
| **Branch stamps** | | | | Set on branch's action |
| `branch_user_id` | `uuid` | YES | — | |
| `branch_user_name` | `text` | YES | — | |
| `branch_reviewed_at` | `timestamptz` | YES | — | UTC |
| `branch_reason` | `text` | YES | — | Rejection reason |
| **Apply stamps** | | | | Set on `applied` transition |
| `applied_at` | `timestamptz` | YES | — | UTC |
| `applied_stock_before` | `numeric` | YES | — | Live stock read at apply moment |
| `applied_stock_after` | `numeric` | YES | — | = `applied_stock_before + delta` |
| **Sync flags** | | | | |
| `is_synced` | `bool` | NO | `false` | |
| `synced_at` | `timestamptz` | YES | — | |
| `created_at` | `timestamptz` | NO | `now()` | |

**Key constraints:**
- `PRIMARY KEY (id)`
- `FOREIGN KEY (batch_id) REFERENCES inventory_balance_batches(id) ON DELETE CASCADE`
- **`CHECK (status IN ('review_pending','branch_pending','reviewer_rejected','branch_rejected','applied'))`**

### 6.4 `inventory_balance_log` (audit trail)

Har action ka immutable log — kis ne kya kiya kab.

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | `uuid` | NO | — | PK |
| `item_id` | `uuid` | NO | — | FK → items (CASCADE) |
| `batch_id` | `uuid` | NO | — | FK → batches (CASCADE) |
| `action` | `text` | NO | — | **CHECK:** `('created' | 'reviewer_accepted' | 'reviewer_rejected' | 'branch_accepted' | 'branch_rejected' | 'applied')` |
| `actor_id` | `uuid` | YES | — | |
| `actor_name` | `text` | YES | — | |
| `actor_role` | `text` | YES | — | e.g. `'warehouse'`, `'reviewer'`, `'branch'` |
| `notes` | `text` | YES | — | Rejection reasons stored here too |
| `is_synced` | `bool` | NO | `false` | |
| `synced_at` | `timestamptz` | YES | — | |
| `created_at` | `timestamptz` | NO | `now()` | UTC |

**Every state transition MUST also insert a log row** (see §7 write patterns).

### 6.5 Table relationships

```
inventory_counting (branch daily counts)
        │
        │  (counting_id — soft ref)
        ▼
inventory_balance_items ────► inventory_balance_batches (batch header)
        │                              ▲
        │                              │  ON DELETE CASCADE
        │  ON DELETE CASCADE           │
        ▼                              │
inventory_balance_log ─────────────────┘
```

---

## 7. Write patterns (action → SQL)

Every reviewer/branch action does **2 writes** (idempotent-safe):

### 7.1 Warehouse creates batch (offline-first, local Postgres)

Warehouse uses **local Postgres** (offline-first) — one transaction, then background sync pushes to Supabase.

```sql
BEGIN;

-- 1. Batch header
INSERT INTO inventory_balance_batches (id, warehouse_id, store_id, batch_number,
    notes, total_items, created_by, created_by_name, created_at, is_synced)
VALUES (@id, @wid, @storeId, @batchNumber, @notes, @totalItems,
    @createdBy, @createdByName, @createdAt, false);

-- 2. Per selected counting row — item + log
INSERT INTO inventory_balance_items (id, batch_id, warehouse_id, store_id,
    product_id, product_name, product_sku, counting_id,
    system_stock_at_count, physical_stock, delta,
    unit_price, is_high_variance, status, created_at, is_synced)
VALUES (@id, @batchId, @wid, @storeId, @productId, @productName, @sku, @countingId,
    @sysStock, @phyStock, @delta, @unitPrice, @isHighVar,
    'review_pending', @createdAt, false);

INSERT INTO inventory_balance_log (id, item_id, batch_id, action, actor_id, actor_name,
    actor_role, created_at, is_synced)
VALUES (@id, @itemId, @batchId, 'created', @actorId, @actorName, 'warehouse', @createdAt, false);

COMMIT;
```

### 7.2 Reviewer accepts (Supabase direct — reviewer is remote-first)

```sql
-- Guarded update (only if still review_pending)
UPDATE inventory_balance_items
SET status = 'branch_pending',
    reviewer_id = @reviewerId,
    reviewer_name = @reviewerName,
    reviewer_reviewed_at = now(),
    reviewer_reason = NULL,
    is_synced = true,
    synced_at = now()
WHERE id = @itemId AND status = 'review_pending';

INSERT INTO inventory_balance_log (id, item_id, batch_id, action, actor_id, actor_name,
    actor_role, is_synced, synced_at)
VALUES (@id, @itemId, @batchId, 'reviewer_accepted', @reviewerId, @reviewerName,
    'reviewer', true, now());
```

### 7.3 Reviewer rejects

Same as accept, but:
- `status = 'reviewer_rejected'`
- `reviewer_reason = @reason` (required, non-empty)
- Log action: `'reviewer_rejected'`, `notes = @reason`

### 7.4 Branch accepts (⚠️ apply step — pending implementation)

**Design (not yet coded):**

```sql
BEGIN;

-- 1. Read current live stock (locked)
SELECT stock INTO @current_stock
FROM branch_stock_inventory
WHERE store_id = @storeId AND product_id = @productId
FOR UPDATE;

-- 2. Apply DELTA (not absolute!) to live stock
UPDATE branch_stock_inventory
SET stock = @current_stock + @delta,
    updated_at = now()
WHERE store_id = @storeId AND product_id = @productId;

-- 3. Stamp item as applied (guarded)
UPDATE inventory_balance_items
SET status = 'applied',
    branch_user_id = @branchUserId,
    branch_user_name = @branchUserName,
    branch_reviewed_at = now(),
    applied_at = now(),
    applied_stock_before = @current_stock,
    applied_stock_after  = @current_stock + @delta,
    is_synced = true, synced_at = now()
WHERE id = @itemId AND status = 'branch_pending';

-- 4. Log
INSERT INTO inventory_balance_log (id, item_id, batch_id, action, actor_id, actor_name,
    actor_role, is_synced, synced_at)
VALUES (@id, @itemId, @batchId, 'applied', @branchUserId, @branchUserName,
    'branch', true, now());

COMMIT;
```

**⚠️ Critical rule — DELTA apply, NOT absolute:**
```
correct   : stock_after = current_stock_now + delta        ✅ safe under sales/transfers
incorrect : stock_after = physical_stock (from item)       ✗ over-corrects
```
Because between count-time and apply-time, sales/transfers can happen. `system_stock_at_count` snapshot is now stale. Only `delta` is invariant (system and physical both drop in lock-step).

### 7.5 Branch rejects

Similar to reviewer reject — no stock change, just stamp + log.

---

## 8. Frontend module structure

### 8.1 Warehouse (create + report)

`lib/features/warehouse/inventory_balance/`

```
├── domain/
│   └── balance_status.dart              ← 5-state enum + kHighVarianceRupeeThreshold
├── data/
│   ├── model/
│   │   ├── balance_batch_model.dart     ← BalanceBatchModel + PendingCountRow
│   │   └── balance_item_model.dart      ← BalanceItemModel (mirrors items table)
│   ├── datasource/
│   │   ├── inventory_balance_local_datasource.dart   ← local Postgres CRUD (offline-first)
│   │   └── inventory_balance_remote_datasource.dart  ← Supabase reads
│   └── repository/
│       └── inventory_balance_repository.dart         ← thin wrapper (local + remote)
└── presentation/
    ├── provider/
    │   └── inventory_balance_provider.dart
    │       ├─ pendingCountsProvider(storeId)   FutureProvider — inventory_counting rows
    │       ├─ createBatchProvider              StateNotifier — Create Request UI state
    │       └─ balanceReportProvider            StateNotifier — history/report tab
    ├── screens/
    │   └── inventory_balance_screen.dart       ← 2-tab shell (Create Request | Report)
    └── widgets/
        ├── create_batch_panel.dart             ← Tab 1 (main create UI)
        ├── balance_report_panel.dart           ← Tab 2 (history/analytics)
        └── balance_widgets.dart                ← shared: BalanceStatusBadge, FourNumberRow, etc.
```

**Create Request tab (Tab 1):**
- Left sidebar (280px): store picker, summary tiles, view filters (All / Red-flag / Missing / Extra), sort mode
- Main content: item cards with checkbox, SYSTEM (r/o), PHYSICAL (r/o, branch evidence), **DELTA stepper (editable, signed +/-, negatives allowed)**, impact, count date+time footer
- Sticky footer: selected count, total impact, "Send to Reviewer" button
- Session 12 change: **DELTA editable, PHYSICAL read-only** (semantic swap — see WAREHOUSE_CONTEXT.md §6)

**Report tab (Tab 2):**
- Filter bar (date range, store, search)
- 5 KPI cards (Total / Review Pending / Awaiting Branch / Accepted / Rejected)
- Status tab bar
- Batch cards (collapsible) → items with 3-dot timeline (warehouse ● → reviewer ● → branch ●) + status pill + rejection reason
- Right column: This Month summary, 6-week audit trend stacked bars

### 8.2 Reviewer (accountant app)

`lib/features/accountant/accountant_inventory_review/`

```
├── data/
│   ├── datasource/
│   │   └── inventory_review_remote_datasource.dart  ← Supabase direct (no local)
│   └── repository/
│       └── inventory_review_repository.dart
└── presentation/
    ├── provider/
    │   └── inventory_review_provider.dart
    │       ├─ reviewQueueProvider     StateNotifier — pending items (Tab 1)
    │       └─ reviewHistoryProvider   StateNotifier — history (Tab 2)
    ├── screen/
    │   └── accountant_inventory_review_screen.dart  ← 2-tab shell
    └── widget/
        ├── review_queue_panel.dart      ← pending items, per-item Accept/Reject
        ├── review_history_panel.dart    ← all statuses, date+status filters
        └── reject_reason_dialog.dart    ← required-reason input on Reject
```

### 8.3 Branch (counting entry — feeds the workflow)

`lib/features/branch/inventory_management/`

```
├── data/
│   ├── model/inventory_countting_model.dart      ← writes updated_at as UTC (Session 12)
│   └── datasource/inventory_counting_datasource.dart  ← RPC get_daily_counting_products
└── presentation/
    ├── provider/inventory_counting_provider.dart
    └── screen/inventory_counting_screen.dart    ← daily 120-product batch, type-and-tick UI
```

**⚠️ Branch-side "apply" screen — not built yet.** The queue that shows `branch_pending` items to branch users and lets them accept/reject → live stock adjust — this is the next piece to build.

### 8.4 Branch counting report (accountant view of raw counts)

`lib/features/accountant/branch_reports/inventory_counting/` — read-only report of `inventory_counting` table for auditing.

---

## 9. Design decisions & rules

### 9.1 Immutable evidence, mutable adjustment

- **`system_stock_at_count`** and **`physical_stock`** are frozen snapshots — never edit after batch create.
- **`delta`** is the warehouse's decision — editable at create time. Default = `physical - system`, but warehouse can override (e.g., branch counted 10 but warehouse decides to only credit 8).
- Session 12: UI changed to make **delta the editable stepper** and **physical read-only**. Semantic: "warehouse decides the adjustment amount," not "warehouse corrects the count."

### 9.2 Delta apply (not absolute)

See §7.4. **Absolute apply is incorrect** — always apply the delta to live stock at apply time.

### 9.3 Guarded updates (idempotent + race-safe)

Every state transition uses a guarded UPDATE:
```sql
UPDATE ... SET status = 'X' WHERE id = @id AND status = 'Y';
```
Row-count check tells the caller if the transition actually happened. Prevents double-transitions if the action fires twice (network retries, multiple devices).

### 9.4 Sync direction

- **Warehouse:** offline-first local Postgres → background sync pushes to Supabase (`is_synced` flag)
- **Reviewer:** Supabase-direct (no local DB) — writes visible instantly to warehouse only after warehouse refreshes cloud
- **Branch:** design TBD (branch app is currently Supabase-direct like reviewer)

### 9.5 Rejected items — no auto-recount

Rejected rows stay as terminal history. The **branch's next daily count** will naturally pick the product up again if the 7-day cooldown has passed (RPC `get_daily_counting_products` — see `inventory_counting_datasource.dart`). No special "requeue after reject" mechanism needed (design decision, not a bug).

### 9.6 Deleted products excluded

Session 12 fixes:
- RPC `get_daily_counting_products` filters `AND b.deleted_at IS NULL` (2 places: batch insert + return query)
- View `linked_store_inventory_v` filters `WHERE deleted_at IS NULL`

### 9.7 No RLS yet

Currently the DB relies on **app-layer role checks** — Supabase RLS policies for `inventory_balance_*` tables not set up. To harden: add RLS + SECURITY DEFINER RPCs for accept/reject.

---

## 10. Time zone rules (UTC store, local display)

**Rule:** All `timestamptz` writes use UTC; all displays convert to local.

**Write side:**
```dart
'updated_at': DateTime.now().toUtc().toIso8601String()  // has 'Z' suffix
```

**Display side:**
```dart
final l = d.toLocal();
final h12 = l.hour == 0 ? 12 : (l.hour > 12 ? l.hour - 12 : l.hour);
```

**Why:** Dart's `DateTime.now().toIso8601String()` returns naive local time (no `Z`). Supabase `timestamptz` interprets naive strings as UTC → PKT user's `14:30` gets stored as `14:30 UTC` = `19:30 PKT` when read back. **Wrong by 5 hours.** Always UTC on write.

Session 12 fixed this across the chain: branch write (`inventory_counting_model.dart`), warehouse display (`create_batch_panel.dart`, `balance_report_panel.dart`), reviewer display (`review_queue_panel.dart`), branch counting report (`inventory_counting_report_screen.dart`), and `timeAgo` extension.

**Note:** `counted_date` is a plain `date` column — no time. For actual timestamps always use `updated_at`.

---

## 11. Batch naming convention

Warehouse generates human-readable batch numbers:

```
IB-<WAREHOUSE_CODE>-YYYYMMDD-<epoch-suffix><4-digit-random>

Example: IB-KHI01-20260912-8451234
```

Generated by `InventoryBalanceRepository.generateBatchNumber()`. Not enforced by DB (just a text column), just a UX convention.

---

## 12. Open items / not yet built

1. **Branch-side accept/reject screen + apply-to-live-stock RPC** — §7.4 spec ready, code pending. This is the last piece to close the loop.
2. **Realtime notifications** — reviewer accept → branch app auto-refresh; branch accept → warehouse notification.
3. **RLS + SECURITY DEFINER RPCs** — currently DB is trust-based.
4. **Rejected auto-recount override** — bypass 7-day cooldown for rejected-then-recounted products (optional enhancement).
5. **Stale-count red banner** — flag items where `branch_stock_inventory.stock` has diverged heavily from `system_stock_at_count` since count time (suggest recount).

---

## 13. Quick file map (jump-to)

| Area | File |
|---|---|
| Enum + threshold | `lib/features/warehouse/inventory_balance/domain/balance_status.dart` |
| Item model | `lib/features/warehouse/inventory_balance/data/model/balance_item_model.dart` |
| Batch model | `lib/features/warehouse/inventory_balance/data/model/balance_batch_model.dart` |
| Warehouse Supabase reads | `lib/features/warehouse/inventory_balance/data/datasource/inventory_balance_remote_datasource.dart` |
| Warehouse local writes | `lib/features/warehouse/inventory_balance/data/datasource/inventory_balance_local_datasource.dart` |
| Warehouse providers | `lib/features/warehouse/inventory_balance/presentation/provider/inventory_balance_provider.dart` |
| Create Request UI | `lib/features/warehouse/inventory_balance/presentation/widgets/create_batch_panel.dart` |
| Report UI | `lib/features/warehouse/inventory_balance/presentation/widgets/balance_report_panel.dart` |
| Reviewer datasource | `lib/features/accountant/accountant_inventory_review/data/datasource/inventory_review_remote_datasource.dart` |
| Reviewer providers | `lib/features/accountant/accountant_inventory_review/presentation/provider/inventory_review_provider.dart` |
| Reviewer queue UI | `lib/features/accountant/accountant_inventory_review/presentation/widget/review_queue_panel.dart` |
| Reviewer history UI | `lib/features/accountant/accountant_inventory_review/presentation/widget/review_history_panel.dart` |
| Branch counting entry | `lib/features/branch/inventory_management/presentation/screen/inventory_counting_screen.dart` |
| Branch counting model | `lib/features/branch/inventory_management/data/model/inventory_countting_model.dart` |
| Branch counting datasource | `lib/features/branch/inventory_management/data/datasource/inventory_counting_datasource.dart` |

---

## 14. Glossary

| Term | Meaning |
|---|---|
| **Counting** | Branch's daily physical stock check (`inventory_counting` table) — one row per product per day |
| **Batch** | A "send to reviewer" request grouping multiple counting rows (`inventory_balance_batches` + `_items`) |
| **Delta** | `physical - system` — the adjustment amount to apply. Can be negative (physical less than system). |
| **System stock at count** | Snapshot of `branch_stock_inventory.stock` at the moment the branch counted (immutable) |
| **Physical stock** | Number the branch staff actually counted on the shelf (immutable evidence) |
| **Impact** | `|delta × unit_price|` — money value of the discrepancy (used for red-flag threshold) |
| **Red-flag / High variance** | Items where impact > Rs 5000 — warning to double-check |
| **Reviewer** | Second pair of eyes between warehouse and branch — currently accountant does dual-duty |
| **Apply** | Final step where branch accepts and `branch_stock_inventory.stock += delta` |
| **Terminal state** | `reviewer_rejected`, `branch_rejected`, `applied` — no further transitions |
