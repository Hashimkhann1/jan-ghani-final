-- ============================================================
-- Accountant Branch Dashboard — single indexed RPC
--
-- Pehle dashboard 8 sequential queries chalata tha, har ek 1000-row
-- pages mein saari rows Dart mein la kar sum karta tha. Bade date range
-- par branch_cash_transaction / customer_ledger / sale_invoices ka full
-- scan timeout ho jata tha — Cash Out ka catch{} usay 0 bana deta tha.
--
-- Ab: indexes + ek RPC jo sab kuch DB mein SUM karta hai.
-- ⚠️ Supabase SQL editor mein run karein.
-- ============================================================

create index if not exists idx_branch_cash_txn_store_created
  on branch_cash_transaction (store_id, created_at)
  where deleted_at is null;

create index if not exists idx_customer_ledger_store_created
  on customer_ledger (store_id, created_at)
  where deleted_at is null;

create index if not exists idx_branch_stock_damage_store_created
  on branch_stock_damage (store_id, created_at);

create index if not exists idx_branch_stock_inventory_store
  on branch_stock_inventory (store_id)
  where deleted_at is null;

create index if not exists idx_customer_store_balance
  on customer (store_id)
  where deleted_at is null and balance > 0;

-- (idx_sale_invoices_store_status_date, idx_sale_returns_store_status_date,
--  idx_sale_invoice_items_invoice, idx_sale_return_items_return,
--  idx_sale_invoice_payments_invoice already exist from earlier migrations.)

create or replace function get_branch_dashboard_summary(
  p_store_id uuid,
  p_from     timestamptz,
  p_to       timestamptz
)
returns table (
  total_sale        numeric,
  total_return      numeric,
  cash_sale         numeric,
  card_sale         numeric,
  credit_sale       numeric,
  installment       numeric,
  gross_profit      numeric,
  cash_in           numeric,
  cash_out          numeric,
  damage            numeric,
  stock_purchase    numeric,
  stock_sale        numeric,
  outstanding       numeric
)
language sql
stable
as $$
  select
    (select coalesce(sum(grand_total), 0) from sale_invoices
      where store_id = p_store_id and status = 'completed' and deleted_at is null
        and invoice_date >= p_from and invoice_date <= p_to),

    (select coalesce(sum(grand_total), 0) from sale_returns
      where store_id = p_store_id and status = 'completed' and deleted_at is null
        and return_date >= p_from and return_date <= p_to),

    coalesce(pay.cash, 0), coalesce(pay.card, 0), coalesce(pay.credit, 0),

    (select coalesce(sum(pay_amount), 0) from customer_ledger
      where store_id = p_store_id and deleted_at is null
        and created_at >= p_from and created_at <= p_to),

    (select coalesce(sum((i.sale_price - i.purchase_price) * i.quantity - coalesce(i.discount, 0)), 0)
       from sale_invoice_items i join sale_invoices s on s.id = i.invoice_id
      where s.store_id = p_store_id and s.status = 'completed' and s.deleted_at is null
        and s.invoice_date >= p_from and s.invoice_date <= p_to)
    -
    (select coalesce(sum((i.sale_price - i.purchase_price) * i.quantity - coalesce(i.discount, 0)), 0)
       from sale_return_items i join sale_returns r on r.id = i.return_id
      where r.store_id = p_store_id and r.status = 'completed' and r.deleted_at is null
        and r.return_date >= p_from and r.return_date <= p_to),

    coalesce(tx.cash_in, 0), coalesce(tx.cash_out, 0),

    (select coalesce(sum(stock_damage * purchase_price), 0) from branch_stock_damage
      where store_id = p_store_id and created_at >= p_from and created_at <= p_to),

    coalesce(inv.purchase, 0), coalesce(inv.sale, 0),

    (select coalesce(sum(balance), 0) from customer
      where store_id = p_store_id and deleted_at is null and balance > 0)
  from
    (select
       sum(p.amount) filter (where p.payment_method = 'cash')   as cash,
       sum(p.amount) filter (where p.payment_method = 'card')   as card,
       sum(p.amount) filter (where p.payment_method = 'credit') as credit
     from sale_invoice_payments p join sale_invoices s on s.id = p.invoice_id
     where s.store_id = p_store_id and s.status = 'completed' and s.deleted_at is null
       and s.invoice_date >= p_from and s.invoice_date <= p_to) pay,
    (select
       sum(cash_out_amount) filter (where transaction_type = 'cash_in')  as cash_in,
       sum(cash_out_amount) filter (where transaction_type is distinct from 'cash_in') as cash_out
     from branch_cash_transaction
     where store_id = p_store_id and deleted_at is null
       and created_at >= p_from and created_at <= p_to) tx,
    (select sum(stock * purchase_price) as purchase, sum(stock * sale_price) as sale
     from branch_stock_inventory
     where store_id = p_store_id and deleted_at is null) inv;
$$;

notify pgrst, 'reload schema';
