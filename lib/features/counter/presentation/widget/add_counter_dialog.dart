import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../data/model/counter_model.dart';
import '../provider/counter_provider.dart';

class AddCounterDialog extends ConsumerStatefulWidget {
  final CounterModel? counter;
  const AddCounterDialog({super.key, this.counter});

  @override
  ConsumerState<AddCounterDialog> createState() => _AddCounterDialogState();
}

class _AddCounterDialogState extends ConsumerState<AddCounterDialog> {
  final _formKey = GlobalKey<FormState>();

  final _counterNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSaving = false;
  bool get _isEdit => widget.counter != null;

  @override
  void initState() {
    super.initState();
    if (widget.counter != null) {
      _counterNameController.text = widget.counter!.counterName;
      _usernameController.text = widget.counter!.username;
      _passwordController.text = widget.counter!.password;
    }
  }

  @override
  void dispose() {
    _counterNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final notifier = ref.read(counterProvider.notifier);

    if (_isEdit) {
      await notifier.updateCounter(
        widget.counter!.copyWith(
          counterName: _counterNameController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );
    } else {
      final newCounter = CounterModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        counterName: _counterNameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await notifier.addCounter(newCounter);
    }

    setState(() => _isSaving = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isEdit ? Icons.edit_outlined : Icons.point_of_sale,
                        color: AppColor.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'Edit Counter' : 'New Counter',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Counter ki details bharein',
                          style: TextStyle(fontSize: 13, color: AppColor.textSecondary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),

                const SizedBox(height: 16),

                _Field(
                  label: 'Counter Name *',
                  controller: _counterNameController,
                  hint: 'Counter 01',
                  validator: (v) => v!.trim().isEmpty ? 'Counter name required hai' : null,
                ),

                const SizedBox(height: 16),

                _Field(
                  label: 'Username *',
                  controller: _usernameController,
                  hint: 'counter01',
                  validator: (v) => v!.trim().isEmpty ? 'Username required hai' : null,
                ),

                const SizedBox(height: 16),

                _Field(
                  label: 'Password *',
                  controller: _passwordController,
                  hint: '••••••••',
                  obscureText: true,
                  validator: (v) => v!.trim().isEmpty ? 'Password required hai' : null,
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                        : Text(_isEdit ? 'Update Counter' : 'Create Counter',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final bool obscureText;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.validator,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          cursorHeight: 14,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColor.grey100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColor.grey200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}