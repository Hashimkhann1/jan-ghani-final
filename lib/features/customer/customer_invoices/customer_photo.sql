-- =============================================================
-- Customer photo — customer_report screen avatar upload
--
-- Isko Supabase Dashboard > SQL Editor mein paste kar ke Run karein.
-- =============================================================

-- ── 1. Column (Supabase + local Postgres dono par chalana hai) ─
ALTER TABLE public.customer
    ADD COLUMN IF NOT EXISTS photo_url text;

-- ── 2. Storage bucket (sirf Supabase par) ──────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('customer-photos', 'customer-photos', true)
ON CONFLICT (id) DO NOTHING;

-- ── 3. RLS policies (sirf Supabase par) ────────────────────────
DROP POLICY IF EXISTS "customer_photos_public_read"   ON storage.objects;
DROP POLICY IF EXISTS "customer_photos_public_insert"  ON storage.objects;
DROP POLICY IF EXISTS "customer_photos_public_update"  ON storage.objects;
DROP POLICY IF EXISTS "customer_photos_public_delete"  ON storage.objects;

CREATE POLICY "customer_photos_public_read"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'customer-photos');

CREATE POLICY "customer_photos_public_insert"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'customer-photos');

CREATE POLICY "customer_photos_public_update"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'customer-photos');

CREATE POLICY "customer_photos_public_delete"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'customer-photos');
