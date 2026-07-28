// =============================================================
// add_company_dialog.dart — Add + Edit dono handle karta hai
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/warehouse/company/presentation/provider/company_provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/model/company_model.dart';

class AddCompanyDialog extends ConsumerStatefulWidget {
  final CompanyModel? company; // null = add, not null = edit

  const AddCompanyDialog({super.key, this.company});

  static void show(BuildContext context, {CompanyModel? company}) {
    showDialog(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:      (_) => AddCompanyDialog(company: company),
    );
  }

  @override
  ConsumerState<AddCompanyDialog> createState() => _AddCompanyDialogState();
}

class _AddCompanyDialogState extends ConsumerState<AddCompanyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name    = TextEditingController();

  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEdit => widget.company != null;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    if (c != null) {
      _name.text = c.name;
      _isActive  = c.isActive;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(companyProvider.notifier);

    try {
      if (_isEdit) {
        await notifier.updateCompany(widget.company!.copyWith(
          name:     _name.text.trim(),
          isActive: _isActive,
        ));
      } else {
        const uuid = Uuid();
        await notifier.addCompany(CompanyModel(
          id:          uuid.v4(),
          warehouseId: AppConfig.warehouseId,
          name:        _name.text.trim(),
          isActive:    _isActive,
          createdAt:   DateTime.now(),
          updatedAt:   DateTime.now(),
        ));
      }

      final hasError = ref.read(companyProvider).errorMessage != null;
      if (!hasError && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 460,
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
                            : Icons.business_outlined,
                        color: AppColor.primary, size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'Edit Company' : 'New Company',
                          style: const TextStyle(
                              fontSize:   16,
                              fontWeight: FontWeight.w700,
                              color:      AppColor.textPrimary),
                        ),
                        const Text(
                          'Company ki details bharein',
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
                const _FieldLabel('Company Name *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _name,
                  style: const TextStyle(
                      fontSize: 14, color: AppColor.textPrimary),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Name required hai'
                          : null,
                  decoration: _inputDec(hint: 'Nestle, Unilever, Coca-Cola...'),
                ),

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
                      const Icon(Icons.toggle_on_outlined,
                          size: 18, color: AppColor.textSecondary),
                      const SizedBox(width: 8),
                      const Text('Active',
                          style: TextStyle(
                              fontSize:   13,
                              fontWeight: FontWeight.w500,
                              color:      AppColor.textPrimary)),
                      const Spacer(),
                      Switch(
                        value:       _isActive,
                        activeColor: AppColor.primary,
                        onChanged:   (v) => setState(() => _isActive = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Error ─────────────────────────────────
                Consumer(builder: (context, ref, _) {
                  final error = ref.watch(
                      companyProvider.select((s) => s.errorMessage));
                  if (error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(error,
                        style: const TextStyle(
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
                            _isEdit ? 'Save Changes' : 'Save Company',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
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
      hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 13),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide:   const BorderSide(color: AppColor.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   const BorderSide(color: AppColor.error)),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize:   13,
          fontWeight: FontWeight.w500,
          color:      AppColor.textPrimary));
}
