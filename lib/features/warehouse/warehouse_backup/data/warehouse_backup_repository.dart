// Updated on 2026-11-08 09:48 AM
// =============================================================
// warehouse_backup_repository.dart
// Local Postgres ka poora backup (schema + data) — pg_dump(.exe) se.
//
//   • pg_dump kahan se: config.json `pg_dump_path` → warna khud dhoondo
//     (Windows: C:\Program Files\PostgreSQL\<ver>\bin\pg_dump.exe — sab se
//      naya version; macOS: Homebrew / Postgres.app; aakhir mein PATH)
//   • Password: PGPASSWORD env var (AppConfig.dbPassword) — command mein NAHI
//   • Format: -Fc (custom, compressed) → restore: pg_restore
//   • Har koshish (success ya fail) ka record `warehouse_backups` mein
//     (SIRF LOCAL — Supabase sync nahi)
//   • Har backup = 2 files (pgAdmin se restore ke liye):
//       <CODE>_backup_<time>_STEP1_user.sql   → Query Tool (roles/users + password hash)
//       <CODE>_backup_<time>_STEP2_data.backup → Restore ("Include CREATE DATABASE")
//   • Safety: pg_dump ke baad `pg_restore --list` se file padh kar check —
//     na padhi jaye / data na ho = FAILED (files delete). STEP1 file na bane
//     to backup phir bhi success + note (data file theek hai).
// =============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_backup/domain/warehouse_backup_model.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

class WarehouseBackupRepository {
  WarehouseBackupRepository._();
  static final instance = WarehouseBackupRepository._();

  Future<Connection> get _db  => DatabaseService.getConnection();
  String             get _wid => AppConfig.warehouseId;

  /// Bahut bara DB ho to bhi itne mein khatam ho jana chahiye.
  static const _timeout = Duration(minutes: 30);

  bool _tableReady = false;

  // ─────────────────────────────────────────────────────────
  // 1. Table ensure (migration file bhi hai — yeh safety net hai
  //    taake production par migration bhool jaane se screen na toote)
  // ─────────────────────────────────────────────────────────
  Future<void> ensureTable() async {
    if (_tableReady) return;
    final conn = await _db;
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS public.warehouse_backups (
          id               uuid        NOT NULL PRIMARY KEY,
          warehouse_id     uuid        NOT NULL,
          file_name        text        NOT NULL,
          file_path        text        NOT NULL,
          file_size_bytes  bigint      NOT NULL DEFAULT 0,
          status           text        NOT NULL,
          error_message    text,
          duration_ms      integer,
          created_by       uuid,
          created_by_name  character varying(150),
          created_at       timestamptz NOT NULL DEFAULT now(),
          CONSTRAINT warehouse_backups_status_check
              CHECK (status = ANY (ARRAY['success'::text, 'failed'::text]))
      )
    ''');
    await conn.execute('''
      CREATE INDEX IF NOT EXISTS idx_warehouse_backups_wh_created
          ON public.warehouse_backups (warehouse_id, created_at DESC)
    ''');
    _tableReady = true;
  }

  // ─────────────────────────────────────────────────────────
  // 2. History (latest pehle)
  // ─────────────────────────────────────────────────────────
  Future<List<WarehouseBackupRecord>> getHistory({int limit = 200}) async {
    await ensureTable();
    final conn = await _db;
    final res = await conn.execute(
      Sql.named('''
        SELECT id, file_name, file_path, file_size_bytes, status,
               error_message, duration_ms, created_by_name, created_at
        FROM warehouse_backups
        WHERE warehouse_id = @wid
        ORDER BY created_at DESC
        LIMIT @limit
      '''),
      parameters: {'wid': _wid, 'limit': limit},
    );
    return res
        .map((r) => WarehouseBackupRecord.fromMap(r.toColumnMap()))
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  // 3. Backup lo → record save → record return
  //    Fail par bhi record banta hai (status = failed + wajah).
  // ─────────────────────────────────────────────────────────
  Future<WarehouseBackupRecord> createBackup({
    required String folderPath,
    String? userId,
    String? userName,
  }) async {
    await ensureTable();

    final stamp    = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final code     = AppConfig.warehouseCode.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final base     = '${code}_backup_$stamp';
    final sep      = Platform.pathSeparator;
    // STEP 1 = user/role SQL (pgAdmin Query Tool) · STEP 2 = data (pgAdmin Restore)
    final fileName    = '${base}_STEP2_data.backup';
    final filePath    = '$folderPath$sep$fileName';
    final userSqlPath = '$folderPath$sep${base}_STEP1_user.sql';

    final watch = Stopwatch()..start();
    String? error;
    String? note;   // success ke saath chhoti warning (backup phir bhi theek)
    var size = 0;

    try {
      final dir = Directory(folderPath);
      if (!await dir.exists()) {
        throw const _BackupError('Chuna hua folder mojood nahi hai.');
      }

      final pgDump = await _resolvePgDump();
      await _checkVersion(pgDump);

      final process = await Process.start(
        pgDump,
        [
          '-h', AppConfig.dbHost,
          '-p', AppConfig.dbPort.toString(),
          '-U', AppConfig.dbUser,
          '-d', AppConfig.dbName,
          '-Fc',
          '--no-password',
          '-f', filePath,
        ],
        environment: {'PGPASSWORD': AppConfig.dbPassword},
      );

      final stderrBuf = StringBuffer();
      final errSub = process.stderr
          .transform(utf8.decoder)
          .listen(stderrBuf.write);
      final outSub = process.stdout.listen((_) {});

      int exitCode;
      try {
        exitCode = await process.exitCode.timeout(_timeout);
      } on TimeoutException {
        process.kill();
        throw const _BackupError(
            'Backup bohat der se chal raha tha (30 min) — rok diya gaya.');
      } finally {
        await errSub.cancel();
        await outSub.cancel();
      }

      if (exitCode != 0) {
        throw _BackupError(_friendlyPgError(stderrBuf.toString(), exitCode));
      }

      final file = File(filePath);
      size = await file.exists() ? await file.length() : 0;
      if (size <= 0) {
        throw const _BackupError('Backup file khaali bani — dobara koshish karein.');
      }

      // ── Safety: file ko pg_restore se padh kar check karo ──
      final pgRestore = await _siblingTool(pgDump, 'pg_restore');
      if (pgRestore == null) {
        note = 'pg_restore nahi mila — file check nahi hui, aur STEP1 user file '
            'nahi bani. Data backup (STEP2) theek hai.';
      } else {
        await _verifyArchive(pgRestore, filePath); // kharab ho to throw → failed

        // ── STEP 1 user SQL (roles + password) — fail ho to sirf note ──
        try {
          await _writeUserSql(
            pgRestore:   pgRestore,
            archivePath: filePath,
            outPath:     userSqlPath,
            dataFile:    fileName,
          );
        } catch (e) {
          note = 'STEP1 user file nahi bani ($e) — data backup (STEP2) theek hai; '
              'restore se pehle "${AppConfig.dbUser}" user khud banana hoga.';
          try {
            final f = File(userSqlPath);
            if (await f.exists()) await f.delete();
          } catch (_) {}
        }
      }
    } on _BackupError catch (e) {
      error = e.message;
    } on ProcessException catch (e) {
      error = 'pg_dump chal nahi saka: ${e.message}';
    } on FileSystemException catch (e) {
      error = 'Folder / file ka masla: ${e.message}${e.path != null ? ' (${e.path})' : ''}';
    } catch (e) {
      error = e.toString();
    }
    watch.stop();

    // Fail par adhoori files mita do (taake galti se use na ho)
    if (error != null) {
      for (final p in [filePath, userSqlPath]) {
        try {
          final f = File(p);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      size = 0;
    }
    final message = error ?? note;

    final id = const Uuid().v4();
    final conn = await _db;
    final res = await conn.execute(
      Sql.named('''
        INSERT INTO warehouse_backups (
          id, warehouse_id, file_name, file_path, file_size_bytes,
          status, error_message, duration_ms, created_by, created_by_name
        ) VALUES (
          @id, @wid, @fileName, @filePath, @size,
          @status, @error, @duration, @userId, @userName
        )
        RETURNING id, file_name, file_path, file_size_bytes, status,
                  error_message, duration_ms, created_by_name, created_at
      '''),
      parameters: {
        'id':       id,
        'wid':      _wid,
        'fileName': fileName,
        'filePath': filePath,
        'size':     size,
        'status':   error == null ? 'success' : 'failed',
        'error':    message == null
            ? null
            : (message.length > 1000 ? message.substring(0, 1000) : message),
        'duration': watch.elapsedMilliseconds,
        'userId':   _uuidOrNull(userId),
        'userName': (userName == null || userName.isEmpty) ? null : userName,
      },
    );
    return WarehouseBackupRecord.fromMap(res.first.toColumnMap());
  }

  // ─────────────────────────────────────────────────────────
  // pg_restore — pg_dump ke saath wale folder mein
  // ─────────────────────────────────────────────────────────
  Future<String?> _siblingTool(String pgDump, String tool) async {
    final i   = pgDump.lastIndexOf(RegExp(r'[\\/]'));
    final exe = Platform.isWindows ? '$tool.exe' : tool;
    if (i > 0) {
      final p = '${pgDump.substring(0, i)}${Platform.pathSeparator}$exe';
      if (await File(p).exists()) return p;
    }
    // pg_dump PATH se mila tha → pg_restore bhi PATH par
    try {
      final r = await Process.run(Platform.isWindows ? 'where' : 'which', [exe]);
      final line = r.stdout.toString().split(RegExp(r'[\r\n]+')).first.trim();
      if (r.exitCode == 0 && line.isNotEmpty) return line;
    } catch (_) {}
    return null;
  }

  /// Backup file ko pg_restore se padho — na padhi jaye ya data na ho = kharab.
  Future<void> _verifyArchive(String pgRestore, String archivePath) async {
    final r = await Process.run(pgRestore, ['--list', archivePath]);
    if (r.exitCode != 0) {
      throw _BackupError(
          'Backup file check mein fail (pg_restore): ${r.stderr.toString().trim()}');
    }
    final dataEntries = RegExp(r' TABLE DATA ').allMatches(r.stdout.toString()).length;
    if (dataEntries == 0) {
      throw const _BackupError('Backup file mein koi table data nahi mila — kharab backup.');
    }
  }

  /// STEP 1 file: restore ke liye zaroori saare roles (users) banane wali SQL.
  /// Roles backup file se hi nikalte hain (OWNER TO / GRANT … TO) — jo restore
  /// mangega wohi. App ka user (config db_user) = LOGIN + config wala password
  /// (SCRAM hash — asal password file mein NAHI). Baaki roles = NOLOGIN.
  /// Idempotent: dobara chalao to kuch nahi tootta.
  Future<void> _writeUserSql({
    required String pgRestore,
    required String archivePath,
    required String outPath,
    required String dataFile,
  }) async {
    final r = await Process.run(
      pgRestore,
      ['-f', '-', '--create', '--schema-only', archivePath],
      stdoutEncoding: utf8,
    );
    if (r.exitCode != 0) {
      throw _BackupError('roles nahi nikle: ${r.stderr.toString().trim()}');
    }

    final appUser = AppConfig.dbUser;
    final roles = <String>{appUser};
    final ident = r'("(?:[^"]|"")+"|[A-Za-z_][A-Za-z0-9_$]*)';
    final ownerRe = RegExp('OWNER TO $ident;');
    final grantRe = RegExp(r'^(?:GRANT .* TO|REVOKE .* FROM) (.+?)( WITH GRANT OPTION)?;$',
        multiLine: true);
    final forRoleRe = RegExp('FOR ROLE $ident');
    for (final re in [ownerRe, forRoleRe]) {
      for (final m in re.allMatches(r.stdout as String)) {
        roles.add(_unquote(m.group(1)!));
      }
    }
    for (final m in grantRe.allMatches(r.stdout as String)) {
      for (final part in m.group(1)!.split(',')) {
        final name = _unquote(part.trim());
        if (name.isNotEmpty && name.toUpperCase() != 'PUBLIC') roles.add(name);
      }
    }

    final dbName   = AppConfig.dbName;
    final verifier = _scramVerifier(AppConfig.dbPassword);
    final others   = roles.where((x) => x != appUser).toList()..sort();
    final now      = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final sb = StringBuffer()
      ..writeln('-- =============================================================')
      ..writeln('-- JAN GHANI WAREHOUSE — RESTORE  STEP 1 / 2  (user banana)')
      ..writeln('-- Backup: $now · ${AppConfig.warehouseName} (${AppConfig.warehouseCode})')
      ..writeln('-- Data file (STEP 2): $dataFile')
      ..writeln('--')
      ..writeln('-- STEP 1 (yeh file):')
      ..writeln('--   pgAdmin → Servers → PostgreSQL → Databases → "postgres" par')
      ..writeln('--   right-click → Query Tool → Open File (folder icon) → yeh file →')
      ..writeln('--   Execute (F5). Neeche result mein "$appUser" + can_login = true dikhe.')
      ..writeln('--')
      ..writeln('-- STEP 2:')
      ..writeln('--   "postgres" database par right-click → Restore… →')
      ..writeln('--   Format: Custom or tar · Filename: $dataFile')
      ..writeln('--   "Query Options" tab → "Include CREATE DATABASE')
      ..writeln('--   statement" ON → Restore. ("$dbName" database khud banega.)')
      ..writeln('--   ⚠️ Sirf naye computer / naye server par — "$dbName" pehle se ho')
      ..writeln('--   to woh option OFF karke seedha "$dbName" par Restore karein.')
      ..writeln('--')
      ..writeln('-- Is file mein asal password NAHI — sirf uska hash (SCRAM). Phir bhi')
      ..writeln('-- kisi ko share na karein. Dobara chalane se kuch nahi tootta.')
      ..writeln('-- =============================================================')
      ..writeln()
      ..writeln(r'DO $jg$')
      ..writeln('BEGIN')
      ..writeln('  -- App ka login user (config.json db_user)')
      ..writeln("  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = ${_lit(appUser)}) THEN")
      ..writeln("    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', ${_lit(appUser)}, ${_lit(verifier)});")
      ..writeln("    RAISE NOTICE 'User % bana diya', ${_lit(appUser)};")
      ..writeln('  ELSE')
      ..writeln("    EXECUTE format('ALTER ROLE %I LOGIN PASSWORD %L', ${_lit(appUser)}, ${_lit(verifier)});")
      ..writeln("    RAISE NOTICE 'User % pehle se tha — login + password theek kiya', ${_lit(appUser)};")
      ..writeln('  END IF;');
    for (final role in others) {
      sb
        ..writeln()
        ..writeln('  -- Backup mein owner/permission ke liye zaroori role (login nahi)')
        ..writeln("  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = ${_lit(role)}) THEN")
        ..writeln("    EXECUTE format('CREATE ROLE %I NOLOGIN', ${_lit(role)});")
        ..writeln("    RAISE NOTICE 'Role % bana diya', ${_lit(role)};")
        ..writeln('  END IF;');
    }
    sb
      ..writeln('END')
      ..writeln(r'$jg$;')
      ..writeln()
      ..writeln('-- Check: yeh sab roles mojood hon')
      ..writeln('SELECT rolname AS role, rolcanlogin AS can_login')
      ..writeln('FROM pg_roles')
      ..writeln('WHERE rolname IN (${roles.map(_lit).join(', ')})')
      ..writeln('ORDER BY rolname;');

    // Windows Notepad / pgAdmin dono ke liye CRLF theek
    final text = Platform.isWindows
        ? sb.toString().replaceAll('\r\n', '\n').replaceAll('\n', '\r\n')
        : sb.toString();
    await File(outPath).writeAsString(text, flush: true);
  }

  static String _unquote(String s) =>
      (s.length >= 2 && s.startsWith('"') && s.endsWith('"'))
          ? s.substring(1, s.length - 1).replaceAll('""', '"')
          : s;

  /// SQL string literal ('it''s')
  static String _lit(String s) => "'${s.replaceAll("'", "''")}'";

  /// PostgreSQL SCRAM-SHA-256 verifier — `CREATE ROLE … PASSWORD 'yeh-hash'`
  /// Postgres pehchaan leta hai ke yeh hash hai, aur login asal password se hota hai.
  static String _scramVerifier(String password, {int iterations = 4096}) {
    final rnd  = Random.secure();
    final salt = Uint8List.fromList(List<int>.generate(16, (_) => rnd.nextInt(256)));
    final pass = utf8.encode(password);

    // PBKDF2-HMAC-SHA256, ek block (32 bytes)
    final hmacP = Hmac(sha256, pass);
    var u = hmacP.convert([...salt, 0, 0, 0, 1]).bytes;
    final salted = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = hmacP.convert(u).bytes;
      for (var j = 0; j < salted.length; j++) {
        salted[j] ^= u[j];
      }
    }

    final hmacS     = Hmac(sha256, salted);
    final clientKey = hmacS.convert(utf8.encode('Client Key')).bytes;
    final storedKey = sha256.convert(clientKey).bytes;
    final serverKey = hmacS.convert(utf8.encode('Server Key')).bytes;

    return 'SCRAM-SHA-256\$$iterations:${base64.encode(salt)}'
        '\$${base64.encode(storedKey)}:${base64.encode(serverKey)}';
  }

  // ─────────────────────────────────────────────────────────
  // pg_dump dhoondo
  // ─────────────────────────────────────────────────────────
  Future<String> _resolvePgDump() async {
    final fromConfig = AppConfig.pgDumpPath?.trim();
    if (fromConfig != null && fromConfig.isNotEmpty) {
      if (await File(fromConfig).exists()) return fromConfig;
      throw _BackupError(
          'config.json ka pg_dump_path galat hai — file nahi mili: $fromConfig');
    }

    final candidates = <String>[];
    if (Platform.isWindows) {
      for (final root in const [
        r'C:\Program Files\PostgreSQL',
        r'C:\Program Files (x86)\PostgreSQL',
      ]) {
        candidates.addAll(await _versionedBins(root, r'bin\pg_dump.exe'));
      }
    } else if (Platform.isMacOS) {
      candidates.addAll(const [
        '/opt/homebrew/bin/pg_dump',
        '/usr/local/bin/pg_dump',
      ]);
      candidates.addAll(await _versionedBins('/Library/PostgreSQL', 'bin/pg_dump'));
      candidates.add('/Applications/Postgres.app/Contents/Versions/latest/bin/pg_dump');
    } else {
      candidates.add('/usr/bin/pg_dump');
    }

    for (final c in candidates) {
      if (await File(c).exists()) return c;
    }

    // Aakhri koshish — PATH par
    final exe = Platform.isWindows ? 'pg_dump.exe' : 'pg_dump';
    try {
      final r = await Process.run(Platform.isWindows ? 'where' : 'which', [exe]);
      final line = r.stdout.toString().split(RegExp(r'[\r\n]+')).first.trim();
      if (r.exitCode == 0 && line.isNotEmpty) return line;
    } catch (_) {}

    throw const _BackupError(
        'pg_dump nahi mila. PostgreSQL install check karein, ya config.json mein '
        '"pg_dump_path" daalein (jaise C:\\Program Files\\PostgreSQL\\18\\bin\\pg_dump.exe).');
  }

  /// `<root>/<version>/<rel>` — sab se naya (bara) version pehle.
  Future<List<String>> _versionedBins(String root, String rel) async {
    final dir = Directory(root);
    if (!await dir.exists()) return const [];
    final versions = <(double, String)>[];
    await for (final e in dir.list(followLinks: false)) {
      if (e is! Directory) continue;
      final name = e.path.split(Platform.pathSeparator).last;
      final v = double.tryParse(name);
      if (v != null) versions.add((v, e.path));
    }
    versions.sort((a, b) => b.$1.compareTo(a.$1));
    return versions.map((v) => '${v.$2}${Platform.pathSeparator}$rel').toList();
  }

  // pg_dump ka major version server se kam ho to pg_dump fail karta hai —
  // pehle hi saaf message do.
  Future<void> _checkVersion(String pgDump) async {
    int? dumpMajor;
    try {
      final r = await Process.run(pgDump, ['--version']);
      final m = RegExp(r'(\d+)(?:\.\d+)?').firstMatch(r.stdout.toString());
      dumpMajor = m == null ? null : int.tryParse(m.group(1)!);
    } catch (_) {}
    if (dumpMajor == null) return; // pata na chale to pg_dump khud batayega

    try {
      final conn = await _db;
      final res  = await conn.execute('SHOW server_version_num');
      final num  = int.tryParse(res.first.first.toString());
      if (num == null) return;
      final serverMajor = num ~/ 10000;
      if (dumpMajor < serverMajor) {
        throw _BackupError(
            'pg_dump version $dumpMajor hai lekin database server $serverMajor hai. '
            'PostgreSQL $serverMajor ka pg_dump chahiye (config.json "pg_dump_path").');
      }
    } on _BackupError {
      rethrow;
    } catch (_) {}
  }

  String _friendlyPgError(String stderr, int exitCode) {
    final s = stderr.trim();
    final lower = s.toLowerCase();
    if (lower.contains('password authentication failed')) {
      return 'Database password galat hai (config.json).';
    }
    if (lower.contains('permission denied')) {
      return 'Database user "${AppConfig.dbUser}" ke paas kuch tables padhne ki '
          'ijazat nahi. Detail: $s';
    }
    if (lower.contains('could not open output file') ||
        lower.contains('could not write')) {
      return 'Folder mein file save nahi ho saki (ijazat / disk full?). Detail: $s';
    }
    if (lower.contains('server version') && lower.contains('mismatch')) {
      return 'pg_dump ka version database se purana hai. Detail: $s';
    }
    return s.isEmpty ? 'pg_dump fail hua (exit code $exitCode).' : s;
  }

  static final _uuidRe = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  String? _uuidOrNull(String? v) =>
      (v != null && _uuidRe.hasMatch(v)) ? v : null;

  // ─────────────────────────────────────────────────────────
  // Folder Explorer / Finder mein kholo
  // ─────────────────────────────────────────────────────────
  Future<void> openFolder(String path) async {
    if (Platform.isWindows) {
      await Process.run('explorer', [path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else {
      await Process.run('xdg-open', [path]);
    }
  }
}

class _BackupError implements Exception {
  final String message;
  const _BackupError(this.message);
  @override
  String toString() => message;
}
