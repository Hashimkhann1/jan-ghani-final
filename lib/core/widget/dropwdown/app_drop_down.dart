import 'package:flutter/material.dart';
import '../../color/app_color.dart';

class DropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const DropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

class AppSearchableDropdown<T> extends StatefulWidget {
  const AppSearchableDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.label,
    this.hint,
    this.prefixIcon,
    this.validator,
    this.fullWidth = false,
    this.desktopWidth = 360,
  });

  final List<DropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final T? value;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;
  final bool fullWidth;
  final double desktopWidth;

  @override
  State<AppSearchableDropdown<T>> createState() => _AppSearchableDropdownState<T>();
}

class _AppSearchableDropdownState<T> extends State<AppSearchableDropdown<T>> {
  final _searchCtrl = TextEditingController();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _isOpen = false;
  late T? _selected;
  List<DropdownItem<T>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _selected = widget.value;
    _filtered = widget.items;
  }

  @override
  void dispose() {
    _overlay?.remove();   // direct remove
    _overlay = null;
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _selectedLabel {
    try {
      return widget.items.firstWhere((e) => e.value == _selected).label;
    } catch (_) {
      return '';
    }
  }

  void _toggleDropdown() {
    _isOpen ? _closeDropdown() : _openDropdown();
  }

  void _openDropdown() {
    _filtered = widget.items;
    _searchCtrl.clear();
    _overlay = _buildOverlay();
    Overlay.of(context).insert(_overlay!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlay?.remove();
    _overlay = null;

    if (!mounted) return;
    setState(() => _isOpen = false);
  }

  void _onSearch(String query) {
    final result = widget.items.where((e) => e.label.toLowerCase().contains(query.toLowerCase())).toList();
    _overlay?.markNeedsBuild();
    _filtered = result;
  }

  void _selectItem(DropdownItem<T> item) {
    setState(() => _selected = item.value);
    widget.onChanged(item.value);
    _closeDropdown();
  }

  OverlayEntry _buildOverlay() {
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;

    return OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDropdown,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            CompositedTransformFollower(
              link: _layerLink,
              offset: Offset(0, size.height + 4),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                shadowColor: Colors.black26,
                child: Container(
                  width: size.width,
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColor.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: TextField(
                          controller: _searchCtrl,
                          autofocus: true,
                          onChanged: (q) {
                            _onSearch(q);
                            _overlay?.markNeedsBuild();
                          },
                          style: const TextStyle(fontSize: 13),
                          cursorHeight: 14,
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: const TextStyle(
                                fontSize: 13, color: AppColor.grey400),
                            prefixIcon: const Icon(Icons.search,
                                size: 18, color: AppColor.grey400),
                            filled: true,
                            fillColor: AppColor.grey100,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppColor.divider),
                      // Items list
                      Flexible(
                        child: StatefulBuilder(
                          builder: (_, setList) {
                            if (_filtered.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No results',
                                    style:
                                    TextStyle(color: AppColor.grey400)),
                              );
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) {
                                final item = _filtered[i];
                                final isSelected = item.value == _selected;
                                return InkWell(
                                  onTap: () => _selectItem(item),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColor.primary
                                          .withValues(alpha: 0.08)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        if (item.icon != null) ...[
                                          Icon(item.icon,
                                              size: 16,
                                              color: isSelected
                                                  ? AppColor.primary
                                                  : AppColor.grey500),
                                          const SizedBox(width: 10),
                                        ],
                                        Expanded(
                                          child: Text(
                                            item.label,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isSelected
                                                  ? AppColor.primary
                                                  : AppColor.textPrimary,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check,
                                              size: 16,
                                              color: AppColor.primary),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 600;

    final field = FormField<T>(
      validator: widget.validator != null
          ? (_) => widget.validator!(_selected)
          : null,
      builder: (state) => CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: AppColor.primary, size: 20)
                  : null,
              suffixIcon: AnimatedRotation(
                turns: _isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down, color: AppColor.grey500),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              errorText: state.errorText,
            ),
            isEmpty: _selected == null,
            child: Text(
              _selected != null ? _selectedLabel : '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );

    if (isDesktop) {
      return SizedBox(width: widget.desktopWidth, child: field);
    }

    return field;
  }
}