import 'package:flutter/material.dart';

/// Reusable Previous / Next page control bar for branch report list screens.
class BranchReportPaginationControls extends StatelessWidget {
  final int page; // 0-based
  final bool hasNextPage;
  final bool isLoading;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  /// Optional exact total (from `count: CountOption.exact`). When provided,
  /// the center label becomes "Page N of M · X records" instead of just
  /// "Page N" — screens that don't pass these keep the old label.
  final int? totalCount;
  final int? totalPages;

  const BranchReportPaginationControls({
    super.key,
    required this.page,
    required this.hasNextPage,
    required this.onPrevious,
    required this.onNext,
    this.isLoading = false,
    this.totalCount,
    this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrevious = page > 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: hasPrevious && !isLoading ? onPrevious : null,
            icon: const Icon(Icons.chevron_left_rounded, size: 18),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              // App theme's OutlinedButtonThemeData sets
              // minimumSize: Size(double.infinity, 52) — fine for a
              // Column, but inside this Row it forces an unbounded
              // width and crashes layout. Override with a finite size.
              minimumSize: const Size(64, 40),
              foregroundColor: Colors.black,
              disabledForegroundColor: Colors.black26,
              side: BorderSide(
                color: hasPrevious && !isLoading
                    ? Colors.black26
                    : const Color(0xFFEEEEEE),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.black),
            )
          else
            Text(
              totalPages != null
                  ? 'Page ${page + 1} of $totalPages'
                      '${totalCount != null ? ' · $totalCount records' : ''}'
                  : 'Page ${page + 1}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          OutlinedButton.icon(
            onPressed: hasNextPage && !isLoading ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded, size: 18),
            label: const Text('Next'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(64, 40),
              foregroundColor: Colors.black,
              disabledForegroundColor: Colors.black26,
              side: BorderSide(
                color: hasNextPage && !isLoading
                    ? Colors.black26
                    : const Color(0xFFEEEEEE),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
