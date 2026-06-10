import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/link_stores_provider.dart';
import '../widgets/linked_store_row.dart';
import 'available_stores_screen.dart';
import '../../store_detail/presentation/screens/store_detail_shell.dart';

class LinkedStoresScreen extends ConsumerWidget {
  final String warehouseId;

  const LinkedStoresScreen({super.key, required this.warehouseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedStoresAsync = ref.watch(linkedStoresProvider(warehouseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Linked Stores'),
        actions: [
          SizedBox(
            width: 160,
            height: 36,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AvailableStoresScreen(
                        warehouseId: warehouseId,
                      ),
                    ),
                  );
                  ref.invalidate(linkedStoresProvider(warehouseId));
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Link Store'),
              ),
            ),
          ),
        ],
      ),
      body: linkedStoresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (stores) {
          if (stores.isEmpty) {
            return const Center(
              child: Text(
                'No stores linked yet.\nClick "Link New Store" to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              mainAxisExtent: 240,
            ),
            itemCount: stores.length,
            itemBuilder: (context, index) {
              return LinkedStoreRow(
                store: stores[index],
                index: index,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoreDetailShell(store: stores[index]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
