-- Sign up (email ya Google) par public.users mein profile row khud ban jaye:
-- role, branch_id, warehouse_id, customer_token sab NULL. User ko app mein
-- sirf "nearest branch par ja kar account connect karo" dikhta hai; branch
-- wala role / branch_id set karta hai tab login chalta hai.
-- (Dobara chalane se koi nuqsan nahi — sab idempotent hai.)

-- role ab NULL ho sakta hai. CHECK constraints NULL role par pass hote hain
-- (users_role_check, chk_branch_id, chk_warehouse_id, chk_customer_token).
alter table public.users alter column role drop not null;

-- Pichli migration ka 'pending' role wapas
update public.users set role = null where role = 'pending';

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

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, full_name, email, role)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      split_part(new.email, '@', 1)
    ),
    new.email,
    null
  )
  on conflict do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- Pehle se sign up kiye hue auth users ka profile (jin ki row nahi hai)
insert into public.users (id, full_name, email, role)
select
  au.id,
  coalesce(
    nullif(au.raw_user_meta_data ->> 'full_name', ''),
    nullif(au.raw_user_meta_data ->> 'name', ''),
    split_part(au.email, '@', 1)
  ),
  au.email,
  null
from auth.users au
where au.email is not null
  and not exists (select 1 from public.users u where u.id = au.id or lower(u.email) = lower(au.email))
on conflict do nothing;
