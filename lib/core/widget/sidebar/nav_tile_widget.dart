import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/sidebar/sidebar_widget.dart';

const _kGrey     = Color(0xFFD3D3D3);
const _kMid      = Color(0xFF666666);
const _kSelected = AppColor.primary;

class NavTile extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final bool isSettings;
  final VoidCallback onTap;

  const NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
    this.isSettings = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFECEFF1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _kGrey : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSettings ? Icons.settings_outlined : item.icon,
              size: 22,
              color: selected ? _kSelected : _kMid,
            ),
            const SizedBox(height: 5),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? _kSelected : _kMid,
                height: 1.2,
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 6),
              Container(
                height: 2,
                width: 24,
                decoration: BoxDecoration(
                  color: _kSelected,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}