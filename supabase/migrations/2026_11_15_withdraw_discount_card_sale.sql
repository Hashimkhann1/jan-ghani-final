-- Cash Withdraw: discount ab card_sale mein bhi minus hota hai.
--
-- Pehle:  card_sale += sale_price * qty            (amount + fee = 2020)
-- Ab:     card_sale += sale_price * qty - discount (amount + fee - discount = 2000)
--
-- Customer ne asal mein grand total (2000) transfer kiya, 2020 nahi.
-- Cash counter ka net amount = fee - discount (profit) rahega.
-- 'digital' (bank transfer / bill / sim) pehle se sahi hai: card -= purchase_price,
-- cash payment = grand total (discount ke baad).

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
           SET card_sale = card_sale + (NEW.sale_price * NEW.quantity) - COALESCE(NEW.discount, 0),
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
