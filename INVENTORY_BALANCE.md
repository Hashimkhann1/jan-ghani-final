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
| **Branch** | branch app | Reviewer-approved items ki queue → per-item **Accept** ya **Reject with reason**. Accept par actual `branch_stock_inventory.stock += delta` (RPC `apply_inventory_balance_item` — see §7.4). |

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

### 7.4 Branch accepts (implemented — atomic RPC)

Client se `SELECT ... FOR UPDATE` + multi-statement transaction PostgREST se possible nahi (no client-side transactions) — isliye poora apply-step ek **Postgres RPC** (`apply_inventory_balance_item`) ke andar atomic hai. Branch app sirf `_client.rpc('apply_inventory_balance_item', params: {...})` call karta hai; migration: `supabase/migrations/2026_09_13_inventory_balance_branch_apply.sql`.

```sql
CREATE OR REPLACE FUNCTION public.apply_inventory_balance_item(
    p_item_id         uuid,
    p_branch_user_id  uuid,
    p_branch_user_name text
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    v_item     public.inventory_balance_items%ROWTYPE;
    v_current  numeric(14,3);
    v_after    numeric(14,3);
    v_now      timestamptz := now();
BEGIN
    -- 1. Lock + guard the item (idempotent — only branch_pending applies)
    SELECT * INTO v_item
    FROM public.inventory_balance_items
    WHERE id = p_item_id AND status = 'branch_pending'
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'item_not_branch_pending');
    END IF;

    -- 2. Lock the live stock row
    SELECT stock INTO v_current
    FROM public.branch_stock_inventory
    WHERE store_id = v_item.store_id AND product_id = v_item.product_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'stock_row_not_found');
    END IF;

    -- 3. Delta apply (NOT absolute!)
    v_after := v_current + v_item.delta;

    UPDATE public.branch_stock_inventory
    SET stock = v_after, updated_at = v_now
    WHERE store_id = v_item.store_id AND product_id = v_item.product_id;

    -- 4. Stamp item as applied
    UPDATE public.inventory_balance_items
    SET status = 'applied',
        branch_user_id = p_branch_user_id,
        branch_user_name = p_branch_user_name,
        branch_reviewed_at = v_now,
        applied_at = v_now,
        applied_stock_before = v_current,
        applied_stock_after  = v_after,
        is_synced = true, synced_at = v_now
    WHERE id = p_item_id;

    -- 5. Log
    INSERT INTO public.inventory_balance_log (id, item_id, batch_id, action, actor_id,
        actor_name, actor_role, is_synced, synced_at)
    VALUES (gen_random_uuid(), p_item_id, v_item.batch_id, 'applied',
        p_branch_user_id, p_branch_user_name, 'branch', true, v_now);

    RETURN jsonb_build_object('success', true, 'stock_before', v_current, 'stock_after', v_after);
END;
$$;
```

Dart side (`BranchInventoryBalanceDatasource.acceptAndApplyItem`):
```dart
final result = await _client.rpc('apply_inventory_balance_item', params: {
  'p_item_id': itemId,
  'p_branch_user_id': branchUserId,
  'p_branch_user_name': branchUserName,
});
// result['success'] == false → throw BranchInventoryBalanceApplyException(result['error'])
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

**Branch-side "apply" screen — implemented.** `lib/features/branch/inventory_balance/` — 2-tab shell (Pending Requests | History), scoped to the logged-in branch's `store_id` via `authProvider`. Accept confirms then calls the atomic RPC (§7.4); Reject stamps `branch_rejected` + reason, same pattern as reviewer. Wired into `BranchSideBar` (`stock_officer` + `manager`/`owner` roles) under a new `inventory_balance` permission module — see §8.3.1.

### 8.3.1 Branch (balance apply — accept/reject queue)

`lib/features/branch/inventory_balance/`

```
├── data/
│   ├── datasource/
│   │   └── branch_inventory_balance_datasource.dart   ← Supabase direct (no local)
│   └── repository/
│       └── branch_inventory_balance_repository.dart
└── presentation/
    ├── provider/
    │   └── branch_inventory_balance_provider.dart
    │       ├─ branchBalanceQueueProvider    StateNotifier — branch_pending items (Tab 1)
    │       └─ branchBalanceHistoryProvider  StateNotifier — history (Tab 2)
    ├── screen/
    │   └── branch_inventory_balance_screen.dart  ← 2-tab shell
    └── widget/
        ├── branch_balance_queue_panel.dart    ← pending items, Accept (confirm→RPC) / Reject
        └── branch_balance_history_panel.dart  ← all statuses, date+status filters
```

Reuses `warehouse/inventory_balance`'s `balance_status.dart`, `balance_item_model.dart`,
`balance_batch_model.dart`, `balance_widgets.dart`, and accountant's
`reject_reason_dialog.dart` — same cross-role sharing pattern the reviewer module already uses.

Permission: new `inventory_balance` module under the **Stock** group
(`permission_catalog.dart`), granted by default to `stock_officer` and
`store_manager`/`store_owner` (not `cashier`). Sidebar entry: **Stock Balance
Requests** (`branch_sidebar_widget.dart`, INVENTORY section).

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
- **Branch:** Supabase-direct (no local DB) — accept goes through RPC `apply_inventory_balance_item` (atomic; see §7.4), reject is a guarded update like reviewer

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

1. ~~Branch-side accept/reject screen + apply-to-live-stock RPC~~ — **done** (§7.4, §8.3.1). Closes the 3-role loop.
2. **Realtime notifications** — reviewer accept → branch app auto-refresh; branch accept → warehouse notification.
3. **RLS + SECURITY DEFINER RPCs** — currently DB is trust-based. `apply_inventory_balance_item` is a plain `LANGUAGE plpgsql` function (not `SECURITY DEFINER`) — hardening this is still open.
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
| Branch balance datasource (apply/reject) | `lib/features/branch/inventory_balance/data/datasource/branch_inventory_balance_datasource.dart` |
| Branch balance providers | `lib/features/branch/inventory_balance/presentation/provider/branch_inventory_balance_provider.dart` |
| Branch balance queue UI | `lib/features/branch/inventory_balance/presentation/widget/branch_balance_queue_panel.dart` |
| Branch balance history UI | `lib/features/branch/inventory_balance/presentation/widget/branch_balance_history_panel.dart` |
| Apply RPC (Supabase) | `supabase/migrations/2026_09_13_inventory_balance_branch_apply.sql` |

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
