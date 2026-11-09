import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/color/app_color.dart';
import '../../../../customer/customer_invoices/data/datasource/customer_report_datasource.dart';
import '../providers/accoutant_session_provider.dart';
import '../providers/accountant_auth_providers.dart';

/// Staff (owner / accountant / viewer / manager) + customer dono accounts wale user ko login ke baad yahan ana hota
/// hai: "Choose your account". Intekhab session mein save hota hai; baad mein
/// sidebar / customer portal ke "Switch account" se yahin wapas aate hain.
class ChooseAccountScreen extends ConsumerStatefulWidget {
  const ChooseAccountScreen({super.key});

  @override
  ConsumerState<ChooseAccountScreen> createState() =>
      _ChooseAccountScreenState();
}

class _ChooseAccountScreenState extends ConsumerState<ChooseAccountScreen> {
  String? _branchName, _customerName;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    final u = ref.read(currentUserProvider);
    if (u == null) return;
    final c = Supabase.instance.client;
    try {
      if ((u.branchId ?? '').isNotEmpty) {
        final r = await c
            .from('branch')
            .select('name')
            .eq('id', u.branchId!)
            .maybeSingle();
        if (mounted) setState(() => _branchName = r?['name']?.toString());
      }
    } catch (_) {}
    try {
      final row = await CustomerReportDatasource()
          .getCustomerInfo(u.customerToken ?? '');
      final n = row?['name'] as String?;
      if (mounted && n != null && n.isNotEmpty) {
        setState(() => _customerName = n);
      }
    } catch (_) {}
  }

  void _choose(AccountMode m) =>
      ref.read(sessionProvider.notifier).setMode(m);
  // Router session.mode sun kar khud sahi screen par bhej deta hai.

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(currentUserProvider);
    if (u == null) return const SizedBox.shrink();

    final staffLines = <String>[
      u.role == 'manager'
          ? 'Branch: ${_branchName ?? '…'}'
          : switch (u.role) {
              'owner'      => 'Owner',
              'accountant' => 'Accountant',
              _            => 'View User',
            },
      'Branch & warehouse reports',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Choose your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1D23))),
                  const SizedBox(height: 6),
                  Text(
                    'Signed in as ${u.fullName.isEmpty ? u.email : u.fullName}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: AppColor.textHint),
                  ),
                  const SizedBox(height: 24),
                  _AccountCard(
                    icon: Icons.person_rounded,
                    color: const Color(0xFF10B981),
                    title: 'Customer Account',
                    lines: [
                      if (_customerName != null) _customerName!,
                      'Your invoices & balance',
                    ],
                    onTap: () => _choose(AccountMode.customer),
                  ),
                  const SizedBox(height: 14),
                  _AccountCard(
                    icon: Icons.bar_chart_rounded,
                    color: const Color(0xFF378ADD),
                    title: 'Jan Ghani Report',
                    lines: staffLines,
                    onTap: () => _choose(AccountMode.staff),
                  ),
                  const SizedBox(height: 18),
                  TextButton.icon(
                    onPressed: () async {
                      await ref
                          .read(accountantAuthNotifierProvider.notifier)
                          .logout();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Logout'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColor.textHint),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> lines;
  final VoidCallback onTap;

  const _AccountCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.lines,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1D23))),
                    const SizedBox(height: 4),
                    for (final l in lines)
                      Text(l,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColor.textHint)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
            ]),
          ),
        ),
      );
}
