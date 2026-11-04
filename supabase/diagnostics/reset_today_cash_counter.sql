-- Aaj ka cash counter 0 karna. Ek ek step karke chalao (pgAdmin aakhri result hi dikhata hai).
-- Sirf aaj (CURRENT_DATE) ki row(s) par asar, purane din nahi.

-- STEP 1: PREVIEW — kaunsi rows 0 hongi
select id, store_id, counter_id, counter_date,
       cash_sale, card_sale, credit_sale, installment, cash_in, cash_out,
       total_sale, total_amount
from public.branch_cash_counter
where counter_date = current_date and deleted_at is null;

-- STEP 2: BACKUP (undo ke liye)
create table if not exists public.branch_cash_counter_backup_20261030 as
select * from public.branch_cash_counter where counter_date = current_date;

-- STEP 3: RESET
-- fn_update_cash_counter delta se chalta hai, is liye columns 0 karne par
-- total_amount (Net) se aaj ka hissa khud minus ho jata hai aur total_sale 0 ho jata hai.
-- Sirf ek counter ke liye neeche "and counter_id = '<uuid>'" add kar lo.
update public.branch_cash_counter
set cash_sale = 0, card_sale = 0, credit_sale = 0,
    installment = 0, cash_in = 0, cash_out = 0
where counter_date = current_date and deleted_at is null;

-- STEP 4: CHECK — total_sale 0 aur total_amount kal ke Net ke barabar hona chahiye
select counter_date, counter_id, total_sale, total_amount
from public.branch_cash_counter
where counter_date >= current_date - 1 and deleted_at is null
order by counter_date desc;
