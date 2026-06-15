import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../../../branch/authentication/presentation/provider/auth_provider.dart';
import '../../../../authentication/presentation/providers/accoutant_session_provider.dart';
import '../../../branch_report_list_screen.dart';
import '../../data/model/accountant_branch_model.dart';
import '../provider/accounttant_branch_provider.dart';

class BranchScreen extends ConsumerStatefulWidget {
  const BranchScreen({super.key});

  @override
  ConsumerState<BranchScreen> createState() => _BranchScreenState();
}

class _BranchScreenState extends ConsumerState<BranchScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 800;

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(branchProvider);
    final notifier = ref.read(branchProvider.notifier);
    final desktop  = _isDesktop(context);

    final isOwner = ref.watch(authProvider).role == 'owner';
    final userBranchId = ref.watch(currentBranchIdProvider);

    final visibleBranches = isOwner ? state.filtered : state.filtered.where((b) => b.id == userBranchId).toList();

    ref.listen<BranchState>(branchProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text(next.errorMessage!),
          backgroundColor: AppColor.error,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label:     'OK',
            textColor: Colors.white,
            onPressed: notifier.clearError,
          ),
        ));
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      floatingActionButton: (!desktop && isOwner) ?
      FloatingActionButton.extended(
        onPressed: () => showAddBranchDialog(context, notifier),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        icon:  const Icon(Icons.add_rounded),
        label: const Text('Add Branch'),
      ) :
      null,
      body: desktop ?
      _DesktopLayout(
        state:      state,
        notifier:   notifier,
        searchCtrl: _searchCtrl,
        isOwner:    isOwner,
        branches:   visibleBranches,
      ) : _MobileLayout(
        state:      state,
        notifier:   notifier,
        searchCtrl: _searchCtrl,
        branches:   visibleBranches,
      ),
    );
  }
}

// ── Desktop Layout ────────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final BranchState state;
  final dynamic notifier;
  final TextEditingController searchCtrl;
  final bool isOwner;
  final List<BranchModel> branches;

  const _DesktopLayout({
    required this.state,
    required this.notifier,
    required this.searchCtrl,
    required this.isOwner,
    required this.branches,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top bar ──────────────────────────────────────────
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Branches',
                    style: TextStyle(
                      fontSize:   22,
                      fontWeight: FontWeight.w700,
                      color:      Color(0xFF1A1D23),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Click on any report to view details',
                    style: TextStyle(fontSize: 13, color: AppColor.textHint),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 280,
                child: _SearchField(
                  controller: searchCtrl,
                  query:      state.searchQuery,
                  onChanged:  notifier.search,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: OutlinedButton.icon(
                  onPressed: notifier.load,
                  icon:  const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.primary,
                    side: const BorderSide(color: AppColor.primary),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              // ✅ Add Branch button — sirf owner ko dikhe
              if (isOwner) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 150,
                  child: ElevatedButton.icon(
                    onPressed: () => showAddBranchDialog(context, notifier),
                    icon:  const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Branch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // ── Stats row ────────────────────────────────────────
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 14),
          child: Row(
            children: [
              _StatPill(
                icon:  Icons.store_rounded,
                label: 'Total Branches',
                value: '${branches.length}',
              ),
              const SizedBox(width: 16),
              if (state.searchQuery.isNotEmpty)
                _StatPill(
                  icon:  Icons.search_rounded,
                  label: 'Search results',
                  value: '${branches.length}',
                  color: AppColor.primary,
                ),
            ],
          ),
        ),

        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // ── Content ──────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : branches.isEmpty
              ? const _EmptyState()
              : _DesktopGrid(branches: branches),
        ),
      ],
    );
  }
}

// ── Desktop Grid ──────────────────────────────────────────────────────────────
class _DesktopGrid extends StatelessWidget {
  final List<BranchModel> branches;
  const _DesktopGrid({required this.branches});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 340,
          mainAxisExtent:     130,
          crossAxisSpacing:   16,
          mainAxisSpacing:    16,
        ),
        itemCount: branches.length,
        itemBuilder: (_, i) => _BranchGridCard(branch: branches[i]),
      ),
    );
  }
}

// ── Branch Grid Card (Desktop) ────────────────────────────────────────────────
class _BranchGridCard extends StatelessWidget {
  final BranchModel branch;
  const _BranchGridCard({required this.branch});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BranchReportListScreen(branchId: branch.id),
        ),
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Container(
              width:  48,
              height: 48,
              decoration: BoxDecoration(
                color:        AppColor.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.store_mall_directory_rounded,
                  color: AppColor.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:  MainAxisAlignment.center,
                children: [
                  Text(
                    branch.name,
                    style: const TextStyle(
                      fontSize:   15,
                      fontWeight: FontWeight.w700,
                      color:      Color(0xFF1A1D23),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          branch.code,
                          style: const TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w600,
                            color:      AppColor.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          branch.address,
                          style: const TextStyle(
                              fontSize: 12, color: AppColor.textHint),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.arrow_forward_rounded,
                          size: 13, color: AppColor.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Report',
                        style: TextStyle(
                          fontSize:   12,
                          color:      AppColor.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Pill ─────────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColor.textHint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: AppColor.textHint),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize:   13,
            fontWeight: FontWeight.w600,
            color:      color == AppColor.textHint
                ? const Color(0xFF1A1D23)
                : color,
          ),
        ),
      ],
    );
  }
}

// ── Mobile Layout ─────────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final BranchState state;
  final dynamic notifier;
  final TextEditingController searchCtrl;
  final List<BranchModel> branches;

  const _MobileLayout({
    required this.state,
    required this.notifier,
    required this.searchCtrl,
    required this.branches,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating:         true,
          backgroundColor:  Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation:        0,
          title: const Text(
            'Branches',
            style: TextStyle(
              fontSize:   20,
              fontWeight: FontWeight.w800,
              color:      Color(0xFF1A1D23),
            ),
          ),
          actions: [
            IconButton(
              onPressed: notifier.load,
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColor.textSecondary),
              tooltip: 'Refresh',
            ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: Container(
              color:   Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _SearchField(
                controller: searchCtrl,
                query:      state.searchQuery,
                onChanged:  notifier.search,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Click on any report to view details',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ),
        ),
        if (state.isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (branches.isEmpty)
          const SliverFillRemaining(child: _EmptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            sliver: SliverList.separated(
              itemCount:        branches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) =>
                  _BranchListCard(branch: branches[i]),
            ),
          ),
      ],
    );
  }
}

// ── Search Field (shared) ─────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:  controller,
      onChanged:   onChanged,
      style: const TextStyle(fontSize: 14),
      cursorHeight: 16,
      decoration: InputDecoration(
        hintText: 'Search Branch',
        hintStyle: const TextStyle(fontSize: 13, color: AppColor.textHint),
        prefixIcon: const Icon(Icons.search_rounded,
            size: 20, color: AppColor.primary),
        suffixIcon: query.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear_rounded,
              size: 18, color: AppColor.textHint),
          onPressed: () {
            controller.clear();
            onChanged('');
          },
        )
            : null,
        filled:    true,
        fillColor: AppColor.grey100,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   const BorderSide(color: AppColor.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ── Branch List Card (Mobile) ─────────────────────────────────────────────────
class _BranchListCard extends StatelessWidget {
  final BranchModel branch;
  const _BranchListCard({required this.branch});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 6),
        leading: Container(
          width:  46,
          height: 46,
          decoration: BoxDecoration(
            color:        AppColor.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.store_mall_directory_rounded,
              color: AppColor.primary, size: 22),
        ),
        title: Text(
          branch.name,
          style: const TextStyle(
            fontSize:   14,
            fontWeight: FontWeight.w700,
            color:      Color(0xFF1A1D23),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            '${branch.code}  •  ${branch.address}',
            style: const TextStyle(fontSize: 12, color: AppColor.textHint),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColor.textHint),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BranchReportListScreen(branchId: branch.id),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.store_mall_directory_outlined,
            size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          'Koi branch nahi mili',
          style: TextStyle(
            fontSize:   16,
            fontWeight: FontWeight.w600,
            color:      Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Search change karein',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
      ],
    ),
  );
}

// ── Add Branch Dialog ─────────────────────────────────────────────────────────
void showAddBranchDialog(BuildContext context, dynamic notifier) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AddBranchDialog(notifier: notifier),
  );
}

class _AddBranchDialog extends StatefulWidget {
  final dynamic notifier;
  const _AddBranchDialog({required this.notifier});

  @override
  State<_AddBranchDialog> createState() => _AddBranchDialogState();
}

class _AddBranchDialogState extends State<_AddBranchDialog> {
  final _formKey   = GlobalKey<FormState>();
  final _codeCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  final _addrCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _codeCtrl.text = widget.notifier.nextBranchCode();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final ok = await widget.notifier.addBranch(
      code:    _codeCtrl.text,
      name:    _nameCtrl.text,
      address: _addrCtrl.text,
      phone:   _phoneCtrl.text,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         const Text('Branch successfully add ho gayi ✅'),
        backgroundColor: Colors.green.shade600,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width:  42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_business_rounded,
                          color: AppColor.primary),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'New Branch',
                      style: TextStyle(
                        fontSize:   18,
                        fontWeight: FontWeight.w700,
                        color:      Color(0xFF1A1D23),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColor.textHint),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _field(
                  controller: _codeCtrl,
                  label: 'Branch Code',
                  hint:  'e.g. BR-002',
                  icon:  Icons.qr_code_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Code zaroori hai'
                      : null,
                ),
                const SizedBox(height: 14),

                _field(
                  controller: _nameCtrl,
                  label: 'Branch Name',
                  hint:  'e.g. Jan Ghani',
                  icon:  Icons.store_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name zaroori hai'
                      : null,
                ),
                const SizedBox(height: 14),

                _field(
                  controller: _addrCtrl,
                  label: 'Address',
                  hint:  'e.g. Mardan Road, Charsadda',
                  icon:  Icons.location_on_rounded,
                ),
                const SizedBox(height: 14),

                _field(
                  controller: _phoneCtrl,
                  label: 'Phone',
                  hint:  'e.g. 03001234567',
                  icon:  Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColor.textSecondary,
                          side: BorderSide(color: AppColor.grey200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _saving
                            ? const SizedBox(
                          width:  20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('Save Branch'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller:   controller,
      validator:    validator,
      keyboardType: keyboardType,
      enabled:      !_saving,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText:  hint,
        prefixIcon: Icon(icon, size: 20, color: AppColor.primary),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   BorderSide(color: AppColor.grey200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   BorderSide(color: AppColor.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
        ),
      ),
    );
  }
}