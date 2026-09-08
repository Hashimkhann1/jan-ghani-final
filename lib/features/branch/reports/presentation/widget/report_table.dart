import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/app_icon.dart';

/// Ek report table column ka definition.
class ReportColumn {
  final String    label;
  final int       flex;
  final Alignment align;

  const ReportColumn(
    this.label, {
    this.flex = 2,
    this.align = Alignment.centerLeft,
  });
}

/// Reusable report table — flex columns + har row ke end me "view" (eye) icon.
/// Row par ya eye icon par tap karne se [onView] absolute index ke saath
/// call hota hai. Client-side pagination andar hi handle hoti hai.
class ReportTable extends StatefulWidget {
  final List<ReportColumn>            columns;
  final int                           rowCount;
  final List<Widget> Function(int index) cellsBuilder;
  final void Function(int index)      onView;
  final int                           rowsPerPage;

  const ReportTable({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.cellsBuilder,
    required this.onView,
    this.rowsPerPage = 30,
  });

  @override
  State<ReportTable> createState() => _ReportTableState();
}

class _ReportTableState extends State<ReportTable> {
  int _page = 0;

  @override
  void didUpdateWidget(covariant ReportTable old) {
    super.didUpdateWidget(old);
    // Row count ghatne par (filter change) page range se bahar na ho.
    final maxPage = _maxPage;
    if (_page > maxPage) _page = maxPage;
  }

  int get _maxPage {
    if (widget.rowCount == 0) return 0;
    return (widget.rowCount - 1) ~/ widget.rowsPerPage;
  }

  @override
  Widget build(BuildContext context) {
    final total     = widget.rowCount;
    final page      = _page.clamp(0, _maxPage);
    final startIdx  = page * widget.rowsPerPage;
    final endIdx    = (startIdx + widget.rowsPerPage) > total
        ? total
        : startIdx + widget.rowsPerPage;
    final pageCount = _maxPage + 1;

    return Container(
      decoration: BoxDecoration(
        color:        AppColor.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColor.grey200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Header row ──────────────────────────────────────
          Container(
            color: AppColor.grey100,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                for (final col in widget.columns)
                  Expanded(
                    flex: col.flex,
                    child: Align(
                      alignment: col.align,
                      child: Text(
                        col.label.toUpperCase(),
                        style: const TextStyle(
                          fontSize:      10.5,
                          fontWeight:    FontWeight.w700,
                          letterSpacing: 0.5,
                          color:         AppColor.textSecondary,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(
                  width: 60,
                  child: Center(
                    child: Text(
                      'VIEW',
                      style: TextStyle(
                        fontSize:      10.5,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: 0.5,
                        color:         AppColor.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColor.grey200),

          // ── Body ────────────────────────────────────────────
          Expanded(
            child: Scrollbar(
              child: ListView.separated(
                itemCount: endIdx - startIdx,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                itemBuilder: (_, i) {
                  final absolute = startIdx + i;
                  final cells    = widget.cellsBuilder(absolute);
                  return InkWell(
                    onTap: () => widget.onView(absolute),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      child: Row(
                        children: [
                          for (var c = 0; c < widget.columns.length; c++)
                            Expanded(
                              flex: widget.columns[c].flex,
                              child: Align(
                                alignment: widget.columns[c].align,
                                child: DefaultTextStyle.merge(
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColor.textPrimary),
                                  child: cells[c],
                                ),
                              ),
                            ),
                          SizedBox(
                            width: 60,
                            child: Center(
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                splashRadius:  18,
                                tooltip: 'View',
                                icon: const AppIcon('ic_view',
                                    size: 18, color: AppColor.primary),
                                onPressed: () => widget.onView(absolute),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Pagination bar ──────────────────────────────────
          if (total > widget.rowsPerPage) ...[
            const Divider(height: 1, color: AppColor.grey200),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text('${startIdx + 1}–$endIdx of $total',
                      style: const TextStyle(
                          fontSize: 12, color: AppColor.textSecondary)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    tooltip: 'Previous',
                    onPressed:
                        page > 0 ? () => setState(() => _page = page - 1) : null,
                  ),
                  Text('Page ${page + 1} of $pageCount',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 22),
                    tooltip: 'Next',
                    onPressed: page < _maxPage
                        ? () => setState(() => _page = page + 1)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Report table ke upar right side se slide hone wala detail panel.
class ReportSlideOver extends StatelessWidget {
  final bool         open;
  final VoidCallback onClose;
  final Widget       child;
  final String       title;
  final double       width;

  /// `true` (default) par child ek scrollable padded area me aata hai.
  /// `false` par child ko seedha `Expanded` me rakha jata hai (jab child
  /// khud apna scroll / pinned footer manage karta ho).
  final bool scrollable;

  const ReportSlideOver({
    super.key,
    required this.open,
    required this.onClose,
    required this.child,
    this.title = 'Details',
    this.width = 460,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final maxW   = MediaQuery.of(context).size.width - 40;
    final panelW = width > maxW ? maxW : width;

    return IgnorePointer(
      ignoring: !open,
      child: Stack(
        children: [
          // Scrim
          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity:  open ? 1 : 0,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                    color: Colors.black.withValues(alpha: 0.32)),
              ),
            ),
          ),
          // Panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve:    Curves.easeOutCubic,
            top:      0,
            bottom:   0,
            right:    open ? 0 : -(panelW + 12),
            width:    panelW,
            child: Material(
              elevation: 16,
              color:     AppColor.grey100,
              child: Column(
                children: [
                  Container(
                    height: 52,
                    padding: const EdgeInsets.only(left: 16, right: 6),
                    decoration: const BoxDecoration(
                      color: AppColor.white,
                      border: Border(
                          bottom: BorderSide(color: AppColor.grey200)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Close',
                          onPressed: onClose,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: scrollable
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: child,
                          )
                        : child,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
