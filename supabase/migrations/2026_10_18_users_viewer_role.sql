-- Naya role: viewer (View User) — sirf Branch aur Warehouse ke reports dekh
-- sakta hai (read-only). Role assign karne ke liye:
--   update public.users set role = 'viewer' where email = '<user email>';
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
      'installment_officer'::text,
      'viewer'::text
    ])
  );
