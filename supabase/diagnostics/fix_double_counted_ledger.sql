-- Pehle ki ghalat Net (total_amount) theek karne ke liye.
-- Sirf un wasooli rows par jo meri pehli (galat) trigger chalne ke baad aayin.
--
-- STEP 0: migration 2026_10_30_ledger_payment_method.sql run karo.
-- STEP 1: neeche since ko wo time do jab pehli dafa trigger lagayi thi, aur
--         PREVIEW chalao. Har row ka extra = jitna Net mein double gina gaya.
-- STEP 2: preview theek lage to UPDATE chalao.

-- PREVIEW
with dbl as (
    select store_id, counter_id, created_at::date as d, sum(pay_amount) as extra
    from public.customer_ledger
    where deleted_at is null
      and (notes is null or notes not like 'Sale Invoice:%')
      and created_at >= timestamptz '2026-10-30 00:00+05'   -- <-- edit: trigger lagne ka time
    group by 1, 2, 3
)
select b.counter_date, b.counter_id, b.cash_sale, b.card_sale, b.installment,
       b.total_amount as net_now, d.extra, b.total_amount - d.extra as net_fixed
from public.branch_cash_counter b
join dbl d on d.store_id = b.store_id and d.counter_id = b.counter_id
          and d.d = b.counter_date;

-- UPDATE (preview theek ho tab hi chalao; ek dafa)
-- update public.branch_cash_counter b
-- set total_amount = b.total_amount - d.extra
-- from (
--     select store_id, counter_id, created_at::date as d, sum(pay_amount) as extra
--     from public.customer_ledger
--     where deleted_at is null
--       and (notes is null or notes not like 'Sale Invoice:%')
--       and created_at >= timestamptz '2026-10-30 00:00+05'
--     group by 1, 2, 3
-- ) d
-- where d.store_id = b.store_id and d.counter_id = b.counter_id
--   and d.d = b.counter_date;
