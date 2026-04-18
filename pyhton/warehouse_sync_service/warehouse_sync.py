# import psycopg2
# import psycopg2.extras
# from supabase import create_client
# import schedule
# import time
# import socket
# from datetime import datetime, date
# from decimal import Decimal
#
# # ═══════════════════════════════════════════════
# #              ⚙️  CONFIG — YAHAN EDIT KARO
# # ═══════════════════════════════════════════════
#
#
# SYNC_INTERVAL_MINUTES = 0.5
#
# # ═══════════════════════════════════════════════
# #    📋 WAREHOUSE TABLES — Dependency order mein
# #    (parent tables pehle, child tables baad mein)
# # ═══════════════════════════════════════════════
#
# TABLES = [
#     # Level 1 — No dependencies
#     "warehouses",
#     "locations",
#
#     # Level 2 — warehouses pe depend karte hain
#     "warehouse_users",
#     "warehouse_categories",
#     "suppliers",
#
#     # Level 3 — warehouses + categories pe depend
#     "warehouse_products",
#
#     # Level 4 — products pe depend
#     "warehouse_inventory",
#     "warehouse_finance",
#     "warehouse_cash_transactions",
#     "warehouse_expenses",
#     "warehouse_stock_movements",
#
#     # Level 5 — suppliers pe depend
#     "supplier_ledger",
#
#     # Level 6 — purchase chain
#     "purchase_orders",
#     "purchase_order_items",
#
#     # Level 7 — stock transfer chain
#     "stock_transfers",
#     "stock_transfer_items",
#
#     # Level 8 — misc
#     "linked_stores",
#     "product_audit_log",
#     "warehouse_sync_log",
# ]
#
# # ═══════════════════════════════════════════════
# #    is_synced column wali tables
# #    (yeh tables is_synced = false se sync hongi)
# # ═══════════════════════════════════════════════
#
# IS_SYNCED_TABLES = {
#     "warehouse_products",
#     "warehouse_inventory",
#     "warehouse_categories",
#     "warehouse_cash_transactions",
#     "warehouse_expenses",
#     "warehouse_stock_movements",
#     "suppliers",
#     "supplier_ledger",
#     "purchase_orders",
# }
#
# # ═══════════════════════════════════════════════
# #    🔧 Smart Serializer — Decimal/date/datetime/list
# # ═══════════════════════════════════════════════
#
# def serialize_value(value):
#     if isinstance(value, Decimal):
#         return float(value)
#     elif isinstance(value, datetime):
#         return value.isoformat()
#     elif isinstance(value, date):
#         return value.isoformat()
#     elif isinstance(value, list):
#         return value  # Supabase arrays support karta hai
#     return value
#
# def serialize_row(row):
#     return {k: serialize_value(v) for k, v in row.items()}
#
# # ═══════════════════════════════════════════════
# #    🔍 Timestamp column check
# # ═══════════════════════════════════════════════
#
# def get_timestamp_column(cursor, table_name):
#     cursor.execute("""
#         SELECT column_name
#         FROM information_schema.columns
#         WHERE table_name   = %s
#           AND table_schema = 'public'
#           AND column_name  IN ('updated_at', 'created_at', 'linked_at', 'changed_at', 'attempted_at')
#         ORDER BY CASE column_name
#             WHEN 'updated_at'   THEN 1
#             WHEN 'created_at'   THEN 2
#             WHEN 'linked_at'    THEN 3
#             WHEN 'changed_at'   THEN 4
#             WHEN 'attempted_at' THEN 5
#         END
#         LIMIT 1
#     """, (table_name,))
#     row = cursor.fetchone()
#     return row[0] if row else None
#
# # ═══════════════════════════════════════════════
# #              🌐 Internet Check
# # ═══════════════════════════════════════════════
#
# def internet_available():
#     try:
#         socket.create_connection(("8.8.8.8", 53), timeout=3)
#         return True
#     except Exception:
#         return False
#
# # ═══════════════════════════════════════════════
# #    🔄 is_synced wali tables ke liye sync
# # ═══════════════════════════════════════════════
#
# def sync_table_by_is_synced(local_conn, supabase, table_name):
#     cursor     = local_conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
#     upd_cursor = local_conn.cursor()
#
#     try:
#         # is_synced = false wale records lo
#         cursor.execute(
#             f'SELECT * FROM public."{table_name}" WHERE is_synced = false LIMIT 500'
#         )
#         rows = cursor.fetchall()
#
#         if not rows:
#             print(f"   ✅ {table_name}: Sab sync hai")
#             return 0
#
#         data = [serialize_row(dict(row)) for row in rows]
#         ids  = [row['id'] for row in rows]
#
#         # Supabase mein upsert karo
#         batch_size = 50
#         total = 0
#         for i in range(0, len(data), batch_size):
#             batch = data[i:i + batch_size]
#             supabase.table(table_name).upsert(batch, on_conflict="id").execute()
#             total += len(batch)
#
#         # Local mein is_synced = true aur synced_at update karo
#         upd_cursor.execute(
#             f'UPDATE public."{table_name}" SET is_synced = true, synced_at = NOW() WHERE id = ANY(%s)',
#             (ids,)
#         )
#         local_conn.commit()
#
#         print(f"   🔄 {table_name}: {total} records sync hue!")
#         return total
#
#     except Exception as e:
#         local_conn.rollback()
#         print(f"   ❌ {table_name} Error: {e}")
#         return 0
#
# # ═══════════════════════════════════════════════
# #    🔄 updated_at wali tables ke liye sync
# # ═══════════════════════════════════════════════
#
# def sync_table_by_timestamp(local_conn, supabase, table_name):
#     cursor     = local_conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
#     col_cursor = local_conn.cursor()
#
#     try:
#         timestamp_col = get_timestamp_column(col_cursor, table_name)
#
#         # Supabase mein last record ka timestamp lo
#         last_sync = None
#         if timestamp_col:
#             try:
#                 result = supabase.table(table_name) \
#                     .select(timestamp_col) \
#                     .order(timestamp_col, desc=True) \
#                     .limit(1) \
#                     .execute()
#                 if result.data and result.data[0].get(timestamp_col):
#                     last_sync = result.data[0][timestamp_col]
#             except Exception:
#                 last_sync = None
#
#         # Local se naye records lo
#         if last_sync and timestamp_col:
#             cursor.execute(
#                 f'SELECT * FROM public."{table_name}" WHERE "{timestamp_col}" > %s ORDER BY "{timestamp_col}" ASC',
#                 (last_sync,)
#             )
#         elif timestamp_col:
#             cursor.execute(
#                 f'SELECT * FROM public."{table_name}" ORDER BY "{timestamp_col}" ASC'
#             )
#         else:
#             cursor.execute(f'SELECT * FROM public."{table_name}"')
#
#         rows = cursor.fetchall()
#
#         if not rows:
#             print(f"   ✅ {table_name}: Sab sync hai")
#             return 0
#
#         data = [serialize_row(dict(row)) for row in rows]
#
#         batch_size = 50
#         total = 0
#         for i in range(0, len(data), batch_size):
#             batch = data[i:i + batch_size]
#             supabase.table(table_name).upsert(batch, on_conflict="id").execute()
#             total += len(batch)
#
#         print(f"   🔄 {table_name}: {total} records sync hue!")
#         return total
#
#     except Exception as e:
#         print(f"   ❌ {table_name} Error: {e}")
#         return 0
#
# # ═══════════════════════════════════════════════
# #    🔄 Smart sync — table ke hisaab se method
# # ═══════════════════════════════════════════════
#
# def sync_table(local_conn, supabase, table_name):
#     if table_name in IS_SYNCED_TABLES:
#         return sync_table_by_is_synced(local_conn, supabase, table_name)
#     else:
#         return sync_table_by_timestamp(local_conn, supabase, table_name)
#
# # ═══════════════════════════════════════════════
# #              🚀 Main Sync
# # ═══════════════════════════════════════════════
#
# def run_sync():
#     now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
#     print(f"\n{'═'*50}")
#     print(f"  🕐 Sync Start: {now}")
#     print(f"{'═'*50}")
#
#     if not internet_available():
#         print("  📵 Internet nahi hai — sync skip kiya")
#         print(f"{'═'*50}\n")
#         return
#
#     print("  🌐 Internet available — Sync shuru...")
#
#     try:
#         local_conn = psycopg2.connect(**LOCAL_DB)
#         supabase   = create_client(SUPABASE_URL, SUPABASE_KEY)
#
#         grand_total = 0
#         for table in TABLES:
#             grand_total += sync_table(local_conn, supabase, table)
#
#         local_conn.close()
#         print(f"{'─'*50}")
#
#         if grand_total > 0:
#             print(f"  ✅ Sync Complete! {grand_total} records Supabase mein gaye! 🎉")
#         else:
#             print(f"  ✅ Sync Complete! Sab pehle se updated tha")
#
#     except psycopg2.OperationalError as e:
#         print(f"  ❌ Local DB connect nahi hua: {e}")
#     except Exception as e:
#         print(f"  ❌ Error: {e}")
#
#     print(f"{'═'*50}\n")
#
# # ═══════════════════════════════════════════════
# #           ⏰ Background Auto Sync
# # ═══════════════════════════════════════════════
#
# if __name__ == "__main__":
#     print("""
# ╔══════════════════════════════════════════╗
# ║   🏪 Jan Ghani Warehouse → Supabase      ║
# ║      Background Sync Service             ║
# ╚══════════════════════════════════════════╝
#     """)
#     print(f"  📋 Tables: {len(TABLES)}")
#     print(f"  ⏱️  Interval: Har {SYNC_INTERVAL_MINUTES} minute")
#     print(f"  🛑 Band karne ke liye: CTRL + C\n")
#
#     # Pehle abhi sync karo
#     run_sync()
#
#     # Phir schedule pe
#     schedule.every(SYNC_INTERVAL_MINUTES).minutes.do(run_sync)
#     print(f"  ⏰ Next sync {SYNC_INTERVAL_MINUTES} minute mein hoga...\n")
#
#     try:
#         while True:
#             schedule.run_pending()
#             time.sleep(1)
#     except KeyboardInterrupt:
#         print("\n  👋 Sync service band kar di. Allah Hafiz!")