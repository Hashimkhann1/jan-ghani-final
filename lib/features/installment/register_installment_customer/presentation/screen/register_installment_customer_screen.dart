import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/installment/installment_calculator/presentation/screen/installment_calculator_screen.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/presentation/provider/installment_dashboard_provider.dart';
import 'package:jan_ghani_final/features/installment/register_installment_customer/domain/new_installment_customer.dart';

/// Naya installment customer register karne ki screen — database mein save
/// hota hai (amount default 0).
class RegisterInstallmentCustomerScreen extends ConsumerStatefulWidget {
  const RegisterInstallmentCustomerScreen({super.key});

  @override
  ConsumerState<RegisterInstallmentCustomerScreen> createState() =>
      _RegisterInstallmentCustomerScreenState();
}

class _RegisterInstallmentCustomerScreenState
    extends ConsumerState<RegisterInstallmentCustomerScreen> {
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

  bool _saving = false;

  Future<void> _onSave() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack('Enter the customer name');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final id = await ref.read(installmentRemoteProvider).registerCustomer(
            NewInstallmentCustomer(
              name: name,
              phone: _phoneController.text.trim(),
              cnic: _cnicController.text.trim(),
              address: _addressController.text.trim(),
            ),
          );
      if (!mounted) return;
      refreshInstallments(ref);

      final createPlan = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Customer added'),
          content: Text('$name has been added. Create an installment plan now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create plan'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (createPlan == true) {
        await Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => InstallmentCalculatorScreen(customerId: id),
        ));
      } else {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) _snack('$e'.replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

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
          onPressed: _saving ? null : _onSave,
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
          onPressed: _saving ? null : _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: AppColor.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.person_add_alt_1, size: 20),
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
