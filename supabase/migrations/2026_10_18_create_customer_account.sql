-- Branch customer ke liye asli Supabase Auth account banata hai (customer khud
-- sign up nahi kar sakta). auth.users mein email-confirmed user banta hai, to
-- app mein usi email/password se normal login chalta hai. on_auth_user_created
-- trigger public.users profile bana deta hai; yahan usay customer se link
-- kiya jata hai (role = 'customer', customer_token = customer id).
-- Dobara chalane se koi nuqsan nahi.

create extension if not exists pgcrypto with schema extensions;

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
    select 1 from public.users
    where role = 'customer' and customer_token = p_customer_id::text
  ) then
    raise exception 'Account already exists for this customer';
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

  -- Trigger ne profile bana di hoti hai; na bani ho to yahan bana do.
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

create or replace function public.update_customer_account_password(
  p_user_id      uuid,
  p_new_password text
)
returns void
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
begin
  if p_new_password is null or length(p_new_password) < 6 then
    raise exception 'Password must be at least 6 characters';
  end if;

  if not exists (
    select 1 from public.users where id = p_user_id and role = 'customer'
  ) then
    raise exception 'Customer account not found';
  end if;

  update auth.users
  set encrypted_password = crypt(p_new_password, gen_salt('bf')),
      updated_at = now()
  where id = p_user_id;

  update public.users
  set password = p_new_password, updated_at = now()
  where id = p_user_id;
end;
$$;

create or replace function public.update_customer_account(
  p_user_id   uuid,
  p_full_name text,
  p_email     text
)
returns void
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  v_email text := lower(trim(p_email));
begin
  if v_email = '' or trim(coalesce(p_full_name, '')) = '' then
    raise exception 'Name and email are required';
  end if;

  if not exists (
    select 1 from public.users where id = p_user_id and role = 'customer'
  ) then
    raise exception 'Customer account not found';
  end if;

  if exists (
    select 1 from auth.users where lower(email) = v_email and id <> p_user_id
  ) then
    raise exception 'This email is already registered';
  end if;

  update auth.users
  set email = v_email,
      raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb)
                           || jsonb_build_object('full_name', trim(p_full_name)),
      updated_at = now()
  where id = p_user_id;

  update auth.identities
  set identity_data = identity_data || jsonb_build_object('email', v_email),
      updated_at = now()
  where user_id = p_user_id and provider = 'email';

  update public.users
  set full_name = trim(p_full_name), email = v_email, updated_at = now()
  where id = p_user_id;
end;
$$;

create or replace function public.delete_customer_account(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
begin
  if not exists (
    select 1 from public.users where id = p_user_id and role = 'customer'
  ) then
    raise exception 'Customer account not found';
  end if;

  delete from public.users where id = p_user_id;
  delete from auth.users   where id = p_user_id;  -- identities cascade
end;
$$;

revoke all on function public.create_customer_account(uuid, text, text, text)
  from public;
revoke all on function public.update_customer_account_password(uuid, text)
  from public;
grant execute on function public.create_customer_account(uuid, text, text, text)
  to anon, authenticated;
grant execute on function public.update_customer_account_password(uuid, text)
  to anon, authenticated;
revoke all on function public.update_customer_account(uuid, text, text)
  from public;
revoke all on function public.delete_customer_account(uuid) from public;
grant execute on function public.update_customer_account(uuid, text, text)
  to anon, authenticated;
grant execute on function public.delete_customer_account(uuid)
  to anon, authenticated;
