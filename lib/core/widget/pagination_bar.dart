import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

/// Chhota client-side pagination bar. [page] 0-based hota hai.
/// Agar total <= perPage ho to kuch render nahi hota.
class PaginationBar extends StatelessWidget {
  final int               total;
  final int               page;
  final int               perPage;
  final ValueChanged<int> onPageChanged;

  const PaginationBar({
    super.key,
    required this.total,
    required this.page,
    required this.onPageChanged,
    this.perPage = 25,
  });

  @override
  Widget build(BuildContext context) {
    if (total <= perPage) return const SizedBox.shrink();

    final pageCount = (total + perPage - 1) ~/ perPage;
    final p         = page.clamp(0, pageCount - 1);
    final start     = p * perPage;
    final end       = (start + perPage) > total ? total : start + perPage;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text('${start + 1}–$end of $total',
              style: const TextStyle(
                  fontSize: 12, color: AppColor.textSecondary)),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.first_page_rounded, size: 20),
            tooltip: 'First page',
            onPressed: p > 0 ? () => onPageChanged(0) : null,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
            tooltip: 'Previous',
            onPressed: p > 0 ? () => onPageChanged(p - 1) : null,
          ),
          Text('Page ${p + 1} of $pageCount',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_right_rounded, size: 22),
            tooltip: 'Next',
            onPressed: p < pageCount - 1 ? () => onPageChanged(p + 1) : null,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.last_page_rounded, size: 20),
            tooltip: 'Last page',
            onPressed:
                p < pageCount - 1 ? () => onPageChanged(pageCount - 1) : null,
          ),
        ],
      ),
    );
  }
}

/// [all] ka current-page slice. [page] 0-based; range se bahar ho to clamp.
List<T> pageSlice<T>(List<T> all, int page, [int perPage = 25]) {
  if (all.length <= perPage) return all;
  final pageCount = (all.length + perPage - 1) ~/ perPage;
  final p         = page.clamp(0, pageCount - 1);
  final start     = p * perPage;
  final end       = (start + perPage) > all.length ? all.length : start + perPage;
  return all.sublist(start, end);
}
