import 'package:flutter/material.dart';
import '../../../../../core/color/app_color.dart';

/// Filters / Export / Refresh ke liye ek hi look — har report mein same.
/// Wide (desktop) par labelled button, narrow par AppBar ka icon.
class ReportActionStyle {
  ReportActionStyle._();

  static const double breakpoint = 800;
  static const double radius     = 10;

  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpoint;

  /// Wide layout mein buttons ke beech 10px (5 + 5).
  static const EdgeInsets wideGap = EdgeInsets.symmetric(horizontal: 5);

  static ButtonStyle outlined() => OutlinedButton.styleFrom(
        foregroundColor: AppColor.primary,
        side:            const BorderSide(color: AppColor.primary),
        minimumSize:     const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius)),
      );

  static ButtonStyle filled({bool enabled = true}) => ElevatedButton.styleFrom(
        backgroundColor:         AppColor.primary,
        foregroundColor:         Colors.white,
        disabledBackgroundColor: Colors.grey.shade400,
        disabledForegroundColor: Colors.white,
        elevation:               0,
        minimumSize:             const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius)),
      );
}
