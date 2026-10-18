-- Branch (desktop) ke User > View drawer ka QR (`user:<branch_users.id>`) app
-- mein role-NULL user scan karta hai to uska account us branch user se connect
-- hota hai:
--   users.role      = branch role ka Supabase role (store_manager -> manager,
--                     cashier -> cashier, stock_officer -> inventory_counter)
--   users.branch_id = branch_users.store_id
-- store_owner ka QR connect nahi hota (owner role QR se nahi milna chahiye).
-- RPC security definer hai taake user khud apna role/branch seedha update na kar sake.

create or replace function public.connect_branch_user_account(p_branch_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid       uuid := auth.uid();
  v_email     text;
  v_confirmed timestamptz;
  v_user_id   uuid;
  v_role      text;
  v_bu_role   text;
  v_store_id  uuid;
  v_new_role  text;
begin
  if v_uid is null then
    raise exception 'Not signed in';
  end if;

  select email, email_confirmed_at into v_email, v_confirmed
  from auth.users where id = v_uid;
  if v_confirmed is null then
    raise exception 'Please confirm your email first';
  end if;

  select id, role into v_user_id, v_role
  from public.users
  where id = v_uid or lower(email) = lower(v_email)
  order by (id = v_uid) desc
  limit 1
  for update;
  if v_user_id is null then
    raise exception 'Account not found';
  end if;
  if v_role is not null then
    raise exception 'Account is already connected';
  end if;

  select role, store_id into v_bu_role, v_store_id
  from public.branch_users
  where id = p_branch_user_id and deleted_at is null and is_active;
  if v_store_id is null then
    raise exception 'Invalid QR code';
  end if;

  v_new_role := case v_bu_role
    when 'store_manager' then 'manager'
    when 'cashier'       then 'cashier'
    when 'stock_officer' then 'inventory_counter'
    else null
  end;
  if v_new_role is null then
    raise exception 'This user role cannot be connected by QR';
  end if;

  update public.users
  set role = v_new_role, branch_id = v_store_id
  where id = v_user_id;
end;
$$;

revoke all on function public.connect_branch_user_account(uuid) from public, anon;
grant execute on function public.connect_branch_user_account(uuid) to authenticated;
