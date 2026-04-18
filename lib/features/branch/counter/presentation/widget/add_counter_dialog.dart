import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/branch/counter/data/model/counter_model.dart';
import 'package:jan_ghani_final/features/branch/counter/presentation/provider/counter_provider.dart';

class AddCounterDialog extends ConsumerStatefulWidget {
  final CounterModel? counter;
  const AddCounterDialog({super.key, this.counter});

  @override
  ConsumerState<AddCounterDialog> createState() => _AddCounterDialogState();
}

class _AddCounterDialogState extends ConsumerState<AddCounterDialog> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  bool  _isSaving    = false;

  bool get _isEdit => widget.counter != null;

  @override
  void initState() {
    super.initState();
    if (widget.counter != null) {
      _nameCtrl.text = widget.counter!.counterName;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(counterProvider.notifier);
      if (_isEdit) {
        await notifier.updateCounter(
            widget.counter!.id, _nameCtrl.text.trim());
      } else {
        await notifier.addCounter(_nameCtrl.text.trim());
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 420,
        child: Padding(
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
                        color:        AppColor.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isEdit
                            ? Icons.edit_outlined
                            : Icons.add_circle_outline_rounded,
                        color: AppColor.primary,
                        size:  20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'Edit Counter' : 'New Counter',
                          style: const TextStyle(
                              fontSize:   16,
                              fontWeight: FontWeight.w700),
                        ),
                        const Text(
                          'Counter ka naam dalein',
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
                const Divider(color: AppColor.grey200),
                const SizedBox(height: 16),

                // ── Counter Name ──────────────────────────
                const Text('Counter Name *',
                    style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                        color:      AppColor.textSecondary,
                        letterSpacing: 0.5)),
                const SizedBox(height: 6),
                TextFormField(
                  controller:      _nameCtrl,
                  cursorHeight:    14,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  style: const TextStyle(
                      fontSize: 14, color: AppColor.textPrimary),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Counter name required hai';
                    if (v.trim().length < 2)
                      return 'Minimum 2 characters chahiye';
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText:  'e.g. Counter 1, Main Counter...',
                    hintStyle: const TextStyle(
                        color: AppColor.textHint, fontSize: 13),
                    prefixIcon: const Icon(
                        Icons.point_of_sale_outlined,
                        size:  18,
                        color: AppColor.grey400),
                    filled:    true,
                    fillColor: AppColor.grey100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: AppColor.grey200)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: AppColor.grey200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColor.primary, width: 1.5)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: AppColor.error)),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Save Button ───────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:         AppColor.primary,
                      foregroundColor:         Colors.white,
                      disabledBackgroundColor:
                      AppColor.primary.withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                        width:  20,
                        height: 20,
                        child:  CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : Text(
                        _isEdit ? 'Update Counter' : 'Save Counter',
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
}