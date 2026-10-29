import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/accountant_auth_providers.dart';
import '../state/accountant_auth_state.dart';

final _uuidRe = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

/// Branch ke customer QR (customer id) ko scan karke account connect karta hai.
/// Success par session update hota hai aur router customer portal khol deta hai.
class AccountantConnectScanScreen extends ConsumerStatefulWidget {
  const AccountantConnectScanScreen({super.key});

  @override
  ConsumerState<AccountantConnectScanScreen> createState() =>
      _AccountantConnectScanScreenState();
}

class _AccountantConnectScanScreenState
    extends ConsumerState<AccountantConnectScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final code = capture.barcodes
        .map((b) => b.rawValue?.trim())
        .whereType<String>()
        .firstOrNull;
    if (code == null) return;

    // `user:<id>` = branch user (staff), sirf `<id>` = branch ka customer.
    final isBranchUser = code.startsWith('user:');
    final id = isBranchUser ? code.substring(code.indexOf(':') + 1) : code;
    if (!_uuidRe.hasMatch(id)) {
      setState(() => _error = 'This is not a Jan Ghani customer QR');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final notifier = ref.read(accountantAuthNotifierProvider.notifier);
    if (isBranchUser) {
      await notifier.connectBranchUser(id);
    } else {
      await notifier.connectCustomer(id);
    }
    if (!mounted) return;

    final auth = ref.read(accountantAuthNotifierProvider);
    if (auth.status == AuthStatus.error) {
      setState(() {
        _busy = false;
        _error = auth.errorMessage;
      });
      notifier.resetState();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan customer QR'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Camera is not available. Please allow camera access.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_busy)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  const Text(
                    'Point the camera at the QR shown at the branch',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColor.errorLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColor.error, fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
