// Updated on 2026-10-15 10:24 AM

// =============================================================
// all_company_screen.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/warehouse_color.dart';
import '../../data/model/company_model.dart';
import '../provider/company_provider.dart';
import '../widget/add_company_dialog.dart';

class AllCompanyScreen extends ConsumerWidget {
  const AllCompanyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(companyProvider);
    final notifier = ref.read(companyProvider.notifier);

    // Error snackbar
    ref.listen<CompanyState>(companyProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(next.errorMessage!),
            backgroundColor: WarehouseAppColor.error,
            behavior:        SnackBarBehavior.floating,
            action: SnackBarAction(
              label:     'OK',
              textColor: Colors.white,
              onPressed: () =>
                  ref.read(companyProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: WarehouseAppColor.background,
      body: Column(
        children: [

          // ── Top Bar ───────────────────────────────────────
          Container(
            width:   double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: WarehouseAppColor.surface,
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Companies',
                        style: TextStyle(
                            fontSize:   22,
                            fontWeight: FontWeight.w700,
                            color:      WarehouseAppColor.textPrimary)),
                    Text('Product companies manage karein',
                        style: TextStyle(
                            fontSize: 13, color: WarehouseAppColor.textSecondary)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => AddCompanyDialog.show(context),
                  icon:  const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New Company'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WarehouseAppColor.primary,
                    foregroundColor: WarehouseAppColor.white,
                    minimumSize: const Size(160, 48),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          // ── Stats ─────────────────────────────────────────
          Container(
            color:   WarehouseAppColor.surface,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                _StatCard(
                  label: 'Total',
                  value: '${state.totalCount}',
                  icon:  Icons.business_outlined,
                  color: WarehouseAppColor.primary,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Active',
                  value: '${state.activeCount}',
                  icon:  Icons.check_circle_outline_rounded,
                  color: WarehouseAppColor.success,
                ),
              ],
            ),
          ),

          // ── Search + Filter ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 320,
                  height: 42,
                  child: TextField(
                    onChanged: notifier.onSearchChanged,
                    decoration: InputDecoration(
                      hintText:  'Company name se search...',
                      hintStyle: const TextStyle(
                          color: WarehouseAppColor.textHint, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: WarehouseAppColor.grey400, size: 20),
                      filled:    true,
                      fillColor: WarehouseAppColor.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: WarehouseAppColor.grey200)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: WarehouseAppColor.grey200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: WarehouseAppColor.primary, width: 1.5)),
                    ),
                  ),
                ),
                const Spacer(),
                ...['all', 'active', 'inactive'].map((v) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _FilterChip(
                    label:         v == 'all'
                        ? 'All'
                        : v[0].toUpperCase() + v.substring(1),
                    value:         v,
                    selectedValue: state.filterStatus,
                    onTap:         notifier.onFilterChanged,
                  ),
                )),
              ],
            ),
          ),

          // ── Content ───────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.filteredCompanies.isEmpty
                    ? _EmptyState(
                        isSearching: state.searchQuery.isNotEmpty ||
                            state.filterStatus != 'all')
                    : _CompanyGrid(
                        companies: state.filteredCompanies,
                        onEdit: (c) =>
                            AddCompanyDialog.show(context, company: c),
                        onDelete: (c) => _confirmDelete(context, ref, c),
                      ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, CompanyModel c) {
    showDialog(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 380,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:    const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:        WarehouseAppColor.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: WarehouseAppColor.error, size: 28),
                ),
                const SizedBox(height: 16),
                const Text('Company Delete Karen?',
                    style: TextStyle(
                        fontSize:   17,
                        fontWeight: FontWeight.w700,
                        color:      WarehouseAppColor.textPrimary)),
                const SizedBox(height: 8),
                Text('"${c.name}"',
                    style: const TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w600,
                        color:      WarehouseAppColor.error)),
                const SizedBox(height: 6),
                const Text(
                  'Delete karne ke baad products is company\nse unlink ho jayenge.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: WarehouseAppColor.textSecondary),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: WarehouseAppColor.textSecondary,
                          side: BorderSide(color: WarehouseAppColor.grey300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref
                              .read(companyProvider.notifier)
                              .deleteCompany(c.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WarehouseAppColor.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Delete',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// COMPANY GRID
// ─────────────────────────────────────────────────────────────
class _CompanyGrid extends StatelessWidget {
  final List<CompanyModel>         companies;
  final ValueChanged<CompanyModel> onEdit;
  final ValueChanged<CompanyModel> onDelete;

  const _CompanyGrid({
    required this.companies,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          mainAxisExtent:     92,
          crossAxisSpacing:   12,
          mainAxisSpacing:    12,
        ),
        itemCount: companies.length,
        itemBuilder: (_, i) => _CompanyCard(
          company:  companies[i],
          onEdit:   () => onEdit(companies[i]),
          onDelete: () => onDelete(companies[i]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// COMPANY CARD
// ─────────────────────────────────────────────────────────────
class _CompanyCard extends StatefulWidget {
  final CompanyModel company;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CompanyCard({
    required this.company,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CompanyCard> createState() => _CompanyCardState();
}

class _CompanyCardState extends State<_CompanyCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.company;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        WarehouseAppColor.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _hovered
                  ? WarehouseAppColor.primary.withOpacity(0.4)
                  : WarehouseAppColor.grey200),
          boxShadow: _hovered
              ? [BoxShadow(
                  color:      WarehouseAppColor.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset:     const Offset(0, 2))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: WarehouseAppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business_rounded,
                      size: 15, color: WarehouseAppColor.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(c.name,
                      style: const TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w600,
                          color:      WarehouseAppColor.textPrimary),
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.isActive
                        ? WarehouseAppColor.successLight
                        : WarehouseAppColor.grey200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    c.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                        fontSize:   10,
                        fontWeight: FontWeight.w600,
                        color:      c.isActive
                            ? WarehouseAppColor.success
                            : WarehouseAppColor.grey500),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Actions — hover pe
            if (_hovered)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ActionBtn(
                    icon:    Icons.edit_outlined,
                    color:   WarehouseAppColor.info,
                    tooltip: 'Edit',
                    onTap:   widget.onEdit,
                  ),
                  const SizedBox(width: 6),
                  _ActionBtn(
                    icon:    Icons.delete_outline_rounded,
                    color:   WarehouseAppColor.error,
                    tooltip: 'Delete',
                    onTap:   widget.onDelete,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:        color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize:   20,
                      fontWeight: FontWeight.w700,
                      color:      WarehouseAppColor.textPrimary)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: WarehouseAppColor.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String               label;
  final String               value;
  final String               selectedValue;
  final ValueChanged<String> onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;
    return InkWell(
      onTap:        () => onTap(value),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? WarehouseAppColor.primary : WarehouseAppColor.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? WarehouseAppColor.primary : WarehouseAppColor.grey300),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w500,
                color:      selected
                    ? WarehouseAppColor.white : WarehouseAppColor.textSecondary)),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color:        color.withOpacity(0.09),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  const _EmptyState({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching
                ? Icons.search_off_rounded
                : Icons.business_outlined,
            size:  56,
            color: WarehouseAppColor.grey300,
          ),
          const SizedBox(height: 12),
          Text(
            isSearching
                ? 'Koi company nahi mili'
                : 'Abhi tak koi company nahi',
            style: const TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      WarehouseAppColor.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            isSearching
                ? 'Search change karein'
                : 'New Company button se add karein',
            style: const TextStyle(fontSize: 13, color: WarehouseAppColor.textHint),
          ),
        ],
      ),
    );
  }
}
