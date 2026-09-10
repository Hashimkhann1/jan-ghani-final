-- =============================================================
-- Inventory Balance Workflow — 3-role weekly cycle
--   warehouse (initiate) → reviewer/owner (accept/reject) → branch (accept/reject → apply)
--
-- Ye migration LOCAL postgres aur Supabase DONO par apply karni hai.
-- IDs app-side generate hoti hain (const Uuid().v4()), isliye koi default nahi.
-- =============================================================

-- ── 1. Batch header ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.inventory_balance_batches (
    id                uuid PRIMARY KEY,
    warehouse_id      uuid NOT NULL,
    store_id          uuid NOT NULL,
    batch_number      text NOT NULL,
    notes             text,
    total_items       int  NOT NULL DEFAULT 0,
    created_by        uuid,
    created_by_name   text,
    created_at        timestamptz NOT NULL DEFAULT now(),
    is_synced         boolean NOT NULL DEFAULT false,
    synced_at         timestamptz,
    CONSTRAINT inventory_balance_batches_unique_number
        UNIQUE (warehouse_id, batch_number)
);

CREATE INDEX IF NOT EXISTS idx_ibb_warehouse
    ON public.inventory_balance_batches(warehouse_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ibb_store
    ON public.inventory_balance_batches(store_id, created_at DESC);

-- ── 2. Batch items (real data + state machine) ──────────────
CREATE TABLE IF NOT EXISTS public.inventory_balance_items (
    id                       uuid PRIMARY KEY,
    batch_id                 uuid NOT NULL,
    warehouse_id             uuid NOT NULL,
    store_id                 uuid NOT NULL,

    product_id               uuid NOT NULL,
    product_name             text NOT NULL,
    product_sku              text,
    counting_id              uuid,

    -- Snapshot at request time
    system_stock_at_count    numeric(14,3) NOT NULL,
    physical_stock           numeric(14,3) NOT NULL,
    delta                    numeric(14,3) NOT NULL,
    unit_price               numeric(14,2) NOT NULL DEFAULT 0,
    is_high_variance         boolean NOT NULL DEFAULT false,

    -- Status machine
    status                   text NOT NULL DEFAULT 'review_pending',

    -- Reviewer action
    reviewer_reviewed_at     timestamptz,
    reviewer_id              uuid,
    reviewer_name            text,
    reviewer_reason          text,

    -- Branch action (branch app fills)
    branch_reviewed_at       timestamptz,
    branch_user_id           uuid,
    branch_user_name         text,
    branch_reason            text,

    -- Applied snapshot (branch fills)
    applied_at               timestamptz,
    applied_stock_before     numeric(14,3),
    applied_stock_after      numeric(14,3),

    is_synced                boolean NOT NULL DEFAULT false,
    synced_at                timestamptz,
    created_at               timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT inventory_balance_items_status_check
        CHECK (status IN (
            'review_pending',
            'branch_pending',
            'reviewer_rejected',
            'branch_rejected',
            'applied'
        )),

    CONSTRAINT inventory_balance_items_batch_fk
        FOREIGN KEY (batch_id) REFERENCES public.inventory_balance_batches(id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_ibi_batch
    ON public.inventory_balance_items(batch_id);

CREATE INDEX IF NOT EXISTS idx_ibi_warehouse_status
    ON public.inventory_balance_items(warehouse_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ibi_store_status
    ON public.inventory_balance_items(store_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ibi_counting
    ON public.inventory_balance_items(counting_id)
    WHERE counting_id IS NOT NULL;

-- ── 3. Audit log (har action ka atomic record) ──────────────
CREATE TABLE IF NOT EXISTS public.inventory_balance_log (
    id           uuid PRIMARY KEY,
    item_id      uuid NOT NULL,
    batch_id     uuid NOT NULL,
    action       text NOT NULL,
    actor_id     uuid,
    actor_name   text,
    actor_role   text,
    notes        text,
    created_at   timestamptz NOT NULL DEFAULT now(),
    is_synced    boolean NOT NULL DEFAULT false,
    synced_at    timestamptz,

    CONSTRAINT inventory_balance_log_action_check
        CHECK (action IN (
            'created',
            'reviewer_accepted',
            'reviewer_rejected',
            'branch_accepted',
            'branch_rejected',
            'applied'
        )),

    CONSTRAINT inventory_balance_log_item_fk
        FOREIGN KEY (item_id) REFERENCES public.inventory_balance_items(id)
        ON DELETE CASCADE,

    CONSTRAINT inventory_balance_log_batch_fk
        FOREIGN KEY (batch_id) REFERENCES public.inventory_balance_batches(id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_ibl_item
    ON public.inventory_balance_log(item_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ibl_batch
    ON public.inventory_balance_log(batch_id, created_at DESC);

-- ── DONE ────────────────────────────────────────────────────
-- Verify (after run):
--   SELECT COUNT(*) FROM public.inventory_balance_batches; -- expect 0
--   SELECT COUNT(*) FROM public.inventory_balance_items;   -- expect 0
--   SELECT COUNT(*) FROM public.inventory_balance_log;     -- expect 0
