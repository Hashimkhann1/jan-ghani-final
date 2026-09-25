import 'package:flutter/material.dart';
import '../../../../../core/color/app_color.dart';
import '../../../../../core/widget/app_icon.dart';

/// AppBar filter button with an active-filter count badge.
class ReportFilterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final int          activeCount;

  const ReportFilterButton({
    super.key,
    required this.onPressed,
    this.activeCount = 0,
  });

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onPressed,
            icon: const AppIcon('ic_filter',
                size: 22, color: AppColor.textSecondary),
            tooltip: 'Filters',
          ),
          if (activeCount > 0)
            Positioned(
              right: 6,
              top:   6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColor.primary,
                  shape: BoxShape.circle,
                ),
                constraints:
                    const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$activeCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize:   9,
                    color:      Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      );
}

/// Shows every filter of a report inside one alert dialog.
///
/// [content] should be a widget that rebuilds itself when the report state
/// changes (e.g. a `Consumer`), so date/dropdown changes show up live while
/// the dialog is open. Filters apply immediately; "Apply" just closes it.
Future<void> showReportFilterDialog({
  required BuildContext context,
  required Widget       content,
  VoidCallback?         onReset,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'Filters',
              style: TextStyle(
                fontSize:   17,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF1A1D23),
              ),
            ),
          ),
          if (onReset != null)
            TextButton(
              onPressed: onReset,
              style: TextButton.styleFrom(foregroundColor: AppColor.primary),
              child: const Text('Reset'),
            ),
          IconButton(
            onPressed: () => Navigator.pop(ctx),
            icon: const AppIcon('ic_clear',
                size: 18, color: AppColor.textSecondary),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SizedBox(
          width: 520,
          child: SingleChildScrollView(child: content),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Apply',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    ),
  );
}
