import 'package:flutter/material.dart';
import 'package:jan_ghani_final/model/warehouse_model/warehouse_model.dart';
import 'package:jan_ghani_final/utils/app_colors/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHOW HELPERS
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showCreateWarehouseDialog(
    BuildContext context, {
      required void Function(WarehouseModel) onSave,
    }) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _WarehouseFormDialog(onSave: onSave),
  );
}

Future<void> showEditWarehouseDialog(
    BuildContext context, {
      required WarehouseModel warehouse,
      required void Function(WarehouseModel) onSave,
    }) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _WarehouseFormDialog(existing: warehouse, onSave: onSave),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _WarehouseFormDialog extends StatefulWidget {
  final WarehouseModel? existing;
  final void Function(WarehouseModel) onSave;

  const _WarehouseFormDialog({
    this.existing,
    required this.onSave,
  });

  @override
  State<_WarehouseFormDialog> createState() =>
      _WarehouseFormDialogState();
}

class _WarehouseFormDialogState extends State<_WarehouseFormDialog> {
  static const _green = AppColors.primaryColors;
  static const _border = Color(0xFFE0E0E0);
  static const _labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1A1A1A),
  );
  static const _hintStyle = TextStyle(
    fontSize: 14,
    color: Color(0xFFBBBBBB),
  );

  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool get _isEdit => widget.existing != null;
  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
          _codeCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final w = widget.existing!;
      _nameCtrl.text = w.name;
      _codeCtrl.text = w.code;
      _addressCtrl.text = w.address ?? '';
      _phoneCtrl.text = w.phone ?? '';
      _emailCtrl.text = w.email ?? '';
      _notesCtrl.text = w.notes ?? '';
    }
    // Rebuild when name/code change to toggle button state
    _nameCtrl.addListener(() => setState(() {}));
    _codeCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_canSave) return;
    final w = WarehouseModel(
      id: _isEdit
          ? widget.existing!.id
          : DateTime.now().millisecondsSinceEpoch,
      name: _nameCtrl.text.trim(),
      code: _codeCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty
          ? null
          : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty
          ? null
          : _emailCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
      productCount: _isEdit ? widget.existing!.productCount : 0,
      unitCount: _isEdit ? widget.existing!.unitCount : 0,
      lowStockCount: _isEdit ? widget.existing!.lowStockCount : 0,
    );
    widget.onSave(w);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 100, vertical: 60),
      child: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                child: _buildFields(),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isEdit ? 'Edit Warehouse' : 'Create Warehouse',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close,
                size: 22, color: Color(0xFF888888)),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  // ── Fields ────────────────────────────────────────────────────────────────
  Widget _buildFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Name + Code row ─────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Name *'),
                  const SizedBox(height: 8),
                  _inputField(
                    _nameCtrl,
                    hint: 'Main Warehouse',
                    autofocus: true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Code *'),
                  const SizedBox(height: 8),
                  _inputField(_codeCtrl, hint: 'WH01'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // ── Address ─────────────────────────────────────────────────
        _fieldLabel('Address'),
        const SizedBox(height: 8),
        _inputField(_addressCtrl, hint: 'Warehouse address'),
        const SizedBox(height: 18),
        // ── Phone + Email row ────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Phone'),
                  const SizedBox(height: 8),
                  _inputField(
                    _phoneCtrl,
                    hint: 'Phone',
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Email'),
                  const SizedBox(height: 8),
                  _inputField(
                    _emailCtrl,
                    hint: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // ── Notes ────────────────────────────────────────────────────
        _fieldLabel('Notes'),
        const SizedBox(height: 8),
        _textAreaField(_notesCtrl, hint: 'Additional notes...'),
        const SizedBox(height: 4),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Cancel
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A1A),
              side: const BorderSide(color: Color(0xFFDDDDDD)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          // Create / Save
          ElevatedButton(
            onPressed: _canSave ? _save : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canSave
                  ? _green
                  : _green.withOpacity(0.5),
              disabledBackgroundColor: _green.withOpacity(0.5),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            child: Text(_isEdit ? 'Save Changes' : 'Create'),
          ),
        ],
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────
  Widget _fieldLabel(String text) => Text(text, style: _labelStyle);

  Widget _inputField(
      TextEditingController ctrl, {
        required String hint,
        bool autofocus = false,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextField(
      controller: ctrl,
      autofocus: autofocus,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _hintStyle,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _textAreaField(
      TextEditingController ctrl, {
        required String hint,
      }) {
    return TextField(
      controller: ctrl,
      minLines: 4,
      maxLines: 6,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _hintStyle,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}