import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/branch_backup_model.dart';
import '../provider/backup_provider.dart';
import '../../data/model/backup_progress_model.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupProvider);
    final notifier = ref.read(backupProvider.notifier);

    // Error snackbar
    ref.listen<BackupState>(backupProvider, (prev, next) {
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Backup',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info Card ──────────────────────────────────────────────────
            _InfoCard(),
            const SizedBox(height: 24),

            // ── Branch Selection ───────────────────────────────────────────
            _SectionCard(
              title: 'Select Branch',
              icon: Icons.store_rounded,
              child: _BranchDropdown(
                branches: state.branches,
                selected: state.selectedBranch,
                isLoading: state.isLoadingBranches,
                onChanged: state.isBackingUp ? null : notifier.selectBranch,
              ),
            ),
            const SizedBox(height: 16),

            // ── Progress (backup chal raha ho tab dikhao) ──────────────────
            if (state.isBackingUp || state.backupDone) ...[
              _SectionCard(
                title: 'Backup Progress',
                icon: Icons.cloud_sync_rounded,
                child: _ProgressWidget(
                  progress: state.progress,
                  isDone: state.backupDone,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Summary (done hone ke baad) ────────────────────────────────
            if (state.backupDone) ...[
              _SummaryCard(progress: state.progress),
              const SizedBox(height: 16),
            ],

            // ── Backup Button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (state.isBackingUp || state.selectedBranch == null)
                    ? null
                    : () {
                  notifier.reset();
                  notifier.performBackup();
                },
                icon: state.isBackingUp
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                    : Icon(
                  state.backupDone
                      ? Icons.refresh_rounded
                      : Icons.backup_rounded,
                ),
                label: Text(
                  state.isBackingUp
                      ? 'Backup Running...'
                      : state.backupDone
                      ? 'Backup Again'
                      : 'Start Backup',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Card
// ─────────────────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.indigo.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.cloud_upload_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supabase → Local Backup',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Branch ka sara data Supabase se local PostgreSQL mein save hoga.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Card wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.indigo),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Branch Dropdown
// ─────────────────────────────────────────────────────────────────────────────
class _BranchDropdown extends StatelessWidget {
  final List<BackupBranchModel> branches;
  final BackupBranchModel? selected;
  final bool isLoading;
  final ValueChanged<BackupBranchModel?>? onChanged;

  const _BranchDropdown({
    required this.branches,
    required this.selected,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Branches load ho rahi hain...',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BackupBranchModel>(
          value: selected,
          hint: const Text(
            'Branch select karo',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.indigo),
          items: branches.map((branch) {
            return DropdownMenuItem<BackupBranchModel>(
              value: branch,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      branch.code,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      branch.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress Widget — table by table progress
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressWidget extends StatelessWidget {
  final BackupProgress progress;
  final bool isDone;

  const _ProgressWidget({required this.progress, required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall progress bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.percentage,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDone ? Colors.green : Colors.indigo,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${(progress.percentage * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDone ? Colors.green : Colors.indigo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Current table
        if (!isDone)
          Row(
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                progress.currentTable,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

        if (isDone)
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 6),
              Text(
                '${progress.completedTables} tables complete',
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
          ),

        const SizedBox(height: 12),

        // Table results list
        if (progress.results.isNotEmpty)
          ...progress.results.map((r) => _TableResultRow(result: r)),
      ],
    );
  }
}

// Single table result row
class _TableResultRow extends StatelessWidget {
  final TableBackupResult result;

  const _TableResultRow({required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.success
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                size: 16,
                color: result.success ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.tableName,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
              if (result.success)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${result.rowsUpserted} rows',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (!result.success)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Failed',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          // Error message — failed hone ki wajah dikhao
          if (!result.success && result.error != null)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 3),
              child: Text(
                result.error!,
                style: TextStyle(fontSize: 10, color: Colors.red.shade400),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Card — backup done hone ke baad
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final BackupProgress progress;

  const _SummaryCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final failed = progress.failedTables;
    final success = progress.completedTables - failed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: failed == 0 ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: failed == 0 ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                failed == 0
                    ? Icons.check_circle_rounded
                    : Icons.warning_rounded,
                color: failed == 0 ? Colors.green : Colors.orange,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                failed == 0 ? 'Backup Complete! ✅' : 'Backup with Errors ⚠️',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: failed == 0
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Total Tables',
            value: '${progress.totalTables}',
          ),
          _SummaryRow(
            label: 'Successful',
            value: '$success',
            valueColor: Colors.green,
          ),
          if (failed > 0)
            _SummaryRow(
              label: 'Failed',
              value: '$failed',
              valueColor: Colors.red,
            ),
          _SummaryRow(
            label: 'Total Rows Saved',
            value: '${progress.totalRowsUpserted}',
            valueColor: Colors.indigo,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}