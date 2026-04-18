import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import 'package:jan_ghani_final/features/branch/counter/presentation/provider/counter_provider.dart';
import '../../../customer/presentation/widget/customer_action_button_widget.dart';
import '../../../customer/presentation/widget/customer_filter_chip_widget.dart';
import '../../../customer/presentation/widget/customer_status_badge_widget.dart';
import '../../data/model/user_model.dart';
import '../provider/user_provider.dart';
import '../widget/add_user_dialog.dart';
import '../widget/user_empty_state_widget.dart';
import '../widget/user_role_badge_widget.dart';

class AllUserScreen extends ConsumerStatefulWidget {
  const AllUserScreen({super.key});

  @override
  ConsumerState<AllUserScreen> createState() => _AllUserScreenState();
}

class _AllUserScreenState extends ConsumerState<AllUserScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).loadUsers();
      ref.read(counterProvider.notifier).loadCounters();
    });
  }

  void _openDialog(BuildContext context, {UserModel? user}) {
    showDialog(
      context:            context,
      barrierDismissible: false,
      builder: (_) => AddUserDialog(user: user),
    );
  }

  void _confirmDelete(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: const Text('User Delete Karein?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('"${user.fullName}" ko delete karna chahte hain?',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColor.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.error,
                foregroundColor: Colors.white,
                elevation:       0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              ref.read(userProvider.notifier).deleteUser(user.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(userProvider);
    final users    = state.filteredUsers;
    final counters = ref.watch(counterProvider).counters;
    final size = MediaQuery.sizeOf(context);
    ref.listen<UserState>(userProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(next.errorMessage!),
            backgroundColor: AppColor.error,
            behavior:        SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label:     'OK',
              textColor: Colors.white,
              onPressed: () =>
                  ref.read(userProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users',
            style: TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight: 60,
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(userProvider.notifier).loadUsers(),
            icon:    const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(
                foregroundColor: AppColor.textSecondary),
          ),
          const SizedBox(width: 4),
          IntrinsicWidth(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton.icon(
                onPressed: () => _openDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  elevation:       0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon:  const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('New User',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Stat Cards ───────────────────────────
            Row(
              children: [
                SummaryCard(
                  title: 'Total Users',
                  value: '${state.totalCount}',
                  icon:  Icons.people_outline_rounded,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Active',
                  value: '${state.activeCount}',
                  icon:  Icons.check_circle_outline_rounded,
                  color: AppColor.success,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Owners',
                  value: '${state.ownerCount}',
                  icon:  Icons.admin_panel_settings_outlined,
                  color: AppColor.error,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Search + Filters ─────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 280,
                    child: TextField(
                      onChanged: ref
                          .read(userProvider.notifier)
                          .onSearchChanged,
                      style:        const TextStyle(fontSize: 13),
                      cursorHeight: 14,
                      decoration: InputDecoration(
                        hintText:  'Search by name, username...',
                        hintStyle: const TextStyle(
                            color: AppColor.textHint, fontSize: 13),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: AppColor.grey400),
                        filled:    true,
                        fillColor: AppColor.grey100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:   BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Status filters
                  ...['all', 'active', 'inactive'].map((v) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: CustomerFilterChip(
                      label: v == 'all'
                          ? 'All'
                          : v[0].toUpperCase() + v.substring(1),
                      value:         v,
                      selectedValue: state.filterStatus,
                      onTap: ref
                          .read(userProvider.notifier)
                          .onFilterStatusChanged,
                    ),
                  )),

                  const _VerticalDivider(),

                  // Role filters
                  ...[
                    ('all',           'All Roles'),
                    ('store_owner',   'Owner'),
                    ('store_manager', 'Manager'),
                    ('cashier',       'Cashier'),
                    ('stock_officer', 'Stock'),
                  ].map((r) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: CustomerFilterChip(
                      label:         r.$2,
                      value:         r.$1,
                      selectedValue: state.filterRole,
                      onTap: ref
                          .read(userProvider.notifier)
                          .onFilterRoleChanged,
                    ),
                  )),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Table ────────────────────────────────
            Expanded(
              child: users.isEmpty
                  ? UserEmptyStateWidget(
                  isSearching: state.searchQuery.isNotEmpty)
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        AppColor.grey100),
                    dataRowColor:
                    WidgetStateProperty.resolveWith<Color?>(
                            (s) => s.contains(
                            WidgetState.hovered)
                            ? AppColor.primary
                            .withValues(alpha: 0.05)
                            : null),
                    dataRowMinHeight:   52,
                    dataRowMaxHeight:   52,
                    columnSpacing: size.width * 0.04,
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Full Name')),
                      DataColumn(label: Text('Username')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Counter')),  // ← new
                      DataColumn(label: Text('Last Login')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: users.map((u) {
                      // Counter name find karo
                      final counterName = u.counterId != null
                          ? counters
                          .where((c) => c.id == u.counterId)
                          .map((c) => c.counterName)
                          .firstOrNull
                          : null;

                      return DataRow(
                        cells: [
                          // Full Name
                          DataCell(Row(
                            children: [
                              CircleAvatar(
                                radius:          16,
                                backgroundColor: AppColor.primary
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  u.fullName.isNotEmpty
                                      ? u.fullName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      fontSize:   13,
                                      fontWeight: FontWeight.w700,
                                      color:      AppColor.primary),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(u.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize:   13)),
                            ],
                          )),

                          // Username
                          DataCell(Text('@${u.username}',
                              style: const TextStyle(
                                  color:    AppColor.textSecondary,
                                  fontSize: 13))),

                          // Phone
                          DataCell(Text(u.phone ?? '—',
                              style: const TextStyle(
                                  fontSize: 13))),

                          // Role
                          DataCell(UserRoleBadge(role: u.role)),

                          // Counter ← new
                          DataCell(_CounterChip(
                            counterName: counterName,
                          )),

                          // Last Login
                          DataCell(Text(u.lastLoginLabel,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColor.textSecondary))),

                          // Status
                          DataCell(CustomerStatusBadge(
                              isActive: u.isActive)),

                          // Actions
                          DataCell(Row(
                            children: [
                              CustomerActionButton(
                                icon:    Icons.edit_outlined,
                                color:   AppColor.primary,
                                tooltip: 'Edit',
                                onTap: () =>
                                    _openDialog(context, user: u),
                              ),
                              const SizedBox(width: 6),
                              CustomerActionButton(
                                icon:    Icons.delete_outline_rounded,
                                color:   AppColor.error,
                                tooltip: 'Delete',
                                onTap: () =>
                                    _confirmDelete(context, u),
                              ),
                            ],
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Counter Chip ──────────────────────────────────────────────
class _CounterChip extends StatelessWidget {
  final String? counterName;
  const _CounterChip({this.counterName});

  @override
  Widget build(BuildContext context) {
    final isAssigned = counterName != null;
    final color      = isAssigned ? AppColor.primary : AppColor.grey400;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.point_of_sale_outlined, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            counterName ?? 'No Counter',
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      color),
          ),
        ],
      ),
    );
  }
}

// ── Vertical Divider ──────────────────────────────────────────
class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) => Container(
    width:  1,
    height: 28,
    color:  AppColor.grey200,
    margin: const EdgeInsets.symmetric(horizontal: 10),
  );
}