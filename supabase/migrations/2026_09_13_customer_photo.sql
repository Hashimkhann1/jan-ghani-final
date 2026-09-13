-- =============================================================
-- Customer photo — customer_report screen avatar upload
--
-- Part 1 (LOCAL postgres aur Supabase DONO par apply karni hai):
--   public.customer par photo_url column add karta hai.
-- Part 2 (SIRF Supabase par — local postgres mein Storage nahi hota):
--   'customer-photos' storage bucket + RLS policies. App anon key
--   se chalta hai (koi Supabase Auth session nahi), isliye policies
--   baqi tables jaisi hi open rakhi gayi hain.
-- =============================================================

-- ── 1. Column ────────────────────────────────────────────────
ALTER TABLE public.customer
    ADD COLUMN IF NOT EXISTS photo_url text;

-- ── 2. Storage bucket (Supabase only) ───────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('customer-photos', 'customer-photos', true)
ON CONFLICT (id) DO NOTHING;

-- ── 3. RLS policies (Supabase only) ─────────────────────────
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
