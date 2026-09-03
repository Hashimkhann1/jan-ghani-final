-- ============================================================
-- branch_cash_transaction — add missing `user_id` column (Supabase)
--
-- Local Postgres ke `branch_cash_transaction` me `user_id uuid` column
-- hai (cash_transaction_remote_datasource.dart `add()` isme insert karta
-- hai — "branch user id"). Supabase ke table me yeh column kabhi add
-- nahi hua, is liye sync push par:
--
--   ❌ branch_cash_transaction row skip: PostgrestException(
--      message: Could not find the 'user_id' column of
--      'branch_cash_transaction' in the schema cache, code: PGRST204)
--
-- Accountant "Cash Difference" report (branch_cash_difference_datasource
-- .dart) bhi `user_id` select karta hai — yani column expected tha,
-- bس missing reh gaya.
--
-- ⚠️  Yeh migration SIRF Supabase par run karni hai (local me pehle se
--     column mojood hai). SQL editor / `supabase db push`.
-- ============================================================

ALTER TABLE public.branch_cash_transaction
  ADD COLUMN IF NOT EXISTS user_id uuid;

-- PostgREST schema cache turant refresh (warna ~10 min lag sakte hain).
NOTIFY pgrst, 'reload schema';
