-- ============================================================
-- Branch Inventory Counting Report — server-side pagination
--
-- Pehle report inventory_counting ki SAARI rows (har store ki) parallel
-- pages mein la kar Dart mein filter/sort/paginate karti thi → browser hang.
-- Ab ek RPC: store + date + search DB mein, sirf ek page wapas, aur
-- total/surplus/shortage/matched counts bhi saath.
-- ⚠️ Supabase SQL editor mein run karein.
-- ============================================================

create index if not exists idx_inventory_counting_store_date
  on inventory_counting (store_id, counted_date);

create index if not exists idx_branch_stock_inventory_store_product
  on branch_stock_inventory (store_id, product_id);

drop function if exists get_inventory_counting_report(uuid, date, date, text, int, int);

create or replace function get_inventory_counting_report(
  p_store_id uuid,
  p_from     date default null,
  p_to       date default null,
  p_search   text default null,
  p_limit    int  default 50,
  p_offset   int  default 0
)
returns setof jsonb
language sql
stable
set statement_timeout = '60s'
as $$
  with base as (
    select
      c.id,
      c.product_id,
      bsi.product_name,
      to_jsonb(bsi.barcode)         as barcode,
      bsi.min_stock,
      bsi.max_stock,
      c.product_stock::numeric      as product_stock,
      c.counting_stock::numeric     as counting_stock,
      c.updated_at,
      c.created_at,
      c.counted_date
    from inventory_counting c
    join lateral (
      select product_name, barcode, min_stock, max_stock
      from branch_stock_inventory b
      where b.store_id = c.store_id and b.product_id = c.product_id
      order by (b.deleted_at is null) desc
      limit 1
    ) bsi on true
    where c.store_id = p_store_id
      and (p_from is null or c.counted_date >= p_from)
      and (p_to   is null or c.counted_date <  p_to + 1)
      and (p_search is null or p_search = ''
           or bsi.product_name ilike '%' || p_search || '%'
           or bsi.barcode::text ilike '%' || p_search || '%')
  ),
  counted as (
    select
      base.*,
      count(*)                                            over () as total_count,
      count(*) filter (where counting_stock > product_stock) over () as surplus_count,
      count(*) filter (where counting_stock < product_stock) over () as shortage_count,
      count(*) filter (where counting_stock = product_stock) over () as matched_count
    from base
  )
  select to_jsonb(t)
  from (
    select * from counted
    order by abs(counting_stock - product_stock) desc,
             lower(product_name), id
    limit greatest(p_limit, 1) offset greatest(p_offset, 0)
  ) t;
$$;

notify pgrst, 'reload schema';
