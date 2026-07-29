import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/color/app_color.dart';
import '../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../customer/data/model/customer_model.dart';
import '../../../customer/presentation/widget/customer_action_button_widget.dart';
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
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  int?  _sortColumnIndex;
  bool  _sortAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeId = ref.read(authProvider).storeId ?? '';
      ref.read(customerAccountProvider.notifier).loadCustomers(storeId);
      ref.read(customerAccountProvider.notifier).loadAccounts(storeId);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filter ───────────────────────────────────────────────
  List<CustomerAccountModel> _filtered(List<CustomerAccountModel> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((a) =>
    a.fullName.toLowerCase().contains(q) ||
        a.email.toLowerCase().contains(q)).toList();
  }

  // ── Sort ─────────────────────────────────────────────────
  int _cmp<T extends Comparable>(T a, T b) =>
      _sortAscending ? a.compareTo(b) : b.compareTo(a);

  List<CustomerAccountModel> _sorted(List<CustomerAccountModel> list) {
    if (_sortColumnIndex == null) return list;
    final s = List<CustomerAccountModel>.from(list);
    s.sort((a, b) {
      switch (_sortColumnIndex) {
        case 1: return _cmp(a.fullName.toLowerCase(), b.fullName.toLowerCase());
        case 2: return _cmp(a.email.toLowerCase(),    b.email.toLowerCase());
        case 4: return _cmp(a.createdAt,              b.createdAt);
        default: return 0;
      }
    });
    return s;
  }

  void _onSort(int col, bool asc) =>
      setState(() { _sortColumnIndex = col; _sortAscending = asc; });

  // ── Snack ────────────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColor.error : AppColor.success,
    ));
  }

  // ── Dialogs ──────────────────────────────────────────────
  void _showCreateAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _CreateAccountDialog(
        onSuccess: (name) => _showSnack('Account created for $name'),
        onError:   (err)  => _showSnack(err, isError: true),
      ),
    );
  }

  void _showUpdatePasswordDialog(CustomerAccountModel account) {
    final passCtrl    = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey     = GlobalKey<FormState>();
    bool passVisible  = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(children: [
            const Icon(Icons.lock_reset, color: AppColor.primary, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Update Password',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ]),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColor.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.person_outline,
                        size: 16, color: AppColor.grey500),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(account.fullName,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(account.email,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColor.textSecondary)),
                        ],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
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
                        size: 18, color: AppColor.grey500,
                      ),
                      onPressed: () => setDlg(() => passVisible = !passVisible),
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
                    if (v == null || v.trim().isEmpty) return 'Password is required';
                    if (v.trim().length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
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
                    if (v == null || v.trim().isEmpty) return 'Please confirm password';
                    if (v.trim() != passCtrl.text.trim()) return 'Passwords do not match';
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
            Consumer(builder: (_, ref, __) {
              final saving = ref.watch(customerAccountProvider).saving;
              return ElevatedButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                  if (!formKey.currentState!.validate()) return;
                  final storeId = ref.read(authProvider).storeId ?? '';
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
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.save_outlined, size: 16),
                label: Text(saving ? 'Saving...' : 'Update Password'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerAccountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Accounts',
            style: TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight: 60,
        actions: [
          IconButton(
            onPressed: () {
              final storeId = ref.read(authProvider).storeId ?? '';
              ref.read(customerAccountProvider.notifier).loadAccounts(storeId);
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(foregroundColor: AppColor.textSecondary),
          ),
          const SizedBox(width: 4),
          IntrinsicWidth(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton.icon(
                onPressed: _showCreateAccountDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Add Account',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: state.loadingAccounts
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search bar ─────────────────────────
            SizedBox(
              width: 300,
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 13),
                cursorHeight: 14,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search by name or username...',
                  hintStyle: const TextStyle(
                      color: AppColor.textHint, fontSize: 13),
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: AppColor.grey400),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close,
                        size: 16, color: AppColor.grey500),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: AppColor.grey100,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Table ──────────────────────────────
            Expanded(child: _buildTable(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(CustomerAccountState state) {
    if (state.accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColor.grey300),
            const SizedBox(height: 12),
            const Text('No customer accounts yet',
                style: TextStyle(fontSize: 15, color: AppColor.textSecondary)),
            const SizedBox(height: 6),
            const Text('Tap "Add Account" to create one',
                style: TextStyle(fontSize: 13, color: AppColor.grey400)),
          ],
        ),
      );
    }

    final rows = _sorted(_filtered(state.accounts));

    if (rows.isEmpty) {
      return const Center(
        child: Text('No results found',
            style: TextStyle(fontSize: 14, color: AppColor.textSecondary)),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      const double minTableWidth = 860;
      final tableWidth = constraints.maxWidth > minTableWidth
          ? constraints.maxWidth
          : minTableWidth;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: tableWidth),
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColor.grey100),
              dataRowColor:
              WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.hovered)) {
                  return AppColor.primary.withValues(alpha: 0.05);
                }
                return null;
              }),
              dataRowMinHeight: 52,
              dataRowMaxHeight: 52,
              columnSpacing: (tableWidth * 0.025).clamp(16.0, 48.0),
              showCheckboxColumn: false,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              columns: [
                const DataColumn(label: Text('#', style: _hStyle)),
                DataColumn(
                  label: const Text('Full Name', style: _hStyle),
                  onSort: _onSort,
                ),
                DataColumn(
                  label: const Text('Username', style: _hStyle),
                  onSort: _onSort,
                ),
                const DataColumn(label: Text('Password', style: _hStyle)),
                DataColumn(
                  label: const Text('Created', style: _hStyle),
                  onSort: _onSort,
                ),
                const DataColumn(label: Text('Actions', style: _hStyle)),
              ],
              rows: List.generate(rows.length, (i) {
                final account = rows[i];
                return DataRow(
                  onSelectChanged: (_) {},
                  cells: [
                    // #
                    DataCell(Text(
                      '${i + 1}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColor.textSecondary),
                    )),

                    // Full Name with avatar
                    DataCell(Row(children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor:
                        AppColor.primary.withValues(alpha: 0.12),
                        child: Text(
                          account.fullName.isNotEmpty
                              ? account.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColor.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        account.fullName,
                        style: const TextStyle(
                            color: AppColor.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ])),

                    // Username
                    DataCell(Text(
                      account.email,
                      style: const TextStyle(
                          fontSize: 13, color: AppColor.textSecondary),
                    )),

                    // Password masked + plain
                    DataCell(Row(children: [
                      Text(
                        '•' * account.password.length.clamp(0, 10),
                        style: const TextStyle(
                            fontSize: 16,
                            letterSpacing: 2,
                            color: AppColor.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${account.password})',
                        style: const TextStyle(
                            fontSize: 11, color: AppColor.grey400),
                      ),
                    ])),

                    // Created date
                    DataCell(Text(
                      DateFormat('dd MMM yyyy').format(account.createdAt),
                      style: const TextStyle(
                          fontSize: 12, color: AppColor.textSecondary),
                    )),

                    // Actions
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomerActionButton(
                          icon: Icons.lock_reset,
                          color: AppColor.primary,
                          tooltip: 'Update Password',
                          onTap: () => _showUpdatePasswordDialog(account),
                        ),
                      ],
                    )),
                  ],
                );
              }),
            ),
          ),
        ),
      );
    });
  }
}

// ── Heading style ─────────────────────────────────────────
const _hStyle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  color: AppColor.textPrimary,
);

// ── Create Account Dialog ─────────────────────────────────
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

  // NO auto-fill — user types username manually
  void _onCustomerSelected(CustomerModel? customer) =>
      setState(() => _selectedCustomer = customer);

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
      }) =>
      InputDecoration(
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  Row(children: [
                    const Icon(Icons.person_add_outlined,
                        color: AppColor.primary, size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Create Customer Account',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ]),
                  const Divider(color: AppColor.divider),
                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: AppSearchableDropdown<CustomerModel>(
                      fullWidth: true,
                      label: 'Select Customer',
                      hint: 'Search by name or code...',
                      prefixIcon: Icons.people_outline,
                      value: _selectedCustomer,
                      items: state.customers
                          .map((c) => DropdownItem<CustomerModel>(
                        value: c,
                        label: '${c.name} (${c.code})',
                        icon: Icons.person_outline,
                      ))
                          .toList(),
                      onChanged: _onCustomerSelected,
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

                  TextFormField(
                    controller: _emailCtrl,
                    enabled: !state.saving,
                    style: const TextStyle(fontSize: 14),
                    decoration: _inputDeco(context,
                        label: 'Username / Email',
                        icon: Icons.alternate_email),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Username is required'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _passCtrl,
                    enabled: !state.saving,
                    obscureText: !_passVisible,
                    style: const TextStyle(fontSize: 14),
                    decoration: _inputDeco(context,
                        label: 'Password',
                        icon: Icons.lock_outline)
                        .copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColor.grey500, size: 20,
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

                  TextFormField(
                    controller: _confirmCtrl,
                    enabled: !state.saving,
                    obscureText: !_confirmVisible,
                    style: const TextStyle(fontSize: 14),
                    decoration: _inputDeco(context,
                        label: 'Confirm Password',
                        icon: Icons.lock_outline)
                        .copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _confirmVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColor.grey500, size: 20,
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
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white),
                      )
                          : const Icon(Icons.person_add_outlined,
                          size: 20),
                      label: Text(
                        state.saving
                            ? 'Creating Account...'
                            : 'Create Account',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
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

// ── Customer info tile ────────────────────────────────────
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
                        fontSize: 12, color: AppColor.textSecondary)),
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