-- =============================================================
-- Branch Cash Out — accountant "Receive" approval.
--
-- Pehle: branch cash out karte hi app seedha
-- janghani_net_amount.cash_in_hand mein amount add kar deti thi.
-- Branch ka internet slow hai, is liye ye aksar fail / atak jata tha.
--
-- Ab: branch sirf local cash out karti hai. Row sync ho kar yahan
-- is_received = false (Pending) ke saath aati hai. Accountant
-- "Receive" dabata hai → receive_branch_cash_out() ek hi transaction
-- mein row ko received mark karta hai aur amount cash_in_hand mein
-- add karta hai. Ek row sirf ek dafa add hoti hai.
-- =============================================================

-- 1. Naye columns (branch upsert in columns ko nahi bhejti, is liye
--    accountant ka set kiya hua is_received kabhi overwrite nahi hota)
ALTER TABLE public.branch_transaction_to_janghani
    ADD COLUMN IF NOT EXISTS is_received boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS received_at timestamptz,
    ADD COLUMN IF NOT EXISTS received_by text;

-- 2. Purani rows: jo purana app pehle hi cash_in_hand mein add kar
--    chuka hai (is_synced = true) unhein Received mark karo, warna
--    accountant dobara Receive karke double add kar dega.
UPDATE public.branch_transaction_to_janghani
SET is_received = true,
    received_at = COALESCE(received_at, updated_at, created_at)
WHERE is_synced = true
  AND is_received = false;

-- 3. Jo branch abhi purane app version par hai woh khud cash_in_hand
--    mein add karke is_synced = true bhejti hai — aisi row ko bhi
--    Received mark karo (amount dobara add kiye baghair).
CREATE OR REPLACE FUNCTION public.fn_btj_legacy_received()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.is_synced IS TRUE AND NEW.is_received IS NOT TRUE THEN
        NEW.is_received := true;
        NEW.received_at := COALESCE(NEW.received_at, now());
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_btj_legacy_received
    ON public.branch_transaction_to_janghani;
CREATE TRIGGER trg_btj_legacy_received
    BEFORE INSERT OR UPDATE ON public.branch_transaction_to_janghani
    FOR EACH ROW EXECUTE FUNCTION public.fn_btj_legacy_received();

-- 4. Accountant ka Receive button yahi function call karta hai.
CREATE OR REPLACE FUNCTION public.receive_branch_cash_out(
    p_id          uuid,
    p_received_by text DEFAULT NULL
) RETURNS numeric
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_amount public.branch_transaction_to_janghani.pay_amount%TYPE;
    v_net_id public.janghani_net_amount.id%TYPE;
BEGIN
    -- Row ko lock + received mark (sirf agar abhi Pending ho)
    UPDATE public.branch_transaction_to_janghani
    SET is_received = true,
        received_at = now(),
        received_by = p_received_by
    WHERE id = p_id
      AND type = 'cash_out'
      AND is_received = false
    RETURNING pay_amount INTO v_amount;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ye cash out pehle hi receive ho chuka hai ya mila nahi';
    END IF;

    SELECT id INTO v_net_id
    FROM public.janghani_net_amount
    LIMIT 1
    FOR UPDATE;

    IF v_net_id IS NULL THEN
        RAISE EXCEPTION 'janghani_net_amount row nahi mili';
    END IF;

    UPDATE public.janghani_net_amount
    SET cash_in_hand = COALESCE(cash_in_hand, 0) + COALESCE(v_amount, 0)
    WHERE id = v_net_id;

    RETURN v_amount;
END;
$$;

GRANT EXECUTE ON FUNCTION public.receive_branch_cash_out(uuid, text)
    TO anon, authenticated;
