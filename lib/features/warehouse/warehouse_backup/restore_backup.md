<!-- Updated on 2026-11-08 10:37 AM -->

# Jan Ghani Warehouse — Backup RESTORE Guide (step by step)

> Yeh guide tab ke liye hai jab warehouse ka computer **kharab ho jaye / badalna ho** aur purana data naye computer par wapas laana ho.
> Sab kuch **sirf pgAdmin** se hota hai — koi command likhne ki zaroorat nahi.

---

## 1. Backup ki files kya hain

App mein **ADMIN → Backup → "Backup Lein"** dabane par chuna hua folder mein **har backup ki 2 files** banti hain:

| # | File ka naam (misaal) | Kya hai |
|---|---|---|
| **STEP 1** | `JG-WH-001_backup_2026-11-08_10-27-06_STEP1_user.sql` | Chhoti SQL file — naye computer par database **user** (`warehouseuser`) banati hai, config.json wale password ke saath. Is mein asal password **nahi**, sirf uska hash (SCRAM). Notepad mein khul sakti hai. |
| **STEP 2** | `JG-WH-001_backup_2026-11-08_10-27-06_STEP2_data.backup` | **Poora database** — saari tables, data, triggers, functions, views, indexes, permissions. PostgreSQL ka **custom format** (compressed, binary — Notepad mein nahi khulti). |

- Dono files ka **date/time same** hona chahiye — hamesha ek hi backup ki dono files saath use karein.
- **Sab se naya** backup use karein (Backup screen par "Last Backup" card mein naam likha hota hai).

### ⚠️ Backup ko mehfooz rakhna
- Backup file **isi computer** par banti hai. Computer kharab = backup bhi gaya. Isliye har backup ki **dono files** USB / Google Drive par bhi copy karein.
- File mein poora data (users bhi) hai — **kisi ko share na karein**.
- Backup ke **baad** jo entries hongi woh is backup mein nahi hongi — isliye **roz** backup lein.

---

## 2. Restore se pehle — tayyari

1. Backup ki **dono files** (STEP1 + STEP2) naye computer par kisi folder mein copy kar lein, jaise `D:\JanGhaniBackup\`.
2. Purane computer ki **`config.json`** file (Jan Ghani app ke `assets/json/` mein) ki copy ya us ki values likh kar rakh lein:
   `warehouse_id`, `warehouse_code`, `warehouse_name`, `db_name`, `db_user`, `db_password`, `db_host`, `db_port`.
   (STEP1 file usi `db_password` se user banati hai jo backup ke waqt config.json mein tha.)

---

## 3. STEP 0 — PostgreSQL + pgAdmin install

1. PostgreSQL ka Windows installer download karein (EnterpriseDB) — **wahi version jo purane computer par tha, ya us se NAYA** (purana version restore nahi kar sakta).
2. Install karte waqt:
   - **pgAdmin 4** wala option ON rakhein (by default hota hai).
   - `postgres` (superuser) ka **password** rakhein aur **yaad rakhein / likh lein**.
   - Port **5432** rehne dein.
   - Locale default rehne dein.
3. Install ke baad **pgAdmin 4** kholein → left side **Servers** → **PostgreSQL <version>** par click → `postgres` ka password daalein (Save password tick kar sakte hain).

---

## 4. STEP 1 — Database user banana (`_STEP1_user.sql`)

1. pgAdmin mein left side: **Servers → PostgreSQL → Databases** kholein.
2. **`postgres`** database par **right-click** → **Query Tool**.
3. Query Tool ke upar **Open File** (📂 folder icon) dabayein → apni **`…_STEP1_user.sql`** file chunein → Open.
   (File ka text editor mein aa jayega.)
4. **Execute** dabayein (▶ button, ya keyboard **F5**).
5. Check karein:
   - **Messages** tab mein: `NOTICE: User warehouseuser bana diya`
   - **Data Output** tab mein 2 lines:

     | role | can_login |
     |---|---|
     | postgres | true |
     | warehouseuser | true |

✅ Dono lines dikhein to STEP 1 mukammal.

> STEP 1 ghalti se **dobara** chal jaye to koi nuqsan nahi — message aayega `User warehouseuser pehle se tha — login + password theek kiya`.

---

## 5. STEP 2 — Data wapas laana (`_STEP2_data.backup`)

> ⚠️ STEP 2 hamesha STEP 1 ke **baad**. Warna error aayega: `role "warehouseuser" does not exist`.

1. Left side **Databases** mein phir **`postgres`** par **right-click** → **Restore…**
2. **General** tab:
   - **Format:** `Custom or tar`
   - **Filename:** 📂 dabayein → apni **`…_STEP2_data.backup`** file chunein
     (file na dikhe to neeche file-type dropdown mein **All Files** chunein)
   - **Role name:** `postgres`
3. **Query Options** tab:
   - **"Include CREATE DATABASE statement"** → **ON** ✅
   (Is se `warehouse_db` database khud ban jayega.)
4. Baaki sab options **default** rehne dein (koi aur cheez ON/OFF na karein).
5. **Restore** button dabayein.
6. Neeche right side **Processes** panel mein status dekhein → **"Successfully completed"** ✅
   (Bara data ho to 1–5 minute lag sakte hain — wait karein.)
7. Left side **Databases** par right-click → **Refresh** → ab **`warehouse_db`** nazar aayega.

### Check karein ke data aa gaya
`warehouse_db` par right-click → **Query Tool** → yeh likh kar **F5**:

```sql
SELECT
  (SELECT count(*) FROM warehouse_products)          AS products,
  (SELECT count(*) FROM suppliers)                   AS suppliers,
  (SELECT count(*) FROM warehouse_cash_transactions) AS cash_entries,
  (SELECT cash_in_hand FROM warehouse_finance LIMIT 1) AS cash_in_hand;
```

Numbers purane computer jaise (backup ke waqt jaise) hone chahiye.

---

## 6. STEP 3 — Jan Ghani app chalana

1. Naye computer par Jan Ghani warehouse app install karein.
2. App ki **`config.json`** (`assets/json/config.json`) mein **purane computer wali values** daalein:

   ```json
   {
     "app_mode": "warehouse",
     "warehouse_id":   "<purane jaisa>",
     "warehouse_code": "<purane jaisa>",
     "warehouse_name": "<purane jaisa>",
     "db_host": "localhost",
     "db_port": 5432,
     "db_name": "warehouse_db",
     "db_user": "warehouseuser",
     "db_password": "<purane jaisa>"
   }
   ```
   - `warehouse_id` **bilkul same** hona chahiye — warna app ko data nahi milega aur Supabase sync galat warehouse par jayega.
3. App kholein → apne purane user se **login** karein.
4. Check karein: Stock, Suppliers, Finance (cash in hand), Expense — sab backup ke waqt jaise.
5. Jo entries backup ke waqt **sync nahi hui thin**, woh internet milte hi Supabase par khud chali jayengi.
6. Backup screen (**ADMIN → Backup**) par naya folder chun kar **foran naya backup** le lein.

---

## 7. Khaas haalaat (agar kuch alag ho)

### A. `warehouse_db` naye server par **pehle se** mojood hai
STEP 2 mein "Include CREATE DATABASE statement" **OFF** rakhein, aur `postgres` ki jagah **`warehouse_db`** par right-click → Restore… karein.
⚠️ Agar `warehouse_db` mein pehle se data hai to restore se duplicate/errors aayenge — pehle confirm kar lein ke woh khaali hai.

### B. STEP 2 mein **locale / collation** error aaye
(Masalan: `invalid locale name` — tab hota hai jab backup kisi aur language-setting wale computer ka ho.)
1. **Databases** par right-click → **Create → Database…**
   - Database: `warehouse_db`
   - Owner: `warehouseuser`
   - Save
2. Phir **`warehouse_db`** par right-click → **Restore…** → STEP 2 jaisa, lekin **"Include CREATE DATABASE statement" OFF**.

### C. Purana backup — sirf `.backup` file hai, `_STEP1_user.sql` nahi
(Pehle wale version ke backups mein STEP1 file nahi banti thi.)
User khud banayein:
1. Left side **Login/Group Roles** par right-click → **Create → Login/Group Role…**
2. **General:** Name = `warehouseuser`
3. **Definition:** Password = config.json wala `db_password`
4. **Privileges:** **Can login? = Yes**
5. **Save** → phir upar wala STEP 2.

### D. Backup screen par "Success" ke saath amber note tha
Matlab data file (`STEP2`) theek hai lekin `STEP1` file nahi bani. Section **C** jaisa user khud banayein, phir STEP 2.

### E. Restore ke baad app connect nahi hoti
- `config.json` ka `db_password` check karein — STEP1 file **backup ke waqt wale** password se user banati hai.
- pgAdmin mein **Login/Group Roles → warehouseuser → Properties → Privileges → Can login = Yes** check karein.
- PostgreSQL service chal rahi hai? (Windows → Services → `postgresql-x64-<version>` → Running)

---

## 8. Common errors aur hal

| Error | Matlab | Hal |
|---|---|---|
| `role "warehouseuser" does not exist` | STEP 1 nahi chala | Pehle STEP 1, phir STEP 2 dobara |
| `database "warehouse_db" already exists` | Database pehle se hai | Section **A** |
| `invalid locale name` / collation error | Locale farq | Section **B** |
| `unsupported version (1.x) in file header` | PostgreSQL purana hai | Wahi ya naya version install karein |
| `password authentication failed for user "warehouseuser"` (app mein) | config.json ka password STEP1 wale se mukhtalif | Purana `db_password` daalein, ya STEP1 dobara chalayein |
| Processes mein "Failed" | Restore mein masla | Processes mein **"View details"** (📄) se poora error parhein |

---

## 9. Pehle se ek dafa TEST zaroor karein

Asli zaroorat se pehle kisi **doosre computer** par (ya naye PostgreSQL install par) STEP 1 + STEP 2 + data check chala kar dekh lein ke restore theek chalta hai.
⚠️ **Chalti hui** warehouse ki `warehouse_db` par kabhi test restore na karein.

---

## 10. Technical (developer ke liye)

- Backup command (app andar se chalati hai):
  `pg_dump -h <db_host> -p <db_port> -U <db_user> -d <db_name> -Fc --no-password -f <file>_STEP2_data.backup` (password `PGPASSWORD` env se)
- Backup ke baad safety check: `pg_restore --list <file>` — file parhi na jaye ya `TABLE DATA` 0 ho → backup **Failed**, files delete.
- STEP1 file: `pg_restore --schema-only --create` ke output se `OWNER TO` / `GRANT … TO` / `FOR ROLE` wale saare roles; app user = `LOGIN PASSWORD '<SCRAM-SHA-256 hash>'`, baaki = `NOLOGIN`, `IF NOT EXISTS` (idempotent).
- pgAdmin "Restore" = `pg_restore`. Command line se same kaam:
  ```bat
  cd "C:\Program Files\PostgreSQL\18\bin"
  psql -U postgres -d postgres -f "D:\JanGhaniBackup\<file>_STEP1_user.sql"
  pg_restore -U postgres -C -d postgres -v "D:\JanGhaniBackup\<file>_STEP2_data.backup"
  ```
- `.sql` (plain text) chahiye: `pg_restore -f data.sql <file>_STEP2_data.backup`
- Tested (Mac, 2026-11-08): bilkul naye khaali PostgreSQL 18 server par STEP1 + STEP2 → exit 0, `warehouseuser` login ✅, data purane ke barabar (816 products, 137 ledger, 103 cash, 27 tables, 13 triggers). pgAdmin UI aur Windows par khud test nahi hua.
- Code: `data/warehouse_backup_repository.dart` · Screen: `presentation/screens/warehouse_backup_screen.dart`
