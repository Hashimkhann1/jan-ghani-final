-- ============================================================
-- Branch Dashboard — Insights graphs (2 indexed RPCs)
--
--  get_branch_insights_range : hourly sale, category sale, staff sale,
--      loss-making products, top customers, top udhaar, dead stock
--  get_branch_insights_trend : bucket-wise sale/profit(margin), discount,
--      credit given vs recovered, damage, cash in vs out
--
-- Sab aggregation database mein; app ko sirf chand rows milti hain.
-- Indexes (pehle se maujood): idx_sale_invoices_store_status_date,
-- idx_sale_invoice_items_invoice, idx_customer_ledger_store_created,
-- idx_branch_cash_txn_store_created, idx_branch_stock_damage_store_created,
-- idx_branch_stock_inventory_store, idx_customer_store_balance.
-- ⚠️ Supabase SQL editor mein run karein.
-- ============================================================

drop function if exists get_branch_insights_range(uuid, timestamptz, timestamptz, int, text);

create or replace function get_branch_insights_range(
  p_store_id uuid,
  p_from     timestamptz,
  p_to       timestamptz,
  p_limit    int  default 8,
  p_tz       text default 'Asia/Karachi'
)
returns jsonb
language sql
stable
set statement_timeout = '60s'
as $$
  with inv as (
    select s.id, s.user_id, s.customer_id, s.invoice_date, s.grand_total
    from sale_invoices s
    where s.store_id = p_store_id and s.status = 'completed' and s.deleted_at is null
      and s.invoice_date >= p_from and s.invoice_date <= p_to
  ),
  items as (
    select i.product_id, max(i.product_name) as name,
           sum(i.quantity) as qty,
           sum(i.sale_price * i.quantity - coalesce(i.discount, 0)) as revenue,
           sum((i.sale_price - i.purchase_price) * i.quantity
               - coalesce(i.discount, 0)) as profit
    from inv join sale_invoice_items i on i.invoice_id = inv.id
    group by i.product_id
  ),
  -- physical (digital / Pull PMG nahi) products + unki category
  phys as (
    select it.*, coalesce(c.name, 'Uncategorized') as category
    from items it
    join branch_stock_inventory b
      on b.product_id = it.product_id and b.store_id = p_store_id and b.deleted_at is null
    left join warehouse_categories c on c.id = b.category_id
    where coalesce(b.product_type, 'physical') = 'physical'
      and lower(regexp_replace(coalesce(c.name, ''), '\s+', '', 'g')) not like '%pmg%'
  )
  select jsonb_build_object(
    'hourly', coalesce((
      select jsonb_agg(jsonb_build_object('hour', h, 'sale', t, 'count', n) order by h)
      from (
        select extract(hour from invoice_date at time zone p_tz)::int as h,
               sum(grand_total) as t, count(*) as n
        from inv group by 1) x), '[]'),
    'category', coalesce((
      select jsonb_agg(jsonb_build_object('name', category, 'sale', s, 'profit', p) order by s desc)
      from (select category, sum(revenue) s, sum(profit) p
            from phys group by category order by s desc limit p_limit) x), '[]'),
    'staff', coalesce((
      select jsonb_agg(jsonb_build_object('name', nm, 'sale', s, 'count', n) order by s desc)
      from (select coalesce(u.full_name, 'Unknown') nm, sum(inv.grand_total) s, count(*) n
            from inv left join branch_users u on u.id = inv.user_id
            group by 1 order by s desc limit p_limit) x), '[]'),
    'loss_products', coalesce((
      select jsonb_agg(jsonb_build_object('name', name, 'qty', qty, 'loss', -profit) order by profit)
      from (select name, qty, profit from phys
            where profit < 0 order by profit limit p_limit) x), '[]'),
    'top_customers', coalesce((
      select jsonb_agg(jsonb_build_object('name', nm, 'total', s, 'count', n) order by s desc)
      from (select coalesce(c.name, 'Walk-in') nm, sum(inv.grand_total) s, count(*) n
            from inv join customer c on c.id = inv.customer_id
            group by c.id, c.name order by s desc limit p_limit) x), '[]'),
    'top_udhaar', coalesce((
      select jsonb_agg(jsonb_build_object('name', name, 'balance', balance) order by balance desc)
      from (select name, balance from customer
            where store_id = p_store_id and deleted_at is null and balance > 0
            order by balance desc limit p_limit) x), '[]'),
    'dead_stock', coalesce((
      select jsonb_agg(jsonb_build_object('name', name, 'stock', stock, 'value', val) order by val desc)
      from (select b.product_name as name, b.stock,
                   b.stock * b.purchase_price as val
            from branch_stock_inventory b
            left join warehouse_categories c on c.id = b.category_id
            where b.store_id = p_store_id and b.deleted_at is null
              and coalesce(b.product_type, 'physical') = 'physical'
              and lower(regexp_replace(coalesce(c.name, ''), '\s+', '', 'g')) not like '%pmg%'
              and b.stock > 0
              and not exists (select 1 from items it where it.product_id = b.product_id)
            order by val desc limit p_limit) x), '[]')
  );
$$;

drop function if exists get_branch_insights_trend(uuid, timestamptz[], timestamptz[]);

create or replace function get_branch_insights_trend(
  p_store_id uuid,
  p_starts   timestamptz[],
  p_ends     timestamptz[]
)
returns table (
  idx        int,
  revenue    numeric,
  profit     numeric,
  discount   numeric,
  credit     numeric,
  recovered  numeric,
  damage     numeric,
  cash_in    numeric,
  cash_out   numeric
)
language sql
stable
set statement_timeout = '60s'
as $$
  select
    b.i::int,
    coalesce(sl.revenue, 0), coalesce(sl.profit, 0), coalesce(sl.discount, 0),
    coalesce(sl.credit, 0),
    coalesce(lg.paid, 0), coalesce(dm.loss, 0),
    coalesce(tx.cash_in, 0), coalesce(tx.cash_out, 0)
  from unnest(p_starts, p_ends) with ordinality as b(s, e, i)
  left join lateral (
    select sum(x.revenue) revenue, sum(x.profit) profit,
           sum(s.total_discount) discount, sum(x.credit) credit
    from sale_invoices s
    left join lateral (
      select
        sum(it.sale_price * it.quantity - coalesce(it.discount, 0)) as revenue,
        sum((it.sale_price - it.purchase_price) * it.quantity - coalesce(it.discount, 0)) as profit,
        (select sum(p.amount) from sale_invoice_payments p
          where p.invoice_id = s.id and p.payment_method = 'credit') as credit
      from sale_invoice_items it where it.invoice_id = s.id
    ) x on true
    where s.store_id = p_store_id and s.status = 'completed' and s.deleted_at is null
      and s.invoice_date >= b.s and s.invoice_date <= b.e
  ) sl on true
  left join lateral (
    select sum(pay_amount) as paid from customer_ledger
    where store_id = p_store_id and deleted_at is null
      and (notes is null or notes not like 'Sale Invoice:%')
      and created_at >= b.s and created_at <= b.e
  ) lg on true
  left join lateral (
    select sum(stock_damage * purchase_price) as loss from branch_stock_damage
    where store_id = p_store_id and created_at >= b.s and created_at <= b.e
  ) dm on true
  left join lateral (
    select
      sum(cash_out_amount) filter (where transaction_type = 'cash_in') as cash_in,
      sum(cash_out_amount) filter (where transaction_type is distinct from 'cash_in') as cash_out
    from branch_cash_transaction
    where store_id = p_store_id and deleted_at is null
      and created_at >= b.s and created_at <= b.e
  ) tx on true
  order by b.i;
$$;

notify pgrst, 'reload schema';
