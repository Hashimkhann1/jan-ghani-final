// =============================================================
// edit_supplier_dialog.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/supplier/domian/supplier_model.dart';
import 'package:jan_ghani_final/features/supplier/presentation/provider/supplier_provider/supplier_provider.dart';

class EditSupplierDialog extends ConsumerStatefulWidget {
  final SupplierModel supplier;

  const EditSupplierDialog({super.key, required this.supplier});

  static void show(BuildContext context, SupplierModel supplier) {
    showDialog(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:      (_) => EditSupplierDialog(supplier: supplier),
    );
  }

  @override
  ConsumerState<EditSupplierDialog> createState() =>
      _EditSupplierDialogState();
}

class _EditSupplierDialogState extends ConsumerState<EditSupplierDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _companyName;
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _contactPerson;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _taxId;
  late final TextEditingController _notes;
  late int  _paymentTerms;
  late bool _isActive;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s        = widget.supplier;
    _companyName   = TextEditingController(text: s.companyName   ?? '');
    _name          = TextEditingController(text: s.name);
    _phone         = TextEditingController(text: s.phone);
    _contactPerson = TextEditingController(text: s.contactPerson ?? '');
    _email         = TextEditingController(text: s.email         ?? '');
    _address       = TextEditingController(text: s.address       ?? '');
    _taxId         = TextEditingController(text: s.taxId         ?? '');
    _notes         = TextEditingController(text: s.notes         ?? '');
    _paymentTerms  = s.paymentTerms;
    _isActive      = s.isActive;
  }

  @override
  void dispose() {
    _companyName.dispose();
    _name.dispose();
    _phone.dispose();
    _contactPerson.dispose();
    _email.dispose();
    _address.dispose();
    _taxId.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize:       MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:        AppColor.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.edit_outlined,
                          color: AppColor.info, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Edit Supplier',
                            style: TextStyle(
                                fontSize:   16,
                                fontWeight: FontWeight.w700,
                                color:      AppColor.textPrimary)),
                        Text(widget.supplier.name,
                            style: TextStyle(
                                fontSize: 12,
                                color:    AppColor.textSecondary)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon:  const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                          foregroundColor: AppColor.textSecondary),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: AppColor.grey200),
                const SizedBox(height: 16),

                // ── Required Info ─────────────────────────────
                _SectionLabel(label: 'Required Info'),
                const SizedBox(height: 10),

                _Field(
                  label:      'Company Name *',
                  controller: _companyName,
                  hint:       'Jan Ghani Traders',
                  validator:  (v) => (v == null || v.trim().isEmpty)
                      ? 'Company name required hai' : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label:      'Supplier Name *',
                        controller: _name,
                        hint:       'M Hashim',
                        validator:  (v) => (v == null || v.trim().isEmpty)
                            ? 'Name required hai' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        label:           'Phone *',
                        controller:      _phone,
                        hint:            '03001234567',
                        keyboardType:    TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+]')),
                          LengthLimitingTextInputFormatter(13),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Phone required hai';
                          if (!RegExp(r'^\+?[0-9]{10,13}$')
                              .hasMatch(v.trim()))
                            return '10-13 numbers dalein';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Additional Info ───────────────────────────
                _SectionLabel(label: 'Additional Info (Optional)'),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label:      'Contact Person',
                        controller: _contactPerson,
                        hint:       'Contact ka naam',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        label:        'Email',
                        controller:   _email,
                        hint:         'email@example.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label:      'Address',
                        controller: _address,
                        hint:       'Gull Abad, Peshawar',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        label:      'Tax ID (NTN)',
                        controller: _taxId,
                        hint:       'NTN-12345',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _Field(
                  label:    'Notes',
                  controller: _notes,
                  hint:     'Koi khaas baat likhein...',
                  maxLines: 3,
                ),

                const SizedBox(height: 20),

                // ── Status & Payment Terms ────────────────────
                _SectionLabel(label: 'Status & Payment Terms'),
                const SizedBox(height: 10),

                // Payment Terms
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Terms',
                        style: TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w500,
                            color:      AppColor.textPrimary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _paymentTerms,
                      decoration: InputDecoration(
                        filled:    true,
                        fillColor: AppColor.grey100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            BorderSide(color: AppColor.grey200)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            BorderSide(color: AppColor.grey200)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: AppColor.primary, width: 1.5)),
                      ),
                      items: [7, 15, 30, 45, 60, 90]
                          .map((d) => DropdownMenuItem(
                          value: d, child: Text('$d days')))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _paymentTerms = v ?? 30),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Active / Inactive toggle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status',
                        style: TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w500,
                            color:      AppColor.textPrimary)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _isActive = !_isActive),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _isActive
                              ? AppColor.successLight
                              : AppColor.grey100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _isActive
                                  ? AppColor.success
                                  : AppColor.grey200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width:  8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isActive
                                    ? AppColor.success
                                    : AppColor.grey400,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize:   13,
                                fontWeight: FontWeight.w500,
                                color:      _isActive
                                    ? AppColor.success
                                    : AppColor.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Outstanding balance — read only info box
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.supplier.hasDue
                        ? AppColor.error.withOpacity(0.06)
                        : AppColor.success.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: widget.supplier.hasDue
                            ? AppColor.error.withOpacity(0.2)
                            : AppColor.success.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.supplier.hasDue
                            ? Icons.account_balance_wallet_outlined
                            : Icons.check_circle_outline_rounded,
                        size:  16,
                        color: widget.supplier.hasDue
                            ? AppColor.error
                            : AppColor.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current Outstanding: '
                            '${widget.supplier.balanceLabel}',
                        style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w500,
                          color:      widget.supplier.hasDue
                              ? AppColor.error
                              : AppColor.success,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Buttons ───────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColor.textSecondary,
                          side: BorderSide(color: AppColor.grey300),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
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
                            : const Text('Save Changes',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize:   15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final updated = widget.supplier.copyWith(
      companyName:   _companyName.text.trim().isEmpty
          ? null : _companyName.text.trim(),
      name:          _name.text.trim(),
      phone:         _phone.text.trim(),
      contactPerson: _contactPerson.text.trim().isEmpty
          ? null : _contactPerson.text.trim(),
      email:         _email.text.trim().isEmpty
          ? null : _email.text.trim(),
      address:       _address.text.trim().isEmpty
          ? null : _address.text.trim(),
      taxId:         _taxId.text.trim().isEmpty
          ? null : _taxId.text.trim(),
      notes:         _notes.text.trim().isEmpty
          ? null : _notes.text.trim(),
      paymentTerms:  _paymentTerms,
      isActive:      _isActive,
    );

    await ref.read(supplierProvider.notifier).updateSupplier(updated);

    setState(() => _isSaving = false);
    if (mounted) Navigator.of(context).pop();
  }
}

// ─────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
            fontSize:      12,
            fontWeight:    FontWeight.w600,
            color:         AppColor.textSecondary,
            letterSpacing: 0.5));
  }
}

// ─────────────────────────────────────────────────────────────
// FORM FIELD
// ─────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String                     label;
  final TextEditingController      controller;
  final String                     hint;
  final TextInputType              keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>?  inputFormatters;
  final int                        maxLines;
  final String?                    helperText;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType    = TextInputType.text,
    this.validator,
    this.inputFormatters,
    this.maxLines        = 1,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w500,
                color:      AppColor.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller:      controller,
          keyboardType:    keyboardType,
          validator:       validator,
          inputFormatters: inputFormatters,
          maxLines:        maxLines,
          style: TextStyle(fontSize: 14, color: AppColor.textPrimary),
          decoration: InputDecoration(
            hintText:    hint,
            hintStyle:   TextStyle(
                color: AppColor.textHint, fontSize: 13),
            helperText:  helperText,
            helperStyle: TextStyle(
                color: AppColor.textSecondary, fontSize: 11),
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
          ),
        ),
      ],
    );
  }
}