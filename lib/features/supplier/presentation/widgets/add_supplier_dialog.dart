// =============================================================
// add_supplier_dialog.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/supplier/domian/supplier_model.dart';
import 'package:jan_ghani_final/features/supplier/presentation/provider/supplier_provider/supplier_provider.dart';
import 'package:uuid/uuid.dart';

class AddSupplierDialog extends ConsumerStatefulWidget {
  const AddSupplierDialog({super.key});

  @override
  ConsumerState<AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends ConsumerState<AddSupplierDialog> {
  final _formKey       = GlobalKey<FormState>();

  final _companyName   = TextEditingController(); // ← NAYA: Company name
  final _name          = TextEditingController(); // required
  final _phone         = TextEditingController(); // required
  final _contactPerson = TextEditingController();
  final _email         = TextEditingController();
  final _address       = TextEditingController();
  final _taxId         = TextEditingController();
  int _paymentTerms    = 30;

  bool _isSaving = false;

  @override
  void dispose() {
    _companyName.dispose(); // ← NAYA
    _name.dispose();
    _phone.dispose();
    _contactPerson.dispose();
    _email.dispose();
    _address.dispose();
    _taxId.dispose();
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
                // ── Header ───────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:        AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.person_add_outlined,
                          color: AppColor.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New Supplier',
                            style: TextStyle(fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColor.textPrimary)),
                        Text('Supplier ki details bharein',
                            style: TextStyle(fontSize: 12,
                                color: AppColor.textSecondary)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon:      const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                          foregroundColor: AppColor.textSecondary),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: AppColor.grey200),
                const SizedBox(height: 16),

                // ── Required fields ───────────────────────────
                Text('Required Info',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColor.textSecondary, letterSpacing: 0.5)),
                const SizedBox(height: 10),

                // ── NAYA: Company Name — pehle field ──────────
                _Field(
                  label:      'Company Name *',
                  controller: _companyName,
                  hint:       'Jan Ghani',
                  validator:  (v) => (v == null || v.trim().isEmpty)
                      ? 'Company name required hai' : null,
                ),
                const SizedBox(height: 12),

                // Supplier Name + Phone
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label:     'Supplier Name *',
                        controller: _name,
                        hint:      'M Hashim',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name required hai' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        label:        'Phone *',
                        controller:   _phone,
                        hint:         '03001234567',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                          LengthLimitingTextInputFormatter(13),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Phone required hai';
                          if (!RegExp(r'^\+?[0-9]{10,13}$')
                              .hasMatch(v.trim())) {
                            return '10-13 numbers dalein';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Optional fields ───────────────────────────
                Text('Additional Info (Optional)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColor.textSecondary, letterSpacing: 0.5)),
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
                        hint:       'Malang abad road, Charsadda',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        label: 'Tax ID (NTN)',
                        controller: _taxId,
                        hint:       'NTN-12345',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Payment Terms dropdown ─────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Terms (Credit Days)',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColor.textPrimary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _paymentTerms,
                      decoration: InputDecoration(
                        filled:         true,
                        fillColor:      AppColor.grey100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColor.grey200)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColor.grey200)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: AppColor.primary, width: 1.5)),
                      ),
                      items: [7, 15, 30, 45, 60, 90].map((days) {
                        return DropdownMenuItem(
                            value: days, child: Text('$days days'));
                      }).toList(),
                      onChanged: (v) =>
                          setState(() => _paymentTerms = v ?? 30),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Save button ───────────────────────────────
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
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Text('Save Supplier',
                        style: TextStyle(
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    const uuid = Uuid();

    final newSupplier = SupplierModel(
      id:                  uuid.v4(),
      tenantId:            'tenant-jan-ghani',
      companyName:         _companyName.text.trim(), // ← NAYA
      name:                _name.text.trim(),
      contactPerson:       _contactPerson.text.trim().isEmpty
          ? null : _contactPerson.text.trim(),
      email:               _email.text.trim().isEmpty
          ? null : _email.text.trim(),
      phone:               _phone.text.trim(),
      address:             _address.text.trim().isEmpty
          ? null : _address.text.trim(),
      code:                null,
      taxId:               _taxId.text.trim().isEmpty
          ? null : _taxId.text.trim(),
      paymentTerms:        _paymentTerms,
      isActive:            true,
      notes:               null,
      createdAt:           DateTime.now(),
      updatedAt:           DateTime.now(),
      outstandingBalance:  0,
      totalOrders:         0,
      totalPurchaseAmount: 0,
    );

    await ref.read(supplierProvider.notifier).addSupplier(newSupplier);

    setState(() => _isSaving = false);
    if (mounted) Navigator.of(context).pop();
  }
}

// ─────────────────────────────────────────────────────────────
// FORM FIELD WIDGET
// ─────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType     = TextInputType.text,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                color: AppColor.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller:      controller,
          keyboardType:    keyboardType,
          validator:       validator,
          inputFormatters: inputFormatters,
          style: TextStyle(fontSize: 14, color: AppColor.textPrimary),
          decoration: InputDecoration(
            hintText:       hint,
            hintStyle:      TextStyle(color: AppColor.textHint, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            filled:    true,
            fillColor: AppColor.grey100,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColor.grey200)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColor.grey200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                BorderSide(color: AppColor.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColor.error)),
          ),
        ),
      ],
    );
  }
}