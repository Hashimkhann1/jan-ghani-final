-- Branch customer ka QR (customer id) dikhata hai; app mein role-NULL user
-- scan karta hai to uska account customer se connect hota hai:
--   users.role = 'customer', users.customer_token = <customer id>
-- RPC security definer hai taake user khud apna role/token seedha update na kar sake.

create or replace function public.connect_customer_account(p_customer_id uuid)
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

  if not exists (
    select 1 from public.customer
    where id = p_customer_id and deleted_at is null
  ) then
    raise exception 'Invalid QR code';
  end if;

  if exists (
    select 1 from public.users where customer_token = p_customer_id::text
  ) then
    raise exception 'This customer is already connected to another account';
  end if;

  update public.users
  set role = 'customer', customer_token = p_customer_id::text
  where id = v_user_id;
end;
$$;

revoke all on function public.connect_customer_account(uuid) from public, anon;
grant execute on function public.connect_customer_account(uuid) to authenticated;
