import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';

/// Naya installment customer register karne ki screen (sirf UI — koi DB nahi).
class RegisterInstallmentCustomerScreen extends StatefulWidget {
  const RegisterInstallmentCustomerScreen({super.key});

  @override
  State<RegisterInstallmentCustomerScreen> createState() =>
      _RegisterInstallmentCustomerScreenState();
}

class _RegisterInstallmentCustomerScreenState
    extends State<RegisterInstallmentCustomerScreen> {
  static const Color _canvas = Color(0xFFF7F7F9);

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onSave() {
    // Abhi sirf UI — yahan baad mein save logic aayega.
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer saved (UI demo)')),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                children: [
                  _LabeledField(
                    label: 'Customer Name',
                    controller: _nameController,
                    hint: 'e.g. Adnan Ahmad',
                    textCapitalization: TextCapitalization.words,
                  ),
                  18.hBox,
                  _LabeledField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    hint: '+92 300 0000000',
                    keyboardType: TextInputType.phone,
                  ),
                  18.hBox,
                  _LabeledField(
                    label: 'CNIC',
                    controller: _cnicController,
                    hint: '42101-XXXXXXX-X',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                    ],
                  ),
                  18.hBox,
                  _LabeledField(
                    label: 'Address',
                    controller: _addressController,
                    hint: 'Street address, City',
                    textCapitalization: TextCapitalization.words,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // ── Top app bar (X · New Customer · Save) ────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColor.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: AppColor.surface,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColor.textPrimary),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const Text(
        'New Customer',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColor.textPrimary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _onSave,
          child: const Text(
            'Save',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColor.primary,
            ),
          ),
        ),
        4.wBox,
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColor.grey200),
      ),
    );
  }

  // ── Bottom primary action ────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: _canvas,
        border: Border(top: BorderSide(color: AppColor.grey200)),
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: AppColor.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.person_add_alt_1, size: 20),
          label: const Text(
            'Save Customer',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

/// Label + input field (form ka ek row).
class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
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
            fontWeight: FontWeight.w600,
            color: AppColor.textPrimary,
          ),
        ),
        8.hBox,
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: AppColor.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 14),
            filled: true,
            fillColor: AppColor.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColor.grey300),
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
