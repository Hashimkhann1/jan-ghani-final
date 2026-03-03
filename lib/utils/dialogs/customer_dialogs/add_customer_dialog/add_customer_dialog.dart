import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jan_ghani_final/utils/app_colors/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHOW HELPER
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showAddCustomerDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AddCustomerDialog(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  static const _border = Color(0xFFE9ECEF);
  static const _subText = Color(0xFF6C757D);
  static const _headerText = Color(0xFF212529);
  static const _tabBg = Color(0xFFF0F0F0);

  int _currentTab = 0; // 0=Details, 1=Credit, 2=Info

  // ── Details fields ────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // ── Credit fields ─────────────────────────────────────────────────────────
  bool _creditEnabled = false;
  final _creditLimitCtrl = TextEditingController(text: '0');
  final _currentCreditCtrl = TextEditingController(text: '0');

  bool get _canProceedFromDetails => _nameCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _creditLimitCtrl.dispose();
    _currentCreditCtrl.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentTab < 2) setState(() => _currentTab++);
  }

  void _onBack() {
    if (_currentTab > 0) setState(() => _currentTab--);
  }

  void _onCreate() {
    // TODO: wire to backend
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 120, vertical: 60),
      child: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildTabs(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: _buildContent(),
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
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 22, color: _headerText),
          const SizedBox(width: 10),
          const Text('Add Customer',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: _headerText)),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20, color: _subText),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: _tabBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _TabBtn(label: 'Details', index: 0, selected: _currentTab,
                onTap: (i) => setState(() => _currentTab = i)),
            _TabBtn(label: 'Credit', index: 1, selected: _currentTab,
                onTap: (i) => setState(() => _currentTab = i)),
            _TabBtn(label: 'Info', index: 2, selected: _currentTab,
                onTap: (i) => setState(() => _currentTab = i)),
          ],
        ),
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────
  Widget _buildContent() {
    switch (_currentTab) {
      case 0:
        return _buildDetails();
      case 1:
        return _buildCredit();
      case 2:
        return _buildInfo();
      default:
        return const SizedBox();
    }
  }

  // ── Details Tab ───────────────────────────────────────────────────────────
  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name *
        _fieldLabel('Name *'),
        const SizedBox(height: 6),
        _inputField(_nameCtrl, 'Customer name', onChanged: (_) => setState(() {})),
        const SizedBox(height: 16),
        // Email + Phone
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Email'),
                  const SizedBox(height: 6),
                  _inputField(_emailCtrl, 'email@example.com',
                      keyboardType: TextInputType.emailAddress),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Phone'),
                  const SizedBox(height: 6),
                  _inputField(_phoneCtrl, '+1 234 567 8900',
                      keyboardType: TextInputType.phone),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Address
        Row(children: const [
          Icon(Icons.location_on_outlined, size: 15, color: _subText),
          SizedBox(width: 6),
          Text('Address',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _headerText)),
        ]),
        const SizedBox(height: 6),
        _textAreaField(_addressCtrl, 'Street address, city, state...', minLines: 3),
        const SizedBox(height: 16),
        // Notes
        _fieldLabel('Notes'),
        const SizedBox(height: 6),
        _textAreaField(_notesCtrl, 'Any additional notes...', minLines: 3),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Credit Tab ────────────────────────────────────────────────────────────
  Widget _buildCredit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enable Credit toggle card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.credit_card_outlined,
                    size: 20, color: AppColors.primaryColors),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Enable Credit',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _headerText)),
                    SizedBox(height: 2),
                    Text('Allow this customer to purchase on credit',
                        style: TextStyle(fontSize: 12, color: _subText)),
                  ],
                ),
              ),
              Switch(
                value: _creditEnabled,
                onChanged: (v) => setState(() => _creditEnabled = v),
                activeColor: AppColors.primaryColors,
              ),
            ],
          ),
        ),
        // Credit fields — only visible when enabled
        if (_creditEnabled) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Credit Limit
                _fieldLabel('Credit Limit'),
                const SizedBox(height: 8),
                _numberField(_creditLimitCtrl),
                const SizedBox(height: 6),
                const Text('Maximum amount customer can owe at any time',
                    style: TextStyle(fontSize: 11, color: _subText)),
                const SizedBox(height: 16),
                // Current Credit
                _fieldLabel('Current Credit'),
                const SizedBox(height: 8),
                _numberField(_currentCreditCtrl),
                const SizedBox(height: 6),
                const Text('Current outstanding credit balance',
                    style: TextStyle(fontSize: 11, color: _subText)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Info Tab ──────────────────────────────────────────────────────────────
  Widget _buildInfo() {
    final creditLimit = double.tryParse(_creditLimitCtrl.text) ?? 0;
    final currentCredit = double.tryParse(_currentCreditCtrl.text) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        // Customer summary card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + name
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(
                        color: Color(0xFFECFDF5), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(_nameCtrl.text.trim()),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColors),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameCtrl.text.trim().isEmpty ? '—' : _nameCtrl.text.trim(),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700, color: _headerText),
                      ),
                      const SizedBox(height: 2),
                      const Text('New Customer',
                          style: TextStyle(fontSize: 12, color: _subText)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Details section
        _infoSection('Contact Details', [
          _infoRow(Icons.person_outline, 'Name',
              _nameCtrl.text.trim().isEmpty ? '—' : _nameCtrl.text.trim()),
          _infoRow(Icons.email_outlined, 'Email',
              _emailCtrl.text.trim().isEmpty ? '—' : _emailCtrl.text.trim()),
          _infoRow(Icons.phone_outlined, 'Phone',
              _phoneCtrl.text.trim().isEmpty ? '—' : _phoneCtrl.text.trim()),
          _infoRow(Icons.location_on_outlined, 'Address',
              _addressCtrl.text.trim().isEmpty ? '—' : _addressCtrl.text.trim()),
          if (_notesCtrl.text.trim().isNotEmpty)
            _infoRow(Icons.notes_outlined, 'Notes', _notesCtrl.text.trim()),
        ]),
        const SizedBox(height: 12),
        // Credit section
        _infoSection('Credit', [
          _infoRow(
            Icons.credit_card_outlined,
            'Credit Enabled',
            _creditEnabled ? 'Yes' : 'No',
            valueColor: _creditEnabled ? AppColors.primaryColors : _subText,
          ),
          if (_creditEnabled) ...[
            _infoRow(Icons.account_balance_wallet_outlined, 'Credit Limit',
                'Rs ${creditLimit.toStringAsFixed(2)}'),
            _infoRow(Icons.receipt_outlined, 'Current Credit',
                'Rs ${currentCredit.toStringAsFixed(2)}'),
          ],
        ]),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    final isLastTab = _currentTab == 2;
    final isFirstTab = _currentTab == 0;

    // On Details tab: Next button disabled until name is filled
    final bool nextEnabled = _currentTab == 0 ? _canProceedFromDetails : true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Back button (hidden on first tab)
          if (!isFirstTab)
            OutlinedButton(
              onPressed: _onBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: _headerText,
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Back'),
            ),
          if (!isFirstTab) const SizedBox(width: 10),
          // Cancel button (only on first tab)
          if (isFirstTab)
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: _headerText,
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel'),
            ),
          if (isFirstTab) const SizedBox(width: 10),
          // Next / Create Customer
          ElevatedButton(
            onPressed: nextEnabled ? (isLastTab ? _onCreate : _onNext) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: nextEnabled
                  ? AppColors.primaryColors
                  : AppColors.primaryColors.withOpacity(0.5),
              foregroundColor: AppColors.whiteColor,
              disabledBackgroundColor: AppColors.primaryColors.withOpacity(0.5),
              disabledForegroundColor: AppColors.whiteColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isLastTab ? 'Create Customer' : 'Next'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  Widget _fieldLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: _headerText));
  }

  Widget _inputField(
      TextEditingController ctrl,
      String hint, {
        TextInputType keyboardType = TextInputType.text,
        ValueChanged<String>? onChanged,
      }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBDBDBD)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryColors, width: 1.5)),
      ),
    );
  }

  Widget _textAreaField(TextEditingController ctrl, String hint,
      {int minLines = 3}) {
    return TextField(
      controller: ctrl,
      minLines: minLines,
      maxLines: null,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBDBDBD)),
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryColors, width: 1.5)),
      ),
    );
  }

  Widget _numberField(TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        // Prevent multiple decimal points
        TextInputFormatter.withFunction((oldValue, newValue) {
          final text = newValue.text;
          if (text.isEmpty) return newValue;
          if (text == '.') return newValue.copyWith(text: '0.');
          final dotCount = text.split('.').length - 1;
          if (dotCount > 1) return oldValue;
          return newValue;
        }),
      ],
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryColors, width: 1.5)),
        suffixIcon: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                final v = double.tryParse(ctrl.text) ?? 0;
                ctrl.text = (v + 1).toStringAsFixed(0);
              },
              child: const Icon(Icons.keyboard_arrow_up, size: 16, color: Color(0xFF9E9E9E)),
            ),
            GestureDetector(
              onTap: () {
                final v = double.tryParse(ctrl.text) ?? 0;
                if (v > 0) ctrl.text = (v - 1).toStringAsFixed(0);
              },
              child: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF9E9E9E)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoSection(String title, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _headerText)),
          ),
          const Divider(height: 1, color: Color(0xFFE9ECEF)),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: _subText),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: _subText)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? _headerText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  final String label;
  final int index;
  final int selected;
  final ValueChanged<int> onTap;

  const _TabBtn({
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.whiteColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: AppColors.primaryColors, width: 1.5)
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                color: isSelected ? const Color(0xFF212529) : const Color(0xFF6C757D),
              ),
            ),
          ),
        ),
      ),
    );
  }
}