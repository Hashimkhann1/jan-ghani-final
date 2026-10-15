// Updated on 2026-10-15 10:28 AM
// =============================================================
// nav_tile_widget.dart — warehouse sidebar ka ek menu item
//   • Expanded (248px): icon + label
//   • Collapsed (72px): sirf icon, tooltip mein label
//   • Active: purple tint + left 3px indicator + purple icon/text
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/warehouse_color.dart';
import 'package:jan_ghani_final/core/widget/sidebar/sidebar_widget.dart';

class NavTile extends StatefulWidget {
  final NavItem      item;
  final bool         selected;
  final bool         collapsed;
  final VoidCallback onTap;

  const NavTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
    this.collapsed = false,
  });

  @override
  State<NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<NavTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final sel   = widget.selected;
    final color = sel ? WarehouseAppColor.primary : WarehouseAppColor.textSecondary;
    final bg    = sel
        ? WarehouseAppColor.primary.withOpacity(0.10)
        : (_hover ? WarehouseAppColor.grey100 : WarehouseAppColor.transparent);

    final icon = Icon(widget.item.icon, size: 20, color: color);

    final tile = MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color:        bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // Active indicator — left edge
              if (sel)
                Positioned(
                  left: 0, top: 8, bottom: 8,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color:        WarehouseAppColor.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              if (widget.collapsed)
                Center(child: icon)
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      icon,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize:   14,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                            color:      sel ? WarehouseAppColor.primary : WarehouseAppColor.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // Collapsed par label tooltip mein
    return widget.collapsed
        ? Tooltip(
            message: widget.item.label,
            waitDuration: const Duration(milliseconds: 300),
            child: tile,
          )
        : tile;
  }
}
