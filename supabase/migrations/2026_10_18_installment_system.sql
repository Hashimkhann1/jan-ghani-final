-- Installment system: customers, plans, schedule, payments + officer RPCs.
-- Role installment_officer (aur owner) customers banata hai, plan calculate
-- karke schedule banata hai aur payments record karta hai. Customer app mein
-- QR scan karke (`inst:<customer id>`) apna account connect karta hai.
-- Pehle 2026_10_17_* migrations chal chuki hon.

-- ── Tables ──────────────────────────────────────────────────────────────────
create table if not exists public.installment_customer (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  phone       text not null default '',
  cnic        text not null default '',
  address     text not null default '',
  -- Customer ka baqi (outstanding) amount: shuru mein 0, plan banne par barhta
  -- hai (plan ka total_payable), payment par ghatta hai.
  amount      numeric(14,2) not null default 0,
  created_by  uuid references public.users(id),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.installment_plan (
  id            uuid primary key default gen_random_uuid(),
  customer_id   uuid not null references public.installment_customer(id) on delete cascade,
  product_name  text not null,
  price         numeric(14,2) not null check (price > 0),
  advance       numeric(14,2) not null check (advance >= 0),
  months        int not null check (months in (6, 10, 12, 18, 24)),
  financed      numeric(14,2) not null,          -- price - advance
  charge_rate   numeric(6,4) not null default 0.025, -- har mahine ka charge
  total_payable numeric(14,2) not null,          -- financed x (1 + rate x months)
  start_date    date not null,
  created_by    uuid references public.users(id),
  created_at    timestamptz not null default now()
);

create table if not exists public.installment_schedule (
  id          uuid primary key default gen_random_uuid(),
  plan_id     uuid not null references public.installment_plan(id) on delete cascade,
  customer_id uuid not null references public.installment_customer(id) on delete cascade,
  number      int not null,
  due_date    date not null,
  amount      numeric(14,2) not null,
  paid_amount numeric(14,2) not null default 0,
  paid_at     timestamptz,
  unique (plan_id, number)
);

create table if not exists public.installment_payment (
  id          uuid primary key default gen_random_uuid(),
  plan_id     uuid not null references public.installment_plan(id) on delete cascade,
  customer_id uuid not null references public.installment_customer(id) on delete cascade,
  schedule_id uuid references public.installment_schedule(id) on delete set null,
  kind        text not null check (kind in ('advance', 'installment')),
  amount      numeric(14,2) not null check (amount > 0),
  received_by uuid references public.users(id),
  paid_at     timestamptz not null default now(),
  note        text
);

create index if not exists installment_plan_customer_idx     on public.installment_plan (customer_id);
create index if not exists installment_schedule_plan_idx     on public.installment_schedule (plan_id);
create index if not exists installment_schedule_customer_idx on public.installment_schedule (customer_id);
create index if not exists installment_payment_plan_idx      on public.installment_payment (plan_id);

-- ── users: installment_id ab asli table se juda hai ──────────────────────────
alter table public.users drop constraint if exists users_installment_id_fkey;
alter table public.users
  add constraint users_installment_id_fkey
  foreign key (installment_id) references public.installment_customer(id) on delete set null;

-- role = customer ko customer_token YA installment_id chahiye
alter table public.users drop constraint if exists chk_customer_token;
alter table public.users
  add constraint chk_customer_token check (
    case
      when role = 'customer' then (customer_token is not null or installment_id is not null)
      else customer_token is null
    end
  );

-- ── Helpers (RLS ke liye) ────────────────────────────────────────────────────
create or replace function public.jg_current_user()
returns public.users
language sql stable security definer set search_path = public as $$
  select u.* from public.users u
  where u.id = auth.uid()
     or lower(u.email) = lower(auth.jwt() ->> 'email')
  order by (u.id = auth.uid()) desc
  limit 1
$$;

create or replace function public.jg_is_installment_staff()
returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select role in ('owner', 'installment_officer') from public.jg_current_user()), false)
$$;

-- ── RLS ──────────────────────────────────────────────────────────────────────
alter table public.installment_customer enable row level security;
alter table public.installment_plan     enable row level security;
alter table public.installment_schedule enable row level security;
alter table public.installment_payment  enable row level security;

drop policy if exists inst_customer_select on public.installment_customer;
create policy inst_customer_select on public.installment_customer for select to authenticated
  using (public.jg_is_installment_staff() or id = (select installment_id from public.jg_current_user()));
drop policy if exists inst_customer_insert on public.installment_customer;
create policy inst_customer_insert on public.installment_customer for insert to authenticated
  with check (public.jg_is_installment_staff());
drop policy if exists inst_customer_update on public.installment_customer;
create policy inst_customer_update on public.installment_customer for update to authenticated
  using (public.jg_is_installment_staff()) with check (public.jg_is_installment_staff());

drop policy if exists inst_plan_select on public.installment_plan;
create policy inst_plan_select on public.installment_plan for select to authenticated
  using (public.jg_is_installment_staff() or customer_id = (select installment_id from public.jg_current_user()));
drop policy if exists inst_schedule_select on public.installment_schedule;
create policy inst_schedule_select on public.installment_schedule for select to authenticated
  using (public.jg_is_installment_staff() or customer_id = (select installment_id from public.jg_current_user()));
drop policy if exists inst_payment_select on public.installment_payment;
create policy inst_payment_select on public.installment_payment for select to authenticated
  using (public.jg_is_installment_staff() or customer_id = (select installment_id from public.jg_current_user()));
-- plan / schedule / payment ki likhai sirf neeche ke RPCs se (security definer).

-- ── RPC: plan banao (calculator ke baad) ─────────────────────────────────────
-- p_schedule: [{"number":1,"due_date":"2026-11-18","amount":3000}, ...]
create or replace function public.create_installment_plan(
  p_customer_id uuid,
  p_product     text,
  p_price       numeric,
  p_advance     numeric,
  p_months      int,
  p_start_date  date,
  p_schedule    jsonb
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  c_rate    constant numeric := 0.025;
  c_min_adv constant numeric := 0.15;
  v_me      public.users;
  v_plan_id uuid := gen_random_uuid();
  v_financed numeric;
  v_total   numeric;
  v_sum     numeric;
begin
  if not public.jg_is_installment_staff() then raise exception 'Not allowed'; end if;
  v_me := public.jg_current_user();

  if not exists (select 1 from installment_customer where id = p_customer_id) then
    raise exception 'Customer not found';
  end if;
  if coalesce(trim(p_product), '') = '' then raise exception 'Product name is required'; end if;
  if p_price is null or p_price <= 0 then raise exception 'Invalid price'; end if;
  if p_months not in (6, 10, 12, 18, 24) then raise exception 'Invalid plan length'; end if;
  if p_advance is null or p_advance < 0 or p_advance >= p_price then
    raise exception 'Invalid advance';
  end if;
  if p_advance < ceil(p_price * c_min_adv) then
    raise exception 'Advance must be at least 15%% of the price';
  end if;

  v_financed := p_price - p_advance;
  v_total    := v_financed * (1 + c_rate * p_months);

  select coalesce(sum((e ->> 'amount')::numeric), 0) into v_sum from jsonb_array_elements(p_schedule) e;
  if jsonb_array_length(p_schedule) <> p_months or abs(v_sum - v_total) > 1.5 then
    raise exception 'Schedule does not match the plan';
  end if;

  insert into installment_plan
    (id, customer_id, product_name, price, advance, months, financed, charge_rate, total_payable, start_date, created_by)
  values
    (v_plan_id, p_customer_id, trim(p_product), p_price, p_advance, p_months, v_financed, c_rate, v_sum, p_start_date, v_me.id);

  insert into installment_schedule (plan_id, customer_id, number, due_date, amount)
  select v_plan_id, p_customer_id, (e ->> 'number')::int, (e ->> 'due_date')::date, (e ->> 'amount')::numeric
  from jsonb_array_elements(p_schedule) e;

  if p_advance > 0 then
    insert into installment_payment (plan_id, customer_id, kind, amount, received_by, note)
    values (v_plan_id, p_customer_id, 'advance', p_advance, v_me.id, 'Advance');
  end if;

  update installment_customer
     set amount = amount + v_sum, updated_at = now()
   where id = p_customer_id;

  return v_plan_id;
end;
$$;

-- ── RPC: qist ki payment ─────────────────────────────────────────────────────
create or replace function public.record_installment_payment(
  p_schedule_id uuid,
  p_amount      numeric,
  p_note        text default null
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_me  public.users;
  v_row installment_schedule;
begin
  if not public.jg_is_installment_staff() then raise exception 'Not allowed'; end if;
  v_me := public.jg_current_user();

  select * into v_row from installment_schedule where id = p_schedule_id for update;
  if not found then raise exception 'Installment not found'; end if;
  if p_amount is null or p_amount <= 0 then raise exception 'Invalid amount'; end if;
  if p_amount > v_row.amount - v_row.paid_amount then
    raise exception 'Amount is more than the remaining installment';
  end if;

  update installment_schedule
     set paid_amount = paid_amount + p_amount,
         paid_at = case when paid_amount + p_amount >= amount then now() else paid_at end
   where id = p_schedule_id;

  insert into installment_payment (plan_id, customer_id, schedule_id, kind, amount, received_by, note)
  values (v_row.plan_id, v_row.customer_id, p_schedule_id, 'installment', p_amount, v_me.id, p_note);

  update installment_customer
     set amount = greatest(amount - p_amount, 0), updated_at = now()
   where id = v_row.customer_id;
end;
$$;

-- ── RPC: customer QR scan se account connect ─────────────────────────────────
create or replace function public.connect_installment_account(p_installment_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid       uuid := auth.uid();
  v_email     text;
  v_confirmed timestamptz;
  v_user_id   uuid;
  v_role      text;
begin
  if v_uid is null then raise exception 'Not signed in'; end if;

  select email, email_confirmed_at into v_email, v_confirmed from auth.users where id = v_uid;
  if v_confirmed is null then raise exception 'Please confirm your email first'; end if;

  select id, role into v_user_id, v_role
  from public.users
  where id = v_uid or lower(email) = lower(v_email)
  order by (id = v_uid) desc
  limit 1
  for update;
  if v_user_id is null then raise exception 'Account not found'; end if;
  if v_role is not null then raise exception 'Account is already connected'; end if;

  if not exists (select 1 from public.installment_customer where id = p_installment_id) then
    raise exception 'Invalid QR code';
  end if;
  if exists (select 1 from public.users where installment_id = p_installment_id) then
    raise exception 'This customer is already connected to another account';
  end if;

  update public.users
     set role = 'customer', installment_id = p_installment_id
   where id = v_user_id;
end;
$$;

revoke all on function public.create_installment_plan(uuid, text, numeric, numeric, int, date, jsonb) from public, anon;
revoke all on function public.record_installment_payment(uuid, numeric, text) from public, anon;
revoke all on function public.connect_installment_account(uuid) from public, anon;
grant execute on function public.create_installment_plan(uuid, text, numeric, numeric, int, date, jsonb) to authenticated;
grant execute on function public.record_installment_payment(uuid, numeric, text) to authenticated;
grant execute on function public.connect_installment_account(uuid) to authenticated;
