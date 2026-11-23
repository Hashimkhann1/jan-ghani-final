// Updated on 2026-11-23 12:33 PM
// =============================================================
// warehouse_permissions_screen.dart — Sidebar ADMIN → Permissions (S31)
//
// Branch ke PermissionsScreen jaisa: left = users, right = module-wise
// access editor (View / Add / Edit / Delete / Pay / Reverse / …).
//   • Owner = hamesha full access (lock) — Owner kisi ka bhi access
//     de / le sakta hai (Manager ka bhi)
//   • Manager ka access sirf Owner badal sakta hai
//   • Password badlein (header button) — Owner: kisi ka bhi; Manager
//     (`users.password`, default on): apna + Staff / Data Entry ka
//   • Naam / Role badlein (header button) — Owner sab ka; `users.edit`
//     wala sirf Staff / Data Entry ka. Apna role koi nahi badalta.
//     (Users screen 23 Nov 2026 se sidebar se band hai)
//   • Naya user (left list header) — Owner / `users.create`
//   • Delete user (editor header) — apna nahi; Owner sab; baaki
//     `users.delete` + sirf Staff / Data Entry
//   • Apna access khud nahi badal sakte (self-lockout se bachao)
//   • Save → local DB `warehouse_user_permissions`; sidebar + buttons
//     foran naye access par chalte hain (us user ke agle login / abhi)
//   • `permissions.edit` na ho to screen sirf dekhne ke liye
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/warehouse_color.dart';
import 'package:jan_ghani_final/features/warehouse/auth/presentation/provider/auth_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_user/data/model/user_model.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_user/presentation/provider/user_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_user/presentation/widget/user_role_badge_widget.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_user/presentation/widget/add_user_dialog.dart';

import '../../domain/warehouse_permission_catalog.dart';
import '../provider/warehouse_permissions_provider.dart';

typedef _Cat = WarehousePermissionCatalog;

class WarehousePermissionsScreen extends ConsumerStatefulWidget {
  const WarehousePermissionsScreen({super.key});

  @override
  ConsumerState<WarehousePermissionsScreen> createState() =>
      _WarehousePermissionsScreenState();
}

class _WarehousePermissionsScreenState
    extends ConsumerState<WarehousePermissionsScreen> {
  String? _selectedId;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(userProvider.notifier).loadUsers();
      ref.read(warehousePermissionsProvider.notifier).load(force: true);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.read(userProvider.notifier).loadUsers();
    ref.read(warehousePermissionsProvider.notifier).load(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(userProvider);

    // Users add / delete ka error (username duplicate wagaira) → snackbar.
    // clearError NAHI — AddUserDialog isi error se tay karta hai ke band ho ya nahi
    ref.listen<String?>(userProvider.select((s) => s.errorMessage), (_, msg) {
      if (msg == null || !mounted) return;
      final width = MediaQuery.of(context).size.width;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
              left: width > 460 ? width - 440 : 16, right: 20, bottom: 20),
          backgroundColor: WarehouseAppColor.error,
          content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        ));
    });
    final perms      = ref.watch(warehousePermissionsProvider);
    final me         = ref.watch(authProvider).user;
    final canEdit    = ref.watch(warehouseAccessProvider)
        .can('${_Cat.permissions}.edit');

    final all = usersState.allUsers.where((u) => u.deletedAt == null).toList()
      ..sort((a, b) {
        final r = _roleRank(a.role).compareTo(_roleRank(b.role));
        return r != 0
            ? r
            : a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
      });

    final q = _search.trim().toLowerCase();
    final users = q.isEmpty
        ? all
        : all.where((u) =>
            u.fullName.toLowerCase().contains(q) ||
            u.username.toLowerCase().contains(q)).toList();

    UserModel? selected;
    for (final u in all) {
      if (u.id == _selectedId) selected = u;
    }

    final customCount = all.where((u) =>
        !_Cat.isFullAccessRole(u.role) && perms.isCustomized(u.id)).length;
    final fullCount = all.where((u) => _Cat.isFullAccessRole(u.role)).length;

    return Scaffold(
      backgroundColor: WarehouseAppColor.grey100,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(onRefresh: _refresh, loading: perms.isLoading),
          if (perms.errorMessage != null)
            _ErrorBanner(
              message: perms.errorMessage!,
              onRetry: _refresh,
            ),
          Expanded(
            child: usersState.isLoading && all.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _KpiCard(
                              label: 'Users',
                              value: '${all.length}',
                              sub:   '${all.where((u) => u.isActive).length} active',
                              icon:  Icons.group_outlined,
                              color: WarehouseAppColor.info,
                            ),
                            const SizedBox(width: 14),
                            _KpiCard(
                              label: 'Custom access',
                              value: '$customCount',
                              sub:   'Role defaults se alag',
                              icon:  Icons.tune_rounded,
                              color: WarehouseAppColor.warningDark,
                            ),
                            const SizedBox(width: 14),
                            _KpiCard(
                              label: 'Full access',
                              value: '$fullCount',
                              sub:   'Owner — hamesha sab kuch',
                              icon:  Icons.shield_outlined,
                              color: WarehouseAppColor.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: LayoutBuilder(builder: (context, c) {
                            final listW = c.maxWidth < 900 ? 230.0 : 290.0;
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: listW,
                                  child: _UserList(
                                    users:      users,
                                    total:      all.length,
                                    selectedId: selected?.id,
                                    meId:       me?.id,
                                    searchCtrl: _searchCtrl,
                                    onSearch:   (v) => setState(() => _search = v),
                                    onSelect:   (u) => setState(() => _selectedId = u.id),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: selected == null
                                      ? const _EmptyEditor()
                                      : _Editor(
                                          key:     ValueKey(selected.id),
                                          user:    selected,
                                          others:  all.where((u) => u.id != selected!.id).toList(),
                                          isMe:    selected.id == me?.id,
                                          canEdit: canEdit,
                                          myRole:  me?.role ?? '',
                                        ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

int _roleRank(String role) {
  final i = _Cat.roles.indexOf(role);
  return i < 0 ? 99 : i;
}

// ══════════════════════════════════════════════════════════════
// Top bar
// ══════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool         loading;
  const _TopBar({required this.onRefresh, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      decoration: const BoxDecoration(
        color:  WarehouseAppColor.surface,
        border: Border(bottom: BorderSide(color: WarehouseAppColor.grey200)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color:        WarehouseAppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.verified_user_outlined,
                size: 20, color: WarehouseAppColor.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Permissions',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: WarehouseAppColor.textPrimary)),
                SizedBox(height: 2),
                Text('Har user kaun si screen dekhe aur kya kar sake',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5, color: WarehouseAppColor.textSecondary)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : onRefresh,
            icon: loading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded,
                    color: WarehouseAppColor.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WarehouseAppColor.errorLight,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: WarehouseAppColor.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, color: WarehouseAppColor.error)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// KPI card (Expanded khud return karta hai)
// ══════════════════════════════════════════════════════════════
class _KpiCard extends StatelessWidget {
  final String   label;
  final String   value;
  final String   sub;
  final IconData icon;
  final Color    color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color:        WarehouseAppColor.surface,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: WarehouseAppColor.grey200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: WarehouseAppColor.textSecondary)),
                  const SizedBox(height: 6),
                  Text(value,
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800,
                          color: color, height: 1.1)),
                  const SizedBox(height: 4),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5, color: WarehouseAppColor.textSecondary)),
                ],
              ),
            ),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color:        color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Left: users list
// ══════════════════════════════════════════════════════════════
class _UserList extends ConsumerWidget {
  bool _canCreateUser(WidgetRef ref) {
    final me = ref.watch(authProvider).user;
    return me != null &&
        _Cat.canCreateUser(me.role, ref.watch(warehouseAccessProvider).keys);
  }

  final List<UserModel>         users;
  final int                     total;
  final String?                 selectedId;
  final String?                 meId;
  final TextEditingController   searchCtrl;
  final ValueChanged<String>    onSearch;
  final ValueChanged<UserModel> onSelect;

  const _UserList({
    required this.users,
    required this.total,
    required this.selectedId,
    required this.meId,
    required this.searchCtrl,
    required this.onSearch,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(warehousePermissionsProvider);

    return Container(
      decoration: BoxDecoration(
        color:        WarehouseAppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: WarehouseAppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('Users ($total)',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                // Naya user — Owner / users.create
                if (_canCreateUser(ref))
                  TextButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const AddUserDialog(),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: WarehouseAppColor.primary,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 17),
                    label: const Text('Naya user',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text('Kisi user ko chunein',
                style: TextStyle(
                    fontSize: 12, color: WarehouseAppColor.textSecondary)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: searchCtrl,
              onChanged:  onSearch,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText:  'Naam ya username…',
                hintStyle: const TextStyle(
                    fontSize: 13, color: WarehouseAppColor.textHint),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: WarehouseAppColor.grey500),
                suffixIcon: searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () {
                          searchCtrl.clear();
                          onSearch('');
                        },
                      ),
                isDense:   true,
                filled:    true,
                fillColor: WarehouseAppColor.grey100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:   BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: WarehouseAppColor.grey200),
          Expanded(
            child: users.isEmpty
                ? const Center(
                    child: Text('Koi user nahi mila',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: WarehouseAppColor.textSecondary)),
                  )
                : ListView.builder(
                    padding:   const EdgeInsets.all(8),
                    itemCount: users.length,
                    itemBuilder: (_, i) {
                      final u      = users[i];
                      final active = u.id == selectedId;
                      final full   = _Cat.isFullAccessRole(u.role);
                      final custom = !full && perms.isCustomized(u.id);
                      final dirty  = perms.isDirty(u.id);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Material(
                          color: active
                              ? WarehouseAppColor.primary.withOpacity(0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => onSelect(u),
                            child: Opacity(
                              opacity: u.isActive ? 1 : 0.55,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 9),
                                child: Row(
                                  children: [
                                    _Avatar(name: u.fullName, active: active),
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
                                                  u.fullName +
                                                      (u.id == meId ? ' (aap)' : ''),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: active
                                                        ? WarehouseAppColor.primary
                                                        : WarehouseAppColor.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              if (dirty)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 6),
                                                  width: 7, height: 7,
                                                  decoration: const BoxDecoration(
                                                    color: WarehouseAppColor.warningDark,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              UserRoleBadge(role: u.role),
                                              if (custom) ...[
                                                const SizedBox(width: 6),
                                                const _Tag('CUSTOM',
                                                    WarehouseAppColor.warningDark),
                                              ],
                                              if (!u.isActive) ...[
                                                const SizedBox(width: 6),
                                                const _Tag('INACTIVE',
                                                    WarehouseAppColor.grey600),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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

class _Avatar extends StatelessWidget {
  final String name;
  final bool   active;
  const _Avatar({required this.name, required this.active});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : (parts.length == 1
            ? parts.first[0]
            : '${parts.first[0]}${parts.last[0]}').toUpperCase();
    return Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: active
            ? WarehouseAppColor.primary
            : WarehouseAppColor.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(initials,
          style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700,
              color: active ? Colors.white : WarehouseAppColor.primary)),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color  color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 9.5, fontWeight: FontWeight.w700,
              letterSpacing: 0.4, color: color)),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Empty editor
// ══════════════════════════════════════════════════════════════
class _EmptyEditor extends StatelessWidget {
  const _EmptyEditor();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        WarehouseAppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: WarehouseAppColor.grey200),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: WarehouseAppColor.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_outlined,
                  size: 34, color: WarehouseAppColor.primary),
            ),
            const SizedBox(height: 14),
            const Text('Left se user chunein',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: WarehouseAppColor.textSecondary)),
            const SizedBox(height: 4),
            const Text('Us ka screen-wise access yahan dikhega',
                style: TextStyle(fontSize: 12, color: WarehouseAppColor.textHint)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Right: editor
// ══════════════════════════════════════════════════════════════
class _Editor extends ConsumerWidget {
  final UserModel       user;
  final List<UserModel> others;
  final bool            isMe;
  final bool            canEdit;
  final String          myRole;

  const _Editor({
    super.key,
    required this.user,
    required this.others,
    required this.isMe,
    required this.canEdit,
    required this.myRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms    = ref.watch(warehousePermissionsProvider);
    final notifier = ref.read(warehousePermissionsProvider.notifier);
    final full     = _Cat.isFullAccessRole(user.role);
    final keys     = perms.editKeysFor(user.id, user.role);
    final dirty    = perms.isDirty(user.id);
    final saving   = perms.isSaving(user.id);
    final custom   = perms.isCustomized(user.id);
    final total    = _Cat.allKeys.length;

    // Password button — Owner sab ka; Manager (users.password) apna +
    // Staff / Data Entry ka
    final me     = ref.watch(authProvider).user;
    final access = ref.watch(warehouseAccessProvider);
    final canPw  = me != null &&
        _Cat.canChangePassword(
          editorId:   me.id,
          editorRole: me.role,
          editorKeys: access.keys,
          targetId:   user.id,
          targetRole: user.role,
        );
    final canDel = me != null &&
        _Cat.canDeleteUser(
          editorId:   me.id,
          editorRole: me.role,
          editorKeys: access.keys,
          targetId:   user.id,
          targetRole: user.role,
        );
    final canEditU = me != null &&
        _Cat.canEditUser(
          editorId:   me.id,
          editorRole: me.role,
          editorKeys: access.keys,
          targetId:   user.id,
          targetRole: user.role,
        );

    // Kyun band hai? (lock message)
    String? lockMsg;
    if (full) {
      lockMsg = 'Owner ke paas hamesha poora access hota hai. Access kam '
          'karna ho to "Naam / Role" se role badlein.';
    } else if (isMe) {
      lockMsg = 'Apna access khud nahi badal sakte — Owner badlega.';
    } else if (!_Cat.canEditRole(myRole, user.role)) {
      lockMsg = 'Manager ka access sirf Owner badal sakta hai.';
    } else if (!canEdit) {
      lockMsg = 'Aap sirf dekh sakte hain — access badalne ki permission '
          '(Permissions → Edit) nahi hai.';
    }
    final locked = lockMsg != null;

    final screens = _Cat.allModules.where((m) => keys.contains(m.viewKey)).length;

    return Container(
      decoration: BoxDecoration(
        color:        WarehouseAppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: WarehouseAppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
            child: Row(
              children: [
                _Avatar(name: user.fullName, active: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          UserRoleBadge(role: user.role),
                          Text('@${user.username}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: WarehouseAppColor.textSecondary)),
                          if (full)
                            const _Tag('FULL ACCESS', WarehouseAppColor.primary)
                          else if (perms.resetPending.contains(user.id))
                            const _Tag('ROLE DEFAULT (save karein)',
                                WarehouseAppColor.warningDark)
                          else if (custom)
                            const _Tag('CUSTOM', WarehouseAppColor.warningDark)
                          else
                            const _Tag('ROLE DEFAULT', WarehouseAppColor.grey600),
                        ],
                      ),
                    ],
                  ),
                ),
                // Naam / Role — Owner sab ka; users.edit wala Staff / Data Entry
                if (canEditU) ...[
                  OutlinedButton.icon(
                    onPressed: () => _EditUserDialog.show(context, user),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WarehouseAppColor.primary,
                      side: BorderSide(
                          color: WarehouseAppColor.primary.withOpacity(0.4)),
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.manage_accounts_outlined, size: 16),
                    label: const Text('Naam / Role',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                ],
                // Password — Owner sab ka; Manager apna + Staff / Data Entry
                if (canPw) ...[
                  OutlinedButton.icon(
                    onPressed: () => _ChangePasswordDialog.show(context, user),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WarehouseAppColor.primary,
                      side: BorderSide(
                          color: WarehouseAppColor.primary.withOpacity(0.4)),
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.key_rounded, size: 16),
                    label: const Text('Password badlein',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(width: locked ? 12 : 4),
                ],
                // Delete user — apna nahi
                if (canDel)
                  IconButton(
                    tooltip: 'User delete karein',
                    onPressed: () => _confirmDelete(context, ref),
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: WarehouseAppColor.error),
                  ),
                if (!locked)
                  PopupMenuButton<String>(
                    tooltip: 'Aur options',
                    icon: const Icon(Icons.more_vert_rounded,
                        color: WarehouseAppColor.textSecondary),
                    onSelected: (v) async {
                      switch (v) {
                        case 'grant':
                          notifier.grantAll(user.id);
                          break;
                        case 'revoke':
                          notifier.revokeAll(user.id);
                          break;
                        case 'reset':
                          notifier.resetToRoleDefaults(user.id);
                          break;
                        case 'copy':
                          final from = await _pickUser(context, others);
                          if (from != null) {
                            notifier.copyFrom(user.id, from.id, from.role);
                          }
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'grant',
                          child: _MenuRow(Icons.done_all_rounded, 'Sab access do')),
                      const PopupMenuItem(
                          value: 'revoke',
                          child: _MenuRow(Icons.remove_done_rounded, 'Sab access band')),
                      if (others.isNotEmpty)
                        const PopupMenuItem(
                            value: 'copy',
                            child: _MenuRow(Icons.copy_all_rounded,
                                'Doosre user jaisa access')),
                      PopupMenuItem(
                          value: 'reset',
                          child: _MenuRow(Icons.restart_alt_rounded,
                              '${_Cat.roleLabel(user.role)} role ke default')),
                    ],
                  ),
              ],
            ),
          ),

          if (lockMsg != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color:        WarehouseAppColor.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        size: 16, color: WarehouseAppColor.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(lockMsg,
                          style: const TextStyle(
                              fontSize: 12.5, height: 1.35,
                              color: WarehouseAppColor.textPrimary)),
                    ),
                  ],
                ),
              ),
            ),

          const Divider(height: 1, color: WarehouseAppColor.grey200),

          // ── Modules ──────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              children: [
                for (final g in _Cat.groups)
                  _GroupSection(
                    group:  g,
                    user:   user,
                    keys:   keys,
                    locked: locked,
                  ),
              ],
            ),
          ),

          // ── Footer ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: WarehouseAppColor.grey200)),
            ),
            child: Row(
              children: [
                Icon(
                  dirty ? Icons.pending_outlined : Icons.check_circle_outline_rounded,
                  size: 16,
                  color: dirty
                      ? WarehouseAppColor.warningDark
                      : WarehouseAppColor.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dirty
                        ? 'Unsaved changes — Save dabayein'
                        : '$screens screens · ${keys.length} / $total permissions',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: dirty
                            ? WarehouseAppColor.warningDark
                            : WarehouseAppColor.textSecondary),
                  ),
                ),
                if (dirty && !locked && !saving) ...[
                  TextButton(
                    onPressed: () => notifier.discard(user.id),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 6),
                ],
                ElevatedButton.icon(
                  onPressed: (dirty && !locked && !saving)
                      ? () => _save(context, ref)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WarehouseAppColor.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: WarehouseAppColor.grey200,
                    disabledForegroundColor: WarehouseAppColor.grey500,
                    elevation:   0,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: saving
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined, size: 16),
                  label: Text(saving ? 'Saving…' : 'Save',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(warehousePermissionsProvider.notifier);
    final keys = ref.read(warehousePermissionsProvider).editKeysFor(user.id, user.role);

    // Koi screen hi nahi bachi → login ke baad khaali app. Confirm karo.
    final noScreen = !_Cat.allModules.any((m) => keys.contains(m.viewKey));
    if (noScreen) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Koi screen nahi bachi'),
          content: Text('${user.fullName} login karke koi bhi screen nahi '
              'dekh sakega. Phir bhi save karein?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Nahi')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Haan, save')),
          ],
        ),
      );
      if (ok != true) return;
    }

    final ok = await notifier.save(user.id, user.role);
    if (!context.mounted) return;
    final width = MediaQuery.of(context).size.width;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
            left: width > 460 ? width - 440 : 16, right: 20, bottom: 20),
        backgroundColor: ok ? WarehouseAppColor.success : WarehouseAppColor.error,
        content: Text(
          ok
              ? '${user.fullName} ka access save ho gaya'
              : (ref.read(warehousePermissionsProvider).errorMessage ??
                  'Save nahi ho saka — dobara koshish karein'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ));
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('User delete karein?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          '"${user.fullName}" (@${user.username}) delete ho jayega aur login '
          'nahi kar sakega. Purana record (entries) waise hi rahega.',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: WarehouseAppColor.error),
            child: const Text('Haan, delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(userProvider.notifier).deleteUser(user.id);
    if (!context.mounted) return;
    if (ref.read(userProvider).errorMessage != null) return; // listener snackbar dikhata
    final width = MediaQuery.of(context).size.width;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
            left: width > 460 ? width - 440 : 16, right: 20, bottom: 20),
        backgroundColor: WarehouseAppColor.success,
        content: Text('${user.fullName} delete ho gaya',
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ));
  }

  Future<UserModel?> _pickUser(BuildContext context, List<UserModel> list) {
    return showDialog<UserModel>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Kis user jaisa access?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        children: [
          for (final u in list)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, u),
              child: Row(
                children: [
                  Expanded(
                    child: Text(u.fullName,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  UserRoleBadge(role: u.role),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Group section (header + "sab" checkbox + modules) ──────────
class _GroupSection extends ConsumerWidget {
  final WhPermGroup group;
  final UserModel   user;
  final Set<String> keys;
  final bool        locked;

  const _GroupSection({
    required this.group,
    required this.user,
    required this.keys,
    required this.locked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(warehousePermissionsProvider.notifier);
    final groupKeys = [
      for (final m in group.modules)
        for (final a in m.actions) m.actionKey(a),
    ];
    final on = groupKeys.where(keys.contains).length;
    final bool? tri = on == 0 ? false : (on == groupKeys.length ? true : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 18, 0, 6),
          child: Row(
            children: [
              Text(group.title.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: WarehouseAppColor.textSecondary)),
              const SizedBox(width: 8),
              Text('$on/${groupKeys.length}',
                  style: const TextStyle(
                      fontSize: 11, color: WarehouseAppColor.textHint)),
              const Spacer(),
              if (!locked)
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => notifier.toggleGroup(
                      user.id, user.role, group, tri != true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18, height: 18,
                          child: Checkbox(
                            tristate: true,
                            value:    tri,
                            activeColor: WarehouseAppColor.primary,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (_) => notifier.toggleGroup(
                                user.id, user.role, group, tri != true),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('Sab',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: WarehouseAppColor.textSecondary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WarehouseAppColor.grey200),
          ),
          child: Column(
            children: [
              for (var i = 0; i < group.modules.length; i++)
                _ModuleRow(
                  module: group.modules[i],
                  user:   user,
                  keys:   keys,
                  locked: locked,
                  last:   i == group.modules.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Module row ────────────────────────────────────────────────
class _ModuleRow extends ConsumerWidget {
  final WhPermModule module;
  final UserModel    user;
  final Set<String>  keys;
  final bool         locked;
  final bool         last;

  const _ModuleRow({
    required this.module,
    required this.user,
    required this.keys,
    required this.locked,
    required this.last,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(warehousePermissionsProvider.notifier);
    final on = keys.contains(module.viewKey);

    final nameCol = Row(
      children: [
        SizedBox(
          width: 22, height: 22,
          child: Checkbox(
            value: on,
            activeColor: WarehouseAppColor.primary,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: locked
                ? null
                : (v) => notifier.toggle(user.id, user.role, module,
                    WhPermAction.view, v ?? false),
          ),
        ),
        const SizedBox(width: 10),
        Icon(module.icon,
            size: 17,
            color: on ? WarehouseAppColor.primary : WarehouseAppColor.grey400),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(module.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600,
                      color: on
                          ? WarehouseAppColor.textPrimary
                          : WarehouseAppColor.textSecondary)),
              const SizedBox(height: 2),
              Text(module.hint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, height: 1.3,
                      color: WarehouseAppColor.textHint)),
            ],
          ),
        ),
      ],
    );

    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in module.actions)
          _ActionChip(
            action:   a,
            selected: keys.contains(module.actionKey(a)),
            // View = row ka checkbox; baaki sirf jab module on ho
            enabled:  !locked && on && a.key != WhPermAction.view.key,
            onTap: (v) => notifier.toggle(user.id, user.role, module, a, v),
          ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: WarehouseAppColor.grey100)),
      ),
      child: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              nameCol,
              const SizedBox(height: 8),
              Padding(padding: const EdgeInsets.only(left: 32), child: chips),
            ],
          );
        }
        return Row(
          children: [
            SizedBox(width: c.maxWidth < 760 ? 220 : 280, child: nameCol),
            const SizedBox(width: 12),
            Expanded(child: chips),
          ],
        );
      }),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final WhPermAction       action;
  final bool               selected;
  final bool               enabled;
  final ValueChanged<bool> onTap;

  const _ActionChip({
    required this.action,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = action.danger ? WarehouseAppColor.error : WarehouseAppColor.primary;

    Color bg, fg, border;
    if (selected && enabled) {
      bg = accent.withOpacity(0.1);
      fg = accent;
      border = accent.withOpacity(0.35);
    } else if (selected) {
      bg = WarehouseAppColor.grey200;
      fg = WarehouseAppColor.grey700;
      border = WarehouseAppColor.grey200;
    } else {
      bg = WarehouseAppColor.grey100;
      fg = WarehouseAppColor.grey500;
      border = WarehouseAppColor.grey200;
    }

    return InkWell(
      onTap: enabled ? () => onTap(!selected) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.check_rounded : action.icon, size: 13, color: fg),
            const SizedBox(width: 5),
            Text(action.label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Naam / Role badlein — Owner sab ka; users.edit wala sirf Staff /
// Data Entry ka. Apna role koi nahi badal sakta (sirf naam).
// ══════════════════════════════════════════════════════════════
class _EditUserDialog extends ConsumerStatefulWidget {
  final UserModel user;
  const _EditUserDialog({required this.user});

  static Future<void> show(BuildContext context, UserModel user) =>
      showDialog(
        context: context,
        builder: (_) => _EditUserDialog(user: user),
      );

  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.fullName);
  late String _role = widget.user.role;
  bool    _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final me = ref.read(authProvider).user;
    final u  = widget.user;
    final ok = me != null &&
        _Cat.canEditUser(
          editorId:   me.id,
          editorRole: me.role,
          editorKeys: ref.read(warehouseAccessProvider).keys,
          targetId:   u.id,
          targetRole: u.role,
        ) &&
        (_role == u.role ||
            (me.id != u.id && _Cat.assignableRoles(me.role).contains(_role)));
    if (!ok) {
      setState(() => _error = 'Is user ka naam / role badalne ki ijazat nahi');
      return;
    }
    final name = _name.text.trim();
    if (name == u.fullName && _role == u.role) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = true;
      _error  = null;
    });
    final err = await ref
        .read(userProvider.notifier)
        .updateNameRole(u.id, name, _role);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _error  = err;
      });
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final width     = MediaQuery.of(context).size.width;
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
            left: width > 460 ? width - 440 : 16, right: 20, bottom: 20),
        backgroundColor: WarehouseAppColor.success,
        content: Text('$name update ho gaya',
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ));
  }

  InputDecoration get _dec => InputDecoration(
        filled:    true,
        fillColor: WarehouseAppColor.grey100,
        isDense:   true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: WarehouseAppColor.grey200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: WarehouseAppColor.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: WarehouseAppColor.primary, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final u  = widget.user;
    final me = ref.watch(authProvider).user;
    final isMe = me?.id == u.id;
    // Role list: editor jo de sakta hai + user ka mojooda role (dikhane ke liye)
    final roles = <String>{
      ..._Cat.assignableRoles(me?.role ?? ''),
      u.role,
    }.toList()
      ..sort((a, b) => _roleRank(a).compareTo(_roleRank(b)));
    final roleLocked = isMe;   // apna role koi nahi badalta (lockout se bachao)
    final customized = ref.watch(warehousePermissionsProvider).isCustomized(u.id);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color:        WarehouseAppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.manage_accounts_outlined,
                          size: 19, color: WarehouseAppColor.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Naam / Role badlein',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          Text('@${u.username}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: WarehouseAppColor.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('Poora naam',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _name,
                  autofocus:  true,
                  style: const TextStyle(fontSize: 14),
                  decoration: _dec,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Naam likhein';
                    if (v.trim().length < 2) return 'Naam bohat chhota hai';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                const Text('Role',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value:      _role,
                  isExpanded: true,
                  decoration: _dec,
                  items: [
                    for (final r in roles)
                      DropdownMenuItem(
                        value: r,
                        child: Text(_Cat.roleLabel(r),
                            style: const TextStyle(fontSize: 14)),
                      ),
                  ],
                  onChanged: roleLocked
                      ? null
                      : (v) => setState(() => _role = v ?? _role),
                ),
                const SizedBox(height: 8),
                Text(
                  roleLocked
                      ? 'Apna role khud nahi badal sakte — sirf naam.'
                      : (_Cat.isFullAccessRole(me?.role ?? '')
                          ? 'Owner = hamesha full access. Manager = default sab kuch.'
                          : 'Aap sirf Staff / Data Entry role de sakte hain.'),
                  style: const TextStyle(
                      fontSize: 11.5, color: WarehouseAppColor.textSecondary),
                ),
                if (!roleLocked && customized && _role != u.role) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Is user ka custom access save hai — role badalne se woh nahi '
                    'badlega. Naye role ke default chahiye to ⋮ → Role ke default.',
                    style: TextStyle(
                        fontSize: 11.5, color: WarehouseAppColor.warningDark),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: const TextStyle(
                          fontSize: 12.5, color: WarehouseAppColor.error)),
                ],
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WarehouseAppColor.primary,
                        foregroundColor: Colors.white,
                        elevation:   0,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined, size: 16),
                      label: Text(_saving ? 'Saving…' : 'Save',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
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
}

// ══════════════════════════════════════════════════════════════
// Password badlein (Owner / Manager) — naya + confirm, min 6 huroof
// ══════════════════════════════════════════════════════════════
class _ChangePasswordDialog extends ConsumerStatefulWidget {
  final UserModel user;
  const _ChangePasswordDialog({required this.user});

  static Future<void> show(BuildContext context, UserModel user) =>
      showDialog(
        context: context,
        builder: (_) => _ChangePasswordDialog(user: user),
      );

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pass    = TextEditingController();
  final _confirm = TextEditingController();
  bool    _show   = false;
  bool    _saving = false;
  String? _error;

  @override
  void dispose() {
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    // Double check (button pehle hi rule se dikhta hai)
    final me = ref.read(authProvider).user;
    final ok = me != null &&
        _Cat.canChangePassword(
          editorId:   me.id,
          editorRole: me.role,
          editorKeys: ref.read(warehouseAccessProvider).keys,
          targetId:   widget.user.id,
          targetRole: widget.user.role,
        );
    if (!ok) {
      setState(() => _error = 'Is user ka password badalne ki ijazat nahi');
      return;
    }
    setState(() {
      _saving = true;
      _error  = null;
    });
    final err = await ref
        .read(userProvider.notifier)
        .changePassword(widget.user.id, _pass.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _error  = err;
      });
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final width     = MediaQuery.of(context).size.width;
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
            left: width > 460 ? width - 440 : 16, right: 20, bottom: 20),
        backgroundColor: WarehouseAppColor.success,
        content: Text('${widget.user.fullName} ka password badal gaya',
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ));
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText:  hint,
        hintStyle: const TextStyle(color: WarehouseAppColor.textHint, fontSize: 13),
        filled:    true,
        fillColor: WarehouseAppColor.grey100,
        isDense:   true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        suffixIcon: IconButton(
          icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18, color: WarehouseAppColor.grey500),
          onPressed: () => setState(() => _show = !_show),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: WarehouseAppColor.grey200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: WarehouseAppColor.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: WarehouseAppColor.primary, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color:        WarehouseAppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.key_rounded,
                          size: 19, color: WarehouseAppColor.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Password badlein',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          Text('${u.fullName} · @${u.username}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: WarehouseAppColor.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('Naya password',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller:  _pass,
                  obscureText: !_show,
                  autofocus:   true,
                  style: const TextStyle(fontSize: 14),
                  decoration:  _dec('Kam se kam 6 huroof'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password likhein';
                    if (v.length < 6) return 'Min 6 characters chahiye';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                const Text('Dobara likhein',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller:  _confirm,
                  obscureText: !_show,
                  style: const TextStyle(fontSize: 14),
                  decoration:  _dec('Wahi password'),
                  onFieldSubmitted: (_) {
                    if (!_saving) _save();
                  },
                  validator: (v) =>
                      v != _pass.text ? 'Dono password ek jaise nahi' : null,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Naya password foran lag jata hai — user agli dafa isi se login karega.',
                  style: TextStyle(fontSize: 11.5, color: WarehouseAppColor.textSecondary),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: const TextStyle(
                          fontSize: 12.5, color: WarehouseAppColor.error)),
                ],
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WarehouseAppColor.primary,
                        foregroundColor: Colors.white,
                        elevation:   0,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined, size: 16),
                      label: Text(_saving ? 'Saving…' : 'Password save karein',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
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
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _MenuRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: WarehouseAppColor.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
