import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

/// Infinite-scroll ke liye chhota wrapper. Kisi bhi descendant scrollable
/// (ListView / SingleChildScrollView) ke bottom ke paas pahunchne par
/// [onLoadMore] fire karta hai — numbered pagination ki jagah.
///
/// [hasMore] false ho ya [isLoading] true ho to kuch nahi hota (duplicate
/// fetch se bachne ke liye).
class BranchReportInfiniteScroll extends StatelessWidget {
  final Widget child;
  final bool hasMore;
  final bool isLoading;
  final VoidCallback onLoadMore;

  /// Bottom se kitne pixels pehle load-more trigger ho.
  final double threshold;

  const BranchReportInfiniteScroll({
    super.key,
    required this.child,
    required this.hasMore,
    required this.isLoading,
    required this.onLoadMore,
    this.threshold = 320,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (!hasMore || isLoading) return false;
        if (n is! ScrollUpdateNotification &&
            n is! OverscrollNotification) {
          return false;
        }
        final m = n.metrics;
        if (m.axis != Axis.vertical || m.maxScrollExtent <= 0) return false;
        if (m.pixels >= m.maxScrollExtent - threshold) {
          onLoadMore();
        }
        return false;
      },
      child: child,
    );
  }
}

/// List ke neeche wali patli loading strip — sirf agli page fetch hote waqt
/// dikhti hai.
class BranchReportLoadMoreStrip extends StatelessWidget {
  const BranchReportLoadMoreStrip({super.key});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColor.primary),
        ),
      );
}
