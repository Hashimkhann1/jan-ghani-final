# Inventory Counting (Branch / Store)

Physical stock counting feature for a **store (branch)**. Staff counts the *actual physical* quantity of each product and submits it; the system records it against the *system* stock at that moment — an audit/variance trail. It does **not** adjust `branch_stock_inventory.stock`; it only **records** counts.

- **Data source:** Supabase directly (`Supabase.instance.client`) — no local DB, no sync layer.
- **Feature folder:** `lib/features/branch/inventory_management/`
- **Supabase project:** store project (the one the branch app points to).

---

## 1. How it works (user flow)

1. An `inventory_counter` user logs in → their `store_id` comes from the session (`authProvider.storeId`).
2. Screen opens → loads **100 products** of that store that were **NOT counted in the last 6 days** (server-side RPC).
3. For each product, staff types the physical count and taps the green ✓ (or presses keyboard "done").
4. On submit, the product's **current stock at that moment** is fetched fresh and saved with the entered count. The tile disappears from the list.
5. When all 100 are counted → a **Reload** button (AppBar) loads the next 100.
6. A product counted today is **hidden for 6 days**, then reappears on the 7th day (rolling recount).

---

## 2. Files & responsibilities

| File | Role |
|---|---|
| `data/model/inventory_countting_model.dart` | `InventoryProductModel` (list item, read from `branch_stock_inventory`) + `InventoryCountingModel` (row saved to `inventory_counting`). |
| `data/datasource/inventory_counting_datasource.dart` | All Supabase calls: RPC fetch, counted-today count, current-stock fetch, insert. |
| `presentation/provider/inventory_counting_provider.dart` | Riverpod `StateNotifier` — load, submit, duplicate handling, state. `autoDispose.family` keyed by **storeId**. |
| `presentation/screen/inventory_counting_screen.dart` | UI (list + count field + submit). Gets `storeId` from `authProvider`. |

**storeId source:** the screen takes an optional `storeId` param.
- If a non-empty `storeId` is passed → use it (the `inventory_counter` user comes through the unified/accountant login, so the dashboard passes `currentUserProvider.branchId`).
- Else → fall back to branch auth session `ref.watch(authProvider).storeId`.
- If both are empty → a "Store nahi mila — dobara login karein" guard is shown.

See **§4.1 Login & routing** below for the full picture.

---

## 3. Database

### Table: `branch_stock_inventory` (READ — product source)
Columns used: `id, store_id, product_id, product_name, barcode (text[]), stock (numeric), updated_at`.
Unique: `(store_id, product_id)`.

### Table: `inventory_counting` (READ + INSERT — the counting log)
| Column | Type | Meaning |
|---|---|---|
| `id` | uuid PK | `gen_random_uuid()` |
| `product_id` | uuid | which product |
| `product_stock` | numeric | **system stock at submit time** |
| `counting_stock` | numeric | **physical count** entered by staff |
| `updated_at` | timestamptz | record time (`now()` at submit) |
| `created_at` | timestamptz | default `now()` |
| `counted_date` | date | default `CURRENT_DATE` (app sends today) |
| `store_id` | uuid | which store |

### RPC: `get_uncounted_products(p_store_id uuid, p_days int=7, p_limit int=100)`
Returns up to `p_limit` products of the store that have **no counting row within the last `p_days-1` days** (i.e. `counted_date > CURRENT_DATE - p_days`), ordered by `product_name`. Server-side `NOT EXISTS` — the app never fetches the whole table.

```sql
CREATE OR REPLACE FUNCTION public.get_uncounted_products(
  p_store_id uuid,
  p_days     integer DEFAULT 7,
  p_limit    integer DEFAULT 100
)
RETURNS SETOF public.branch_stock_inventory
LANGUAGE sql
STABLE
AS $$
  SELECT b.*
  FROM public.branch_stock_inventory b
  WHERE b.store_id = p_store_id
    AND NOT EXISTS (
      SELECT 1 FROM public.inventory_counting c
      WHERE c.store_id    = p_store_id
        AND c.product_id  = b.product_id
        AND c.counted_date > (CURRENT_DATE - p_days)
    )
  ORDER BY b.product_name ASC
  LIMIT p_limit;
$$;

GRANT EXECUTE ON FUNCTION public.get_uncounted_products(uuid, integer, integer)
  TO anon, authenticated;
```

### Indexes (performance)
```sql
CREATE INDEX IF NOT EXISTS idx_inventory_counting_store_product_date
  ON public.inventory_counting (store_id, product_id, counted_date);

CREATE INDEX IF NOT EXISTS idx_branch_stock_inventory_store_name
  ON public.branch_stock_inventory (store_id, product_name);
```

### Unique constraint (prevents double count same day)
```sql
ALTER TABLE public.inventory_counting
  ADD CONSTRAINT inventory_counting_store_product_date_unique
  UNIQUE (store_id, product_id, counted_date);
```
> If this ever fails to add, dedupe `(store_id, product_id, counted_date)` first.

---

## 4. Key logic (and where to change it)

### 6-day cooldown
- **Where:** RPC `WHERE c.counted_date > (CURRENT_DATE - p_days)` + `_cooldownDays = 7` in the datasource.
- **Meaning:** counted today → excluded for today + next 6 days; reappears on day 7.
- **To change the window:** edit `_cooldownDays` in `inventory_counting_datasource.dart` (it is passed as `p_days`). No SQL change needed.

### Daily page size (100)
- **Where:** `_pageSize = 100` in the datasource (passed as `p_limit`).

### Submit-time stock (not load-time)
- **Where:** `submitCounting()` in the provider calls `fetchCurrentStock(storeId, productId)` right before saving, and stores it as `product_stock`. So `product_stock` = stock **at the moment of submit**, even if sales changed it after the list loaded.

### `updated_at`
- Set to `DateTime.now()` at submit (record time). Not the product's `updated_at`.

### Duplicate handling (graceful)
- **Where:** `submitCounting()` catches `PostgrestException` with `code == '23505'` (unique violation). It means the product was already counted today (e.g. from another device) → the tile is silently removed from the list, **no red error**.

### Counter ("counted: N")
- Shows **counted today** (`fetchCountedTodayCount`). It resets each day and drives the serial numbers in the list (`countedCount + index + 1`).

### storeId
- Optional `storeId` param (passed by the dashboard) → else branch `authProvider.storeId`. Empty → guard message. Details in §4.1.

---

## 4.1 Login & routing (inventory_counter role)

The counting user logs in through the **unified/accountant login** (`users` table, email + password), NOT the branch (local) login. The flow:

```
Login (email + password)  →  currentUserProvider (role, branchId, ...)
        │
        ▼  AccountantDashboardScreen (lib/features/accountant/dashboard/.../dashboard_screen.dart)
   role == 'inventory_counter'  →  return InventoryCountingScreen(storeId: user.branchId)
```

- **Routing:** `dashboard_screen.dart` `build()` has `if (role == 'inventory_counter') return InventoryCountingScreen(storeId: user?.branchId);` (same pattern as the `manager` → `BranchScreen` case). A generic **empty-navItems guard** is also there so no role ever crashes with a `navItems[safeIndex]` RangeError.
- **store id = `branchId`:** the user's `branch_id` (from `currentUserProvider`) is the store id passed to the screen.

### `users` table (Supabase) — creating a counting user
Columns: `id (PK, gen_random_uuid)`, `full_name`, `email` (**NOT NULL, required, = login id**), `role`, `branch_id`, `warehouse_id`, `customer_token`, `password` (**plaintext** — login does `.eq('password', password)`), `created_at/updated_at` (default now()).

CHECK constraints matter — an `inventory_counter` user with a `branch_id` requires these to be updated first:

```sql
-- 1) allow the new role
ALTER TABLE public.users DROP CONSTRAINT users_role_check;
ALTER TABLE public.users ADD CONSTRAINT users_role_check
  CHECK (role = ANY (ARRAY['owner','manager','accountant','cashier',
    'warehouse_manager','customer','inventory_counter']));

-- 2) allow inventory_counter to carry a branch_id (store-based role)
ALTER TABLE public.users DROP CONSTRAINT chk_branch_id;
ALTER TABLE public.users ADD CONSTRAINT chk_branch_id
  CHECK (CASE
    WHEN role = ANY (ARRAY['manager','cashier','inventory_counter'])
      THEN branch_id IS NOT NULL
    ELSE branch_id IS NULL
  END);

-- 3) create the user
INSERT INTO public.users (full_name, email, role, branch_id, warehouse_id, customer_token, password)
VALUES ('M Hashim Count', 'set-a-login-email@example.com', 'inventory_counter',
        '<store_branch_id>', NULL, NULL, '<plaintext_password>');
```
> Other constraints for reference: `chk_warehouse_id` (warehouse_id only for `warehouse_manager`), `chk_customer_token` (customer_token only for `customer`).

---

## 5. Data flow (summary)

```
Login (inventory_counter)
        │  authProvider.storeId
        ▼
Screen ──watch──► inventoryCountingProvider(storeId)
        │
        ├─ loadPage()
        │     ├─ RPC get_uncounted_products(storeId, 7, 100)  → 100 products
        │     └─ fetchCountedTodayCount(storeId)              → counter
        │
        └─ submitCounting(product, count)
              ├─ fetchCurrentStock(storeId, productId)   → submit-time stock
              ├─ INSERT inventory_counting               → (23505 = already counted → graceful)
              └─ remove tile + counter++
```

---

## 6. Known limits / future ideas (not done)
- **Barcode scan / search** to jump to a product (would speed counting) — needs UI change.
- **Variance display** (system vs physical difference) on the tile — UI change.
- **Offline queue** — currently online-only (Supabase direct).
- `inventory_counting.store_id` is nullable; could be made `NOT NULL`.
- The "next 100" reload only advances after the current 100 are counted (uncounted set shrinks as you count). It is not offset-based pagination.

---

## 7. Deploy checklist (when setting up a new store DB)
1. Run the **RPC** + **indexes** + **unique constraint** SQL (§3) on the Supabase store project.
2. Update the **`users` CHECK constraints** and create the counting user(s) (§4.1) — `role = 'inventory_counter'`, `branch_id = <store id>`, a login `email`, plaintext `password`.
3. Routing is already wired: `dashboard_screen.dart` sends `inventory_counter` → `InventoryCountingScreen`. No extra nav work needed — just log in with that user.
