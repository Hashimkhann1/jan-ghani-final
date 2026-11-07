-- Manager / accountant / owner PWA push: jab branch par koi customer wasooli
-- (installment) de aur wo customer_ledger ke zariye Supabase mein sync ho,
-- to jis manager ne PWA mein notification on ki ho usay jaye:
--   "<customer> ne Rs <amount> installment mein diye".
--
-- Subscriptions wahi `customer_push_subscriptions` table use karti hain
-- (2026_10_31_customer_push_notifications.sql) — sirf user ka role alag hai.
--
-- Receivers:
--   * owner, accountant            -> har branch ki wasooli
--   * manager                      -> sirf apni branch (users.branch_id = store_id)
--
-- SIRF Supabase (cloud) par chalayein. Safe to re-run.
--
-- Chalane ke baad ek dafa push_config mein URL set karein (secret wahi
-- 'notify_sale_secret' use hota hai):
--   insert into public.push_config (key, value) values
--     ('notify_installment_url',
--      'https://<project-ref>.supabase.co/functions/v1/notify-installment')
--   on conflict (key) do update set value = excluded.value;
-- Edge Function deploy: supabase functions deploy notify-installment --no-verify-jwt

create extension if not exists pg_net with schema extensions;

create or replace function public.fn_notify_installment_payment()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
    v_url    text;
    v_secret text;
begin
    -- Sirf asli wasooli: amount > 0, delete nahi, taza (purani rows ka pehla
    -- sync spam na kare) aur sale-invoice wali entries nahi.
    if NEW.deleted_at is not null
       or coalesce(NEW.pay_amount, 0) <= 0
       or (NEW.notes is not null and NEW.notes like 'Sale Invoice:%')
       or NEW.created_at < now() - interval '1 day' then
        return NEW;
    end if;

    -- Koi receiver subscribed hai?
    if not exists (
        select 1
        from public.users u
        join public.customer_push_subscriptions s on s.user_id = u.id
        where u.role in ('owner', 'accountant')
           or (u.role = 'manager' and u.branch_id::text = NEW.store_id::text)
    ) then
        return NEW;
    end if;

    select value into v_url    from public.push_config where key = 'notify_installment_url';
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
                     'ledger_id',      NEW.id,
                     'store_id',       NEW.store_id,
                     'customer_id',    NEW.customer_id,
                     'customer_name',  NEW.customer_name,
                     'pay_amount',     NEW.pay_amount,
                     'new_amount',     NEW.new_amount,
                     'payment_method', NEW.payment_method)
    );

    return NEW;
exception when others then
    -- Notification fail ho to ledger ka sync kabhi na ruke
    raise warning 'fn_notify_installment_payment: %', sqlerrm;
    return NEW;
end;
$$;

drop trigger if exists trg_notify_installment_payment on public.customer_ledger;
create trigger trg_notify_installment_payment
    after insert on public.customer_ledger
    for each row execute function public.fn_notify_installment_payment();
