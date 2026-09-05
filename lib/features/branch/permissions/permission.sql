-- ============================================================
-- Branch user permissions — persistence for the Permissions screen
--
-- Ab tak `permissionsProvider` sirf in-memory tha (PermissionsScreen
-- band karte hi sab kuch reset ho jaata tha, sidebar bhi role ke
-- static list se chalta tha). Yeh migration do cheezein add karti hai:
--
--   1. `branch_users.permissions_customized` — flag ke taur par:
--        false → user role ke default permissions use karta hai
--                (PermissionCatalog.defaultsForRole), koi row store
--                nahi hoti.
--        true  → user ke exact granted keys `branch_user_permissions`
--                me pade hain (khaali bhi ho sakte hain — matlab
--                "revoke all" explicitly save kiya gaya tha).
--
--   2. `branch_user_permissions` — har (user, module.action) grant ek
--      row. "Reset to role defaults" is table se user ki rows delete
--      karke `permissions_customized` false kar deta hai, taake role
--      defaults badalne par yeh user khud-ba-khud naye defaults follow
--      kare.
--
-- ⚠️  Yeh migration DONO jagah run karein:
--       1. Local PostgreSQL (store_db)   — psql -U storeuser -d store_db -f <file>
--       2. Supabase (janghani project)   — SQL editor / supabase db push
--     (same file `supabase/migrations/2026_09_05_branch_user_permissions.sql`
--     me bhi rakha hua hai.)
-- ============================================================

ALTER TABLE public.branch_users
  ADD COLUMN IF NOT EXISTS permissions_customized boolean NOT NULL DEFAULT false;

CREATE TABLE IF NOT EXISTS public.branch_user_permissions (
  user_id    uuid NOT NULL REFERENCES public.branch_users(id) ON DELETE CASCADE,
  perm_key   text NOT NULL,          -- `<module>.<action>`, e.g. 'sale_invoice.edit'
  created_at timestamptz NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, perm_key)
);

CREATE INDEX IF NOT EXISTS idx_branch_user_permissions_user
  ON public.branch_user_permissions (user_id);

-- Sync ke liye: branch_users push-only sync already `updated_at` par chalta
-- hai (add_user/update_user dono `updated_at = NOW()` bump karte hain), is
-- liye `permissions_customized` bhi normal user-sync ke saath Supabase
-- pahunch jaata hai — koi extra sync-service wiring nahi chahiye.
--
-- `branch_user_permissions` khud sync table list me nahi hai (abhi
-- branch-local hi kaam karti hai). Agar aage chal kar dusre branches /
-- accountant ko bhi yeh permissions dikhani hon to isko
-- `sync_service.dart` ki table list me add karna hoga.
