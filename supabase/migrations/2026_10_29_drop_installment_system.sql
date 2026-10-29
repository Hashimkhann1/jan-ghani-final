-- Installment module hata diya gaya (accountant app se). DESTRUCTIVE: in
-- tables ka saara data permanently delete ho jata hai.

-- RPCs
drop function if exists public.create_installment_plan(uuid, text, numeric, numeric, int, date, jsonb);
drop function if exists public.record_installment_payment(uuid, numeric, text);
drop function if exists public.connect_installment_account(uuid);

-- FK pehle (users -> installment_customer), phir tables (unki RLS policies
-- users.installment_id par depend karti hain), phir column.
alter table public.users drop constraint if exists users_installment_id_fkey;

drop table if exists public.installment_payment;
drop table if exists public.installment_schedule;
drop table if exists public.installment_plan;
drop table if exists public.installment_customer;

-- Helper jo sirf in tables ki RLS mein use hota tha
drop function if exists public.jg_is_installment_staff();

-- users.installment_id (FK ke saath) + customer check wapas sirf customer_token par
alter table public.users drop constraint if exists chk_customer_token;
alter table public.users drop column if exists installment_id;
alter table public.users
  add constraint chk_customer_token check (
    case
      when role = 'customer' then customer_token is not null
      else customer_token is null
    end
  );
