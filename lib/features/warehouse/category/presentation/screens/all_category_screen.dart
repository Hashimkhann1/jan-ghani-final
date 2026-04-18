// =============================================================
// all_category_screen.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../data/model/category_model.dart';
import '../provider/category_provider.dart';
import '../widget/add_category_dialog.dart';

class AllCategoryScreen extends ConsumerWidget {
  const AllCategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(categoryProvider);
    final notifier = ref.read(categoryProvider.notifier);

    // Error snackbar
    ref.listen<CategoryState>(categoryProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(next.errorMessage!),
            backgroundColor: AppColor.error,
            behavior:        SnackBarBehavior.floating,
            action: SnackBarAction(
              label:     'OK',
              textColor: Colors.white,
              onPressed: () =>
                  ref.read(categoryProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColor.background,
      body: Column(
        children: [

          // ── Top Bar ───────────────────────────────────────
          Container(
            width:   double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 16),
            color: AppColor.surface,
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Categories',
                        style: TextStyle(
                            fontSize:   22,
                            fontWeight: FontWeight.w700,
                            color:      AppColor.textPrimary)),
                    Text('Product categories manage karein',
                        style: TextStyle(
                            fontSize: 13,
                            color:    AppColor.textSecondary)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () =>
                      AddCategoryDialog.show(context),
                  icon:  const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New Category'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: AppColor.white,
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
            color:   AppColor.surface,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                _StatCard(
                  label: 'Total',
                  value: '${state.totalCount}',
                  icon:  Icons.category_outlined,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Active',
                  value: '${state.activeCount}',
                  icon:  Icons.check_circle_outline_rounded,
                  color: AppColor.success,
                ),
              ],
            ),
          ),

          // ── Search + Filter ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 320,
                  height: 42,
                  child: TextField(
                    onChanged: notifier.onSearchChanged,
                    decoration: InputDecoration(
                      hintText:  'Category name se search...',
                      hintStyle: TextStyle(
                          color: AppColor.textHint, fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: AppColor.grey400, size: 20),
                      filled:    true,
                      fillColor: AppColor.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                          BorderSide(color: AppColor.grey200)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                          BorderSide(color: AppColor.grey200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: AppColor.primary, width: 1.5)),
                    ),
                  ),
                ),
                const Spacer(),
                // Filter chips
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
                : state.filteredCategories.isEmpty
                ? _EmptyState(
                isSearching: state.searchQuery.isNotEmpty ||
                    state.filterStatus != 'all')
                : _CategoryGrid(
              categories: state.filteredCategories,
              onEdit: (c) =>
                  AddCategoryDialog.show(context,
                      category: c),
              onDelete: (c) =>
                  _confirmDelete(context, ref, c),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, CategoryModel c) {
    showDialog(
      context:     context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
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
                    color:        AppColor.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      color: AppColor.error, size: 28),
                ),
                const SizedBox(height: 16),
                Text('Category Delete Karen?',
                    style: TextStyle(
                        fontSize:   17,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.textPrimary)),
                const SizedBox(height: 8),
                Text('"${c.name}"',
                    style: TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w600,
                        color:      AppColor.error)),
                const SizedBox(height: 6),
                Text(
                  'Delete karne ke baad products is category\nse unlink ho jayenge.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color:    AppColor.textSecondary),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColor.textSecondary,
                          side: BorderSide(color: AppColor.grey300),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(10)),
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
                              .read(categoryProvider.notifier)
                              .deleteCategory(c.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Delete',
                            style: TextStyle(
                                fontWeight: FontWeight.w600)),
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
// CATEGORY GRID
// ─────────────────────────────────────────────────────────────
class _CategoryGrid extends StatelessWidget {
  final List<CategoryModel>         categories;
  final ValueChanged<CategoryModel> onEdit;
  final ValueChanged<CategoryModel> onDelete;

  const _CategoryGrid({
    required this.categories,
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
          mainAxisExtent:     120,
          crossAxisSpacing:   12,
          mainAxisSpacing:    12,
        ),
        itemCount: categories.length,
        itemBuilder: (_, i) => _CategoryCard(
          category: categories[i],
          onEdit:   () => onEdit(categories[i]),
          onDelete: () => onDelete(categories[i]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CATEGORY CARD
// ─────────────────────────────────────────────────────────────
class _CategoryCard extends StatefulWidget {
  final CategoryModel category;
  final VoidCallback  onEdit;
  final VoidCallback  onDelete;

  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _hovered = false;

  Color get _color {
    if (widget.category.colorCode == null) return AppColor.primary;
    final h = widget.category.colorCode!.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.category;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        AppColor.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _hovered
                  ? _color.withOpacity(0.4)
                  : AppColor.grey200),
          boxShadow: _hovered
              ? [BoxShadow(
              color:      _color.withOpacity(0.1),
              blurRadius: 8,
              offset:     const Offset(0, 2))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Color dot
                Container(
                  width:  10,
                  height: 10,
                  decoration: BoxDecoration(
                    color:  _color,
                    shape:  BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                // Name
                Expanded(
                  child: Text(c.name,
                      style: TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w600,
                          color:      AppColor.textPrimary),
                      overflow: TextOverflow.ellipsis),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.isActive
                        ? AppColor.successLight
                        : AppColor.grey200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    c.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                        fontSize:   10,
                        fontWeight: FontWeight.w600,
                        color:      c.isActive
                            ? AppColor.success
                            : AppColor.grey500),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Description
            Expanded(
              child: Text(
                c.description ?? 'Koi description nahi',
                style: TextStyle(
                    fontSize: 12,
                    color:    AppColor.textSecondary),
                maxLines:  2,
                overflow:  TextOverflow.ellipsis,
              ),
            ),

            // Actions — hover pe
            if (_hovered)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ActionBtn(
                    icon:    Icons.edit_outlined,
                    color:   AppColor.info,
                    tooltip: 'Edit',
                    onTap:   widget.onEdit,
                  ),
                  const SizedBox(width: 6),
                  _ActionBtn(
                    icon:    Icons.delete_outline_rounded,
                    color:   AppColor.error,
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
                  style: TextStyle(
                      fontSize:   20,
                      fontWeight: FontWeight.w700,
                      color:      AppColor.textPrimary)),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color:    AppColor.textSecondary)),
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
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColor.primary : AppColor.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected
                  ? AppColor.primary : AppColor.grey300),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w500,
                color:      selected
                    ? AppColor.white : AppColor.textSecondary)),
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
                : Icons.category_outlined,
            size:  56,
            color: AppColor.grey300,
          ),
          const SizedBox(height: 12),
          Text(
            isSearching
                ? 'Koi category nahi mili'
                : 'Abhi tak koi category nahi',
            style: TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      AppColor.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            isSearching
                ? 'Search change karein'
                : 'New Category button se add karein',
            style: TextStyle(
                fontSize: 13, color: AppColor.textHint),
          ),
        ],
      ),
    );
  }
}