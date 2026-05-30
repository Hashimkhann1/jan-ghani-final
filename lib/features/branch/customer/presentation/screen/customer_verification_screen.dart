import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/color/app_color.dart';
import '../provider/customer_report_provider.dart';
import 'customer_report_screen.dart';

class CustomerVerificationScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerVerificationScreen({
    super.key,
    required this.customerId,
  });

  @override
  ConsumerState<CustomerVerificationScreen> createState() =>
      _CustomerVerificationScreenState();
}

class _CustomerVerificationScreenState
    extends ConsumerState<CustomerVerificationScreen> {
  final _phoneCtrl  = TextEditingController();
  final _focusNode  = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final notifier = ref.read(
      customerVerifyProvider(widget.customerId).notifier,
    );
    await notifier.verify(_phoneCtrl.text.trim());

    final state = ref.read(customerVerifyProvider(widget.customerId));
    if (!mounted) return;

    if (state.isVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerReportScreen(
            customerId:   widget.customerId,
            customerName: state.customerName ?? '',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      customerVerifyProvider(widget.customerId),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // ── Icon ────────────────────────────────────────
                Container(
                  width:  80,
                  height: 80,
                  decoration: BoxDecoration(
                    color:        AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size:  36,
                    color: AppColor.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Title ────────────────────────────────────────
                const Text(
                  'Verify Your Identity',
                  style: TextStyle(
                    fontSize:   22,
                    fontWeight: FontWeight.w800,
                    color:      Color(0xFF1A1D23),
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Enter the last 4 digits of your\nregistered phone number',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color:    AppColor.textSecondary,
                    height:   1.5,
                  ),
                ),
                const SizedBox(height: 36),

                // ── Input ─────────────────────────────────────────
                TextField(
                  controller:    _phoneCtrl,
                  focusNode:     _focusNode,
                  keyboardType:  TextInputType.number,
                  textAlign:     TextAlign.center,
                  maxLength:     4,
                  style: const TextStyle(
                    fontSize:      28,
                    fontWeight:    FontWeight.w800,
                    letterSpacing: 12,
                    color:         Color(0xFF1A1D23),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (v) {
                    // Auto verify when 4 digits entered
                    if (v.length == 4) _verify();
                  },
                  decoration: InputDecoration(
                    counterText:  '',
                    hintText:     '• • • •',
                    hintStyle: const TextStyle(
                      fontSize:      28,
                      letterSpacing: 12,
                      color:         AppColor.grey400,
                    ),
                    filled:      true,
                    fillColor:   Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical:   20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:   BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColor.grey200, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColor.primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColor.error, width: 1.5),
                    ),
                    errorText: state.status == VerifyStatus.failed
                        ? state.errorMessage
                        : null,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Button ────────────────────────────────────────
                SizedBox(
                  width:  double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                      AppColor.primary.withOpacity(0.6),
                      elevation:    0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                      width:  22,
                      height: 22,
                      child:  CircularProgressIndicator(
                        color:       Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      'Verify & View Report',
                      style: TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Helper text ───────────────────────────────────
                const Text(
                  'Example: if your number is 0300-1234567\nenter 4567',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color:    AppColor.textHint,
                    height:   1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}