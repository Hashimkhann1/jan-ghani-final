-- Ek staff user (owner / accountant / viewer, ya manager jiski branch_id set
-- ho) ke paas Jan Ghani Report aur CUSTOMER account dono ho sakte hain.
-- Customer connect karne par users.role / branch_id / warehouse_id NAHI
-- badalte — sirf users.customer_token set hota hai. App login ke baad
-- "Choose your account" (Customer Account / Jan Ghani Report) dikhati hai.
--
-- Do raaste:
--   1. connect_customer_account(p_customer_id)  — QR scan (role NULL ya staff)
--   2. create_customer_account(...)             — branch se; email pehle se
--      staff user ki ho to naya auth user nahi banta, usi se link hota hai
--      (password / role / branch / warehouse jas ke tas).
-- Dobara chalane se koi nuqsan nahi.

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
  v_token     text;
  v_branch    uuid;
begin
  if v_uid is null then
    raise exception 'Not signed in';
  end if;

  select email, email_confirmed_at into v_email, v_confirmed
  from auth.users where id = v_uid;
  if v_confirmed is null then
    raise exception 'Please confirm your email first';
  end if;

  select id, role, customer_token, branch_id into v_user_id, v_role, v_token, v_branch
  from public.users
  where id = v_uid or lower(email) = lower(v_email)
  order by (id = v_uid) desc
  limit 1
  for update;
  if v_user_id is null then
    raise exception 'Account not found';
  end if;
  if coalesce(v_token, '') <> '' then
    raise exception 'Account is already connected';
  end if;
  -- Owner / accountant / viewer, ya manager (branch ke saath) customer bhi
  -- ban sakte hain.
  if v_role is not null and not (
       v_role in ('owner', 'accountant', 'viewer')
       or (v_role = 'manager' and v_branch is not null)
     ) then
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

  if v_role is null then
    update public.users
    set role = 'customer', customer_token = p_customer_id::text
    where id = v_user_id;
  else
    -- Staff: role / branch_id / warehouse_id jas ke tas.
    update public.users
    set customer_token = p_customer_id::text
    where id = v_user_id;
  end if;
end;
$$;

revoke all on function public.connect_customer_account(uuid) from public, anon;
grant execute on function public.connect_customer_account(uuid) to authenticated;


create or replace function public.create_customer_account(
  p_customer_id uuid,
  p_full_name   text,
  p_email       text,
  p_password    text
)
returns uuid
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  v_email text := lower(trim(p_email));
  v_uid   uuid := gen_random_uuid();
  v_staff uuid;
begin
  if v_email = '' or p_password is null or length(p_password) < 6 then
    raise exception 'Valid email and a password of at least 6 characters are required';
  end if;

  if not exists (
    select 1 from public.customer
    where id = p_customer_id and deleted_at is null
  ) then
    raise exception 'Customer not found';
  end if;

  if exists (
    select 1 from public.users where customer_token = p_customer_id::text
  ) then
    raise exception 'Account already exists for this customer';
  end if;

  -- Email pehle se staff (owner / accountant / viewer / manager+branch) ki
  -- hai aur uske paas customer account nahi → naya auth user nahi, usi se link.
  select id into v_staff
  from public.users
  where lower(email) = v_email
    and (role in ('owner', 'accountant', 'viewer')
         or (role = 'manager' and branch_id is not null))
    and coalesce(customer_token, '') = ''
  limit 1;
  if v_staff is not null then
    update public.users
    set customer_token = p_customer_id::text, updated_at = now()
    where id = v_staff;
    return v_staff;
  end if;

  if exists (select 1 from auth.users where lower(email) = v_email) then
    raise exception 'This email is already registered';
  end if;

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change, email_change_token_new
  ) values (
    '00000000-0000-0000-0000-000000000000', v_uid, 'authenticated',
    'authenticated', v_email, crypt(p_password, gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', p_full_name),
    now(), now(), '', '', '', ''
  );

  insert into auth.identities (
    id, user_id, provider_id, provider, identity_data,
    last_sign_in_at, created_at, updated_at
  ) values (
    gen_random_uuid(), v_uid, v_uid::text, 'email',
    jsonb_build_object('sub', v_uid::text, 'email', v_email,
                       'email_verified', true),
    now(), now(), now()
  );

  insert into public.users (id, full_name, email, role)
  values (v_uid, p_full_name, v_email, null)
  on conflict do nothing;

  update public.users
  set role = 'customer',
      customer_token = p_customer_id::text,
      full_name = p_full_name,
      password = p_password,
      updated_at = now()
  where id = v_uid;

  return v_uid;
end;
$$;
