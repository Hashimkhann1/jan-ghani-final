-- ============================================================
-- PostgreSQL Triggers Control (pgAdmin Query Tool)
-- Schema: public
-- Har section ko alag select karke run karo (F5)
-- ============================================================


-- ============================================================
-- 1) DISABLE: public schema ke sab user triggers band karo
--    (system/FK triggers ko touch nahi karta)
-- ============================================================
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT DISTINCT n.nspname AS schema_name, c.relname AS table_name
        FROM pg_trigger t
        JOIN pg_class c ON c.oid = t.tgrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE NOT t.tgisinternal
          AND n.nspname = 'public'
    LOOP
        EXECUTE format('ALTER TABLE %I.%I DISABLE TRIGGER USER;', r.schema_name, r.table_name);
    END LOOP;
END $$;


-- ============================================================
-- 2) ENABLE: public schema ke sab user triggers wapis on karo
-- ============================================================
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT DISTINCT n.nspname AS schema_name, c.relname AS table_name
        FROM pg_trigger t
        JOIN pg_class c ON c.oid = t.tgrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE NOT t.tgisinternal
          AND n.nspname = 'public'
    LOOP
        EXECUTE format('ALTER TABLE %I.%I ENABLE TRIGGER USER;', r.schema_name, r.table_name);
    END LOOP;
END $$;


-- ============================================================
-- 3) CHECK: kon sa trigger enabled hai aur kon sa disabled
-- ============================================================
SELECT n.nspname AS schema_name,
       c.relname AS table_name,
       t.tgname  AS trigger_name,
       CASE t.tgenabled
            WHEN 'D' THEN 'DISABLED'
            ELSE 'ENABLED'
       END AS status
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE NOT t.tgisinternal
  AND n.nspname = 'public'
ORDER BY c.relname, t.tgname;
