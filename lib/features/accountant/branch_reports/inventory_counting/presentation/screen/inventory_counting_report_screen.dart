import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/model/inventory_counting_report_model.dart';
import '../provider/inventory_counting_provider.dart';

const double _kWideBreakpoint = 900;

// UUID pattern — rows jahan product name resolve nahi hua
final _uuidRegex = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

bool _isUuid(String s) => _uuidRegex.hasMatch(s);

String _barcodeText(List<String> barcodes) =>
    barcodes.isEmpty ? '—' : barcodes.join(', ');

class InventoryCountingReportScreen extends ConsumerStatefulWidget {
  final String storeId;

  const InventoryCountingReportScreen({
    super.key,
    required this.storeId,
  });

  @override
  ConsumerState<InventoryCountingReportScreen> createState() =>
      _InventoryCountingReportScreenState();
}

class _InventoryCountingReportScreenState
    extends ConsumerState<InventoryCountingReportScreen> {
  final _searchController = TextEditingController();
  final _startController  = TextEditingController();
  final _endController    = TextEditingController();
  final _fieldDateFmt      = DateFormat('dd MMM yyyy');

  @override
  void dispose() {
    _searchController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate(
      InventoryCountingReportNotifier notifier,
      InventoryCountingReportState state,
      ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: state.startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _startController.text = _fieldDateFmt.format(picked);
      notifier.setStartDate(picked);
    }
  }

  Future<void> _pickEndDate(
      InventoryCountingReportNotifier notifier,
      InventoryCountingReportState state,
      ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: state.endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _endController.text = _fieldDateFmt.format(picked);
      notifier.setEndDate(picked);
    }
  }

  void _clearDates(InventoryCountingReportNotifier notifier) {
    _startController.clear();
    _endController.clear();
    notifier.clearDateFilter();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryCountingReportProvider(widget.storeId));
    final notifier =
    ref.read(inventoryCountingReportProvider(widget.storeId).notifier);

    // UUID wali rows hamesha hide (search + date filter provider mein ho chuka)
    final visible = state.filtered.where((r) => !_isUuid(r.productName)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Inventory Counting Report"),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!state.isLoading && state.errorMessage == null && state.records.isNotEmpty) ...[
              _buildSummaryCards(context, visible),
              _buildSearchBar(context, notifier),
              _buildDateFilterRow(context, notifier, state),
            ],
            Expanded(child: _buildBody(context, visible, state, notifier)),
          ],
        ),
      ),
    );
  }

  // ─── Summary Cards ────────────────────────────────────────────────────────

  Widget _buildSummaryCards(
      BuildContext context, List<InventoryCountingRecord> visible) {
    final surplus = visible.where((r) => r.difference > 0).length;
    final shortage = visible.where((r) => r.difference < 0).length;
    final matched = visible.where((r) => r.difference == 0).length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _StatCard(
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFF4A90D9),
              label: 'Total',
              value: '${visible.length}',
              valueColor: const Color(0xFF4A90D9),
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: Icons.trending_up,
              iconColor: Colors.green,
              label: 'Surplus',
              value: '$surplus',
              valueColor: Colors.green,
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: Icons.trending_down,
              iconColor: Colors.red,
              label: 'Shortage',
              value: '$shortage',
              valueColor: Colors.red,
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: Icons.check_circle_outline,
              iconColor: Colors.grey,
              label: 'Matched',
              value: '$matched',
              valueColor: Colors.grey.shade700,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Search Bar ───────────────────────────────────────────────────────────

  Widget _buildSearchBar(
      BuildContext context, InventoryCountingReportNotifier notifier) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: notifier.search,
        decoration: InputDecoration(
          hintText: 'Product name or barcode search...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon:
          Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: () {
              _searchController.clear();
              notifier.search('');
            },
          )
              : null,
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: Color(0xFF4A90D9), width: 1.5),
          ),
        ),
      ),
    );
  }

  // ─── Date Filter Row ──────────────────────────────────────────────────────

  Widget _buildDateFilterRow(
      BuildContext context,
      InventoryCountingReportNotifier notifier,
      InventoryCountingReportState state,
      ) {
    final hasDateFilter = state.startDate != null || state.endDate != null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _startController,
              readOnly: true,
              onTap: () => _pickStartDate(notifier, state),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Start date',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: Icon(Icons.calendar_today_outlined,
                    size: 16, color: Colors.grey.shade500),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: Color(0xFF4A90D9), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _endController,
              readOnly: true,
              onTap: () => _pickEndDate(notifier, state),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'End date',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: Icon(Icons.calendar_today_outlined,
                    size: 16, color: Colors.grey.shade500),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: Color(0xFF4A90D9), width: 1.5),
                ),
              ),
            ),
          ),
          if (hasDateFilter) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _clearDates(notifier),
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18, color: Colors.red),
              tooltip: 'Clear date filter',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody(
      BuildContext context,
      List<InventoryCountingRecord> visible,
      InventoryCountingReportState state,
      InventoryCountingReportNotifier notifier,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child:
              Text(state.errorMessage!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => notifier.loadReport(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              (state.searchQuery.isNotEmpty ||
                  state.startDate != null ||
                  state.endDate != null)
                  ? 'Koi product nahi mila'
                  : 'Koi record nahi mila',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _kWideBreakpoint) {
          return _WebTableView(records: visible);
        }
        return _MobileCardView(records: visible);
      },
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                  TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: valueColor)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Web Table View ───────────────────────────────────────────────────────────

class _WebTableView extends StatelessWidget {
  final List<InventoryCountingRecord> records;
  const _WebTableView({required this.records});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  // Table header
                  Container(
                    color: const Color(0xFFF8F9FA),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: const Row(
                      children: [
                        SizedBox(width: 40, child: _ColHeader('#')),
                        SizedBox(width: 200, child: _ColHeader('Product')),
                        SizedBox(width: 140, child: _ColHeader('Barcode')),
                        SizedBox(
                            width: 90,
                            child: _ColHeader('Min Stock',
                                align: TextAlign.right)),
                        SizedBox(
                            width: 90,
                            child: _ColHeader('Max Stock',
                                align: TextAlign.right)),
                        SizedBox(
                            width: 100,
                            child: _ColHeader('System Stock',
                                align: TextAlign.right)),
                        SizedBox(
                            width: 100,
                            child: _ColHeader('Counted Stock',
                                align: TextAlign.right)),
                        SizedBox(
                            width: 100,
                            child: _ColHeader('Difference',
                                align: TextAlign.right)),
                        Expanded(
                            child: _ColHeader('Counted On',
                                align: TextAlign.right)),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  // Rows
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => Divider(
                        height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final r = records[index];
                      final isEven = index % 2 == 0;
                      return Container(
                        color: isEven
                            ? Colors.white
                            : const Color(0xFFFAFAFA),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text('${index + 1}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade400)),
                            ),
                            SizedBox(
                              width: 200,
                              child: Text(r.productName,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            SizedBox(
                              width: 140,
                              child: Text(
                                _barcodeText(r.barcodes),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              child: Text(
                                r.minStock.toStringAsFixed(1),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600),
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              child: Text(
                                r.maxStock.toStringAsFixed(1),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text(
                                r.productStock.toStringAsFixed(1),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text(
                                r.countingStock.toStringAsFixed(1),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: _DifferenceBadge(
                                    difference: r.difference),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                DateFormat('dd MMM yyyy')
                                    .format(r.countedDate),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

class _ColHeader extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _ColHeader(this.text, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ─── Mobile Card View ─────────────────────────────────────────────────────────

class _MobileCardView extends StatelessWidget {
  final List<InventoryCountingRecord> records;
  const _MobileCardView({required this.records});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _MobileCard(serialNumber: index + 1, record: records[index]),
    );
  }
}

class _MobileCard extends StatelessWidget {
  final int serialNumber;
  final InventoryCountingRecord record;
  const _MobileCard({required this.serialNumber, required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text('$serialNumber',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(record.productName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2),
              ),
              _DifferenceBadge(difference: record.difference),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.tag_rounded, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _barcodeText(record.barcodes),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Min Stock',
                  value: record.minStock.toStringAsFixed(1),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Max Stock',
                  value: record.maxStock.toStringAsFixed(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                    label: 'System Stock',
                    value: record.productStock.toStringAsFixed(1)),
              ),
              Expanded(
                child: _MiniStat(
                    label: 'Counted Stock',
                    value: record.countingStock.toStringAsFixed(1)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Counted On',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
              Text(
                DateFormat('dd MMM yyyy').format(record.countedDate),
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _MiniStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color ?? Colors.black87)),
      ],
    );
  }
}

// ─── Difference Badge ─────────────────────────────────────────────────────────

class _DifferenceBadge extends StatelessWidget {
  final double difference;
  const _DifferenceBadge({required this.difference});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String text;

    if (difference > 0) {
      bg = Colors.green.withOpacity(0.1);
      fg = Colors.green.shade700;
      text = '+${difference.toStringAsFixed(1)}';
    } else if (difference < 0) {
      bg = Colors.red.withOpacity(0.1);
      fg = Colors.red.shade700;
      text = difference.toStringAsFixed(1);
    } else {
      bg = Colors.grey.withOpacity(0.1);
      fg = Colors.grey.shade600;
      text = '0.0';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
