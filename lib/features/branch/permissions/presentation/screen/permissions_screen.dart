import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/app_icon.dart';

import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../store_user/data/model/user_model.dart';
import '../../../store_user/presentation/provider/user_provider.dart';
import '../../domain/permission_catalog.dart';
import '../provider/permissions_provider.dart';

/// Jis role ke paas hamesha full access hota hai (yahan edit nahi hota).
bool _isFullAccessRole(String role) => role == 'store_owner';

String _roleWord(UserModel u) => u.roleLabel.toLowerCase();

/// Owner-only. Har user ke liye module-wise access set karta hai.
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
    final state  = ref.watch(userProvider);
    final perms  = ref.watch(permissionsProvider);

    final activeUsers =
        state.allUsers.where((u) => u.deletedAt == null).toList();

    final users = activeUsers
        .where((u) =>
            _search.isEmpty ||
            u.fullName.toLowerCase().contains(_search) ||
            u.username.toLowerCase().contains(_search))
        .toList()
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

    final selected = _selectedUserId == null
        ? null
        : activeUsers.firstWhereOrNull((u) => u.id == _selectedUserId);

    final customCount = activeUsers
        .where((u) => perms.byUser.containsKey(u.id))
        .length;
    final adminCount =
        activeUsers.where((u) => _isFullAccessRole(u.role)).length;

    return Scaffold(
      backgroundColor: AppColor.grey100,
      appBar: AppBar(
        title: const Text('Permissions',
            style: TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight: 60,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(userProvider.notifier).loadUsers();
              ref.read(permissionsProvider.notifier).loadForStore(
                  ref.read(authProvider).storeId,
                  force: true);
            },
            icon: const AppIcon('ic_refresh', size: 20, color: AppColor.textSecondary),
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
                  // ── Stat cards ─────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Users',
                          value: '${activeUsers.length}',
                          iconAsset: 'ic_top_customers',
                          color: AppColor.info,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          label: 'Custom Access',
                          value: '$customCount',
                          iconAsset: 'ic_custom_access',
                          color: AppColor.info,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          label: 'Admins',
                          value: '$adminCount',
                          iconAsset: 'ic_admin',
                          color: AppColor.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Main split ─────────────────────────────
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 300,
                          child: _UserListPanel(
                            users:       users,
                            totalUsers:  activeUsers.length,
                            selectedId:  selected?.id,
                            showSearch:  activeUsers.length > 6,
                            onSearch: (v) => setState(
                                () => _search = v.toLowerCase().trim()),
                            onSelect: (u) =>
                                setState(() => _selectedUserId = u.id),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: selected == null
                              ? const _EmptyEditor()
                              : _PermissionEditor(user: selected),
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
//  Stat card
// ══════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final String  label;
  final String  value;
  final Color   color;
  final String? iconAsset;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        color:        AppColor.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (iconAsset != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AppIcon(iconAsset!, size: 15, color: color),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize:      11,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 0.8,
                  color:         AppColor.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize:   30,
              fontWeight: FontWeight.w800,
              color:      color,
              height:     1,
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
class _UserListPanel extends ConsumerWidget {
  final List<UserModel>         users;
  final int                     totalUsers;
  final String?                 selectedId;
  final bool                    showSearch;
  final ValueChanged<String>    onSearch;
  final ValueChanged<UserModel> onSelect;

  const _UserListPanel({
    required this.users,
    required this.totalUsers,
    required this.selectedId,
    required this.showSearch,
    required this.onSearch,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(permissionsProvider);

    return Container(
      decoration: BoxDecoration(
        color:        AppColor.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 2),
            child: Text('Users',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Text('Pick someone to edit',
                style: TextStyle(
                    fontSize: 13, color: AppColor.textSecondary)),
          ),

          if (showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: TextField(
                onChanged: onSearch,
                style: const TextStyle(fontSize: 13),
                cursorHeight: 14,
                decoration: InputDecoration(
                  hintText: 'Search user...',
                  hintStyle: const TextStyle(
                      color: AppColor.textHint, fontSize: 13),
                  prefixIcon: const AppIcon('ic_search',
                      size: 18, color: AppColor.grey400),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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

          const Divider(height: 1, color: AppColor.grey200),

          Expanded(
            child: users.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Koi user nahi mila',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: AppColor.textSecondary)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: users.length,
                    itemBuilder: (_, i) {
                      final u        = users[i];
                      final isActive = u.id == selectedId;
                      final dirty    = perms.isDirty(u.id);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: InkWell(
                          onTap: () => onSelect(u),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColor.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
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
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isActive
                                              ? AppColor.primary
                                              : AppColor.textPrimary,
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
                                const SizedBox(height: 2),
                                Text(
                                  _roleWord(u),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColor.textSecondary),
                                ),
                              ],
                            ),
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
class _EmptyEditor extends StatelessWidget {
  const _EmptyEditor();

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
                color: AppColor.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_outlined,
                  size: 34, color: AppColor.primary),
            ),
            const SizedBox(height: 16),
            const Text('Pick someone to edit',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textSecondary)),
            const SizedBox(height: 4),
            const Text('Us user ke module-wise access yahan dikhega',
                style: TextStyle(fontSize: 12, color: AppColor.textHint)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Right: access editor
// ══════════════════════════════════════════════════════════════
class _PermissionEditor extends ConsumerWidget {
  final UserModel user;
  const _PermissionEditor({required this.user});

  int get _totalKeys => PermissionCatalog.allKeys.length;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(permissionsProvider.notifier);
    final perms    = ref.watch(permissionsProvider);
    final granted  = perms.keysFor(user.id, user.role);
    final dirty    = perms.isDirty(user.id);
    final saving   = perms.isSaving(user.id);
    final locked   = _isFullAccessRole(user.role);

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
            padding: const EdgeInsets.fromLTRB(20, 18, 10, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Access — ${user.fullName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text('Role: ${_roleWord(user)}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColor.textSecondary)),
                    ],
                  ),
                ),
                if (!locked)
                  PopupMenuButton<String>(
                    tooltip: 'Bulk actions',
                    icon: const Icon(Icons.more_vert_rounded,
                        color: AppColor.textSecondary),
                    onSelected: (v) {
                      switch (v) {
                        case 'grant':
                          notifier.grantAll(user.id, user.role);
                          break;
                        case 'revoke':
                          notifier.revokeAll(user.id, user.role);
                          break;
                        case 'reset':
                          notifier.resetToRoleDefaults(user.id, user.role);
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'grant',
                        child: _MenuRow(
                            icon: Icons.done_all_rounded,
                            label: 'Grant all access'),
                      ),
                      const PopupMenuItem(
                        value: 'revoke',
                        child: _MenuRow(
                            icon: Icons.remove_done_rounded,
                            label: 'Revoke all access'),
                      ),
                      PopupMenuItem(
                        value: 'reset',
                        child: _MenuRow(
                            icon: Icons.restart_alt_rounded,
                            label: 'Reset to ${_roleWord(user)} defaults'),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          if (locked)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        size: 17, color: AppColor.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_roleWord(user)[0].toUpperCase()}${_roleWord(user).substring(1)}s '
                        "always have full access. Change this person's role "
                        'on the Users screen to restrict them.',
                        style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: AppColor.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColor.grey200),

          // ── Module list ─────────────────────────────────────
          Expanded(
            child: IgnorePointer(
              ignoring: locked,
              child: Opacity(
                opacity: locked ? 0.55 : 1,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  children: [
                    for (final group in PermissionCatalog.groups) ...[
                      _SectionHeader(group.title),
                      for (final m in group.modules)
                        _ModuleRow(
                          user:    user,
                          module:  m,
                          granted: granted,
                          locked:  locked,
                        ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Footer ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColor.grey200)),
            ),
            child: Row(
              children: [
                if (!locked) ...[
                  Icon(
                    dirty
                        ? Icons.pending_outlined
                        : Icons.check_circle_outline_rounded,
                    size: 16,
                    color: dirty
                        ? AppColor.warningDark
                        : AppColor.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      dirty
                          ? 'Unsaved changes'
                          : '${granted.length} of $_totalKeys permissions',
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
                ],
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: (dirty && !locked && !saving)
                      ? () async {
                          final ok =
                              await notifier.save(user.id, user.role);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? '${user.fullName} ka access save ho gaya'
                                  : (ref
                                          .read(permissionsProvider)
                                          .errorMessage ??
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
                    disabledBackgroundColor: AppColor.grey200,
                    disabledForegroundColor: AppColor.grey500,
                    elevation: 0,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
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
                  label: Text(saving ? 'Saving...' : 'Save changes',
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 0, 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize:      11,
          fontWeight:    FontWeight.w700,
          letterSpacing: 0.8,
          color:         AppColor.textSecondary,
        ),
      ),
    );
  }
}

// ── Module row ────────────────────────────────────────────────
class _ModuleRow extends ConsumerWidget {
  final UserModel   user;
  final PermModule  module;
  final Set<String> granted;
  final bool        locked;

  const _ModuleRow({
    required this.user,
    required this.module,
    required this.granted,
    required this.locked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(permissionsProvider.notifier);
    final viewKey  = module.actionKey(PermAction.view);
    final moduleOn = granted.contains(viewKey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 210,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: moduleOn,
                    activeColor: AppColor.textPrimary,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                    onChanged: locked
                        ? null
                        : (v) => notifier.toggle(
                            user.id, user.role, viewKey, v ?? false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    module.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: moduleOn
                          ? AppColor.textPrimary
                          : AppColor.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                for (final a in module.actions)
                  _ActionButton(
                    action: a,
                    selected: granted.contains(module.actionKey(a)),
                    // `View` checkbox se control hota hai — button sirf mirror.
                    enabled:
                        !locked && moduleOn && a != PermAction.view,
                    onTap: (v) => notifier.toggle(
                        user.id, user.role, module.actionKey(a), v),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action button (View / Add / Edit / Delete / Export) ───────
class _ActionButton extends StatelessWidget {
  final PermAction         action;
  final bool               selected;
  final bool               enabled;
  final ValueChanged<bool> onTap;

  const _ActionButton({
    required this.action,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        action == PermAction.delete ? AppColor.error : AppColor.primary;

    final Color bg;
    final Color fg;
    final Color border;

    if (selected && enabled) {
      bg     = accent.withValues(alpha: 0.12);
      fg     = accent;
      border = accent.withValues(alpha: 0.35);
    } else if (selected) {
      bg     = AppColor.grey200;
      fg     = AppColor.grey600;
      border = AppColor.grey200;
    } else {
      bg     = AppColor.grey100;
      fg     = AppColor.grey400;
      border = AppColor.grey200;
    }

    return InkWell(
      onTap: enabled ? () => onTap(!selected) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.check_rounded : action.icon,
              size: 13,
              color: fg,
            ),
            const SizedBox(width: 6),
            Text(
              action.label,
              style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Popup-menu row ────────────────────────────────────────────
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _MenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColor.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
