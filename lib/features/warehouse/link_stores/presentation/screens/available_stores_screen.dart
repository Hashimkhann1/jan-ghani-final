import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/warehouse/link_stores/data/models/store_model/store_model.dart';
import '../providers/link_stores_provider.dart';
import '../widgets/available_store_card.dart';

class AvailableStoresScreen extends ConsumerWidget {
  final String warehouseId;

  const AvailableStoresScreen({super.key, required this.warehouseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allStoresAsync = ref.watch(allStoresProvider);
    final linkedIdsAsync = ref.watch(linkedStoreIdsProvider(warehouseId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Available Stores'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: allStoresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text('Error: $error', style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
        data: (allStores) {
          return linkedIdsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: (linkedIds) {
              if (allStores.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.store_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No stores available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final linkedCount =
                  allStores.where((s) => linkedIds.contains(s.storeId)).length;

              return Column(
                children: [
                  // Summary bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    color: Colors.white,
                    child: Row(
                      children: [
                        _summaryChip(
                          label: 'Total',
                          count: allStores.length,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 12),
                        _summaryChip(
                          label: 'Linked',
                          count: linkedCount,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 12),
                        _summaryChip(
                          label: 'Available',
                          count: allStores.length - linkedCount,
                          color: Colors.orange.shade700,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 1),
                  // Grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: allStores.length,
                      itemBuilder: (context, index) {
                        final store = allStores[index];
                        final isLinked = linkedIds.contains(store.storeId);

                        return AvailableStoreCard(
                          store: store,
                          isAlreadyLinked: isLinked,
                          onLink: isLinked
                              ? null
                              : () async {
                            await _linkStore(context, ref, store);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _linkStore(
      BuildContext context,
      WidgetRef ref,
      StoreModel store,
      ) async {
    try {
      final linkStore = ref.read(linkStoreProvider);
      await linkStore(
        warehouseId: warehouseId,
        warehouseName: AppConfig.warehouseName,
        store: store,
        linkedByName: 'M Hashim',
        linkedById: null,
      );

      ref.invalidate(linkedStoreIdsProvider(warehouseId));
      ref.invalidate(allStoresProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('${store.storeName} linked successfully!'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}