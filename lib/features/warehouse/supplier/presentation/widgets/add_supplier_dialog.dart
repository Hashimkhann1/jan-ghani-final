// =============================================================
// add_supplier_dialog.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/warehouse/auth/local/auth_local_storage.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_model.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/provider/supplier_provider/supplier_provider.dart';
import 'package:uuid/uuid.dart';

class AddSupplierDialog extends ConsumerStatefulWidget {
  const AddSupplierDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:      (_) => const AddSupplierDialog(),
    );
  }

  @override
  ConsumerState<AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends ConsumerState<AddSupplierDialog> {
  final _formKey        = GlobalKey<FormState>();

  final _companyName    = TextEditingController();
  final _name           = TextEditingController();
  final _phone          = TextEditingController();
  final _contactPerson  = TextEditingController();
  final _email          = TextEditingController();
  final _address        = TextEditingController();
  final _taxId          = TextEditingController();
  final _notes          = TextEditingController();
  final _openingBalance = TextEditingController();
  int _paymentTerms     = 30;
  bool _isSaving        = false;

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
    _openingBalance.dispose();
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
                            style: TextStyle(
                                fontSize:   16,
                                fontWeight: FontWeight.w700,
                                color:      AppColor.textPrimary)),
                        Text('Supplier ki details bharein',
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

                // ── Balance & Payment Terms ───────────────────
                _SectionLabel(label: 'Balance & Payment Terms'),
                const SizedBox(height: 10),

                Row(
                  children: [
                    // Opening Balance
                    Expanded(
                      child: _Field(
                        label:        'Opening Balance (Rs)',
                        controller:   _openingBalance,
                        hint:         '0',
                        keyboardType: const TextInputType
                            .numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]')),
                        ],
                        helperText: 'System se pehle ka baqi balance',
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Payment Terms
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Payment Terms (Credit Days)',
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
                              contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: AppColor.grey200)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: AppColor.grey200)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color:  AppColor.primary,
                                      width:  1.5)),
                            ),
                            items: [7, 15, 30, 45, 60, 90]
                                .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text('$d days')))
                                .toList(),
                            onChanged: (v) => setState(
                                    () => _paymentTerms = v ?? 30),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Opening balance info box
                ValueListenableBuilder(
                  valueListenable: _openingBalance,
                  builder: (_, value, __) {
                    final amount =
                        double.tryParse(value.text.trim()) ?? 0;
                    if (amount <= 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColor.warning.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color:
                              AppColor.warning.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 16, color: AppColor.warning),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Rs ${amount.toStringAsFixed(0)} '
                                    'outstanding hoga — ledger mein '
                                    'opening entry ban jaye gi',
                                style: TextStyle(
                                    fontSize: 12,
                                    color:    AppColor.warning),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ── Error message ─────────────────────────────
                Consumer(builder: (context, ref, _) {
                  final error = ref.watch(
                      supplierProvider.select((s) => s.errorMessage));
                  if (error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(error,
                        style: TextStyle(
                            color: AppColor.error, fontSize: 12)),
                  );
                }),

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
                        width:  20,
                        height: 20,
                        child:  CircularProgressIndicator(
                            strokeWidth: 2,
                            color:       Colors.white))
                        : const Text('Save Supplier',
                        style: TextStyle(
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    const uuid = Uuid();

    // Current user SharedPreferences se lo
    final userMap = await AuthLocalStorage.loadUser();
    final userId  = userMap?['id']?.toString();

    final newSupplier = SupplierModel(
      id:                  uuid.v4(),
      warehouseId:         AppConfig.warehouseId,
      companyName:         _companyName.text.trim(),
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
      notes:               _notes.text.trim().isEmpty
          ? null : _notes.text.trim(),
      createdById:         userId,
      createdAt:           DateTime.now(),
      updatedAt:           DateTime.now(),
      outstandingBalance:  0,
      totalOrders:         0,
      totalPurchaseAmount: 0,
    );

    // Opening balance alag pass karo — repository ledger mein entry karega
    final openingBalance =
        double.tryParse(_openingBalance.text.trim()) ?? 0.0;

    await ref
        .read(supplierProvider.notifier)
        .addSupplier(newSupplier, openingBalance: openingBalance);

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