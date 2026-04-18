import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/branch/counter/data/model/counter_model.dart';
import 'package:jan_ghani_final/features/branch/counter/presentation/provider/counter_provider.dart';
import '../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../data/model/user_model.dart';
import '../provider/user_provider.dart';

class AddUserDialog extends ConsumerStatefulWidget {
  final UserModel? user;
  const AddUserDialog({super.key, this.user});

  @override
  ConsumerState<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<AddUserDialog> {
  final _formKey  = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _phone    = TextEditingController();
  final _password = TextEditingController();
  String  _role          = 'cashier';
  bool    _isActive      = true;
  bool    _isSaving      = false;
  bool    _showPass      = false;
  CounterModel? _selectedCounter; // ← new

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    if (u != null) {
      _fullName.text = u.fullName;
      _username.text = u.username;
      _phone.text    = u.phone ?? '';
      _role          = u.role;
      _isActive      = u.isActive;
    }

    // Edit mein counter pre-select karo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (u?.counterId != null) {
        final counters = ref.read(counterProvider).counters;
        try {
          _selectedCounter = counters
              .firstWhere((c) => c.id == u!.counterId);
          setState(() {});
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(userProvider.notifier);

    try {
      if (_isEdit) {
        await notifier.updateUser(widget.user!.copyWith(
          fullName:     _fullName.text.trim(),
          phone:        _phone.text.trim().isEmpty
              ? null
              : _phone.text.trim(),
          role:         _role,
          isActive:     _isActive,
          counterId:    _selectedCounter?.id,  // ← new
          clearCounter: _selectedCounter == null, // ← null set karo
          passwordHash: _password.text.isNotEmpty
              ? _password.text
              : widget.user!.passwordHash,
        ));
      } else {
        await notifier.addUser(
          username:  _username.text.trim(),
          password:  _password.text,
          fullName:  _fullName.text.trim(),
          phone:     _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          role:      _role,
          isActive:  _isActive,
          counterId: _selectedCounter?.id,     // ← new
        );
      }

      final hasError = ref.read(userProvider).errorMessage != null;
      if (!hasError && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final counters = ref.watch(counterProvider).counters;

    final counterItems = [
      // None option
      const DropdownItem<CounterModel?>(
        value: null,
        label: 'No Counter',
        icon:  Icons.block_outlined,
      ),
      ...counters.map((c) => DropdownItem<CounterModel?>(
        value: c,
        label: c.counterName,
        icon:  Icons.point_of_sale_outlined,
      )),
    ];

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

                // ── Header ───────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color:        AppColor.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
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
                        Text(_isEdit ? 'Edit User' : 'New User',
                            style: const TextStyle(
                                fontSize:   16,
                                fontWeight: FontWeight.w700)),
                        const Text('User ki details bharein',
                            style: TextStyle(
                                fontSize: 12,
                                color:    AppColor.textSecondary)),
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

                // ── Required ─────────────────────────────
                const _Label('Required Info'),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label:     'Full Name *',
                        controller: _fullName,
                        hint:      'Ahmad Khan',
                        validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Name required hai'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        label:      'Username *',
                        controller: _username,
                        hint:       'ahmad_khan',
                        enabled:    !_isEdit,
                        validator:  (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Username required hai';
                          if (v.trim().length < 3)
                            return 'Minimum 3 characters chahiye';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Password ──────────────────────────────
                _Label(_isEdit
                    ? 'New Password (khali chorein agar change na karna ho)'
                    : 'Password *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller:   _password,
                  obscureText:  !_showPass,
                  cursorHeight: 14,
                  style: const TextStyle(
                      fontSize: 14, color: AppColor.textPrimary),
                  validator: (v) {
                    if (!_isEdit && (v == null || v.isEmpty))
                      return 'Password required hai';
                    if (v != null && v.isNotEmpty && v.length < 6)
                      return 'Minimum 6 characters chahiye';
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText:  _isEdit
                        ? 'Naya password (optional)'
                        : '••••••••',
                    hintStyle: const TextStyle(
                        color: AppColor.textHint, fontSize: 13),
                    filled:    true,
                    fillColor: AppColor.grey100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18, color: AppColor.grey400,
                      ),
                      onPressed: () =>
                          setState(() => _showPass = !_showPass),
                    ),
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
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        const BorderSide(color: AppColor.error)),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Optional ─────────────────────────────
                const _Label('Additional Info (Optional)'),
                const SizedBox(height: 10),

                _Field(
                  label:        'Phone',
                  controller:   _phone,
                  hint:         '03001234567',
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 12),

                // ── Role ─────────────────────────────────
                const _Label('Role *'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: InputDecoration(
                    filled:    true,
                    fillColor: AppColor.grey100,
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
                    DropdownMenuItem(
                        value: 'store_owner',
                        child: Text('Store Owner')),
                    DropdownMenuItem(
                        value: 'store_manager',
                        child: Text('Store Manager')),
                    DropdownMenuItem(
                        value: 'cashier',
                        child: Text('Cashier')),
                    DropdownMenuItem(
                        value: 'stock_officer',
                        child: Text('Stock Officer')),
                  ],
                  onChanged: (v) =>
                      setState(() => _role = v ?? 'cashier'),
                ),

                const SizedBox(height: 12),

                // ── Counter Assign ────────────────────────
                const _Label('Assign Counter (Optional)'),
                const SizedBox(height: 6),
                AppSearchableDropdown<CounterModel?>(
                  items:     counterItems,
                  value:     _selectedCounter,
                  hint:      'Counter select karein...',
                  fullWidth: true,
                  onChanged: (v) =>
                      setState(() => _selectedCounter = v),
                ),

                const SizedBox(height: 12),

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
                      const Text('Active User',
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

                // ── Save Button ───────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:         AppColor.primary,
                      foregroundColor:         AppColor.white,
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
                        _isEdit ? 'Update User' : 'Save User',
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

// ── Private Widgets ───────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize:      12,
          fontWeight:    FontWeight.w600,
          color:         AppColor.textSecondary,
          letterSpacing: 0.5));
}

class _Field extends StatelessWidget {
  final String                     label;
  final TextEditingController      controller;
  final String                     hint;
  final TextInputType              keyboardType;
  final String? Function(String?)? validator;
  final bool                       enabled;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w500,
                color:      AppColor.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller:   controller,
          keyboardType: keyboardType,
          validator:    validator,
          enabled:      enabled,
          cursorHeight: 14,
          style: TextStyle(
              fontSize: 14,
              color:    enabled
                  ? AppColor.textPrimary
                  : AppColor.textSecondary),
          decoration: InputDecoration(
            hintText:  hint,
            hintStyle: const TextStyle(
                color: AppColor.textHint, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            filled:    true,
            fillColor: enabled ? AppColor.grey100 : AppColor.grey200,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                const BorderSide(color: AppColor.grey200)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                const BorderSide(color: AppColor.grey200)),
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                const BorderSide(color: AppColor.grey200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: AppColor.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                const BorderSide(color: AppColor.error)),
          ),
        ),
      ],
    );
  }
}