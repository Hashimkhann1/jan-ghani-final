import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/customer/presentation/provider/customer_provider.dart';
import '../../data/model/customer_model.dart';

class AddCustomerDialog extends ConsumerStatefulWidget {
  final CustomerModel? customer;
  const AddCustomerDialog({super.key, this.customer});

  @override
  ConsumerState<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends ConsumerState<AddCustomerDialog> {
  final _formKey      = GlobalKey<FormState>();
  final _name         = TextEditingController();
  final _phone        = TextEditingController();
  final _address      = TextEditingController();
  final _creditLimit  = TextEditingController();
  final _notes        = TextEditingController();
  String _type        = 'walkin';
  bool   _isActive    = true;
  bool   _isSaving    = false;

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    if (c != null) {
      _name.text        = c.name;
      _phone.text       = c.phone;
      _address.text     = c.address ?? '';
      _creditLimit.text = c.creditLimit.toStringAsFixed(0);
      _notes.text       = c.notes ?? '';
      _type             = c.customerType;
      _isActive         = c.isActive;
    } else {
      _creditLimit.text = '0';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _creditLimit.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(customerProvider.notifier);

    if (_isEdit) {
      await notifier.updateCustomer(widget.customer!.copyWith(
        name:         _name.text.trim(),
        phone:        _phone.text.trim(),
        address:      _address.text.trim(),
        customerType: _type,
        creditLimit:  double.tryParse(_creditLimit.text) ?? 0,
        isActive:     _isActive,
        notes:        _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ));
    } else {
      await notifier.addCustomer(CustomerModel(
        id:             DateTime.now().millisecondsSinceEpoch.toString(),
        tenantId:       'tenant-jan-ghani',
        storeId:        'store-main',
        code:           'CUST-${DateTime.now().millisecondsSinceEpoch % 9000 + 1000}',
        name:           _name.text.trim(),
        phone:          _phone.text.trim(),
        address:        _address.text.trim().isEmpty ? null : _address.text.trim(),
        customerType:   _type,
        creditLimit:    double.tryParse(_creditLimit.text) ?? 0,
        isActive:       _isActive,
        notes:          _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        createdAt:      DateTime.now(),
        updatedAt:      DateTime.now(),
        currentBalance:  0,
        availableCredit: double.tryParse(_creditLimit.text) ?? 0,
        totalSales:      0,
        totalSaleAmount: 0,
      ));
    }

    setState(() => _isSaving = false);
    if (mounted) Navigator.of(context).pop();
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
                // ── Header ─────────────────────────────────
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
                            : Icons.person_add_outlined,
                        color: AppColor.primary, size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'Edit Customer' : 'New Customer',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Customer ki details bharein',
                          style: const TextStyle(
                              fontSize: 12, color: AppColor.textSecondary),
                        ),
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
                const Divider(color: AppColor.grey200),
                const SizedBox(height: 16),

                // ── Required ───────────────────────────────
                const _SectionLabel('Required Info'),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label:      'Customer Name *',
                        controller: _name,
                        hint:       'Ahmad Khan',
                        validator:  (v) => (v == null || v.trim().isEmpty)
                            ? 'Name required hai'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        label:        'Phone *',
                        controller:   _phone,
                        hint:         '03001234567',
                        keyboardType: TextInputType.phone,
                        validator:    (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Phone required hai';
                          if (!RegExp(r'^\+?[0-9]{10,13}$')
                              .hasMatch(v.trim()))
                            return 'Valid phone dalein';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Optional ───────────────────────────────
                const _SectionLabel('Additional Info (Optional)'),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label:      'Address',
                        controller: _address,
                        hint:       'Hayatabad, Peshawar',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        label:        'Credit Limit (Rs)',
                        controller:   _creditLimit,
                        hint:         '50000',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Customer Type dropdown
                const _SectionLabel('Customer Type'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: InputDecoration(
                    filled:        true,
                    fillColor:     AppColor.grey100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        const BorderSide(color: AppColor.grey200)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        const BorderSide(color: AppColor.grey200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColor.primary, width: 1.5)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'walkin',    child: Text('Walk-in')),
                    DropdownMenuItem(value: 'credit',    child: Text('Credit')),
                    DropdownMenuItem(value: 'wholesale', child: Text('Wholesale')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'walkin'),
                ),

                const SizedBox(height: 12),

                _Field(
                  label:      'Notes',
                  controller: _notes,
                  hint:       'Extra notes...',
                  maxLines:   3,
                ),

                const SizedBox(height: 12),

                // Active toggle
                Row(
                  children: [
                    const Text('Active',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColor.textPrimary)),
                    const Spacer(),
                    Switch(
                      value:       _isActive,
                      activeColor: AppColor.primary,
                      onChanged:   (v) => setState(() => _isActive = v),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Save button ────────────────────────────
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
                        : Text(
                        _isEdit ? 'Update Customer' : 'Save Customer',
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
}

// ─────────────────────────────────────────────────────────────
// PRIVATE WIDGETS
// ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize:      12,
            fontWeight:    FontWeight.w600,
            color:         AppColor.textSecondary,
            letterSpacing: 0.5));
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColor.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          cursorHeight: 14,
          style: const TextStyle(fontSize: 14, color: AppColor.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:  const TextStyle(color: AppColor.textHint, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: AppColor.grey100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColor.grey200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColor.grey200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColor.error),
            ),
          ),
        ),
      ],
    );
  }
}