-- =============================================================
-- Inventory Balance — Branch "apply" step, DELTA → ABSOLUTE.
--
-- Bug: apply_inventory_balance_item(...) did
--   v_after := v_current + v_item.delta
-- i.e. it added the counted delta on top of whatever the LIVE
-- stock was at accept-time. If live stock drifted between the
-- physical count and the branch accepting it (more sales, other
-- corrections, etc.), the delta landed on the wrong base and
-- produced nonsense results — e.g. live stock already at -5,
-- delta -3 from an old count => -8 instead of the counted 3.
--
-- Fix: physical count IS the new truth. Branch accept now SETS
-- stock = v_item.physical_stock directly (absolute), not a delta
-- on top of current live stock.
-- =============================================================

CREATE OR REPLACE FUNCTION public.apply_inventory_balance_item(
    p_item_id         uuid,
    p_branch_user_id  uuid,
    p_branch_user_name text
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    v_item     public.inventory_balance_items%ROWTYPE;
    v_current  numeric(14,3);
    v_after    numeric(14,3);
    v_now      timestamptz := now();
BEGIN
    -- 1. Lock + guard the item (idempotent — only branch_pending applies)
    SELECT * INTO v_item
    FROM public.inventory_balance_items
    WHERE id = p_item_id AND status = 'branch_pending'
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'item_not_branch_pending'
        );
    END IF;

    -- 2. Lock the live stock row
    SELECT stock INTO v_current
    FROM public.branch_stock_inventory
    WHERE store_id = v_item.store_id AND product_id = v_item.product_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'stock_row_not_found'
        );
    END IF;

    -- 3. ABSOLUTE set — counted physical stock becomes the new truth
    v_after := v_item.physical_stock;

    UPDATE public.branch_stock_inventory
    SET stock = v_after,
        updated_at = v_now
    WHERE store_id = v_item.store_id AND product_id = v_item.product_id;

    -- 4. Stamp item as applied
    UPDATE public.inventory_balance_items
    SET status               = 'applied',
        branch_user_id       = p_branch_user_id,
        branch_user_name     = p_branch_user_name,
        branch_reviewed_at   = v_now,
        applied_at           = v_now,
        applied_stock_before = v_current,
        applied_stock_after  = v_after,
        is_synced            = true,
        synced_at            = v_now
    WHERE id = p_item_id;

    -- 5. Audit log
    INSERT INTO public.inventory_balance_log (
        id, item_id, batch_id, action, actor_id, actor_name, actor_role,
        is_synced, synced_at
    ) VALUES (
        gen_random_uuid(), p_item_id, v_item.batch_id, 'applied',
        p_branch_user_id, p_branch_user_name, 'branch', true, v_now
    );

    RETURN jsonb_build_object(
        'success', true,
        'stock_before', v_current,
        'stock_after', v_after
    );
END;
$$;

-- ── DONE ────────────────────────────────────────────────────
-- Verify (after run):
--   SELECT proname FROM pg_proc WHERE proname = 'apply_inventory_balance_item';
