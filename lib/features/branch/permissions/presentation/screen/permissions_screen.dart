import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../store_user/data/model/user_model.dart';
import '../../../store_user/presentation/provider/user_provider.dart';
import '../../../store_user/presentation/widget/user_role_badge_widget.dart';
import '../../domain/permission_catalog.dart';
import '../provider/permissions_provider.dart';

Color _roleColor(String role) {
  switch (role) {
    case 'store_owner':   return AppColor.error;
    case 'store_manager': return AppColor.primary;
    case 'stock_officer': return AppColor.info;
    default:              return AppColor.grey500;
  }
}

String _roleShortLabel(String role) {
  switch (role) {
    case 'store_owner':   return 'Owner';
    case 'store_manager': return 'Manager';
    case 'stock_officer': return 'Stock';
    default:              return 'Cashier';
  }
}

/// Owner-only. Har user ke liye module-wise access toggles.
/// Save DB par persist hota hai (`branch_user_permissions`) aur sidebar
/// isi state se granted modules filter karta hai.
class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  String? _selectedUserId;
  String  _search = '';
  String? _roleFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).loadUsers();
      ref.read(permissionsProvider.notifier)
          .loadForStore(ref.read(authProvider).storeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProvider);
    final activeUsers =
        state.allUsers.where((u) => u.deletedAt == null).toList();
    final users = activeUsers
        .where((u) => _roleFilter == null || u.role == _roleFilter)
        .where((u) => u.fullName.toLowerCase().contains(_search) ||
            u.username.toLowerCase().contains(_search))
        .toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    final selected = _selectedUserId == null
        ? null
        : users.firstWhereOrNull((u) => u.id == _selectedUserId) ??
            state.allUsers
                .firstWhereOrNull((u) => u.id == _selectedUserId);

    return Scaffold(
      backgroundColor: AppColor.grey100,
      appBar: AppBar(
        title: const Text('Permissions',
            style: TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight: 60,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.read(userProvider.notifier).loadUsers(),
            icon: const Icon(Icons.refresh_rounded),
            style: IconButton.styleFrom(
                foregroundColor: AppColor.textSecondary),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: state.isLoading && state.allUsers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _InfoBanner(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 292,
                          child: _UserListPanel(
                            users:        users,
                            activeUsers:  activeUsers,
                            selectedId:   selected?.id,
                            roleFilter:   _roleFilter,
                            hasSearch:    _search.isNotEmpty,
                            onSearch:     (v) => setState(
                                () => _search = v.toLowerCase().trim()),
                            onRoleFilter: (r) =>
                                setState(() => _roleFilter = r),
                            onSelect: (u) =>
                                setState(() => _selectedUserId = u.id),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: selected == null
                              ? const EmptyEditor()
                              : PermissionEditor(user: selected),
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

// ══════════════════════════════════════════════════════════════
//  Info banner
// ══════════════════════════════════════════════════════════════
class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColor.infoLight,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColor.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:        AppColor.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.info_outline_rounded,
                size: 16, color: AppColor.info),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'User select karein aur module-wise access set karein. '
              'Save dabane par yeh us user ke sidebar par turant apply '
              'ho jata hai.',
              style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColor.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Left: user list
// ══════════════════════════════════════════════════════════════
const List<String?> _roleFilterOrder = [
  null, 'store_owner', 'store_manager', 'stock_officer', 'cashier',
];

class _UserListPanel extends ConsumerStatefulWidget {
  final List<UserModel>          users;
  final List<UserModel>          activeUsers;
  final String?                  selectedId;
  final String?                  roleFilter;
  final bool                     hasSearch;
  final ValueChanged<String>     onSearch;
  final ValueChanged<String?>    onRoleFilter;
  final ValueChanged<UserModel>  onSelect;

  const _UserListPanel({
    required this.users,
    required this.activeUsers,
    required this.selectedId,
    required this.roleFilter,
    required this.hasSearch,
    required this.onSearch,
    required this.onRoleFilter,
    required this.onSelect,
  });

  @override
  ConsumerState<_UserListPanel> createState() => _UserListPanelState();
}

class _UserListPanelState extends ConsumerState<_UserListPanel> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchCtrl.clear();
    widget.onSearch('');
    widget.onRoleFilter(null);
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(permissionsProvider);
    final hasFilters = widget.hasSearch || widget.roleFilter != null;

    return Container(
      decoration: BoxDecoration(
        color:        AppColor.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                const Text('Users',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Text('(${widget.activeUsers.length})',
                    style: const TextStyle(
                        fontSize: 12, color: AppColor.textSecondary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                widget.onSearch(v);
                setState(() {});
              },
              style: const TextStyle(fontSize: 13),
              cursorHeight: 14,
              decoration: InputDecoration(
                hintText: 'Search user...',
                hintStyle:
                    const TextStyle(color: AppColor.textHint, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: AppColor.grey400),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : InkWell(
                        onTap: () {
                          _searchCtrl.clear();
                          widget.onSearch('');
                          setState(() {});
                        },
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppColor.grey400),
                      ),
                filled: true,
                fillColor: AppColor.grey100,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 12, right: 12),
              itemCount: _roleFilterOrder.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final role     = _roleFilterOrder[i];
                final isActive = widget.roleFilter == role;
                final label    = role == null ? 'All' : _roleShortLabel(role);
                final color    = role == null
                    ? AppColor.textSecondary
                    : _roleColor(role);
                return InkWell(
                  onTap: () => widget.onRoleFilter(isActive ? null : role),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive
                          ? color.withValues(alpha: 0.12)
                          : AppColor.grey100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? color.withValues(alpha: 0.4)
                            : AppColor.grey200,
                      ),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isActive ? color : AppColor.textSecondary)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColor.grey200),
          Expanded(
            child: widget.users.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_search_rounded,
                              size: 32, color: AppColor.grey400),
                          const SizedBox(height: 10),
                          const Text('Koi user nahi mila',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.textSecondary)),
                          if (hasFilters) ...[
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: _clearFilters,
                              child: const Text('Clear filters',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColor.primary)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: widget.users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (_, i) {
                      final u        = widget.users[i];
                      final isActive = u.id == widget.selectedId;
                      final dirty    = perms.isDirty(u.id);
                      final rColor   = _roleColor(u.role);
                      return InkWell(
                        onTap: () => widget.onSelect(u),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColor.primary.withValues(alpha: 0.08)
                                : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isActive
                                    ? AppColor.primary
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: rColor.withValues(alpha: 0.12),
                                child: Text(
                                  u.fullName.isNotEmpty
                                      ? u.fullName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: rColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            u.fullName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (dirty)
                                          Container(
                                            margin: const EdgeInsets.only(
                                                left: 6),
                                            width: 7,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              color: AppColor.warningDark,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    UserRoleBadge(role: u.role),
                                  ],
                                ),
                              ),
                              if (isActive)
                                const Icon(Icons.chevron_right_rounded,
                                    size: 18, color: AppColor.primary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Empty state (no user selected)
// ══════════════════════════════════════════════════════════════
class EmptyEditor extends StatelessWidget {
  const EmptyEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColor.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color:  AppColor.primary.withValues(alpha: 0.08),
                shape:  BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_outlined,
                  size: 36, color: AppColor.primary),
            ),
            const SizedBox(height: 16),
            const Text('Left se ek user select karein',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textSecondary)),
            const SizedBox(height: 4),
            const Text('Us user ke module-wise permissions yahan dikhengi',
                style:
                    TextStyle(fontSize: 12, color: AppColor.textHint)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Right: permission editor
// ══════════════════════════════════════════════════════════════
class PermissionEditor extends ConsumerWidget {
  final UserModel user;
  const PermissionEditor({super.key, required this.user});

  int get _totalKeys => PermissionCatalog.allKeys.length;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(permissionsProvider.notifier);
    final perms    = ref.watch(permissionsProvider);
    final granted  = perms.keysFor(user.id, user.role);
    final dirty    = perms.isDirty(user.id);
    final saving   = perms.isSaving(user.id);
    final isOwner  = user.role == 'store_owner';

    return Container(
      decoration: BoxDecoration(
        color:        AppColor.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      AppColor.primary.withValues(alpha: 0.1),
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColor.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(user.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          UserRoleBadge(role: user.role),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('@${user.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColor.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _GrantSummary(
                    granted: granted.length, total: _totalKeys),
              ],
            ),
          ),

          if (isOwner)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColor.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 15, color: AppColor.warningDark),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Store Owner ke paas hamesha full access hota hai.',
                      style: TextStyle(
                          fontSize: 11.5, color: AppColor.warningDark),
                    ),
                  ),
                ],
              ),
            ),

          // ── Quick actions ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniButton(
                  icon: Icons.done_all_rounded,
                  label: 'Grant all',
                  onTap: isOwner
                      ? null
                      : () => notifier.grantAll(user.id, user.role),
                ),
                _MiniButton(
                  icon: Icons.remove_done_rounded,
                  label: 'Revoke all',
                  onTap: isOwner
                      ? null
                      : () => notifier.revokeAll(user.id, user.role),
                ),
                _MiniButton(
                  icon: Icons.restart_alt_rounded,
                  label: 'Reset to ${user.roleLabel} defaults',
                  onTap: isOwner
                      ? null
                      : () => notifier.resetToRoleDefaults(
                          user.id, user.role),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColor.grey200),

          // ── Groups ──────────────────────────────────────────
          Expanded(
            child: IgnorePointer(
              ignoring: isOwner,
              child: Opacity(
                opacity: isOwner ? 0.5 : 1,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final group in PermissionCatalog.groups)
                      _GroupCard(
                        user:    user,
                        group:   group,
                        granted: granted,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Footer / Save ───────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: AppColor.grey200)),
            ),
            child: Row(
              children: [
                Icon(
                  dirty
                      ? Icons.pending_outlined
                      : Icons.check_circle_outline_rounded,
                  size: 16,
                  color: dirty
                      ? AppColor.warningDark
                      : AppColor.success,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    dirty ? 'Unsaved changes' : 'Up to date',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: dirty
                          ? AppColor.warningDark
                          : AppColor.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: (dirty && !isOwner && !saving)
                      ? () async {
                          final ok = await notifier.save(user.id, user.role);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? '${user.fullName} ki permissions save ho gayin'
                                  : (ref.read(permissionsProvider).errorMessage ??
                                      'Save nahi ho saka, dobara koshish karein')),
                              backgroundColor:
                                  ok ? AppColor.success : AppColor.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined, size: 16),
                  label: Text(saving ? 'Saving...' : 'Save',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grant summary chip ────────────────────────────────────────
class _GrantSummary extends StatelessWidget {
  final int granted;
  final int total;
  const _GrantSummary({required this.granted, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : granted / total;
    final color = pct >= 0.99
        ? AppColor.success
        : pct <= 0.01
            ? AppColor.error
            : AppColor.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$granted / $total',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const Text('permissions',
              style:
                  TextStyle(fontSize: 10, color: AppColor.textSecondary)),
        ],
      ),
    );
  }
}

// ── Group card ────────────────────────────────────────────────
class _GroupCard extends ConsumerStatefulWidget {
  final UserModel   user;
  final PermGroup   group;
  final Set<String> granted;

  const _GroupCard({
    required this.user,
    required this.group,
    required this.granted,
  });

  @override
  ConsumerState<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends ConsumerState<_GroupCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(permissionsProvider.notifier);
    final user     = widget.user;
    final group    = widget.group;
    final granted  = widget.granted;

    final groupKeys = [
      for (final m in group.modules)
        for (final a in m.actions) m.actionKey(a),
    ];
    final grantedInGroup =
        groupKeys.where(granted.contains).length;
    final allOn  = grantedInGroup == groupKeys.length;
    final someOn = grantedInGroup > 0 && !allOn;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        AppColor.grey100,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(
            color: someOn || allOn
                ? AppColor.primary.withValues(alpha: 0.25)
                : AppColor.grey200),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColor.grey500),
                  ),
                  const SizedBox(width: 4),
                  Icon(group.icon, size: 16, color: AppColor.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(group.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: allOn
                          ? AppColor.success.withValues(alpha: 0.12)
                          : AppColor.grey200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('$grantedInGroup/${groupKeys.length}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: allOn
                                ? AppColor.success
                                : AppColor.textSecondary)),
                  ),
                  const Spacer(),
                  Checkbox(
                    value: allOn ? true : (someOn ? null : false),
                    tristate: true,
                    visualDensity: VisualDensity.compact,
                    activeColor: AppColor.primary,
                    onChanged: (_) => notifier.toggleGroup(
                        user.id, user.role, group, !allOn),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 150),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                const Divider(height: 1, color: AppColor.grey200),
                for (final m in group.modules)
                  _ModuleRow(
                    user:    user,
                    module:  m,
                    granted: granted,
                  ),
              ],
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ── Module row ────────────────────────────────────────────────
class _ModuleRow extends ConsumerWidget {
  final UserModel   user;
  final PermModule  module;
  final Set<String> granted;

  const _ModuleRow({
    required this.user,
    required this.module,
    required this.granted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(permissionsProvider.notifier);
    final moduleOn =
        module.actions.any((a) => granted.contains(module.actionKey(a)));

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(module.icon,
                  size: 15,
                  color: moduleOn
                      ? AppColor.textPrimary
                      : AppColor.grey400),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  module.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: moduleOn
                        ? AppColor.textPrimary
                        : AppColor.textSecondary,
                  ),
                ),
              ),
              Switch(
                value: moduleOn,
                activeColor: AppColor.primary,
                materialTapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
                onChanged: (v) => notifier.toggleModule(
                    user.id, user.role, module, v),
              ),
            ],
          ),
          if (moduleOn && module.actions.length > 1)
            Padding(
              padding: const EdgeInsets.only(left: 23, top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final a in module.actions)
                    if (a != PermAction.view)
                      _ActionChip(
                        action: a,
                        selected:
                            granted.contains(module.actionKey(a)),
                        onTap: (v) => notifier.toggle(
                          user.id,
                          user.role,
                          module.actionKey(a),
                          v,
                        ),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Action chip ───────────────────────────────────────────────
class _ActionChip extends StatelessWidget {
  final PermAction         action;
  final bool               selected;
  final ValueChanged<bool> onTap;

  const _ActionChip({
    required this.action,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        action == PermAction.delete ? AppColor.error : AppColor.primary;
    return InkWell(
      onTap: () => onTap(!selected),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : AppColor.grey200,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_rounded : action.icon,
              size: 12,
              color: selected ? color : AppColor.grey600,
            ),
            const SizedBox(width: 4),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColor.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mini button ───────────────────────────────────────────────
class _MiniButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback? onTap;

  const _MiniButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColor.primary,
        side: BorderSide(
            color: disabled ? AppColor.grey300 : AppColor.grey300),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
      icon: Icon(icon, size: 14),
      label: Text(label),
    );
  }
}
