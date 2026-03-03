import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:jan_ghani_final/utils/app_colors/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHOW HELPER
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showAddProductDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AddProductDialog(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  int _tab = 0;

  // Basic
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedCategory;
  String? _previewImageUrl;

  // Pricing
  final _sellingCtrl = TextEditingController(text: '0');
  final _costCtrl = TextEditingController(text: '0');
  final _stockCtrl = TextEditingController(text: '0');
  final _lowStockCtrl = TextEditingController(text: '10');
  bool _trackInventory = true;

  final List<String> _categories = ['Beverages', 'DBR', 'Unilever', 'Snacks', 'Dairy', 'Oral Care'];
  static const _border = Color(0xFFE0E0E0);
  static const _labelStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A));
  static const _subText = Color(0xFF6C757D);

  double get _margin {
    final sell = double.tryParse(_sellingCtrl.text) ?? 0;
    final cost = double.tryParse(_costCtrl.text) ?? 0;
    if (sell == 0) return 0;
    return ((sell - cost) / sell) * 100;
  }

  double get _profitPerUnit {
    final sell = double.tryParse(_sellingCtrl.text) ?? 0;
    final cost = double.tryParse(_costCtrl.text) ?? 0;
    return sell - cost;
  }

  String _generateSku() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    final prefix = (_nameCtrl.text.isNotEmpty ? _nameCtrl.text.substring(0, min(3, _nameCtrl.text.length)).toUpperCase() : 'PRD');
    final suffix = List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
    return '$prefix-$suffix';
  }

  String _generateBarcode() {
    final rand = Random();
    return List.generate(13, (_) => rand.nextInt(10).toString()).join();
  }

  void _onImageUrlChanged(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty) {
      setState(() => _previewImageUrl = null);
      return;
    }
    // Fixed: Accept any URL that starts with http, https, or data:image
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('data:image')) {
      setState(() => _previewImageUrl = trimmed);
    } else {
      // Optional: still update preview even if invalid, or show error
      setState(() => _previewImageUrl = null);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _imageUrlCtrl.dispose();
    _descCtrl.dispose();
    _sellingCtrl.dispose();
    _costCtrl.dispose();
    _stockCtrl.dispose();
    _lowStockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      child: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: _buildTabContent(),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
      child: Row(
        children: [
          const Text('Add New Product',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20, color: Color(0xFF6C757D)),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ──────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    const tabs = ['Basic', 'Pricing', 'Info'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final selected = _tab == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: selected
                        ? Border.all(color: AppColors.primaryColors, width: 1.5)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.primaryColors : const Color(0xFF6C757D),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Tab Content ──────────────────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_tab) {
      case 0: return _buildBasicTab();
      case 1: return _buildPricingTab();
      case 2: return _buildInfoTab();
      default: return const SizedBox();
    }
  }

  // ── BASIC TAB ────────────────────────────────────────────────────────────
  Widget _buildBasicTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        const Text('Product Image', style: _labelStyle),
        const SizedBox(height: 10),
        Row(
          children: [
            // Preview box
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFF8F8F8),
              ),
              clipBehavior: Clip.antiAlias,
              child: _previewImageUrl != null
                  ? _buildImagePreview(_previewImageUrl!)
                  :  Center(
                child: Icon(Icons.upload_outlined,
                    size: 28, color: Color(0xFFADB5BD)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inputField(
                controller: _imageUrlCtrl,
                hint: 'Enter image URL',
                onChanged: _onImageUrlChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Product Name
        const Text('Product Name *', style: _labelStyle),
        const SizedBox(height: 8),
        _inputField(controller: _nameCtrl, hint: ''),
        const SizedBox(height: 20),

        // SKU + Barcode
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SKU *', style: _labelStyle),
                  const SizedBox(height: 8),
                  _inputWithAction(
                    controller: _skuCtrl,
                    icon: Icons.qr_code_2,
                    tooltip: 'Auto-generate SKU',
                    onAction: () => setState(() => _skuCtrl.text = _generateSku()),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Barcode', style: _labelStyle),
                  const SizedBox(height: 8),
                  _inputWithAction(
                    controller: _barcodeCtrl,
                    icon: Icons.barcode_reader,
                    tooltip: 'Auto-generate Barcode',
                    onAction: () => setState(() => _barcodeCtrl.text = _generateBarcode()),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Category
        Row(
          children: [
            const Text('Category', style: _labelStyle),
            const Spacer(),
            GestureDetector(
              onTap: _showAddCategoryDialog,
              child: const Text('+ New Category',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryColors,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              focusColor: Colors.transparent,
              value: _selectedCategory,
              autofocus: false,
              isExpanded: true,
              hint: const Text('Select category',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF6C757D)),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Description
        const Text('Description', style: _labelStyle),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _descCtrl,
            maxLines: 4,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── PRICING TAB ──────────────────────────────────────────────────────────
  Widget _buildPricingTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selling + Cost Price
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selling Price *', style: _labelStyle),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: _sellingCtrl,
                    hint: '0',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cost Price', style: _labelStyle),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: _costCtrl,
                    hint: '0',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Margin / Profit info cards
        Row(
          children: [
            Expanded(
              child: _infoCard(children: [
                _infoRow('Margin:', '${_margin.toStringAsFixed(1)}%',
                    valueColor: _margin < 0 ? AppColors.redColors : AppColors.redColors),
                const SizedBox(height: 6),
                _infoRow('Profit/Unit:', _profitPerUnit.toStringAsFixed(2)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _infoCard(children: [
                _infoRow('Avg Cost (WAC):', '0.00'),
                const SizedBox(height: 6),
                _infoRow('Last Purchase:', '0.00'),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Current Stock + Low Stock Alert
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Stock', style: _labelStyle),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: _stockCtrl,
                    hint: '0',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Low Stock Alert', style: _labelStyle),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: _lowStockCtrl,
                    hint: '10',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Track Inventory toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Track Inventory',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                  SizedBox(height: 2),
                  Text('Auto update stock on sales',
                      style: TextStyle(fontSize: 12, color: _subText)),
                ],
              ),
              const Spacer(),
              Switch(
                value: _trackInventory,
                onChanged: (v) => setState(() => _trackInventory = v),
                activeColor: AppColors.greenColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── INFO TAB ─────────────────────────────────────────────────────────────
  Widget _buildInfoTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Product Details',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 4),
        const Text('Please review all information before creating the product.',
            style: TextStyle(fontSize: 12, color: _subText)),
        const SizedBox(height: 20),

        // Image preview
        if (_previewImageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              _previewImageUrl!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        _reviewSection('Basic Information', [
          _reviewRow('Product Name', _nameCtrl.text.isEmpty ? '—' : _nameCtrl.text),
          _reviewRow('SKU', _skuCtrl.text.isEmpty ? '—' : _skuCtrl.text),
          _reviewRow('Barcode', _barcodeCtrl.text.isEmpty ? '—' : _barcodeCtrl.text),
          _reviewRow('Category', _selectedCategory ?? '—'),
          _reviewRow('Description', _descCtrl.text.isEmpty ? '—' : _descCtrl.text),
        ]),
        const SizedBox(height: 16),

        _reviewSection('Pricing & Stock', [
          _reviewRow('Selling Price', 'Rs ${_sellingCtrl.text}'),
          _reviewRow('Cost Price', 'Rs ${_costCtrl.text}'),
          _reviewRow('Margin', '${_margin.toStringAsFixed(1)}%'),
          _reviewRow('Profit/Unit', 'Rs ${_profitPerUnit.toStringAsFixed(2)}'),
          _reviewRow('Current Stock', _stockCtrl.text),
          _reviewRow('Low Stock Alert', _lowStockCtrl.text),
          _reviewRow('Track Inventory', _trackInventory ? 'Yes' : 'No'),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── FOOTER ───────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Cancel
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A1A),
              side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 10),
          // Next / Create Product
          ElevatedButton(
            onPressed: () {
              if (_tab < 2) {
                setState(() => _tab++);
              } else {
                // TODO: submit product
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColors,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(
              _tab == 2 ? 'Create Product' : 'Next',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryColors)),
        ),
      ),
    );
  }

  Widget _inputWithAction({
    required TextEditingController controller,
    required IconData icon,
    required String tooltip,
    required VoidCallback onAction,
  }) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          // Generate button on the LEFT
          Tooltip(
            message: tooltip,
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF8F8F8),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF495057)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primaryColors)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _subText)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? const Color(0xFF1A1A1A))),
      ],
    );
  }

  Widget _reviewSection(String title, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: _subText)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A))),
          ),
        ],
      ),
    );
  }

  // ── IMAGE PREVIEW HELPER (MOVED INSIDE THE CLASS) ────────────────────────
  Widget _buildImagePreview(String url) {
    // Handle base64
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.contains(',') ? url.split(',').last : url;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          width: 90,
          height: 90,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image_outlined,
                color: Color(0xFFADB5BD), size: 28),
          ),
        );
      } catch (_) {
        return const Center(
          child: Icon(Icons.broken_image_outlined,
              color: Color(0xFFADB5BD), size: 28),
        );
      }
    }

    // Handle network URL
    return Image.network(
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRtTTwP__hhA0q7_R9e1w3r-VyzrUB-_l11vA&s',
      fit: BoxFit.cover,
      width: 90,
      height: 90,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryColors,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image_outlined,
            color: Color(0xFFADB5BD), size: 28),
      ),
    );
  }



  // Add New Category ────────────────────────
  void _showAddCategoryDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('New Category',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter category name',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryColors),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6C757D))),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColors,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _categories.add(result);        // adds to the list
        _selectedCategory = result;     // auto-selects the new category
      });
    }
  }
}
