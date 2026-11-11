# Jan Ghani POS — LAN Setup

`X` = router ka subnet (e.g. router `192.168.1.1` ho to `X = 1`). Code mein koi IP
hardcode nahi hai — sab IP/naam `assets/json/branch_config.json` se aate hain.

## Current setup (Switch)

```
Internet Router ──(LAN cable, ~10 m)── 5-port Switch ──┬── PC-1  (PostgreSQL + app)   192.168.X.250
                                                       ├── PC-2  (counter, sirf app)  IP Automatic (DHCP)
                                                       └── Network thermal printer    192.168.X.251 : 9100
```

### 1. PC-1 (server)
- Network adapter → IPv4 → **static**: `192.168.X.250`, subnet `255.255.255.0`,
  gateway = router ka IP, DNS = router ka IP (ya 8.8.8.8).
- PostgreSQL yahin chalta hai. `postgresql.conf` mein `listen_addresses = '*'`.
- `pg_hba.conf` mein subnet allow karo:
  `host  all  all  192.168.X.0/24  scram-sha-256`
- Windows Firewall mein inbound TCP **5432** allow karo.
- `branch_config.json`:
  ```json
  "db_host": "localhost"
  ```

### 2. PC-2 (counter)
- IP: **Automatic (DHCP)**.
- `branch_config.json`:
  ```json
  "db_host": "192.168.X.250"
  ```
- PostgreSQL install karne ki zaroorat nahi, sirf app.

### 3. Network thermal printer
- Printer ka IP static: `192.168.X.251`, port **9100** (printer ki self-test slip / panel se set karo).
- **Dono PCs par** Windows mein: Printers & scanners → Add printer → *The printer I want isn't listed* →
  *Add a printer using TCP/IP address* → IP `192.168.X.251`, port 9100 (Standard TCP/IP Port).
- Dono PCs par printer ka naam **bilkul same** rakho (e.g. `BlackCopper`).

### 4. Printer ka naam config mein
App printer ko Windows ke installed naam se dhoondti hai (naam ka hissa bhi chalta hai, capital/small farq nahi).

```json
"printer_name": "BlackCopper"
```

- `printer_name` **na likha ho** to purana default `blackcopper` use hota hai; woh na mile to default/pehla printer.
- `printer_name` **likha ho** aur wo naam na mile to app error dikhati hai:
  `Printer "<naam>" nahi mila. Installed printers: ...`

### 5. Optional config fields
| Field | Default | Matlab |
|---|---|---|
| `db_host` | `localhost` | PostgreSQL ka host/IP |
| `db_port` | `5432` | PostgreSQL port |
| `printer_name` | `blackcopper` | Windows printer ka naam |

### 6. Timeout / cable nikalne par
DB connection timeout **5 second** hai. Counter PC (PC-2) ki cable nikal jaye to app hang nahi hoti —
5 second baad "Database se connect nahi ho saka" screen aati hai jis par **asal `db_host:port`** aur
**error message** dikhta hai. Cable wapas lagao aur **Retry** dabao.

### Troubleshooting
- PC-2 par "connect nahi ho saka": PC-1 par app/PostgreSQL chal raha hai? `ping 192.168.X.250`,
  firewall port 5432, `pg_hba.conf` subnet.
- Print nahi ho raha: `ping 192.168.X.251`, Windows mein printer ka naam `printer_name` se match karta hai?

---

## Old setup (direct cable)

Pehle 2 PCs seedhi LAN cable se direct connected the (router/switch ke baghair), static IPs `192.168.10.x` par:
- PC-1 (PostgreSQL + app) aur PC-2 (counter) — dono par manual static IP `192.168.10.x`.
- PC-2 ki `branch_config.json` mein `db_host` = PC-1 ka `192.168.10.x` IP.
- Printer USB se PC par laga hota tha; app naam `blackcopper` dhoondti thi.

Ye setup ab use nahi hota; naye setup ke liye upar "Current setup" dekho.
