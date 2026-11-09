-- ============================================================
-- Branch Dashboard — Top products (selling / profit / low stock)
-- ONE RPC: aggregation database mein, app ko sirf ~24 rows milti hain.
-- Indexes: idx_sale_invoices_store_status_date + idx_sale_invoice_items_invoice
-- Digital (product_type != physical) aur Pull PMG category ke products shamil nahi.
-- ⚠️ Supabase SQL editor mein run karein.
-- ============================================================

drop function if exists get_branch_top_products(uuid, timestamptz, timestamptz, int);

create or replace function get_branch_top_products(
  p_store_id uuid,
  p_from     timestamptz,
  p_to       timestamptz,
  p_limit    int default 8
)
returns table (
  kind       text,
  product_id uuid,
  name       text,
  qty_sold   numeric,
  revenue    numeric,
  profit     numeric,
  stock      numeric
)
language sql
stable
set statement_timeout = '60s'
as $$
  with sold as (
    select
      i.product_id,
      max(i.product_name)                                             as name,
      sum(i.quantity)                                                 as qty,
      sum(i.sale_price * i.quantity - coalesce(i.discount, 0))        as revenue,
      sum((i.sale_price - i.purchase_price) * i.quantity
          - coalesce(i.discount, 0))                                  as profit
    from sale_invoices s
    join sale_invoice_items i on i.invoice_id = s.id
    where s.store_id = p_store_id and s.status = 'completed'
      and s.deleted_at is null
      and s.invoice_date >= p_from and s.invoice_date <= p_to
    group by i.product_id
  ),
  phys as (
    select d.product_id, d.name, d.qty, d.revenue, d.profit,
           greatest(coalesce(inv.stock, 0), 0) as stock
    from sold d
    join branch_stock_inventory inv
      on inv.product_id = d.product_id and inv.store_id = p_store_id
     and inv.deleted_at is null
    left join warehouse_categories c on c.id = inv.category_id
    where coalesce(inv.product_type, 'physical') = 'physical'
      and lower(regexp_replace(coalesce(c.name, ''), '\s+', '', 'g')) not like '%pmg%'
  ),
  selling as (select 'selling' k, * from phys order by qty desc limit p_limit),
  prof    as (select 'profit'  k, * from phys order by profit desc limit p_limit),
  low     as (
    select 'low' k, * from phys
    where qty > 0 and stock <= qty
    order by (stock / qty) asc, qty desc limit p_limit
  )
  select k, product_id, name, qty, revenue, profit, stock from selling
  union all select k, product_id, name, qty, revenue, profit, stock from prof
  union all select k, product_id, name, qty, revenue, profit, stock from low;
$$;

notify pgrst, 'reload schema';
