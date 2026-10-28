-- Digital products (Bank Transfer / Pay Bill / SIM Load / Cash Withdraw)
--
--  product_type on branch_stock_inventory:
--    physical          -> normal stock product (default, unchanged behaviour)
--    digital           -> no stock; card_sale -= purchase_price
--    digital_withdraw  -> no stock; card_sale += sale_price, cash_sale -= purchase_price
--
--  Safe to re-run, also on a DB that ran the earlier (ledger/balance) version.

BEGIN;

-- ── 1. product_type ──────────────────────────────────────────
ALTER TABLE public.branch_stock_inventory
    ADD COLUMN IF NOT EXISTS product_type text NOT NULL DEFAULT 'physical';

ALTER TABLE public.branch_stock_inventory
    DROP CONSTRAINT IF EXISTS branch_stock_inventory_product_type_check;
ALTER TABLE public.branch_stock_inventory
    ADD CONSTRAINT branch_stock_inventory_product_type_check
    CHECK (product_type IN ('physical', 'digital', 'digital_withdraw'));

-- Older version of this migration created per-counter balance tables.
-- Card now lives in branch_cash_counter.card_sale, so they are not needed.
DROP TABLE IF EXISTS public.branch_digital_ledger  CASCADE;
DROP TABLE IF EXISTS public.branch_digital_balance CASCADE;
DROP FUNCTION IF EXISTS public.fn_digital_ledger_to_balance();

-- ── 2. Sale item trigger: physical = stock, digital = cash counter ──
--  digital:           cash_sale += sale_price (cash payment row, unchanged)
--                     card_sale -= purchase_price
--                     => net amount grows by the profit only
--  digital_withdraw:  card_sale += sale_price (customer transferred to us)
--                     cash_sale -= purchase_price (cash handed to customer)
--                     cash_out is not touched
--                     => net amount grows by the profit only
CREATE OR REPLACE FUNCTION public.fn_sale_item_inventory()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    v_store_id   UUID;
    v_counter_id UUID;
    v_type       TEXT;
BEGIN
    SELECT store_id, counter_id
      INTO v_store_id, v_counter_id
      FROM public.sale_invoices WHERE id = NEW.invoice_id;

    SELECT product_type INTO v_type
      FROM public.branch_stock_inventory
     WHERE product_id = NEW.product_id
       AND store_id   = v_store_id;

    IF v_type = 'digital' THEN
        UPDATE public.branch_cash_counter
           SET card_sale = card_sale - (NEW.purchase_price * NEW.quantity)
         WHERE store_id     = v_store_id
           AND counter_id   = v_counter_id
           AND counter_date = CURRENT_DATE;

    ELSIF v_type = 'digital_withdraw' THEN
        UPDATE public.branch_cash_counter
           SET card_sale = card_sale + (NEW.sale_price * NEW.quantity),
               cash_sale = cash_sale - (NEW.purchase_price * NEW.quantity)
         WHERE store_id     = v_store_id
           AND counter_id   = v_counter_id
           AND counter_date = CURRENT_DATE;

    ELSE
        UPDATE public.branch_stock_inventory
           SET stock      = stock - NEW.quantity,
               updated_at = NOW()
         WHERE product_id = NEW.product_id
           AND store_id   = v_store_id;
    END IF;

    RETURN NEW;
END;
$$;

-- ── 3. Digital products cannot be returned ───────────────────
CREATE OR REPLACE FUNCTION public.fn_return_item_inventory()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    v_branch_id UUID;
    v_type      TEXT;
BEGIN
    SELECT store_id INTO v_branch_id
      FROM public.sale_returns WHERE id = NEW.return_id;

    SELECT product_type INTO v_type
      FROM public.branch_stock_inventory
     WHERE product_id = NEW.product_id
       AND store_id   = v_branch_id;

    IF v_type IN ('digital', 'digital_withdraw') THEN
        RAISE EXCEPTION 'Digital product ka return nahi ho sakta';
    END IF;

    UPDATE public.branch_stock_inventory
       SET stock      = stock + NEW.quantity,
           updated_at = NOW()
     WHERE product_id = NEW.product_id
       AND store_id   = v_branch_id;

    RETURN NEW;
END;
$$;

COMMIT;
