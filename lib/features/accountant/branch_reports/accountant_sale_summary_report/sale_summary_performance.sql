-- ============================================================
-- Sale Report & Sale Return Report — kill the full-table summary scan
--
-- Both `AccountantSaleReportDatasource.getReportSummary` and
-- `AccountantSaleReturnDatasource.getReportSummary` currently fetch
-- EVERY matching invoice/return in the date range (1000 rows at a
-- time, in a loop, with nested items) just to compute 4 numbers for
-- the summary cards — the exact same anti-pattern the P&L report had.
-- This runs on every load/filter/date change, in parallel with the
-- 20-row paginated list, which is why these screens feel slow.
--
-- These two RPCs replace that loop with a single SUM/COUNT query.
-- The indexes they rely on (store_id+status+date, item FK columns,
-- customer_id) were already created by
-- 2026_08_30_pnl_report_optimization.sql — only one new index is
-- needed here (sale_invoice_payments, for the payment-type filter).
-- ============================================================


-- ── New index — sale_invoice_payments has no useful index yet.
-- Needed for the "does this invoice have a payment of type X"
-- check inside get_sale_report_summary (and speeds up the same
-- lookup when getReportPage's payment-type filter is eventually
-- pushed server-side too).
create index if not exists idx_sale_invoice_payments_invoice
  on sale_invoice_payments (invoice_id, payment_method);


-- ── Sale Report summary ──────────────────────────────────────
create or replace function get_sale_report_summary(
  p_store_id     uuid,
  p_from         timestamptz,
  p_to           timestamptz,
  p_customer_id  uuid default null,
  p_payment_type text default null
)
returns table (
  total_invoices bigint,
  total_sale     numeric,
  total_quantity numeric,
  total_discount numeric
)
language sql
stable
as $$
  with matched as (
    select si.id, si.grand_total, si.total_discount
    from sale_invoices si
    where si.store_id = p_store_id
      and si.status = 'completed'
      and si.deleted_at is null
      and si.invoice_date >= p_from
      and si.invoice_date <= p_to
      and (p_customer_id is null or si.customer_id = p_customer_id)
      and (
        p_payment_type is null
        or exists (
          select 1 from sale_invoice_payments sip
          where sip.invoice_id = si.id
            and sip.payment_method = p_payment_type
        )
      )
  )
  select
    (select count(*)::bigint from matched)                 as total_invoices,
    (select coalesce(sum(grand_total), 0) from matched)    as total_sale,
    (select coalesce(sum(sii.quantity), 0)
       from sale_invoice_items sii
       join matched m on m.id = sii.invoice_id)            as total_quantity,
    (select coalesce(sum(total_discount), 0) from matched) as total_discount;
$$;

grant execute on function get_sale_report_summary(uuid, timestamptz, timestamptz, uuid, text)
  to authenticated, anon;


-- ── Sale Return Report summary ───────────────────────────────
-- refund_type is a plain column on sale_returns (unlike payment
-- method on the sale side, which lives in a child table), so no
-- EXISTS subquery/join is needed for that filter.
create or replace function get_sale_return_summary(
  p_store_id    uuid,
  p_from        timestamptz,
  p_to          timestamptz,
  p_customer_id uuid default null,
  p_refund_type text default null
)
returns table (
  total_returns  bigint,
  total_amount   numeric,
  total_quantity numeric,
  total_discount numeric
)
language sql
stable
as $$
  with matched as (
    select sr.id, sr.grand_total, sr.total_discount
    from sale_returns sr
    where sr.store_id = p_store_id
      and sr.status = 'completed'
      and sr.deleted_at is null
      and sr.return_date >= p_from
      and sr.return_date <= p_to
      and (p_customer_id is null or sr.customer_id = p_customer_id)
      and (p_refund_type is null or sr.refund_type = p_refund_type)
  )
  select
    (select count(*)::bigint from matched)                 as total_returns,
    (select coalesce(sum(grand_total), 0) from matched)    as total_amount,
    (select coalesce(sum(sri.quantity), 0)
       from sale_return_items sri
       join matched m on m.id = sri.return_id)             as total_quantity,
    (select coalesce(sum(total_discount), 0) from matched) as total_discount;
$$;

grant execute on function get_sale_return_summary(uuid, timestamptz, timestamptz, uuid, text)
  to authenticated, anon;


-- ── Verify ────────────────────────────────────────────────────
-- select * from pg_indexes where tablename = 'sale_invoice_payments';
-- select * from get_sale_report_summary('<a real store_id>'::uuid, now() - interval '30 days', now(), null, null);
-- select * from get_sale_return_summary('<a real store_id>'::uuid, now() - interval '30 days', now(), null, null);
