// =============================================================
// store_detail_shell.dart
// Linked store ka detail container — left sidebar + content.
// Abhi sirf "Inventory". Baad mein naye sections yahan add honge
// (apne folder/files ke saath) — bas _sections list mein entry.
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/link_stores/data/models/linked_store_model/linked_store_model.dart';
import 'package:jan_ghani_final/features/warehouse/link_stores/inventory/presentation/screens/linked_store_inventory_screen.dart';

// ─────────────────────────────────────────────────────────────
// Section model
// ─────────────────────────────────────────────────────────────

class _Section {
  final IconData icon;
  final String label;
  final String description;
  final Widget Function(LinkedStoreModel store)? builder;

  const _Section({
    required this.icon,
    required this.label,
    required this.description,
    this.builder,
  });

  // builder null = abhi ready nahi (coming soon)
  bool get comingSoon => builder == null;
}

// Yahan naye sections add karein (e.g. Sales, Ledger) — apni screen ke saath
const List<_Section> _kSections = [
  _Section(
    icon: Icons.inventory_2_outlined,
    label: 'Inventory',
    description: 'Stock, low / out of stock',
    builder: _buildInventory,
  ),
];

Widget _buildInventory(LinkedStoreModel store) =>
    LinkedStoreInventoryScreen(storeId: store.storeId);

// ─────────────────────────────────────────────────────────────
// SHELL
// ─────────────────────────────────────────────────────────────

class StoreDetailShell extends StatefulWidget {
  final LinkedStoreModel store;
  const StoreDetailShell({super.key, required this.store});

  @override
  State<StoreDetailShell> createState() => _StoreDetailShellState();
}

class _StoreDetailShellState extends State<StoreDetailShell> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final store    = widget.store;
    final section  = _kSections[_selected];

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Row(
          children: [
            // ── Sidebar ─────────────────────────────────────
            _Sidebar(
              store: store,
              selected: _selected,
              onSelect: (i) => setState(() => _selected = i),
              onBack: () => Navigator.of(context).maybePop(),
            ),

            // ── Content ─────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ContentHeader(store: store, section: section),
                  Expanded(
                    child: (section.builder != null)
                        ? section.builder!(store)
                        : const _ComingSoon(),
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

// ─────────────────────────────────────────────────────────────
// SIDEBAR
// ─────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final LinkedStoreModel store;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onBack;

  const _Sidebar({
    required this.store,
    required this.selected,
    required this.onSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      decoration: const BoxDecoration(
        color: AppColor.surface,
        border: Border(right: BorderSide(color: AppColor.grey200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + store header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColor.grey100,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColor.grey200),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColor.grey700),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.storefront_rounded, size: 18, color: AppColor.primary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(store.storeName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                if (store.storeCode.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(store.storeCode,
                      style: const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppColor.grey200),
          const SizedBox(height: 8),

          // Section items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _kSections.length,
              itemBuilder: (_, i) {
                final s = _kSections[i];
                final isSel = i == selected;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: s.comingSoon ? null : () => onSelect(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? AppColor.primary.withOpacity(0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel ? AppColor.primary.withOpacity(0.3) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(s.icon, size: 17,
                              color: isSel ? AppColor.primary : AppColor.grey600),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.label,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isSel ? AppColor.primary : AppColor.textPrimary,
                                    )),
                                const SizedBox(height: 1),
                                Text(s.description,
                                    style: const TextStyle(fontSize: 9.5, color: AppColor.textHint),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          if (s.comingSoon)
                            const Text('Soon',
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppColor.grey400)),
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

// ─────────────────────────────────────────────────────────────
// CONTENT HEADER
// ─────────────────────────────────────────────────────────────

class _ContentHeader extends StatelessWidget {
  final LinkedStoreModel store;
  final _Section section;
  const _ContentHeader({required this.store, required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(section.icon, size: 18, color: AppColor.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section.label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.textPrimary)),
              Text('${store.storeName} · read-only',
                  style: const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// COMING SOON
// ─────────────────────────────────────────────────────────────

class _ComingSoon extends StatelessWidget {
  const _ComingSoon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_empty_rounded, size: 34, color: AppColor.grey300),
          SizedBox(height: 10),
          Text('Coming soon', style: TextStyle(fontSize: 13, color: AppColor.textHint)),
        ],
      ),
    );
  }
}
