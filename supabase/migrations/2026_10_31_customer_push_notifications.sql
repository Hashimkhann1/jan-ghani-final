-- Customer PWA push notification: jab kisi customer ki sale (invoice) Supabase
-- mein aaye aur us customer ne PWA mein notification on ki ho (subscription
-- save ho), to usay "apni sale ki" notification jaye. Jis customer ne login /
-- notification on nahi ki, usay kuch nahi jata.
--
-- SIRF Supabase (claoud) par chalayein — branch ki local DB par nahi.
--
-- Chalane ke baad 2 cheezein set karni hain (neeche aakhir mein dekhein):
--   1) push_config mein Edge Function ka URL aur secret
--   2) Edge Function `notify-sale` deploy + secrets
--
-- Safe to re-run.

create extension if not exists pg_net with schema extensions;

-- ── Customer ki device subscriptions ─────────────────────────
create table if not exists public.customer_push_subscriptions (
    id         uuid primary key default gen_random_uuid(),
    user_id    uuid not null references auth.users(id) on delete cascade,
    endpoint   text not null unique,
    p256dh     text not null,
    auth       text not null,
    user_agent text,
    created_at timestamptz not null default now()
);

create index if not exists idx_cps_user on public.customer_push_subscriptions(user_id);

alter table public.customer_push_subscriptions enable row level security;

drop policy if exists cps_own_select on public.customer_push_subscriptions;
create policy cps_own_select on public.customer_push_subscriptions
    for select using (user_id = auth.uid());

drop policy if exists cps_own_insert on public.customer_push_subscriptions;
create policy cps_own_insert on public.customer_push_subscriptions
    for insert with check (user_id = auth.uid());

drop policy if exists cps_own_update on public.customer_push_subscriptions;
create policy cps_own_update on public.customer_push_subscriptions
    for update using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists cps_own_delete on public.customer_push_subscriptions;
create policy cps_own_delete on public.customer_push_subscriptions
    for delete using (user_id = auth.uid());

-- ── Config (URL + secret) — RLS on, koi policy nahi: sirf security definer
--    function / dashboard padh sakta hai ─────────────────────────────
create table if not exists public.push_config (
    key   text primary key,
    value text not null
);
alter table public.push_config enable row level security;

-- ── Trigger: nayi sale → Edge Function ───────────────────────
create or replace function public.fn_notify_customer_sale()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
    v_url    text;
    v_secret text;
begin
    -- Sirf customer wali, completed aur taza sale. Purani invoices ka pehla
    -- sync (backfill) notification spam na kare.
    if NEW.customer_id is null
       or NEW.status <> 'completed'
       or NEW.created_at < now() - interval '1 day' then
        return NEW;
    end if;

    -- Sirf jis customer ne login kar ke notification on ki ho
    if not exists (
        select 1
        from public.users u
        join public.customer_push_subscriptions s on s.user_id = u.id
        where u.role = 'customer'
          and u.customer_token = NEW.customer_id::text
    ) then
        return NEW;
    end if;

    select value into v_url    from public.push_config where key = 'notify_sale_url';
    select value into v_secret from public.push_config where key = 'notify_sale_secret';
    if v_url is null or v_secret is null then
        return NEW;
    end if;

    perform net.http_post(
        url     := v_url,
        headers := jsonb_build_object(
                     'Content-Type',     'application/json',
                     'x-webhook-secret', v_secret),
        body    := jsonb_build_object(
                     'invoice_id',      NEW.id,
                     'invoice_no',      NEW.invoice_no,
                     'customer_id',     NEW.customer_id,
                     'grand_total',     NEW.grand_total,
                     'previous_amount', NEW.previous_amount,
                     'new_amount',      NEW.new_amount)
    );

    return NEW;
exception when others then
    -- Notification fail ho to sale ka sync kabhi na ruke
    raise warning 'fn_notify_customer_sale: %', sqlerrm;
    return NEW;
end;
$$;

drop trigger if exists trg_notify_customer_sale on public.sale_invoices;
create trigger trg_notify_customer_sale
    after insert on public.sale_invoices
    for each row execute function public.fn_notify_customer_sale();

-- ── Chalane ke baad (ek dafa, apni values ke saath) ──────────
-- insert into public.push_config (key, value) values
--   ('notify_sale_url',    'https://<project-ref>.supabase.co/functions/v1/notify-sale'),
--   ('notify_sale_secret', '<koi lamba random secret>')
-- on conflict (key) do update set value = excluded.value;
