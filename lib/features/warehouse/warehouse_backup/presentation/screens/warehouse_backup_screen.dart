// Updated on 2026-11-08 09:48 AM
// =============================================================
// warehouse_backup_screen.dart  (sidebar: ADMIN → Backup)
//   • User folder chunta hai → "Backup Lein" → pg_dump se poora local DB
//     backup (.backup file, custom format) us folder mein
//   • Last backup card (date · time · user · size · kitne din pehle)
//   • Backup record table (success + failed dono, wajah ke saath)
//   • Restore guide card — 2 files (STEP1 user .sql + STEP2 data .backup),
//     sirf pgAdmin se restore
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/warehouse_color.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_backup/domain/warehouse_backup_model.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_backup/presentation/provider/warehouse_backup_provider.dart';

/// Itne din se purana backup ho to warning (amber/laal)
const int kBackupWarnDays = 3;

String _fmtDate(DateTime d) => DateFormat('dd MMM yyyy').format(d.toLocal());
String _fmtTime(DateTime d) => DateFormat('hh:mm a').format(d.toLocal());

String _parentFolder(String filePath) {
  final i = filePath.lastIndexOf(RegExp(r'[\\/]'));
  return i <= 0 ? filePath : filePath.substring(0, i);
}

/// STEP2 data file ke saath wali STEP1 user file ka naam (purane records = null)
String? _userSqlName(String dataFileName) =>
    dataFileName.endsWith('_STEP2_data.backup')
        ? dataFileName.replaceFirst('_STEP2_data.backup', '_STEP1_user.sql')
        : null;

String _daysAgo(DateTime d) {
  final days = DateTime.now().difference(d.toLocal()).inDays;
  if (days <= 0) return 'Aaj';
  if (days == 1) return 'Kal';
  return '$days din pehle';
}

class WarehouseBackupScreen extends ConsumerStatefulWidget {
  const WarehouseBackupScreen({super.key});

  @override
  ConsumerState<WarehouseBackupScreen> createState() =>
      _WarehouseBackupScreenState();
}

class _WarehouseBackupScreenState extends ConsumerState<WarehouseBackupScreen> {
  @override
  void initState() {
    super.initState();
    // Screen khulte hi taaza record (backup chal raha ho to nahi)
    Future.microtask(() {
      if (!mounted) return;
      final s = ref.read(warehouseBackupProvider);
      if (!s.isBackingUp && !s.isLoading) {
        ref.read(warehouseBackupProvider.notifier).load();
      }
    });
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        width: 460,
        duration: const Duration(seconds: 4),
      ));
  }

  Future<void> _runBackup() async {
    final rec = await ref.read(warehouseBackupProvider.notifier).runBackup();
    if (!mounted || rec == null) return;
    if (rec.isSuccess && rec.errorMessage != null) {
      _snack('Backup save ho gaya, lekin: ${rec.errorMessage}',
          WarehouseAppColor.warningDark);
    } else if (rec.isSuccess) {
      _snack('Backup save ho gaya (2 files) — ${formatBackupSize(rec.fileSizeBytes)}',
          WarehouseAppColor.success);
    } else {
      _snack('Backup fail: ${rec.errorMessage ?? ''}', WarehouseAppColor.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(warehouseBackupProvider);
    final notifier = ref.read(warehouseBackupProvider.notifier);

    ref.listen<WarehouseBackupState>(warehouseBackupProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        _snack(next.errorMessage!, WarehouseAppColor.error);
      }
    });

    return Scaffold(
      backgroundColor: WarehouseAppColor.grey100,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(
            isBusy:    state.isLoading || state.isBackingUp,
            onRefresh: notifier.load,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(builder: (context, c) {
                    final backupCard = _NewBackupCard(
                      folderPath:  state.folderPath,
                      isBackingUp: state.isBackingUp,
                      onPick:      notifier.pickFolder,
                      onBackup:    _runBackup,
                    );
                    final lastCard = _LastBackupCard(
                      last:   state.lastSuccess,
                      onOpen: (p) => notifier.openFolder(p),
                    );
                    if (c.maxWidth >= 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: backupCard),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: lastCard),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        backupCard,
                        const SizedBox(height: 16),
                        lastCard,
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
                  const _RestoreHelpCard(),
                  const SizedBox(height: 16),
                  _HistoryCard(
                    state:  state,
                    onOpen: (p) => notifier.openFolder(p),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onRefresh;
  const _TopBar({required this.isBusy, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color:  WarehouseAppColor.surface,
        border: Border(bottom: BorderSide(color: WarehouseAppColor.grey200)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: WarehouseAppColor.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.backup_outlined,
                color: WarehouseAppColor.primary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Backup',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: WarehouseAppColor.textPrimary)),
                Text('Local database ka poora backup (schema + data) is computer par',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13, color: WarehouseAppColor.textSecondary)),
              ],
            ),
          ),
          SizedBox(
            width: 40, height: 40,
            child: IconButton(
              tooltip: 'Refresh',
              onPressed: isBusy ? null : onRefresh,
              icon: const Icon(Icons.refresh_rounded,
                  color: WarehouseAppColor.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card shell ────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title;
  final Widget?  trailing;
  final Widget   child;
  const _Card({
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WarehouseAppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WarehouseAppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: WarehouseAppColor.textPrimary)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Naya backup ───────────────────────────────────────────────
class _NewBackupCard extends StatelessWidget {
  final String?      folderPath;
  final bool         isBackingUp;
  final VoidCallback onPick;
  final VoidCallback onBackup;
  const _NewBackupCard({
    required this.folderPath,
    required this.isBackingUp,
    required this.onPick,
    required this.onBackup,
  });

  @override
  Widget build(BuildContext context) {
    final hasFolder = folderPath != null && folderPath!.isNotEmpty;

    return _Card(
      icon:  Icons.cloud_upload_outlined,
      color: WarehouseAppColor.primary,
      title: 'Naya Backup',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('BACKUP FOLDER',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: WarehouseAppColor.textSecondary)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: WarehouseAppColor.grey100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: WarehouseAppColor.grey200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.folder_outlined,
                          size: 18,
                          color: hasFolder
                              ? WarehouseAppColor.warning
                              : WarehouseAppColor.grey400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Tooltip(
                          message: hasFolder ? folderPath! : '',
                          child: Text(
                            hasFolder ? folderPath! : 'Koi folder nahi chuna',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: hasFolder
                                  ? WarehouseAppColor.textPrimary
                                  : WarehouseAppColor.textHint,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 150, height: 44,
                child: OutlinedButton.icon(
                  onPressed: isBackingUp ? null : onPick,
                  icon: const Icon(Icons.drive_folder_upload_outlined, size: 18),
                  label: Text(hasFolder ? 'Folder Badlein' : 'Folder Chunein'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WarehouseAppColor.primary,
                    side: const BorderSide(color: WarehouseAppColor.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: (!hasFolder || isBackingUp) ? null : onBackup,
              style: ElevatedButton.styleFrom(
                backgroundColor: WarehouseAppColor.primary,
                foregroundColor: WarehouseAppColor.white,
                disabledBackgroundColor: WarehouseAppColor.grey300,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: isBackingUp
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: WarehouseAppColor.white),
                        ),
                        SizedBox(width: 12),
                        Text('Backup ban raha hai… app band na karein',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.backup_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('Backup Lein',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
          if (!hasFolder) ...[
            const SizedBox(height: 8),
            const Text('Pehle folder chunein jahan backup save hoga.',
                style: TextStyle(
                    fontSize: 12, color: WarehouseAppColor.textSecondary)),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WarehouseAppColor.infoLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: WarehouseAppColor.info),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Backup file isi computer par banti hai — computer kharab ho to '
                    'backup bhi chala jayega. USB / Google Drive par bhi copy kar lein. '
                    'File mein poora data (users bhi) hai — kisi ko share na karein.',
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: WarehouseAppColor.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Last backup ───────────────────────────────────────────────
class _LastBackupCard extends StatelessWidget {
  final WarehouseBackupRecord? last;
  final void Function(String folder) onOpen;
  const _LastBackupCard({required this.last, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final rec = last;
    if (rec == null) {
      return const _Card(
        icon:  Icons.history_rounded,
        color: WarehouseAppColor.warning,
        title: 'Last Backup',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Text('Abhi tak koi backup nahi liya gaya.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: WarehouseAppColor.warningDark)),
        ),
      );
    }

    final days  = DateTime.now().difference(rec.createdAt.toLocal()).inDays;
    final old   = days >= kBackupWarnDays;
    final color = old ? WarehouseAppColor.error : WarehouseAppColor.success;

    Widget line(IconData i, String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(i, size: 15, color: WarehouseAppColor.grey500),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: WarehouseAppColor.textSecondary)),
              ),
              Expanded(
                child: Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: WarehouseAppColor.textPrimary)),
              ),
            ],
          ),
        );

    return _Card(
      icon:  Icons.history_rounded,
      color: color,
      title: 'Last Backup',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(_daysAgo(rec.createdAt),
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line(Icons.calendar_today_outlined, 'Date', _fmtDate(rec.createdAt)),
          line(Icons.schedule_rounded, 'Time', _fmtTime(rec.createdAt)),
          line(Icons.person_outline_rounded, 'User', rec.createdByName ?? '—'),
          line(Icons.sd_storage_outlined, 'Size', formatBackupSize(rec.fileSizeBytes)),
          line(Icons.description_outlined, 'Data', rec.fileName),
          if (_userSqlName(rec.fileName) != null)
            line(Icons.person_add_alt_outlined, 'User', _userSqlName(rec.fileName)!),
          if (rec.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(rec.errorMessage!,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: WarehouseAppColor.warningDark)),
            ),
          if (old)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                  '$kBackupWarnDays din se zyada purana — naya backup le lein.',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: WarehouseAppColor.error)),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 160, height: 38,
              child: TextButton.icon(
                onPressed: () => onOpen(_parentFolder(rec.filePath)),
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                label: const Text('Folder Kholein'),
                style: TextButton.styleFrom(
                    foregroundColor: WarehouseAppColor.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Restore guide (pgAdmin) ───────────────────────────────────
class _RestoreHelpCard extends StatelessWidget {
  const _RestoreHelpCard();

  @override
  Widget build(BuildContext context) {
    Widget step(String n, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: WarehouseAppColor.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(n,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: WarehouseAppColor.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: '$title  ',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: body),
                  ]),
                  style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: WarehouseAppColor.textPrimary),
                ),
              ),
            ],
          ),
        );

    return _Card(
      icon:  Icons.settings_backup_restore_rounded,
      color: WarehouseAppColor.success,
      title: 'Restore kaise karein (naya computer — sirf pgAdmin)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Har backup ki 2 files banti hain — dono saath copy karein (USB / Drive).',
            style: TextStyle(fontSize: 12, color: WarehouseAppColor.textSecondary),
          ),
          const SizedBox(height: 10),
          step('0', 'PostgreSQL install', '— wahi ya naya version, saath pgAdmin.'),
          step('1', 'User banayein:',
              'pgAdmin → Databases → "postgres" par right-click → Query Tool → '
              'Open File → "…_STEP1_user.sql" → Execute (F5). Result mein user + can_login = true.'),
          step('2', 'Data wapas:',
              '"postgres" par right-click → Restore… → Format "Custom or tar" → '
              'file "…_STEP2_data.backup" → Query Options mein "Include CREATE DATABASE '
              'statement" ON → Restore. Database khud ban jayega.'),
          step('3', 'App:',
              'Jan Ghani install karein, config.json purane jaisa (warehouse_id, db_name, db_user, db_password).'),
          const Text(
            '⚠️ Step 2 sirf naye server par — database pehle se ho to option OFF karke seedha us database par Restore karein.',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: WarehouseAppColor.warningDark),
          ),
        ],
      ),
    );
  }
}

// ── History table ─────────────────────────────────────────────
const _cDate = 3, _cTime = 2, _cUser = 3, _cFile = 6, _cSize = 2, _cStatus = 3;

class _HistoryCard extends StatelessWidget {
  final WarehouseBackupState state;
  final void Function(String folder) onOpen;
  const _HistoryCard({required this.state, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final list = state.history;

    Widget badge(String text, Color color) => Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(text,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        );

    Widget body;
    if (state.isLoading && list.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (list.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: Text('Koi record nahi — pehla backup lein.',
              style: TextStyle(
                  fontSize: 13, color: WarehouseAppColor.textSecondary)),
        ),
      );
    } else {
      body = LayoutBuilder(builder: (context, c) {
        final width = c.maxWidth < 900 ? 900.0 : c.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _HeaderRow(),
                for (var i = 0; i < list.length; i++)
                  _HistoryRow(
                    rec:    list[i],
                    isLast: i == list.length - 1,
                    onOpen: onOpen,
                  ),
              ],
            ),
          ),
        );
      });
    }

    return _Card(
      icon:  Icons.list_alt_rounded,
      color: WarehouseAppColor.info,
      title: 'Backup Record',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge('${state.successCount} success', WarehouseAppColor.success),
          if (state.failedCount > 0)
            badge('${state.failedCount} fail', WarehouseAppColor.error),
        ],
      ),
      child: body,
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    Widget h(String t, int flex, {TextAlign align = TextAlign.left}) => Expanded(
          flex: flex,
          child: Text(t,
              textAlign: align,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: WarehouseAppColor.textSecondary)),
        );
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          h('DATE', _cDate),
          h('TIME', _cTime),
          h('USER', _cUser),
          h('FILE', _cFile),
          h('SIZE', _cSize, align: TextAlign.right),
          const SizedBox(width: 16),
          h('STATUS', _cStatus),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final WarehouseBackupRecord rec;
  final bool isLast;
  final void Function(String folder) onOpen;
  const _HistoryRow({required this.rec, required this.isLast, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    const txt = TextStyle(fontSize: 13, color: WarehouseAppColor.textPrimary);
    final ok      = rec.isSuccess;
    final hasNote = ok && rec.errorMessage != null; // success + chhoti warning
    final color   = !ok
        ? WarehouseAppColor.error
        : (hasNote ? WarehouseAppColor.warningDark : WarehouseAppColor.success);

    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: WarehouseAppColor.grey100)),
      ),
      child: Row(
        children: [
          Expanded(flex: _cDate, child: Text(_fmtDate(rec.createdAt), style: txt)),
          Expanded(flex: _cTime, child: Text(_fmtTime(rec.createdAt), style: txt)),
          Expanded(
            flex: _cUser,
            child: Text(rec.createdByName ?? '—',
                overflow: TextOverflow.ellipsis, style: txt),
          ),
          Expanded(
            flex: _cFile,
            child: Tooltip(
              message: rec.filePath,
              child: Text(rec.fileName,
                  overflow: TextOverflow.ellipsis,
                  style: txt.copyWith(
                      color: ok
                          ? WarehouseAppColor.textPrimary
                          : WarehouseAppColor.textSecondary)),
            ),
          ),
          Expanded(
            flex: _cSize,
            child: Text(formatBackupSize(rec.fileSizeBytes),
                textAlign: TextAlign.right, style: txt),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: _cStatus,
            child: Tooltip(
              message: rec.errorMessage ?? '',
              child: Row(
                children: [
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(ok ? 'Success' : 'Fail',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                  if (rec.errorMessage != null) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(rec.errorMessage ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11,
                              color: WarehouseAppColor.textSecondary)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: ok
                ? IconButton(
                    tooltip: 'Folder kholein',
                    onPressed: () => onOpen(_parentFolder(rec.filePath)),
                    icon: const Icon(Icons.folder_open_outlined,
                        size: 18, color: WarehouseAppColor.grey600),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
