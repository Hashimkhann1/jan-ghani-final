import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/inventory_countting_model.dart';
import '../provider/inventory_counting_provider.dart';

class InventoryCountingScreen extends ConsumerWidget {
  static const String _storeId = '09ed6ad4-373d-4afb-a7fb-badb1e72e9e3';

  const InventoryCountingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryCountingProvider(_storeId));
    final notifier = ref.read(inventoryCountingProvider(_storeId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Inventory Counting'),
            Text(
              'Counted: ${state.countedCount} / 50',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // Reload: sirf tab show karo jab 50 complete hon
          if (state.allCounted)
            IconButton(
              tooltip: 'Load Next 50',
              icon: const Icon(Icons.refresh),
              onPressed: state.isLoading ? null : () => notifier.loadPage(),
            ),
        ],
      ),
      body: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(
      BuildContext context,
      InventoryCountingState state,
      InventoryCountingNotifier notifier,
      ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => notifier.loadPage(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.allCounted && state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              '50 products counted!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'AppBar mein Reload button se next 50 load karo',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (state.products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Koi product nahi mila',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.products.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = state.products[index];
        return _ProductListTile(
          key: ValueKey(product.productId), // ← ye zaroori hai
          serialNumber: state.countedCount + index + 1,
          product: product,
          onSubmit: (countingStock) => notifier.submitCounting(
            product: product,
            countingStock: countingStock,
          ),
        );
      },
    );
  }
}

// ─── Product List Tile ────────────────────────────────────────────────────────

class _ProductListTile extends StatefulWidget {
  final int serialNumber;
  final InventoryProductModel product;
  // bool return karta hai — true: success, false: error
  final Future<bool> Function(double countingStock) onSubmit;

  const _ProductListTile({
    super.key,
    required this.serialNumber,
    required this.product,
    required this.onSubmit,
  });

  @override
  State<_ProductListTile> createState() => _ProductListTileState();
}

class _ProductListTileState extends State<_ProductListTile> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final value = double.tryParse(_controller.text.trim());
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sirf number likho'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await widget.onSubmit(value);

    // Agar error aaya toh spinner hata do — tile wapas active ho jaye
    if (!success && mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save nahi hua, dobara try karo'),
          backgroundColor: Colors.red,
        ),
      );
    }
    // Success pe tile list se remove ho jata hai — setState zaroori nahi
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Text(
        '${widget.serialNumber}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      title: Text(
        widget.product.productName,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: SizedBox(
        width: 130,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                enabled: !_isSubmitting,
                onSubmitted: (_) => _handleSubmit(),
                decoration: InputDecoration(
                  hintText: 'Count',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _isSubmitting
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : InkWell(
              onTap: _handleSubmit,
              borderRadius: BorderRadius.circular(4),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}