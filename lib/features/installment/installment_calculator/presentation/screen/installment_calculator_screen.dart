import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/installment/domain/installment_calculator.dart';
import 'package:jan_ghani_final/features/installment/installment_plan_detail/domain/installment_schedule_item.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_customer.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/presentation/provider/installment_dashboard_provider.dart';

/// Officer ka installment calculator: customer select → product, qeemat,
/// advance → plan (6/10/12/18/24 mahine) → schedule ban kar database mein save.
/// Formula website ke calculator wala hi hai (InstallmentCalculator).
class InstallmentCalculatorScreen extends ConsumerStatefulWidget {
  /// Diya jaye to customer pehle se select hota hai.
  final String? customerId;
  const InstallmentCalculatorScreen({super.key, this.customerId});

  @override
  ConsumerState<InstallmentCalculatorScreen> createState() =>
      _InstallmentCalculatorScreenState();
}

class _InstallmentCalculatorScreenState
    extends ConsumerState<InstallmentCalculatorScreen> {
  static const Color _canvas = Color(0xFFF7F7F9);

  final _productCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _advanceCtrl = TextEditingController();

  InstallmentCustomer? _customer;
  String? _customerId; // data load hone se pehle bhi yaad rahe
  int _months = 12;
  DateTime _start = DateTime.now();
  bool _advanceTouched = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _customerId = widget.customerId;
  }

  @override
  void dispose() {
    _productCtrl.dispose();
    _priceCtrl.dispose();
    _advanceCtrl.dispose();
    super.dispose();
  }

  double _parse(String t) => double.tryParse(t.replaceAll(',', '').trim()) ?? 0;
  double get _price => _parse(_priceCtrl.text);
  double get _advance => _parse(_advanceCtrl.text);

  /// User ne advance khud nahi likha to hamesha 15% auto bhar do.
  void _onPriceChanged(String _) {
    if (!_advanceTouched) {
      final min = InstallmentCalculator.minAdvance(_price);
      _advanceCtrl.text = _price > 0 ? min.toStringAsFixed(0) : '';
    }
    setState(() => _error = null);
  }

  String? get _advanceError =>
      _price <= 0 ? null : InstallmentCalculator.validateAdvance(_price, _advance);

  bool get _canQuote => _price > 0 && _advanceError == null;

  InstallmentQuote? _quoteFor(int months) => _canQuote
      ? InstallmentCalculator.quote(
          price: _price, advance: _advance, months: months)
      : null;

  Future<void> _pickCustomer(List<InstallmentCustomer> all) async {
    final picked = await showModalBottomSheet<InstallmentCustomer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CustomerPicker(customers: all),
    );
    if (picked != null) {
      setState(() {
        _customer = picked;
        _customerId = picked.id;
        _error = null;
      });
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _start = d);
  }

  Future<void> _save() async {
    final customer = _customer;
    if (customer == null) {
      setState(() => _error = 'Select a customer');
      return;
    }
    if (_productCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter the product name');
      return;
    }
    final quote = _quoteFor(_months);
    if (quote == null) {
      setState(() => _error = _advanceError ?? 'Enter the product price');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(installmentRemoteProvider).createPlan(
            customerId: customer.id,
            product: _productCtrl.text.trim(),
            quote: quote,
            startDate: _start,
          );
      if (!mounted) return;
      refreshInstallments(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Plan created for ${customer.name}: ${quote.months} installments')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(installmentCustomersDataProvider);

    // Preselected customer data aane par resolve karo.
    if (_customer == null && _customerId != null) {
      _customer = customers.valueOrNull
          ?.where((c) => c.id == _customerId)
          .firstOrNull;
    }

    final quote = _quoteFor(_months);

    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: AppColor.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColor.surface,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColor.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Installment Calculator',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColor.grey200),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                children: [
                  // ── Customer ───────────────────────────────────────────
                  const _Label('Customer'),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: customers.hasValue
                        ? () => _pickCustomer(customers.value!)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: _boxDeco(),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline,
                              color: AppColor.textSecondary),
                          10.wBox,
                          Expanded(
                            child: Text(
                              _customer?.name ??
                                  (customers.isLoading
                                      ? 'Loading customers...'
                                      : 'Select customer'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _customer == null
                                    ? AppColor.textHint
                                    : AppColor.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down,
                              color: AppColor.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  18.hBox,

                  // ── Product ────────────────────────────────────────────
                  const _Label('Product name'),
                  TextField(
                    controller: _productCtrl,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() => _error = null),
                    decoration: _inputDeco('e.g. Samsung 43" LED TV'),
                  ),
                  18.hBox,

                  // ── Price / Advance ────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Label('Price'),
                            TextField(
                              controller: _priceCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: _onPriceChanged,
                              decoration: _inputDeco('Rs 0', prefix: 'Rs '),
                            ),
                          ],
                        ),
                      ),
                      12.wBox,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Label('Advance paid'),
                            TextField(
                              controller: _advanceCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: (t) => setState(() {
                                _advanceTouched = t.trim().isNotEmpty;
                                _error = null;
                              }),
                              decoration: _inputDeco('Rs 0', prefix: 'Rs '),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_price > 0) ...[
                    6.hBox,
                    Text(
                      _advanceError ??
                          'Remaining: Rs ${(_price - _advance).pkrFormat}  •  '
                              'min advance Rs ${InstallmentCalculator.minAdvance(_price).pkrFormat}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _advanceError != null
                            ? AppColor.error
                            : AppColor.textSecondary,
                      ),
                    ),
                  ],
                  22.hBox,

                  // ── Months ─────────────────────────────────────────────
                  const _Label('Plan length'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in InstallmentCalculator.plans)
                        _MonthChip(
                          months: m,
                          selected: m == _months,
                          monthly: _quoteFor(m)?.monthly,
                          onTap: () => setState(() => _months = m),
                        ),
                    ],
                  ),
                  22.hBox,

                  // ── Breakdown ──────────────────────────────────────────
                  if (quote != null) _Breakdown(quote: quote),
                  if (quote != null) ...[
                    14.hBox,
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: _boxDeco(),
                        child: Row(
                          children: [
                            const Icon(Icons.event_outlined,
                                color: AppColor.textSecondary),
                            10.wBox,
                            const Expanded(
                              child: Text('Start date',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: AppColor.textSecondary)),
                            ),
                            Text(planDetailDmy(_start),
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                    14.hBox,
                    _SchedulePreview(quote: quote, start: _start),
                  ],
                ],
              ),
            ),
            _buildBottom(quote),
          ],
        ),
      ),
    );
  }

  Widget _buildBottom(InstallmentQuote? quote) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColor.surface,
        border: Border(top: BorderSide(color: AppColor.grey200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColor.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_error!,
                  style:
                      const TextStyle(color: AppColor.error, fontSize: 13)),
            ),
            10.hBox,
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: AppColor.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      quote == null
                          ? 'Create plan'
                          : 'Create plan  •  Rs ${quote.monthly.pkrFormat} x ${quote.months}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDeco() => BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.grey300),
      );

  InputDecoration _inputDeco(String hint, {String? prefix}) => InputDecoration(
        hintText: hint,
        prefixText: prefix,
        hintStyle: const TextStyle(color: AppColor.textHint),
        filled: true,
        fillColor: AppColor.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
        ),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColor.textSecondary)),
      );
}

class _MonthChip extends StatelessWidget {
  final int months;
  final bool selected;
  final double? monthly;
  final VoidCallback onTap;
  const _MonthChip({
    required this.months,
    required this.selected,
    required this.monthly,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 104,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColor.primary.withValues(alpha: 0.08)
                : AppColor.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColor.primary : AppColor.grey300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text('$months months',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColor.primary : AppColor.textPrimary,
                  )),
              const SizedBox(height: 2),
              Text(
                monthly == null ? '—' : 'Rs ${monthly!.pkrFormat}/mo',
                style: const TextStyle(
                    fontSize: 11, color: AppColor.textSecondary),
              ),
            ],
          ),
        ),
      );
}

class _Breakdown extends StatelessWidget {
  final InstallmentQuote quote;
  const _Breakdown({required this.quote});

  @override
  Widget build(BuildContext context) {
    final pct = (InstallmentCalculator.ratePerMonth * quote.months * 100);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Column(
        children: [
          _Row('Price', 'Rs ${quote.price.pkrFormat}'),
          _Row('Advance', 'Rs ${quote.advance.pkrFormat}'),
          _Row('Remaining', 'Rs ${quote.financed.pkrFormat}'),
          _Row('Charge (${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1)}%)',
              'Rs ${quote.charge.pkrFormat}'),
          const Divider(height: 20, color: AppColor.grey200),
          _Row('Total installment', 'Rs ${quote.total.pkrFormat}', bold: true),
          _Row('Monthly', 'Rs ${quote.monthly.pkrFormat} x ${quote.months}',
              bold: true, color: AppColor.primary),
          if ((quote.last - quote.monthly).abs() >= 1)
            _Row('Last installment', 'Rs ${quote.last.pkrFormat}'),
          _Row('Total with advance', 'Rs ${quote.grandTotal.pkrFormat}'),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color color;
  const _Row(this.label, this.value,
      {this.bold = false, this.color = AppColor.textPrimary});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14, color: AppColor.textSecondary)),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    color: color)),
          ],
        ),
      );
}

class _SchedulePreview extends StatelessWidget {
  final InstallmentQuote quote;
  final DateTime start;
  const _SchedulePreview({required this.quote, required this.start});

  @override
  Widget build(BuildContext context) {
    final rows = quote.schedule(start);
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.grey200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text('Schedule (${rows.length} installments)',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          children: [
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('${r.number}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColor.textSecondary)),
                    ),
                    Expanded(
                      child: Text(planDetailDmy(r.dueDate),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    Text('Rs ${r.amount.pkrFormat}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Customer chunne ki bottom sheet (search ke saath).
class _CustomerPicker extends StatefulWidget {
  final List<InstallmentCustomer> customers;
  const _CustomerPicker({required this.customers});

  @override
  State<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends State<_CustomerPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = widget.customers
        .where((c) =>
            c.name.toLowerCase().contains(_q) || c.phone.contains(_q))
        .toList();
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColor.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search customer...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColor.grey100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(
                      child: Text('No customers found',
                          style: TextStyle(color: AppColor.textSecondary)))
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColor.grey100),
                      itemBuilder: (_, i) {
                        final c = list[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColor.primary.withValues(alpha: 0.12),
                            child: Text(c.initials,
                                style: const TextStyle(
                                    color: AppColor.primary,
                                    fontWeight: FontWeight.w700)),
                          ),
                          title: Text(c.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: c.phone.isEmpty ? null : Text(c.phone),
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
