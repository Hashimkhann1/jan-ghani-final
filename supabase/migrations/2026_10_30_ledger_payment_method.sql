-- Customer wasooli (customer_ledger) mein Cash / Card payment method.
--
--   cash -> branch_cash_counter.cash_sale += pay_amount
--   card -> branch_cash_counter.card_sale += pay_amount
--
-- installment += pay_amount PEHLE se fn_ledger_to_cash_counter karta hai,
-- usay ye migration NAHI chhedti. Ye cash_sale / card_sale ka alag trigger
-- add karti hai (insert, amount/method edit, soft delete).
--
-- Double count fix: total_amount (Net) delta se chalta hai
--   total_amount += d(cash_sale) + d(card_sale) + d(installment) + ...
-- Ab wasooli cash_sale/card_sale mein bhi jati hai, is liye fn_update_cash_counter
-- se installment ka term hata diya. Warna wasooli Net mein 2 dafa jama hoti.
-- Installment sirf customer_ledger (Sale Invoice notes ke ilawa) se badalta hai.
--
-- 'Sale Invoice:%' notes skip hote hain (purani trigger bhi skip karti hai;
-- wo amount sale mein pehle se count hai).
--
-- Safe to re-run. Purane rows 'cash' maane jayenge, un par kuch apply nahi hota.

BEGIN;

ALTER TABLE public.customer_ledger
    ADD COLUMN IF NOT EXISTS payment_method text NOT NULL DEFAULT 'cash';

ALTER TABLE public.customer_ledger
    DROP CONSTRAINT IF EXISTS customer_ledger_payment_method_check;
ALTER TABLE public.customer_ledger
    ADD CONSTRAINT customer_ledger_payment_method_check
    CHECK (payment_method IN ('cash', 'card'));

CREATE OR REPLACE FUNCTION public.fn_ledger_payment_method_to_cash_counter()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    v_amt  NUMERIC;
BEGIN
    -- Purani entry ka asar wapas (update / soft delete)
    IF TG_OP = 'UPDATE' AND OLD.deleted_at IS NULL AND OLD.counter_id IS NOT NULL
       AND (OLD.notes IS NULL OR OLD.notes NOT LIKE 'Sale Invoice:%') THEN
        v_amt := COALESCE(OLD.pay_amount, 0);
        UPDATE public.branch_cash_counter
           SET cash_sale = cash_sale - CASE WHEN OLD.payment_method = 'cash' THEN v_amt ELSE 0 END,
               card_sale = card_sale - CASE WHEN OLD.payment_method = 'card' THEN v_amt ELSE 0 END
         WHERE store_id     = OLD.store_id
           AND counter_id   = OLD.counter_id
           AND counter_date = OLD.created_at::date;
    END IF;

    -- Nayi entry apply (insert / update, soft-deleted nahi)
    IF NEW.deleted_at IS NULL AND NEW.counter_id IS NOT NULL
       AND (NEW.notes IS NULL OR NEW.notes NOT LIKE 'Sale Invoice:%') THEN
        v_amt := COALESCE(NEW.pay_amount, 0);
        UPDATE public.branch_cash_counter
           SET cash_sale = cash_sale + CASE WHEN NEW.payment_method = 'cash' THEN v_amt ELSE 0 END,
               card_sale = card_sale + CASE WHEN NEW.payment_method = 'card' THEN v_amt ELSE 0 END
         WHERE store_id     = NEW.store_id
           AND counter_id   = NEW.counter_id
           AND counter_date = COALESCE(NEW.created_at, NOW())::date;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ledger_payment_method_to_cash_counter ON public.customer_ledger;
CREATE TRIGGER trg_ledger_payment_method_to_cash_counter
    AFTER INSERT OR UPDATE OF pay_amount, payment_method, deleted_at
    ON public.customer_ledger
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_ledger_payment_method_to_cash_counter();

-- ── Net (total_amount): installment ka delta nahi ginna.
-- ── total_sale = cash_sale + card_sale + credit_sale - installment ──
CREATE OR REPLACE FUNCTION public.fn_update_cash_counter()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Wasooli (installment) cash_sale/card_sale mein bhi jati hai, sale nahi hai
    NEW.total_sale = NEW.cash_sale + NEW.card_sale + NEW.credit_sale - NEW.installment;
    NEW.total_amount = OLD.total_amount
                     + (NEW.cash_sale   - OLD.cash_sale)
                     + (NEW.card_sale   - OLD.card_sale)
                     + (NEW.cash_in     - OLD.cash_in)
                     - (NEW.cash_out    - OLD.cash_out);
    RETURN NEW;
END;
$function$;

-- ── Branch summary (dashboard) ka total_sale bhi isi formula par ──
CREATE OR REPLACE FUNCTION public.fn_sync_branch_summary()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_prev_amount NUMERIC(12,2);
BEGIN
    SELECT COALESCE(total_amount, 0) INTO v_prev_amount
    FROM public.branch_summary
    WHERE store_id = NEW.store_id 
      AND counter_date < CURRENT_DATE
    ORDER BY counter_date DESC
    LIMIT 1;

    INSERT INTO public.branch_summary (store_id, counter_date)
    VALUES (NEW.store_id, CURRENT_DATE)
    ON CONFLICT (store_id, counter_date) DO NOTHING;

    UPDATE public.branch_summary
    SET
        total_cash_sale   = (SELECT COALESCE(SUM(cash_sale),   0) FROM public.branch_cash_counter WHERE store_id = NEW.store_id AND counter_date = CURRENT_DATE),
        total_card_sale   = (SELECT COALESCE(SUM(card_sale),   0) FROM public.branch_cash_counter WHERE store_id = NEW.store_id AND counter_date = CURRENT_DATE),
        total_credit_sale = (SELECT COALESCE(SUM(credit_sale), 0) FROM public.branch_cash_counter WHERE store_id = NEW.store_id AND counter_date = CURRENT_DATE),
        total_sale        = (SELECT COALESCE(SUM(cash_sale + card_sale + credit_sale - installment), 0) FROM public.branch_cash_counter WHERE store_id = NEW.store_id AND counter_date = CURRENT_DATE),
        total_installment = (SELECT COALESCE(SUM(installment), 0) FROM public.branch_cash_counter WHERE store_id = NEW.store_id AND counter_date = CURRENT_DATE),
        total_cash_in     = (SELECT COALESCE(SUM(cash_out),    0) FROM public.branch_cash_counter WHERE store_id = NEW.store_id AND counter_date = CURRENT_DATE),
        total_amount      = COALESCE(v_prev_amount, 0)
                          + (SELECT COALESCE(SUM(cash_out), 0) FROM public.branch_cash_counter WHERE store_id = NEW.store_id AND counter_date = CURRENT_DATE)
                          - COALESCE((SELECT total_cash_out FROM public.branch_summary WHERE store_id = NEW.store_id AND counter_date = CURRENT_DATE), 0)
                          - COALESCE((SELECT total_expense  FROM public.branch_summary WHERE store_id = NEW.store_id AND counter_date = CURRENT_DATE), 0)
    WHERE store_id = NEW.store_id AND counter_date = CURRENT_DATE;

    RETURN NEW;
END;
$function$;

COMMIT;
