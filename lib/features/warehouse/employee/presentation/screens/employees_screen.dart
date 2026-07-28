// =============================================================
// employees_screen.dart — employee master list
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import '../../domain/employee_model.dart';
import '../provider/employee_provider.dart';
import '../widgets/add_employee_dialog.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(employeeProvider);
    final notifier = ref.read(employeeProvider.notifier);

    ref.listen<EmployeeState>(employeeProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage!),
          backgroundColor: AppColor.error,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
              label: 'OK', textColor: Colors.white,
              onPressed: notifier.clearError),
        ));
      }
    });

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.surface,
        elevation: 0,
        foregroundColor: AppColor.textPrimary,
        title: const Text('Employees',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 180,
              child: ElevatedButton.icon(
                onPressed: () => AddEmployeeDialog.show(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Employee'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: AppColor.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        // Stats + search
        Container(
          color: AppColor.surface,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
          child: Row(children: [
            _StatChip(label: 'Total', value: '${state.totalCount}',
                icon: Icons.people_outline, color: AppColor.primary),
            const SizedBox(width: 12),
            _StatChip(label: 'Active', value: '${state.activeCount}',
                icon: Icons.check_circle_outline_rounded, color: AppColor.success),
            const SizedBox(width: 12),
            _StatChip(label: 'Monthly Total', value: 'Rs ${state.totalMonthly.pkrFormat}',
                icon: Icons.payments_outlined, color: const Color(0xFF5C6BC0)),
            const Spacer(),
            SizedBox(
              width: 300, height: 42,
              child: TextField(
                onChanged: notifier.onSearch,
                decoration: InputDecoration(
                  hintText: 'Name ya phone se search...',
                  hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColor.grey400, size: 20),
                  filled: true, fillColor: AppColor.grey100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColor.grey200)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColor.grey200)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColor.primary, width: 1.5)),
                ),
              ),
            ),
          ]),
        ),

        if (state.isLoading) const LinearProgressIndicator(minHeight: 2),

        Expanded(
          child: state.filtered.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: state.filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _EmployeeCard(
                    employee: state.filtered[i],
                    onEdit: () => AddEmployeeDialog.show(context,
                        employee: state.filtered[i]),
                    onDelete: () => _confirmDelete(context, ref, state.filtered[i]),
                  ),
                ),
        ),
      ]),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, EmployeeModel e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Employee Delete?'),
        content: Text('"${e.name}" ko delete karein? '
            'Payment history rahegi, magar salary cycle se hat jayega.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(employeeProvider.notifier).deleteEmployee(e.id);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final EmployeeModel employee;
  final VoidCallback onEdit, onDelete;
  const _EmployeeCard({required this.employee, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final e = employee;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(e.name.isEmpty ? '?' : e.name[0].toUpperCase(),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColor.primary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(e.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary)),
                const SizedBox(width: 8),
                if (!e.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColor.grey200,
                        borderRadius: BorderRadius.circular(5)),
                    child: const Text('Inactive',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                            color: AppColor.grey600)),
                  ),
              ]),
              const SizedBox(height: 2),
              Text(
                  [
                    if (e.phone != null) e.phone,
                    if (e.address != null) e.address,
                  ].whereType<String>().join(' · '),
                  style: const TextStyle(fontSize: 11, color: AppColor.textSecondary),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        // Salary + advance
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Rs ${e.monthlySalary.pkrFormat}',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary)),
            Text('Max advance ${e.maxAdvancePercent.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 10, color: AppColor.textHint)),
          ],
        ),
        const SizedBox(width: 8),
        IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColor.info)),
        IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColor.error)),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatChip({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppColor.textSecondary)),
          ],
        ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.badge_outlined, size: 56, color: AppColor.grey300),
        const SizedBox(height: 12),
        const Text('Abhi tak koi employee nahi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: AppColor.textSecondary)),
        const SizedBox(height: 4),
        const Text('New Employee button se add karein',
            style: TextStyle(fontSize: 13, color: AppColor.textHint)),
      ]),
    );
  }
}
