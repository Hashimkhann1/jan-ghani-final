-- =============================================================
-- Branch -> Warehouse Stock Return
--
--  Branch "Send" karta hai:
--     * branch stock (local DB) turant minus
--     * stock_returns (pending) + stock_return_items (inventory ka poora snapshot)
--  Warehouse:
--     * accept_stock_return()  -> status=accepted (stock warehouse app local DB mein add kare)
--     * reject_stock_return()  -> status=rejected  (branch app apna stock wapis
--                                 add karke stock_restored = true kar deta hai)
--
-- Ye SIRF Supabase par chalti hai. Safe to re-run.
-- =============================================================

CREATE TABLE IF NOT EXISTS public.stock_returns (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    return_number     varchar     NOT NULL UNIQUE,
    from_store_id     uuid        NOT NULL,
    from_store_name   text        NOT NULL DEFAULT '',
    warehouse_id      uuid        NOT NULL,
    status            varchar     NOT NULL DEFAULT 'pending'
                      CHECK (status IN ('pending', 'accepted', 'rejected')),
    returned_by_id    uuid,
    returned_by_name  text,
    returned_at       timestamptz NOT NULL DEFAULT now(),
    notes             text,
    total_items       integer     NOT NULL DEFAULT 0,   -- total qty
    total_cost        numeric     NOT NULL DEFAULT 0,
    total_sale_price  numeric     NOT NULL DEFAULT 0,
    -- warehouse ka jawab
    responded_by_id   uuid,
    responded_by_name text,
    responded_at      timestamptz,
    reject_reason     text,
    -- reject hone par branch ka stock wapis add ho chuka? (idempotency flag)
    stock_restored    boolean     NOT NULL DEFAULT false,
    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now(),
    deleted_at        timestamptz
);

CREATE TABLE IF NOT EXISTS public.stock_return_items (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    return_id        uuid    NOT NULL REFERENCES public.stock_returns(id) ON DELETE CASCADE,
    product_id       uuid    NOT NULL,
    inventory_id     uuid,                       -- branch_stock_inventory.id
    -- branch_stock_inventory ke saare fields ka snapshot
    product_name     text    NOT NULL,
    sku              text,
    barcode          text[],
    category_id      uuid,
    unit             text    NOT NULL DEFAULT 'pcs',
    purchase_price   numeric NOT NULL DEFAULT 0,
    sale_price       numeric NOT NULL DEFAULT 0,
    wholesale_price  numeric DEFAULT 0,
    min_stock        numeric DEFAULT 0,
    max_stock        numeric DEFAULT 0,
    shelf_name       text,
    stock_before     numeric,                    -- return se pehle branch ka stock
    -- return
    quantity_returned numeric NOT NULL CHECK (quantity_returned > 0),
    total_cost       numeric NOT NULL DEFAULT 0,
    total_sale_price numeric NOT NULL DEFAULT 0,
    created_at       timestamptz NOT NULL DEFAULT now(),
    deleted_at       timestamptz
);

CREATE INDEX IF NOT EXISTS idx_stock_returns_store_status
    ON public.stock_returns (from_store_id, status, returned_at DESC);
CREATE INDEX IF NOT EXISTS idx_stock_returns_wh_status
    ON public.stock_returns (warehouse_id, status, returned_at DESC);
CREATE INDEX IF NOT EXISTS idx_stock_return_items_return
    ON public.stock_return_items (return_id);

-- ── Warehouse: ACCEPT (status claim only) ────────────────────
-- Warehouse app ka asal stock LOCAL Postgres (warehouse_inventory) mein hota
-- hai aur wahan se Supabase ko sync hota hai. Is liye ye function SIRF status
-- pending -> accepted atomically flip karta hai (double-accept se bachata hai).
-- Stock warehouse app apne local DB mein add kare (is_synced = false) —
-- Supabase ki warehouse_inventory yahan se direct touch NAHI hoti, warna
-- local sync us value ko overwrite kar dega.
-- Local add fail ho to revert_stock_return_accept() se status wapis pending.
CREATE OR REPLACE FUNCTION public.accept_stock_return(
    p_return_id uuid,
    p_user_id   uuid DEFAULT NULL,
    p_user_name text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.stock_returns
       SET status = 'accepted',
           responded_by_id = p_user_id, responded_by_name = p_user_name,
           responded_at = now(), updated_at = now()
     WHERE id = p_return_id AND status = 'pending' AND deleted_at IS NULL;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'return_not_pending');
    END IF;
    RETURN jsonb_build_object('success', true);
END;
$$;

CREATE OR REPLACE FUNCTION public.revert_stock_return_accept(p_return_id uuid)
RETURNS jsonb
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.stock_returns
       SET status = 'pending', responded_by_id = NULL, responded_by_name = NULL,
           responded_at = NULL, updated_at = now()
     WHERE id = p_return_id AND status = 'accepted' AND deleted_at IS NULL;
    RETURN jsonb_build_object('success', FOUND);
END;
$$;

-- ── Warehouse: REJECT ─────────────────────────────────────────
-- Branch app stock_restored = false wale rejected returns dekh kar
-- apna stock wapis add karti hai.
CREATE OR REPLACE FUNCTION public.reject_stock_return(
    p_return_id uuid,
    p_user_id   uuid DEFAULT NULL,
    p_user_name text DEFAULT NULL,
    p_reason    text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.stock_returns
       SET status = 'rejected', reject_reason = p_reason,
           responded_by_id = p_user_id, responded_by_name = p_user_name,
           responded_at = now(), updated_at = now()
     WHERE id = p_return_id AND status = 'pending' AND deleted_at IS NULL;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'return_not_pending');
    END IF;
    RETURN jsonb_build_object('success', true);
END;
$$;
