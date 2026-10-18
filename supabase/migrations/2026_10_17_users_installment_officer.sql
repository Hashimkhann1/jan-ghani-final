-- Accountant app ab Supabase Auth se login/sign up karti hai.
-- public.users sirf profile (role, branch, ...) rakhta hai; password Supabase
-- Auth (auth.users) mein hota hai. Profile email se auth user se match hota hai.

-- 1) Naya field: installment_id
alter table public.users
  add column if not exists installment_id uuid null;

-- 2) Naya role: installment_officer
alter table public.users drop constraint if exists users_role_check;
alter table public.users
  add constraint users_role_check check (
    role = any (array[
      'owner'::text,
      'manager'::text,
      'accountant'::text,
      'cashier'::text,
      'warehouse_manager'::text,
      'customer'::text,
      'inventory_counter'::text,
      'installment_officer'::text
    ])
  );

-- 3) Auth se sign up hone wale users ka profile row bina password ke banta hai
alter table public.users alter column password drop not null;
