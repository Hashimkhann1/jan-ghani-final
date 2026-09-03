-- ============================================================
-- branch_stock_inventory — soft delete (deleted_at)
--
-- Tak ab `BranchStockDataSource.deleteProduct` hard `DELETE` karta
-- tha. Problem:
--   • Push-only sync (sync_service.dart) kabhi row delete nahi karta —
--     is liye branch se delete hua product Supabase par reh jaata tha
--     aur accountant reports / dusri branch ke sync me wapas aa jaata.
--   • `branch_stock_inventory_logs` me pehle se `deleted_at` hai, lekin
--     parent table me nahi — pattern adhoora tha.
--
-- Ab `customer` table jaisa soft-delete:
--   deleteProduct  → UPDATE ... SET deleted_at = NOW(), updated_at = NOW()
--   saari "current stock" reads → WHERE deleted_at IS NULL
--   updated_at bump hone se soft-delete normal sync se Supabase pahunch
--   jaata hai (koi delete-propagation logic nahi chahiye).
--
-- ⚠️  Yeh migration DONO jagah run karein:
--       1. Local PostgreSQL (store_db)   — psql -U storeuser -d store_db -f <file>
--       2. Supabase (janghani project)   — SQL editor / supabase db push
--     Warna sync push me `deleted_at` column mismatch se
--     branch_stock_inventory ka upsert fail ho jayega.
-- ============================================================

ALTER TABLE public.branch_stock_inventory
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- Active rows (store_id, product_id) — sync ka conflict target isi par
-- hai, aur har "current stock" query deleted_at IS NULL filter karti hai.
CREATE INDEX IF NOT EXISTS idx_branch_stock_inventory_active
  ON public.branch_stock_inventory (store_id, product_id)
  WHERE deleted_at IS NULL;


-- deleteProduct ab `branch_stock_inventory_logs` me change_type='delete'
-- likhta hai. Agar change_type ek enum hai to value add karo (text column
-- hai to yeh DO block chup-chap skip ho jayega).
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_attribute a ON a.atttypid = t.oid
    JOIN pg_class c ON c.oid = a.attrelid
    WHERE c.relname = 'branch_stock_inventory_logs'
      AND a.attname = 'change_type'
      AND t.typtype = 'e'
  ) THEN
    EXECUTE format(
      'ALTER TYPE %s ADD VALUE IF NOT EXISTS ''delete''',
      (SELECT format_type(a.atttypid, NULL)
         FROM pg_attribute a
         JOIN pg_class c ON c.oid = a.attrelid
        WHERE c.relname = 'branch_stock_inventory_logs'
          AND a.attname = 'change_type')
    );
  END IF;
END $$;


-- ── TODO (server-side RPCs — sirf Supabase) ─────────────────────────
-- Branch "Inventory Counting" screen in RPCs par depend karta hai; inke
-- andar `branch_stock_inventory` se select hota hai. Inki body me bhi
-- `AND deleted_at IS NULL` add karna hoga (definitions repo me nahi hain):
--     • get_daily_counting_products(p_store_id, p_days, p_limit)
--     • get_inventory_products(...)   [inventory_counting_datasource.dart]
