-- Sirf padhne wali queries (kuch change nahi karti). pgAdmin mein ek ek karke
-- run karo aur teeno ka output bhejo.

-- 1) total_sale / total_amount generated hain ya normal column
select column_name, is_generated, generation_expression, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name   = 'branch_cash_counter'
  and column_name in ('total_sale', 'total_amount');

-- 2) branch_cash_counter par lage triggers
select tgname, pg_get_triggerdef(oid)
from pg_trigger
where tgrelid = 'public.branch_cash_counter'::regclass
  and not tgisinternal;

-- 3) wasooli ka purana trigger function
select pg_get_functiondef('public.fn_ledger_to_cash_counter'::regproc);
