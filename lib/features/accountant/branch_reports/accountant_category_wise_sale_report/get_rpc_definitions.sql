-- Run this in Supabase Dashboard → SQL Editor and paste the output back —
-- it shows the current SQL body of the two RPC functions this report
-- uses, so a category filter (or other optimization) can be added to
-- them safely, without guessing their signature.

select pg_get_functiondef(oid)
from pg_proc
where proname in ('get_category_wise_sales', 'get_category_product_sales');
