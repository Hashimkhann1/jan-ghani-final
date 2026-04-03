import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

class FigureCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final String? svgPath;
  final Color? iconBackgroundColor;

  const FigureCardWidget({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.svgPath,
    this.iconBackgroundColor,
  }) : assert(
  icon != null || svgPath != null,
  '',
  );

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Breakpoints
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    final iconSize = isDesktop ? 28.0 : isTablet ? 24.0 : 20.0;
    final iconBoxSize = isDesktop ? 56.0 : isTablet ? 48.0 : 42.0;
    final titleFontSize = isDesktop ? 13.0 : isTablet ? 12.0 : 11.0;
    final valueFontSize = isDesktop ? 22.0 : isTablet ? 20.0 : 16.0;
    final cardPadding = isDesktop ? 16.0 : isTablet ? 14.0 : 12.0;
    final cardRadius = isDesktop ? 20.0 : isTablet ? 16.0 : 14.0;
    final iconRadius = isDesktop ? 16.0 : isTablet ? 12.0 : 10.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.all(cardPadding),
      child: Row(
        children: [
          // Icon Box
          Container(
            height: iconBoxSize,
            width: iconBoxSize,
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? AppColor.primary,
              borderRadius: BorderRadius.circular(iconRadius),
            ),
            child: Center(
              child: svgPath != null
                  ? SvgPicture.asset(
                svgPath!,
                height: iconSize,
                width: iconSize,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              )
                  : Icon(
                icon,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),

          SizedBox(width: cardPadding),

          // Title & Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF9E9E9E),
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: const Color(0xFF1A1A2E),
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}