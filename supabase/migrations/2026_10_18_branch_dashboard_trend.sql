-- ============================================================
-- Accountant Branch Dashboard — trend (charts) in ONE RPC
--
-- Pehle har chart 6-7 parallel get_branch_dashboard_summary calls karta tha
-- (har ek mein items join + ledger/cash scans) → statement timeout (57014).
-- Ab ek call, sirf chart ke 5 columns, bucket-wise.
-- ⚠️ Supabase SQL editor mein run karein.
-- ============================================================

drop function if exists get_branch_dashboard_trend(uuid, timestamptz[], timestamptz[]);

create or replace function get_branch_dashboard_trend(
  p_store_id uuid,
  p_starts   timestamptz[],
  p_ends     timestamptz[]
)
returns table (
  idx          int,
  total_sale   numeric,
  total_return numeric,
  gross_profit numeric,
  credit_sale  numeric,
  installment  numeric
)
language sql
stable
set statement_timeout = '60s'
as $$
  select
    b.i::int,
    coalesce(sl.total, 0),
    coalesce(rt.total, 0),
    coalesce(sl.profit, 0) - coalesce(rt.profit, 0),
    coalesce(sl.credit, 0),
    coalesce(lg.paid, 0)
  from unnest(p_starts, p_ends) with ordinality as b(s, e, i)
  left join lateral (
    select
      sum(s.grand_total) as total,
      sum(x.profit)      as profit,
      sum(x.credit)      as credit
    from sale_invoices s
    left join lateral (
      select
        sum((i.sale_price - i.purchase_price) * i.quantity - coalesce(i.discount, 0)) as profit,
        (select sum(p.amount) from sale_invoice_payments p
          where p.invoice_id = s.id and p.payment_method = 'credit') as credit
      from sale_invoice_items i where i.invoice_id = s.id
    ) x on true
    where s.store_id = p_store_id and s.status = 'completed' and s.deleted_at is null
      and s.invoice_date >= b.s and s.invoice_date <= b.e
  ) sl on true
  left join lateral (
    select
      sum(r.grand_total) as total,
      sum(x.profit)      as profit
    from sale_returns r
    left join lateral (
      select sum((i.sale_price - i.purchase_price) * i.quantity - coalesce(i.discount, 0)) as profit
      from sale_return_items i where i.return_id = r.id
    ) x on true
    where r.store_id = p_store_id and r.status = 'completed' and r.deleted_at is null
      and r.return_date >= b.s and r.return_date <= b.e
  ) rt on true
  left join lateral (
    select sum(pay_amount) as paid
    from customer_ledger
    where store_id = p_store_id and deleted_at is null
      and created_at >= b.s and created_at <= b.e
  ) lg on true
  order by b.i;
$$;

-- Summary RPC bhi bade range par 8s default se aage na ruke.
alter function get_branch_dashboard_summary(uuid, timestamptz, timestamptz)
  set statement_timeout = '60s';

notify pgrst, 'reload schema';
