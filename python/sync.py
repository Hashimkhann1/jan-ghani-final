import psycopg2
import psycopg2.extras
from supabase import create_client
import schedule
import time
import socket
from datetime import datetime, date
from decimal import Decimal
import os
from dotenv import load_dotenv

# ═══════════════════════════════════════════════
#         📦 .env file se values load karo
# ═══════════════════════════════════════════════
load_dotenv()

# ═══════════════════════════════════════════════
#              ⚙️  CONFIG — YAHAN EDIT KARO
# ═══════════════════════════════════════════════

LOCAL_DB = {
    "host":     os.getenv("DB_HOST", "localhost"),
    "database": os.getenv("DB_NAME", "store_db"),
    "user":     os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD"),
}

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SECRET_KEY")

SYNC_INTERVAL_SECONDS = 20

# ── Startup validation ──────────────────────────
missing = [k for k, v in {
    "SUPABASE_URL":        SUPABASE_URL,
    "SUPABASE_SECRET_KEY": SUPABASE_KEY,
    "DB_PASSWORD":         LOCAL_DB["password"],
}.items() if not v]

if missing:
    raise EnvironmentError(
        f"❌ .env mein yeh variables missing hain: {', '.join(missing)}\n"
        "   .env.example dekho aur apni .env file banao."
    )

TABLES = [
    "branch",
    "branch_users",
    "customer",
    "branch_counter",
    "branch_cash_counter",
    "branch_cash_transaction",
    "customer_ledger",
    "branch_expense",
    "sale_invoices",
    "sale_invoice_items",
    "sale_invoice_payments",
    "sale_returns",
    "sale_return_payments",
    "sale_return_items",
    "branch_summary",
    "branch_stock_inventory",
    "branch_summary",
]

# ═══════════════════════════════════════════════
#    🔧 Smart Serializer — Decimal/date/datetime
# ═══════════════════════════════════════════════
def serialize_value(value):
    if isinstance(value, Decimal):
        return float(value)
    elif isinstance(value, datetime):
        return value.isoformat()
    elif isinstance(value, date):
        return value.isoformat()
    return value

def serialize_row(row):
    return {k: serialize_value(v) for k, v in row.items()}

# ═══════════════════════════════════════════════
#    🔍 Table mein updated_at ya created_at check
# ═══════════════════════════════════════════════
def get_timestamp_column(cursor, table_name):
    cursor.execute("""
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = %s 
          AND table_schema = 'public'
          AND column_name IN ('updated_at', 'created_at')
        ORDER BY CASE column_name 
            WHEN 'updated_at' THEN 1 
            WHEN 'created_at' THEN 2 
        END
        LIMIT 1
    """, (table_name,))
    row = cursor.fetchone()
    return row[0] if row else None

# ═══════════════════════════════════════════════
#              🌐 Internet Check
# ═══════════════════════════════════════════════
def internet_available():
    try:
        socket.create_connection(("8.8.8.8", 53), timeout=3)
        return True
    except Exception:
        return False

# ═══════════════════════════════════════════════
#         🔄 Single Table Sync
# ═══════════════════════════════════════════════
def sync_table(local_conn, supabase, table_name):
    cursor     = local_conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    col_cursor = local_conn.cursor()

    try:
        timestamp_col = get_timestamp_column(col_cursor, table_name)

        last_sync = None
        if timestamp_col:
            try:
                result = supabase.table(table_name) \
                    .select(timestamp_col) \
                    .order(timestamp_col, desc=True) \
                    .limit(1) \
                    .execute()
                if result.data and result.data[0].get(timestamp_col):
                    last_sync = result.data[0][timestamp_col]
            except Exception:
                last_sync = None

        if last_sync and timestamp_col:
            cursor.execute(
                f'SELECT * FROM "{table_name}" WHERE "{timestamp_col}" > %s ORDER BY "{timestamp_col}" ASC',
                (last_sync,)
            )
        elif timestamp_col:
            cursor.execute(f'SELECT * FROM "{table_name}" ORDER BY "{timestamp_col}" ASC')
        else:
            cursor.execute(f'SELECT * FROM "{table_name}"')

        rows = cursor.fetchall()

        if not rows:
            print(f"   ✅ {table_name}: Sab sync hai")
            return 0

        data = [serialize_row(dict(row)) for row in rows]

        batch_size = 50
        total = 0
        for i in range(0, len(data), batch_size):
            batch = data[i:i + batch_size]
            supabase.table(table_name).upsert(batch, on_conflict="id").execute()
            total += len(batch)

        print(f"   🔄 {table_name}: {total} records sync hue!")
        return total

    except Exception as e:
        print(f"   ❌ {table_name} Error: {e}")
        return 0

# ═══════════════════════════════════════════════
#              🚀 Main Sync
# ═══════════════════════════════════════════════
def run_sync():
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"\n{'═'*50}")
    print(f"  🕐 Sync Start: {now}")
    print(f"{'═'*50}")

    if not internet_available():
        print("  📵 Internet nahi hai — sync skip kiya")
        print(f"{'═'*50}\n")
        return

    print("  🌐 Internet available — Sync shuru...")

    try:
        local_conn = psycopg2.connect(**LOCAL_DB)
        supabase   = create_client(SUPABASE_URL, SUPABASE_KEY)

        grand_total = 0
        for table in TABLES:
            grand_total += sync_table(local_conn, supabase, table)

        local_conn.close()
        print(f"{'─'*50}")

        if grand_total > 0:
            print(f"  ✅ Sync Complete! {grand_total} records Supabase mein gaye! 🎉")
        else:
            print(f"  ✅ Sync Complete! Sab pehle se updated tha")

    except psycopg2.OperationalError as e:
        print(f"  ❌ Local DB connect nahi hua: {e}")
    except Exception as e:
        print(f"  ❌ Error: {e}")

    print(f"{'═'*50}\n")

# ═══════════════════════════════════════════════
#           ⏰ Background Auto Sync
# ═══════════════════════════════════════════════
if __name__ == "__main__":
    print("""
╔══════════════════════════════════════════╗
║     🏪 Store DB → Supabase Sync          ║
║     Background Sync Service              ║
╚══════════════════════════════════════════╝
    """)
    print(f"  📋 Tables: {len(TABLES)}")
    print(f"  ⏱️  Interval: Har {SYNC_INTERVAL_SECONDS} seconds")
    print(f"  🛑 Band karne ke liye: CTRL + C\n")

    run_sync()

    schedule.every(SYNC_INTERVAL_SECONDS).seconds.do(run_sync)
    print(f"  ⏰ Next sync {SYNC_INTERVAL_SECONDS} seconds mein hoga...\n")

    try:
        while True:
            schedule.run_pending()
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n  👋 Sync service band kar di. Allah Hafiz!")