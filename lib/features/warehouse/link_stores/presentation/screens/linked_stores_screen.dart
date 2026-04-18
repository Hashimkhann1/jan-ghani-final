import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/link_stores_provider.dart';
import '../widgets/linked_store_row.dart';
import 'available_stores_screen.dart';

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

          return Column(
            children: [
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: Colors.grey.shade100,
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Text('Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 3, child: Text('Store Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 2, child: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 2, child: Text('Manager', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 3, child: Text('Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                ),
              ),
              // Table rows
              Expanded(
                child: ListView.builder(
                  itemCount: stores.length,
                  itemBuilder: (context, index) {
                    return LinkedStoreRow(
                      store: stores[index],
                      index: index,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
