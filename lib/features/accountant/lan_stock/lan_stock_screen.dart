// Mobile par branch ka LOCAL stock (same Wi-Fi par branch PC ke Postgres se).
// Read-only: name, barcode, shelf, stock, purchase & sale price.

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/branch/branch_stock_inventory/data/model/branch_stock_model.dart';

import 'barcode_scan_screen.dart';
import 'lan_stock_service.dart';

class LanStockScreen extends StatefulWidget {
  const LanStockScreen({super.key});

  @override
  State<LanStockScreen> createState() => _LanStockScreenState();
}

class _LanStockScreenState extends State<LanStockScreen> {
  final _search = TextEditingController();
  List<BranchStockModel> _all = const [];
  String _filter = 'all'; // all | in_stock | low_stock | out_of_stock | loss
  String _query = '';
  String _host = LanStockService.defaultHost;
  bool _loading = true;
  String? _error;
  DateTime? _loadedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final t = await LanStockService.instance.loadTarget();
      _host = t.host;
      final rows = await LanStockService.instance.fetchAll();
      if (!mounted) return;
      setState(() {
        _all = rows;
        _loadedAt = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<BranchStockModel> get _filtered {
    final q = _query.trim().toLowerCase();
    return _all.where((p) {
      if (_filter == 'in_stock' && (p.isLowStock || p.isOutOfStock)) {
        return false;
      }
      if (_filter == 'low_stock' && !p.isLowStock) return false;
      if (_filter == 'out_of_stock' && !p.isOutOfStock) return false;
      // Loss: purchase price sale price se zyada.
      if (_filter == 'loss' && !(p.costPrice > p.sellingPrice)) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          (p.barcode?.toLowerCase().contains(q) ?? false) ||
          (p.shelfName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _scan() async {
    final code = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const BarcodeScanScreen()));
    if (code == null || !mounted) return;
    _search.text = code;
    setState(() {
      _query = code;
      _filter = 'all';
    });
  }

  Future<void> _editShelf(BranchStockModel p) async {
    final c = TextEditingController(text: p.shelfName ?? '');
    final stockC = TextEditingController(
        text: p.quantity == p.quantity.roundToDouble()
            ? p.quantity.toStringAsFixed(0)
            : p.quantity.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: c,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  labelText: 'Shelf',
                  hintText: 'e.g. A-3 (khali = shelf hata do)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stockC,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Stock'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await LanStockService.instance
          .updateShelf(
              id: p.id,
              shelfName: c.text,
              stock: double.tryParse(stockC.text.trim()));
      messenger.showSnackBar(const SnackBar(
          content: Text('Shelf/Stock branch PC mein update ho gayi')));
      final rows = await LanStockService.instance.fetchAll();
      if (mounted) setState(() => _all = rows);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Update fail: $e')));
    }
  }

  Future<void> _editHost() async {
    final t = await LanStockService.instance.loadTarget();
    final hostC = TextEditingController(text: t.host);
    final portC = TextEditingController(text: '${t.port}');
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Branch PC ka IP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Mobile aur branch PC dono same Wi-Fi par hon.',
                style: TextStyle(fontSize: 13, color: AppColor.textMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: hostC,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                  labelText: 'IP address', hintText: '192.168.100.250'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: portC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Port'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save & Connect')),
        ],
      ),
    );
    if (ok != true) return;
    final host = hostC.text.trim();
    if (host.isEmpty) return;
    await LanStockService.instance
        .saveTarget(host, int.tryParse(portC.text.trim()) ?? 5432);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.surface,
        foregroundColor: AppColor.textDark,
        elevation: 0,
        title: const Text('Branch Stock (Local)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
              tooltip: 'Branch IP',
              onPressed: _editHost,
              icon: const Icon(Icons.wifi_rounded)),
          IconButton(
              tooltip: 'Refresh',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Name, barcode ya shelf search karo',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_query.isNotEmpty)
                        IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            }),
                      IconButton(
                          tooltip: 'Barcode scan',
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          onPressed: _scan),
                    ],
                  ),
                  filled: true,
                  fillColor: AppColor.grey100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final f in const [
                    ('all', 'All'),
                    ('in_stock', 'In Stock'),
                    ('low_stock', 'Low'),
                    ('out_of_stock', 'Out'),
                    ('loss', 'Loss'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f.$2),
                        selected: _filter == f.$1,
                        onSelected: (_) => setState(() => _filter = f.$1),
                      ),
                    ),
                ],
              ),
            ),
            if (!_loading && _error == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                child: Row(
                  children: [
                    Text('${list.length} / ${_all.length} products',
                        style: const TextStyle(
                            fontSize: 12, color: AppColor.textMuted)),
                    const Spacer(),
                    Icon(Icons.circle, size: 8, color: AppColor.cashIn),
                    const SizedBox(width: 4),
                    Text('$_host${_loadedAt == null ? '' : '  •  ${_hm(_loadedAt!)}'}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColor.textMuted)),
                  ],
                ),
              ),
            Expanded(child: _body(list)),
          ],
        ),
      ),
    );
  }

  Widget _body(List<BranchStockModel> list) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 44),
              const SizedBox(height: 12),
              Text('Branch PC ($_host) se connect nahi ho saka',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text(
                  'Check karo: mobile branch ke Wi-Fi par hai, PC chalu hai, '
                  'IP sahi hai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColor.textMuted)),
              const SizedBox(height: 8),
              Text(_error!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11, color: AppColor.textMuted)),
              const SizedBox(height: 14),
              Wrap(spacing: 8, children: [
                FilledButton(onPressed: _load, child: const Text('Retry')),
                OutlinedButton(
                    onPressed: _editHost, child: const Text('IP badlo')),
              ]),
            ],
          ),
        ),
      );
    }
    if (list.isEmpty) {
      return const Center(child: Text('Koi product nahi mila'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) =>
            _StockCard(p: list[i], onEditShelf: () => _editShelf(list[i])),
      ),
    );
  }

  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _StockCard extends StatelessWidget {
  const _StockCard({required this.p, required this.onEditShelf});
  final BranchStockModel p;
  final VoidCallback onEditShelf;

  static String _n(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final out = p.isOutOfStock;
    final low = p.isLowStock;
    final color = out
        ? AppColor.error
        : low
            ? AppColor.warningDark
            : AppColor.success;
    final bg = out
        ? AppColor.errorLight
        : low
            ? AppColor.warningLight
            : AppColor.successLight;

    Widget kv(String k, String v) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(k,
                  style: const TextStyle(
                      fontSize: 11, color: AppColor.textMuted)),
              const SizedBox(height: 2),
              Text(v,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  p.isTrackStock ? _n(p.quantity) : '∞',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
              child: Text(
                [
                  if ((p.barcode ?? '').isNotEmpty) p.barcode!,
                  'Shelf: ${(p.shelfName ?? '').isEmpty ? '—' : p.shelfName}',
                ].join('   •   '),
                style:
                    const TextStyle(fontSize: 12, color: AppColor.textMuted),
              ),
            ),
            InkWell(
              onTap: onEditShelf,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.edit_rounded,
                    size: 18, color: AppColor.primary),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            kv('Purchase${p.costPrice > p.sellingPrice ? ' ⚠' : ''}', _n(p.costPrice)),
            kv('Sale', _n(p.sellingPrice)),
            kv('Status', p.isTrackStock ? p.stockStatus : 'Digital'),
          ]),
        ],
      ),
    );
  }
}
