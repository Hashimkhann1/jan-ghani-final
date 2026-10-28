-- Seed the 4 digital products for every branch.
-- Safe to re-run: (store_id, product_id) is unique and conflicts are skipped.
-- Run AFTER 2026_10_28_digital_products.sql.

INSERT INTO public.branch_stock_inventory
    (store_id, product_id, sku, barcode, product_name, purchase_price, sale_price,
     wholesale_price, stock, min_stock, max_stock, unit, product_type)
SELECT b.id, d.product_id::uuid, d.sku, ARRAY[d.sku], d.name,
       0, 0, 0, 0, 0, 0, 'service', d.product_type
FROM public.branch b
CROSS JOIN (VALUES
    ('d1617a01-0000-4000-8000-000000000001', 'DIG-BANK',     'Bank Transfer', 'digital'),
    ('d1617a01-0000-4000-8000-000000000002', 'DIG-BILL',     'Pay Bill',      'digital'),
    ('d1617a01-0000-4000-8000-000000000003', 'DIG-SIM',      'SIM Load',      'digital'),
    ('d1617a01-0000-4000-8000-000000000004', 'DIG-WITHDRAW', 'Cash Withdraw', 'digital_withdraw')
) AS d(product_id, sku, name, product_type)
ON CONFLICT (store_id, product_id) DO NOTHING;
