// =============================================================
// add_category_dialog.dart — Add + Edit dono handle karta hai
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/category/presentation/provider/category_provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/model/category_model.dart';

class AddCategoryDialog extends ConsumerStatefulWidget {
  final CategoryModel? category; // null = add, not null = edit

  const AddCategoryDialog({super.key, this.category});

  static void show(BuildContext context, {CategoryModel? category}) {
    showDialog(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:      (_) => AddCategoryDialog(category: category),
    );
  }

  @override
  ConsumerState<AddCategoryDialog> createState() =>
      _AddCategoryDialogState();
}

class _AddCategoryDialogState
    extends ConsumerState<AddCategoryDialog> {
  final _formKey     = GlobalKey<FormState>();
  final _name        = TextEditingController();
  final _description = TextEditingController();

  String? _selectedColor;
  bool    _isActive = true;
  bool    _isSaving = false;

  bool get _isEdit => widget.category != null;

  // ── Predefined colors ─────────────────────────────────────
  static const List<Map<String, dynamic>> _colors = [
    {'label': 'Red',    'hex': '#E53935'},
    {'label': 'Pink',   'hex': '#D81B60'},
    {'label': 'Purple', 'hex': '#8E24AA'},
    {'label': 'Blue',   'hex': '#1E88E5'},
    {'label': 'Teal',   'hex': '#00897B'},
    {'label': 'Green',  'hex': '#43A047'},
    {'label': 'Orange', 'hex': '#FB8C00'},
    {'label': 'Brown',  'hex': '#6D4C41'},
    {'label': 'Grey',   'hex': '#757575'},
    {'label': 'Indigo', 'hex': '#3949AB'},
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    if (c != null) {
      _name.text        = c.name;
      _description.text = c.description ?? '';
      _selectedColor    = c.colorCode;
      _isActive         = c.isActive;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(categoryProvider.notifier);

    try {
      if (_isEdit) {
        await notifier.updateCategory(widget.category!.copyWith(
          name:        _name.text.trim(),
          description: _description.text.trim().isEmpty
              ? null : _description.text.trim(),
          colorCode:   _selectedColor,
          isActive:    _isActive,
        ));
      } else {
        const uuid = Uuid();
        await notifier.addCategory(CategoryModel(
          id:          uuid.v4(),
          warehouseId: AppConfig.warehouseId,
          name:        _name.text.trim(),
          description: _description.text.trim().isEmpty
              ? null : _description.text.trim(),
          colorCode:   _selectedColor,
          isActive:    _isActive,
          createdAt:   DateTime.now(),
          updatedAt:   DateTime.now(),
        ));
      }

      final hasError =
          ref.read(categoryProvider).errorMessage != null;
      if (!hasError && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize:       MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ───────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isEdit
                            ? Icons.edit_outlined
                            : Icons.category_outlined,
                        color: AppColor.primary, size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit
                              ? 'Edit Category'
                              : 'New Category',
                          style: TextStyle(
                              fontSize:   16,
                              fontWeight: FontWeight.w700,
                              color:      AppColor.textPrimary),
                        ),
                        Text(
                          'Category ki details bharein',
                          style: TextStyle(
                              fontSize: 12,
                              color:    AppColor.textSecondary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon:  const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                          foregroundColor: AppColor.textSecondary),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: AppColor.grey200),
                const SizedBox(height: 16),

                // ── Name ─────────────────────────────────
                _FieldLabel('Category Name *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _name,
                  style: TextStyle(
                      fontSize: 14, color: AppColor.textPrimary),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Name required hai'
                          : null,
                  decoration: _inputDec(hint: 'Grocery, Electronics...'),
                ),

                const SizedBox(height: 16),

                // ── Description ───────────────────────────
                _FieldLabel('Description (Optional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _description,
                  maxLines:   3,
                  style: TextStyle(
                      fontSize: 14, color: AppColor.textPrimary),
                  decoration: _inputDec(
                      hint: 'Category ke baare mein kuch likho...'),
                ),

                const SizedBox(height: 16),

                // ── Color ─────────────────────────────────
                _FieldLabel('Color (Optional)'),
                const SizedBox(height: 10),
                Wrap(
                  spacing:     10,
                  runSpacing:  10,
                  children: _colors.map((c) {
                    final hex      = c['hex'] as String;
                    final color    = _hexToColor(hex);
                    final selected = _selectedColor == hex;
                    return GestureDetector(
                      onTap: () => setState(() =>
                          _selectedColor =
                              selected ? null : hex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width:  34,
                        height: 34,
                        decoration: BoxDecoration(
                          color:  color,
                          shape:  BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? AppColor.textPrimary
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: selected
                              ? [BoxShadow(
                                  color:      color.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset:     const Offset(0, 2))]
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),

                if (_selectedColor != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width:  12,
                        height: 12,
                        decoration: BoxDecoration(
                          color:  _hexToColor(_selectedColor!),
                          shape:  BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(_selectedColor!,
                          style: TextStyle(
                              fontSize: 12,
                              color:    AppColor.textSecondary)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _selectedColor = null),
                        child: Text('Clear',
                            style: TextStyle(
                                fontSize: 12,
                                color:    AppColor.error)),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // ── Active Toggle ─────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color:        AppColor.grey100,
                    borderRadius: BorderRadius.circular(8),
                    border:       Border.all(color: AppColor.grey200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.toggle_on_outlined,
                          size: 18, color: AppColor.textSecondary),
                      const SizedBox(width: 8),
                      Text('Active',
                          style: TextStyle(
                              fontSize:   13,
                              fontWeight: FontWeight.w500,
                              color:      AppColor.textPrimary)),
                      const Spacer(),
                      Switch(
                        value:       _isActive,
                        activeColor: AppColor.primary,
                        onChanged:   (v) =>
                            setState(() => _isActive = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Error ─────────────────────────────────
                Consumer(builder: (context, ref, _) {
                  final error = ref.watch(categoryProvider
                      .select((s) => s.errorMessage));
                  if (error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(error,
                        style: TextStyle(
                            color: AppColor.error, fontSize: 12)),
                  );
                }),

                // ── Save Button ───────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: AppColor.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width:  20,
                            height: 20,
                            child:  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:       Colors.white))
                        : Text(
                            _isEdit
                                ? 'Save Changes'
                                : 'Save Category',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize:   15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec({required String hint}) {
    return InputDecoration(
      hintText:  hint,
      hintStyle: TextStyle(
          color: AppColor.textHint, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      filled:    true,
      fillColor: AppColor.grey100,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   BorderSide(color: AppColor.grey200)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   BorderSide(color: AppColor.grey200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: AppColor.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   BorderSide(color: AppColor.error)),
    );
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize:   13,
          fontWeight: FontWeight.w500,
          color:      AppColor.textPrimary));
}
