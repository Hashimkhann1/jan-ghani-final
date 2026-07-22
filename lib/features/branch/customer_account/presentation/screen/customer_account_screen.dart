import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/color/app_color.dart';
import '../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../customer/data/model/customer_model.dart';
import '../../data/model/customer_account_model.dart';
import '../provider/customer_account_provider.dart';

class CustomerAccountScreen extends ConsumerStatefulWidget {
  const CustomerAccountScreen({super.key});

  @override
  ConsumerState<CustomerAccountScreen> createState() =>
      _CustomerAccountScreenState();
}

class _CustomerAccountScreenState
    extends ConsumerState<CustomerAccountScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeId = ref.read(authProvider).storeId ?? '';
      ref.read(customerAccountProvider.notifier).loadCustomers(storeId);
      ref.read(customerAccountProvider.notifier).loadAccounts(storeId);
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColor.error : AppColor.success,
      ),
    );
  }

  // ── Create Account Dialog ─────────────────────────────────
  void _showCreateAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _CreateAccountDialog(
        onSuccess: (name) {
          _showSnack('Account created for $name');
        },
        onError: (err) {
          _showSnack(err, isError: true);
        },
      ),
    );
  }

  // ── Password update dialog ────────────────────────────────
  void _showUpdatePasswordDialog(CustomerAccountModel account) {
    final passCtrl    = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey     = GlobalKey<FormState>();
    bool passVisible  = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              const Icon(Icons.lock_reset, color: AppColor.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Update Password',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account info
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColor.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 16, color: AppColor.grey500),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.fullName,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              account.email,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColor.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // New password
                TextFormField(
                  controller: passCtrl,
                  obscureText: !passVisible,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline,
                        size: 18, color: AppColor.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        passVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: AppColor.grey500,
                      ),
                      onPressed: () =>
                          setDlg(() => passVisible = !passVisible),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AppColor.primary, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Password is required';
                    }
                    if (v.trim().length < 6) {
                      return 'Minimum 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Confirm password
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: !passVisible,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline,
                        size: 18, color: AppColor.primary),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AppColor.primary, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please confirm password';
                    }
                    if (v.trim() != passCtrl.text.trim()) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColor.grey500)),
            ),
            Consumer(
              builder: (_, ref, __) {
                final saving = ref.watch(customerAccountProvider).saving;
                return ElevatedButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                    if (!formKey.currentState!.validate()) return;
                    final storeId =
                        ref.read(authProvider).storeId ?? '';
                    await ref
                        .read(customerAccountProvider.notifier)
                        .updatePassword(
                      userId:      account.id,
                      newPassword: passCtrl.text.trim(),
                      storeId:     storeId,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: saving
                      ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.save_outlined, size: 16),
                  label:
                  Text(saving ? 'Saving...' : 'Update Password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(customerAccountProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Accounts'),
        actions: [
          IntrinsicWidth(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: _showCreateAccountDialog,
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Add Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildManageBody(state, isDesktop),
    );
  }

  // ── Manage / Table body ───────────────────────────────────
  Widget _buildManageBody(CustomerAccountState state, bool isDesktop) {
    if (state.loadingAccounts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 64, color: AppColor.grey300),
            const SizedBox(height: 12),
            const Text(
              'No customer accounts yet',
              style: TextStyle(
                  fontSize: 15, color: AppColor.textSecondary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap "Add Account" to create one',
              style:
              TextStyle(fontSize: 13, color: AppColor.grey400),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: isDesktop
          ? _buildDesktopTable(state.accounts)
          : _buildMobileCards(state.accounts),
    );
  }

  // ── Desktop DataTable ─────────────────────────────────────
  Widget _buildDesktopTable(List<CustomerAccountModel> accounts) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.border),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          headingRowColor:
          WidgetStateProperty.all(AppColor.primary.withValues(alpha: 0.07)),
          columnSpacing: 120,
          columns: const [
            DataColumn(label: Text('#',           style: _hStyle)),
            DataColumn(label: Text('Full Name',   style: _hStyle)),
            DataColumn(label: Text('Username',    style: _hStyle)),
            DataColumn(label: Text('Password',    style: _hStyle)),
            DataColumn(label: Text('Created',     style: _hStyle)),
            DataColumn(label: Text('Actions',     style: _hStyle)),
          ],
          rows: accounts.asMap().entries.map((entry) {
            final i       = entry.key;
            final account = entry.value;
            return DataRow(
              color: WidgetStateProperty.resolveWith((states) =>
              i.isOdd ? AppColor.grey100.withValues(alpha: 0.5) : Colors.white),
              cells: [
                DataCell(Text('${i + 1}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColor.textSecondary))),
                DataCell(Text(account.fullName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500))),
                DataCell(Text(account.email,
                    style: const TextStyle(
                        fontSize: 13, color: AppColor.textSecondary))),
                DataCell(
                  Row(
                    children: [
                      Text(
                        '•' * account.password.length.clamp(0, 10),
                        style: const TextStyle(
                            fontSize: 16,
                            letterSpacing: 2,
                            color: AppColor.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${account.password})',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColor.grey400),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(
                  DateFormat('dd MMM yyyy').format(account.createdAt),
                  style: const TextStyle(
                      fontSize: 12, color: AppColor.textSecondary),
                )),
                DataCell(
                  IconButton(
                    tooltip: 'Update Password',
                    icon: const Icon(Icons.lock_reset,
                        size: 20, color: AppColor.primary),
                    onPressed: () =>
                        _showUpdatePasswordDialog(account),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Mobile Cards ──────────────────────────────────────────
  Widget _buildMobileCards(List<CustomerAccountModel> accounts) {
    return Column(
      children: accounts.asMap().entries.map((entry) {
        final i       = entry.key;
        final account = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColor.border),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 3,
                  offset: Offset(0, 1)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                AppColor.primary.withValues(alpha: 0.12),
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: AppColor.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.fullName,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.email,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColor.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 12, color: AppColor.grey400),
                        const SizedBox(width: 4),
                        Text(
                          account.password,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColor.grey500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Update Password',
                icon: const Icon(Icons.lock_reset,
                    color: AppColor.primary),
                onPressed: () =>
                    _showUpdatePasswordDialog(account),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Heading style constant ─────────────────────────────────
const _hStyle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  color: AppColor.textPrimary,
);

// ── Create Account Dialog (extracted from old Tab 1) ───────
class _CreateAccountDialog extends ConsumerStatefulWidget {
  const _CreateAccountDialog({
    required this.onSuccess,
    required this.onError,
  });

  final void Function(String customerName) onSuccess;
  final void Function(String error) onError;

  @override
  ConsumerState<_CreateAccountDialog> createState() =>
      _CreateAccountDialogState();
}

class _CreateAccountDialogState
    extends ConsumerState<_CreateAccountDialog> {
  final _formKey     = GlobalKey<FormState>();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _passVisible    = false;
  bool _confirmVisible = false;
  CustomerModel? _selectedCustomer;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _onCustomerSelected(CustomerModel? customer) {
    setState(() => _selectedCustomer = customer);
    if (customer != null) {
      final suggestion =
          '${customer.name.toLowerCase().replaceAll(' ', '.')}'
          '@janghani.com';
      _emailCtrl.text = suggestion;
    }
  }

  Future<void> _submit() async {
    if (_selectedCustomer == null) {
      widget.onError('Please select a customer');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final storeId = ref.read(authProvider).storeId ?? '';
    await ref.read(customerAccountProvider.notifier).createAccount(
      customer: _selectedCustomer!,
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      storeId:  storeId,
    );
  }

  InputDecoration _inputDeco(
      BuildContext context, {
        required String label,
        required IconData icon,
      }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: AppColor.primary),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColor.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColor.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
        const BorderSide(color: AppColor.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColor.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
        const BorderSide(color: AppColor.error, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerAccountProvider);

    ref.listen<CustomerAccountState>(customerAccountProvider, (_, next) {
      if (next.success) {
        final name = _selectedCustomer?.name ?? '';
        ref.read(customerAccountProvider.notifier).resetSuccess();
        widget.onSuccess(name);
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      }
      if (next.error != null) {
        widget.onError(next.error!);
        ref.read(customerAccountProvider.notifier).clearError();
      }
    });

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: state.loadingCustomers
              ? const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          )
              : Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_add_outlined,
                          color: AppColor.primary, size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Create Customer Account',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: AppColor.divider),
                  const SizedBox(height: 8),

                  // Customer selection — forced full width to match text fields
                  SizedBox(
                    width: double.infinity,
                    child: AppSearchableDropdown<CustomerModel>(
                      fullWidth: true,
                      label: 'Select Customer',
                      hint: 'Search by name or code...',
                      prefixIcon: Icons.people_outline,
                      value: _selectedCustomer,
                      items: state.customers
                          .map(
                            (c) => DropdownItem<CustomerModel>(
                          value: c,
                          label: '${c.name} (${c.code})',
                          icon: Icons.person_outline,
                        ),
                      )
                          .toList(),
                      onChanged: (v) => _onCustomerSelected(v),
                      validator: (_) => _selectedCustomer == null
                          ? 'Please select a customer'
                          : null,
                    ),
                  ),
                  if (_selectedCustomer != null) ...[
                    const SizedBox(height: 12),
                    _CustomerInfoTile(customer: _selectedCustomer!),
                  ],
                  const SizedBox(height: 18),

                  // Email / Username
                  TextFormField(
                    controller: _emailCtrl,
                    enabled: !state.saving,
                    style: const TextStyle(fontSize: 14),
                    decoration: _inputDeco(
                      context,
                      label: 'Username / Email',
                      icon: Icons.alternate_email,
                    ),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Username is required'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Password
                  TextFormField(
                    controller: _passCtrl,
                    enabled: !state.saving,
                    obscureText: !_passVisible,
                    style: const TextStyle(fontSize: 14),
                    decoration: _inputDeco(
                      context,
                      label: 'Password',
                      icon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColor.grey500,
                          size: 20,
                        ),
                        onPressed: () => setState(
                                () => _passVisible = !_passVisible),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Password is required';
                      }
                      if (v.trim().length < 6) {
                        return 'Minimum 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Confirm password
                  TextFormField(
                    controller: _confirmCtrl,
                    enabled: !state.saving,
                    obscureText: !_confirmVisible,
                    style: const TextStyle(fontSize: 14),
                    decoration: _inputDeco(
                      context,
                      label: 'Confirm Password',
                      icon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _confirmVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColor.grey500,
                          size: 20,
                        ),
                        onPressed: () => setState(() =>
                        _confirmVisible = !_confirmVisible),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please confirm password';
                      }
                      if (v.trim() != _passCtrl.text.trim()) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: state.saving ? null : _submit,
                      icon: state.saving
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.person_add_outlined,
                          size: 20),
                      label: Text(
                        state.saving
                            ? 'Creating Account...'
                            : 'Create Account',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Customer info tile ─────────────────────────────────────
class _CustomerInfoTile extends StatelessWidget {
  const _CustomerInfoTile({required this.customer});
  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppColor.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColor.primary.withValues(alpha: 0.15),
            child: Text(
              customer.name.isNotEmpty
                  ? customer.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppColor.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(customer.phone,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColor.textSecondary)),
                if (customer.address != null &&
                    customer.address!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(customer.address!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColor.textSecondary)),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: customer.isClear
                  ? AppColor.grey100
                  : customer.hasBalance
                  ? AppColor.error.withValues(alpha: 0.1)
                  : AppColor.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: customer.isClear
                    ? AppColor.grey300
                    : customer.hasBalance
                    ? AppColor.error.withValues(alpha: 0.4)
                    : AppColor.success.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              customer.balanceLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: customer.isClear
                    ? AppColor.grey500
                    : customer.hasBalance
                    ? AppColor.error
                    : AppColor.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}