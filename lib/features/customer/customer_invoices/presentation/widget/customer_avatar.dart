import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../provider/customer_report_provider.dart';

const _accent = Color(0xFF0F5C3F);
const _red = Color(0xFFC01048);

/// Customer ka avatar — tap karke photo upload (photo na ho to naam ka pehla harf).
class CustomerAvatar extends ConsumerWidget {
  final String customerId;
  final String name;
  final double size;

  /// false = sirf initial (photo upload nahi) — jin customers ki `customer`
  /// table mein row nahi (installment-only), unke liye.
  final bool editable;
  const CustomerAvatar({
    super.key,
    required this.customerId,
    required this.name,
    this.size = 46,
    this.editable = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoUrl = editable
        ? ref.watch(customerPhotoProvider(customerId)).asData?.value
        : null;
    final radius   = size * 0.3;

    return GestureDetector(
      onTap: editable
          ? () => _pickAndUploadCustomerPhoto(context, ref, customerId)
          : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size, height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F5C3F), Color(0xFF0B4A32)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: (photoUrl != null && photoUrl.isNotEmpty)
                ? Image.network(
              photoUrl,
              width: size, height: size, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initial(),
            )
                : _initial(),
          ),
          if (editable)
          Positioned(
            right: -2, bottom: -2,
            child: Container(
              width: size * 0.36, height: size * 0.36,
              decoration: BoxDecoration(
                color:  _accent,
                shape:  BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(Icons.camera_alt_rounded,
                  size: size * 0.2, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initial() => Text(
    name.isNotEmpty ? name[0].toUpperCase() : '?',
    style: TextStyle(
        color: Colors.white, fontSize: size * 0.43,
        fontWeight: FontWeight.w700),
  );
}

Future<void> _pickAndUploadCustomerPhoto(
    BuildContext context, WidgetRef ref, String customerId) async {
  try {
    final file = await ImagePicker().pickImage(
      source:      ImageSource.gallery,
      maxWidth:    1024,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final ext = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'jpg';

    await ref.read(customerPhotoProvider(customerId).notifier).upload(bytes, ext);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Photo upload failed: $e'),
        backgroundColor: _red,
      ));
    }
  }
}
