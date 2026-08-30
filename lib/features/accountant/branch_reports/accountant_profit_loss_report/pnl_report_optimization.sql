-- ============================================================
-- Profit & Loss report — server-side aggregation, count & pagination
-- Run this in the Supabase SQL Editor.
--
-- Run block 0 FIRST and sanity-check the output against the
-- assumptions used below (table/column names, uuid types) before
-- running blocks 1-3. If anything differs, fix the script to match
-- your real schema before continuing.
-- ============================================================


-- ── 0) INTROSPECTION — run first, just to confirm assumptions ──
select table_name, column_name, data_type
from information_schema.columns
where table_name in
  ('sale_invoices','sale_invoice_items','sale_returns','sale_return_items','customer')
order by table_name, ordinal_position;

-- also worth checking which of these indexes already exist before adding more:
select tablename, indexname, indexdef
from pg_indexes
where tablename in
  ('sale_invoices','sale_invoice_items','sale_returns','sale_return_items')
order by tablename;


-- ── 1) INDEXES ───────────────────────────────────────────────
-- Composite, matches the exact filter+sort shape used by every branch
-- report query: .eq('store_id', x).eq('status','completed')
--   .gte(date, from).lte(date, to).order(date, desc)
-- This is the single highest-impact index — it benefits the Sale
-- Report, Sale Return Report, Discount/Category-wise reports, and
-- this P&L report simultaneously. `where deleted_at is null` makes it
-- a partial index (smaller, faster) since every query excludes
-- soft-deleted rows.
create index if not exists idx_sale_invoices_store_status_date
  on sale_invoices (store_id, status, invoice_date desc)
  where deleted_at is null;

create index if not exists idx_sale_returns_store_status_date
  on sale_returns (store_id, status, return_date desc)
  where deleted_at is null;

-- Postgres does NOT auto-index foreign keys (only primary keys).
-- Without these, aggregating profit per invoice/return (the view and
-- RPC below) forces a sequential scan of the *_items tables — the
-- largest tables in this schema — for every single invoice.
create index if not exists idx_sale_invoice_items_invoice
  on sale_invoice_items (invoice_id);

create index if not exists idx_sale_return_items_return
  on sale_return_items (return_id);

-- Used by the existing customer-dropdown filter
-- (.eq('customer_id', customerId)) on the Sale Report / Sale Return
-- Report screens.
create index if not exists idx_sale_invoices_customer
  on sale_invoices (customer_id);

create index if not exists idx_sale_returns_customer
  on sale_returns (customer_id);

-- Deliberately NOT indexing: product_name, sku, discount — never
-- filtered/sorted on in any of these report queries. `status` alone
-- also isn't indexed separately — it has very low cardinality
-- ('completed' vs a couple of others), so a standalone index on it
-- would rarely be chosen by the planner; it's only useful combined
-- with store_id+date as above.


-- ── 2) VIEW — powers the paginated "Invoices" tab ───────────────
-- One row per sale invoice / sale return, profit/revenue/cost already
-- summed at the DB level. Because it's a plain (non-materialized)
-- view, PostgREST's .eq()/.gte()/.lte()/.order()/.range() filters
-- apply on top of it normally, and Postgres pushes the store_id/date
-- predicates down before the join+group-by — so it still uses the
-- indexes above instead of scanning everything.
create or replace view pnl_transactions_view as
select
  si.id,
  'sale'::text                     as type,
  si.invoice_no                    as doc_no,
  si.invoice_date                  as tx_date,
  si.store_id,
  si.customer_id,
  c.name                           as customer_name,
  coalesce(sum(sii.sale_price * sii.quantity), 0)                                        as total_revenue,
  coalesce(sum(sii.purchase_price * sii.quantity), 0)                                    as total_cost,
  coalesce(sum((sii.sale_price - sii.purchase_price) * sii.quantity - sii.discount), 0)  as total_profit,
  count(sii.invoice_id)       as item_count
from sale_invoices si
left join sale_invoice_items sii on sii.invoice_id = si.id
left join customer c            on c.id = si.customer_id
where si.deleted_at is null and si.status = 'completed'
group by si.id, si.invoice_no, si.invoice_date, si.store_id, si.customer_id, c.name

union all

select
  sr.id,
  'return'::text                   as type,
  sr.return_no                     as doc_no,
  sr.return_date                   as tx_date,
  sr.store_id,
  sr.customer_id,
  c.name                           as customer_name,
  coalesce(sum(sri.sale_price * sri.quantity), 0)                                        as total_revenue,
  coalesce(sum(sri.purchase_price * sri.quantity), 0)                                    as total_cost,
  coalesce(sum((sri.sale_price - sri.purchase_price) * sri.quantity - sri.discount), 0)  as total_profit,
  count(sri.return_id)        as item_count
from sale_returns sr
left join sale_return_items sri on sri.return_id = sr.id
left join customer c           on c.id = sr.customer_id
where sr.deleted_at is null and sr.status = 'completed'
group by sr.id, sr.return_no, sr.return_date, sr.store_id, sr.customer_id, c.name;

grant select on pnl_transactions_view to authenticated, anon;


-- ── 3) RPC — one-shot summary + daily breakdown ─────────────────
-- Returns 4 scalars, 2 counts, and a JSON array with (at most) one
-- row per calendar day in range — never one row per invoice. This is
-- what replaces the "fetch everything, sum in Dart" logic.
create or replace function get_pnl_summary(
  p_store_id uuid,
  p_from     timestamptz,
  p_to       timestamptz
)
returns table (
  total_invoices      bigint,
  total_returns       bigint,
  gross_sale_profit   numeric,
  gross_return_profit numeric,
  total_sale_revenue  numeric,
  total_cost          numeric,
  daily               jsonb
)
language sql
stable
as $$
  with sales as (
    select si.id, si.invoice_date,
           coalesce(sum((sii.sale_price - sii.purchase_price) * sii.quantity - sii.discount), 0) as profit,
           coalesce(sum(sii.sale_price * sii.quantity), 0)     as revenue,
           coalesce(sum(sii.purchase_price * sii.quantity), 0) as cost
    from sale_invoices si
    left join sale_invoice_items sii on sii.invoice_id = si.id
    where si.store_id = p_store_id
      and si.status = 'completed'
      and si.deleted_at is null
      and si.invoice_date >= p_from
      and si.invoice_date <= p_to
    group by si.id, si.invoice_date
  ),
  returns as (
    select sr.id, sr.return_date,
           coalesce(sum((sri.sale_price - sri.purchase_price) * sri.quantity - sri.discount), 0) as profit
    from sale_returns sr
    left join sale_return_items sri on sri.return_id = sr.id
    where sr.store_id = p_store_id
      and sr.status = 'completed'
      and sr.deleted_at is null
      and sr.return_date >= p_from
      and sr.return_date <= p_to
    group by sr.id, sr.return_date
  ),
  daily_sales as (
    select invoice_date::date as d, sum(profit) as sale_profit
    from sales group by invoice_date::date
  ),
  daily_returns as (
    select return_date::date as d, sum(profit) as return_profit
    from returns group by return_date::date
  ),
  daily_merged as (
    select coalesce(ds.d, dr.d)               as d,
           coalesce(ds.sale_profit, 0)        as sale_profit,
           coalesce(dr.return_profit, 0)      as return_profit
    from daily_sales ds
    full outer join daily_returns dr on ds.d = dr.d
  )
  select
    (select count(*) from sales)                  as total_invoices,
    (select count(*) from returns)                as total_returns,
    (select coalesce(sum(profit),0)  from sales)   as gross_sale_profit,
    (select coalesce(sum(profit),0)  from returns) as gross_return_profit,
    (select coalesce(sum(revenue),0) from sales)   as total_sale_revenue,
    (select coalesce(sum(cost),0)    from sales)   as total_cost,
    (select coalesce(jsonb_agg(jsonb_build_object(
        'date', d, 'sale_profit', sale_profit, 'return_profit', return_profit
      ) order by d desc), '[]'::jsonb) from daily_merged) as daily;
$$;

grant execute on function get_pnl_summary(uuid, timestamptz, timestamptz) to authenticated, anon;

-- `security invoker` is the default (no `security definer` used), so the
-- function runs under the calling user's role and respects any existing
-- Row Level Security policies on these tables — it doesn't bypass
-- anything you already have configured. If your tables have RLS enabled
-- and anon/authenticated currently can't read them directly, the
-- RPC/view will hit the same restriction, which is expected.


-- ── 4) VERIFY (after running 1-3) ───────────────────────────────
-- Confirm all 6 indexes exist:
select tablename, indexname, indexdef
from pg_indexes
where tablename in
  ('sale_invoices','sale_invoice_items','sale_returns','sale_return_items')
order by tablename;

-- Confirm the view uses the new index (look for "Index Scan" /
-- "Bitmap Index Scan" on idx_sale_invoices_store_status_date, not
-- "Seq Scan") — replace the store_id with a real one from your data:
-- explain analyze
-- select * from pnl_transactions_view
-- where store_id = '00000000-0000-0000-0000-000000000000'
-- order by tx_date desc limit 20;
