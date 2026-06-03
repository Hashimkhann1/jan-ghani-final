import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/color/app_color.dart';
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

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(branchProvider);
    final notifier = ref.read(branchProvider.notifier);

    // ── Error Snackbar ────────────────────────────────────
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
      body: CustomScrollView(
        slivers: [

          // ── SliverAppBar ──────────────────────────────────
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
                child: TextField(
                  controller: _searchCtrl,
                  onChanged:  notifier.search,
                  style: const TextStyle(fontSize: 14),
                  cursorHeight: 16,
                  decoration: InputDecoration(
                    hintText: 'Branch dhoondein...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColor.textHint),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 20, color: AppColor.primary),
                    suffixIcon: state.searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          size: 18, color: AppColor.textHint),
                      onPressed: () {
                        _searchCtrl.clear();
                        notifier.search('');
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
                      borderSide:
                      const BorderSide(color: AppColor.grey200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColor.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Subtitle ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Kisi branch ko tap karke uska data dekhein',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500),
              ),
            ),
          ),

          // ── Loading ───────────────────────────────────────
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )

          // ── Empty ─────────────────────────────────────────
          else if (state.filtered.isEmpty)
            const SliverFillRemaining(child: _EmptyState())

          // ── List ──────────────────────────────────────────
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.separated(
                itemCount:        state.filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) =>
                    _BranchCard(branch: state.filtered[i]),
              ),
            ),
        ],
      ),
    );
  }
}


class _BranchCard extends StatelessWidget {
  final BranchModel branch;
  const _BranchCard({required this.branch});

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
            style: const TextStyle(
                fontSize: 12, color: AppColor.textHint),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColor.textHint),
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

// ═══════════════════════════════════════════════════════════
//  Empty State
// ═══════════════════════════════════════════════════════════

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
          style: TextStyle(
              fontSize: 13, color: Colors.grey.shade400),
        ),
      ],
    ),
  );
}