import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../core/service/supabase_service.dart';


final String _grokApiKey = dotenv.env['GROK_API_KEY'] ?? '';
final String _grokApiUrl = dotenv.env['GROK_API_URL'] ?? '';
final String _grokModel = dotenv.env['GROK_MODEL'] ?? 'grok-3';

const String? _storeId = null;

// ─── Color Palette ────────────────────────────────────────────────────────────
class _C {
  static const bg          = Color(0xFFF5F7FA);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF0F4FF);
  static const border      = Color(0xFFE4E9F2);
  static const primary     = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1D4ED8);
  static const primarySoft = Color(0xFFEFF4FF);
  static const accent      = Color(0xFF0EA5E9);
  static const success     = Color(0xFF10B981);
  static const successSoft = Color(0xFFECFDF5);
  static const textPrimary = Color(0xFF111827);
  static const textSec     = Color(0xFF6B7280);
  static const textTertiary= Color(0xFF9CA3AF);
  static const userBubble  = Color(0xFF2563EB);
  static const botBubble   = Color(0xFFFFFFFF);
  static const shadow      = Color(0x14000000);
}

// ─── Message Model ────────────────────────────────────────────────────────────
enum MessageRole { user, assistant }

class ChatMessage {
  final String      content;
  final MessageRole role;
  final DateTime    timestamp;

  ChatMessage({
    required this.content,
    required this.role,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class QuickAction {
  final String icon, label, query;
  const QuickAction(this.icon, this.label, this.query);
}

// ─── AI Business Chatbot Screen ───────────────────────────────────────────────
class AIBusinessChatbotScreen extends StatefulWidget {
  const AIBusinessChatbotScreen({super.key});
  @override State<AIBusinessChatbotScreen> createState() => _State();
}

class _State extends State<AIBusinessChatbotScreen> {
  final _input   = TextEditingController();
  final _scroll  = ScrollController();
  final _svc     = SupabaseService(storeId: _storeId);
  final _msgs    = <ChatMessage>[];
  final _history = <Map<String, String>>[];
  bool  _loading = false;

  static const _actions = [
    QuickAction('📊', 'Sales',     'Aaj ki sales report do'),
    QuickAction('💰', 'P&L',       'Is mahine ka profit and loss dikhao'),
    QuickAction('📦', 'Stock',     'Low stock aur out of stock batao'),
    QuickAction('💸', 'Expenses',  'Is mahine ke expenses breakdown do'),
    QuickAction('🏆', 'Top Items', 'Top 10 bestselling products konse hain?'),
    QuickAction('👥', 'Customers', 'Customer credit baaki kitna hai?'),
    QuickAction('↩️', 'Returns',  'Is mahine kitne returns hue?'),
    QuickAction('⚠️', 'Damage',   'Damage stock ki report do'),
  ];

  @override
  void initState() {
    super.initState();
    _msgs.add(ChatMessage(
      content: '👋 Assalam-u-Alaikum! Main aapka **AI Business Assistant** hun.\n\n'
          'Powered by **Grok AI** 🚀\n\n'
          'Mujhe yeh pooch sakte ho:\n'
          '• "Aaj ki sales report do"\n'
          '• "Is mahine ka P&L dikhao"\n'
          '• "Low stock products konse hain?"\n'
          '• "Customer credit kitna baaki hai?"\n'
          '• "Expenses breakdown do"\n\n'
          'Neeche buttons se jaldi report lo! 👇',
      role: MessageRole.assistant,
    ));
  }

  // ─── Intent Detection + Data Fetch ───────────────────────────────────────

  Future<Map<String, dynamic>> _fetchData(String msg) async {
    final m = msg.toLowerCase();

    final now = DateTime.now();
    DateTime s = DateTime(now.year, now.month, 1);
    DateTime e = now;

    if (_has(m, ['aaj', 'today', 'abhi'])) {
      s = DateTime(now.year, now.month, now.day);
    } else if (_has(m, ['kal', 'yesterday'])) {
      final y = now.subtract(const Duration(days: 1));
      s = DateTime(y.year, y.month, y.day);
      e = DateTime(y.year, y.month, y.day, 23, 59, 59);
    } else if (_has(m, ['is hafte', 'this week'])) {
      s = now.subtract(Duration(days: now.weekday - 1));
    } else if (_has(m, ['pichle mahine', 'last month'])) {
      s = DateTime(now.year, now.month - 1, 1);
      e = DateTime(now.year, now.month, 0);
    } else if (_has(m, ['is saal', 'this year'])) {
      s = DateTime(now.year, 1, 1);
    }

    final data = <String, dynamic>{};

    if (_has(m, ['aaj', 'today', 'abhi'])) {
      data['today_summary'] = await _svc.getTodaySummary();
    }
    if (_has(m, ['profit', 'loss', 'p&l', 'faida', 'nuqsan', 'munafa'])) {
      data['profit_and_loss'] = await _svc.getProfitAndLoss(startDate: s, endDate: e);
    }
    if (_has(m, ['sale', 'revenue', 'bikri', 'bika', 'invoice', 'report']) &&
        !_has(m, ['profit', 'p&l'])) {
      data['sales_summary']   = await _svc.getSalesSummary(startDate: s, endDate: e);
      data['top_products']    = await _svc.getTopProducts(startDate: s, endDate: e);
      data['payment_methods'] = await _svc.getSalesByPaymentMethod(startDate: s, endDate: e);
    }
    if (_has(m, ['expense', 'kharcha', 'kharch', 'cost'])) {
      data['expenses'] = await _svc.getExpensesSummary(startDate: s, endDate: e);
    }
    if (_has(m, ['stock', 'inventory', 'maal', 'product', 'low', 'out of'])) {
      data['stock_summary'] = await _svc.getStockSummary();
    }
    if (_has(m, ['customer', 'credit', 'ledger', 'baaki', 'receivable', 'udhaar'])) {
      data['customer_summary'] = await _svc.getCustomerSummary();
    }
    if (_has(m, ['return', 'wapas', 'refund'])) {
      data['returns'] = await _svc.getReturnsSummary(startDate: s, endDate: e);
    }
    if (_has(m, ['damage', 'kharab', 'waste', 'nuksan'])) {
      data['damage_summary'] = await _svc.getDamageSummary();
    }

    if (data.isEmpty) {
      data['business_snapshot'] = await _svc.getBusinessSnapshot();
    }

    data['query_period'] = {
      'start': s.toIso8601String().substring(0, 10),
      'end'  : e.toIso8601String().substring(0, 10),
    };
    return data;
  }

  bool _has(String msg, List<String> kws) => kws.any((k) => msg.contains(k));

  // ─── System Prompt ────────────────────────────────────────────────────────

  String _sysPrompt(Map<String, dynamic> data) {
    final json = const JsonEncoder.withIndent('  ').convert(data);
    return '''
You are an expert AI Business Assistant for a Pakistani retail store (POS system).
Always respond in Hinglish (Urdu + English mix) — like a Pakistani business consultant.

FORMATTING:
- Use **bold** for important numbers
- Use emojis: 📊💰📦💸🏆👥✅❌🔴🟢
- Currency: "PKR 1,25,000" format
- Profit = 🟢 Faida, Loss = 🔴 Nuqsan
- End with 1-2 actionable tips

LIVE DATA from Supabase (real-time):
$json

Rules:
1. Sirf relevant data mention karo
2. Zero ya null values bhi batao
3. Pakistani number format use karo
4. Business context ke saath analyze karo
''';
  }

  // ─── Call Grok API ────────────────────────────────────────────────────────

  Future<String> _callGrok(String systemPrompt) async {
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ..._history,
    ];

    final res = await http.post(
      Uri.parse(_grokApiUrl),
      headers: {
        'Content-Type' : 'application/json',
        'Authorization': 'Bearer $_grokApiKey',
      },
      body: jsonEncode({
        'model'      : _grokModel,
        'messages'   : messages,
        'max_tokens' : 2000,
        'temperature': 0.7,
      }),
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['choices'][0]['message']['content'] as String;
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error']?['message'] ?? 'Grok API Error ${res.statusCode}');
  }

  // ─── Send Message ─────────────────────────────────────────────────────────

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    _input.clear();

    setState(() {
      _msgs.add(ChatMessage(content: text, role: MessageRole.user));
      _loading = true;
    });
    _scrollDown();

    try {
      final data   = await _fetchData(text);
      final prompt = _sysPrompt(data);

      _history.add({'role': 'user', 'content': text});
      final reply = await _callGrok(prompt);
      _history.add({'role': 'assistant', 'content': reply});

      setState(() {
        _loading = false;
        _msgs.add(ChatMessage(content: reply, role: MessageRole.assistant));
      });
    } catch (err) {
      setState(() {
        _loading = false;
        _msgs.add(ChatMessage(
          content: '❌ Error: $err\n\nDobara try karo.',
          role: MessageRole.assistant,
        ));
      });
    }
    _scrollDown();
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  });

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _C.bg,
    appBar: _appBar(),
    body: Column(children: [
      Expanded(child: _messageList()),
      _quickActionsBar(),
      _inputBar(),
    ]),
  );

  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: _C.surface,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: _C.border),
    ),
    titleSpacing: 0,
    title: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(children: [
        _botAvatar(size: 40),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'AI Business Assistant',
            style: TextStyle(
              color: _C.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          Row(children: [
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(color: _C.success, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            const Text(
              'Online · Grok AI',
              style: TextStyle(color: _C.success, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ]),
        ]),
      ]),
    ),
    actions: [
      Container(
        margin: const EdgeInsets.only(right: 12),
        child: IconButton(
          icon: const Icon(Icons.refresh_rounded, color: _C.textSec, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: _C.surfaceAlt,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(8),
          ),
          onPressed: () => setState(() { _msgs.clear(); _history.clear(); initState(); }),
          tooltip: 'New Chat',
        ),
      ),
    ],
  );

  Widget _botAvatar({double size = 36}) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(size * 0.28),
      boxShadow: [
        BoxShadow(
          color: _C.primary.withOpacity(0.25),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Center(
      child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: size * 0.5),
    ),
  );

  Widget _messageList() => ListView.builder(
    controller: _scroll,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    itemCount: _msgs.length + (_loading ? 1 : 0),
    itemBuilder: (ctx, i) =>
    i == _msgs.length ? _typingIndicator() : _bubble(_msgs[i]),
  );

  Widget _bubble(ChatMessage msg) {
    final isUser = msg.role == MessageRole.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _botAvatar(size: 32),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Label
                Padding(
                  padding: EdgeInsets.only(
                    left: isUser ? 0 : 2,
                    right: isUser ? 2 : 0,
                    bottom: 4,
                  ),
                  child: Text(
                    isUser ? 'You' : 'AI Assistant',
                    style: const TextStyle(
                      color: _C.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? _C.userBubble : _C.botBubble,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(18),
                      topRight:    const Radius.circular(18),
                      bottomLeft:  Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser ? null : Border.all(color: _C.border, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? _C.primary.withOpacity(0.2)
                            : _C.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _richText(msg.content, isUser),
                ),
                // Timestamp
                const SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a').format(msg.timestamp),
                  style: const TextStyle(color: _C.textTertiary, fontSize: 10),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            // User avatar
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _C.primarySoft,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _C.border),
              ),
              child: const Center(
                child: Icon(Icons.person_rounded, color: _C.primary, size: 17),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _richText(String content, bool isUser) {
    final base   = isUser ? Colors.white : _C.textPrimary;
    final accent = isUser ? const Color(0xFFBADAFF) : _C.primary;
    final boldRe = RegExp(r'\*\*(.+?)\*\*');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content.split('\n').map((line) {
        if (line.trim().isEmpty) return const SizedBox(height: 4);
        final spans = <TextSpan>[];
        int last = 0;
        for (final m in boldRe.allMatches(line)) {
          if (m.start > last) spans.add(TextSpan(
              text: line.substring(last, m.start),
              style: TextStyle(color: base, fontSize: 13.5, height: 1.6)));
          spans.add(TextSpan(
              text: m.group(1),
              style: TextStyle(
                color: accent,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                height: 1.6,
              )));
          last = m.end;
        }
        if (last < line.length) spans.add(TextSpan(
            text: line.substring(last),
            style: TextStyle(color: base, fontSize: 13.5, height: 1.6)));
        return Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: spans.isEmpty
              ? Text(line, style: TextStyle(color: base, fontSize: 13.5, height: 1.6))
              : RichText(text: TextSpan(children: spans)),
        );
      }).toList(),
    );
  }

  Widget _typingIndicator() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _botAvatar(size: 32),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 4),
              child: Text('AI Assistant', style: TextStyle(color: _C.textTertiary, fontSize: 11)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _C.botBubble,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18), topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4),
                ),
                border: Border.all(color: _C.border),
                boxShadow: [BoxShadow(color: _C.shadow, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const _Dot(delay: 0),
                const SizedBox(width: 5),
                const _Dot(delay: 200),
                const SizedBox(width: 5),
                const _Dot(delay: 400),
                const SizedBox(width: 10),
                Text(
                  'Soch raha hun...',
                  style: TextStyle(color: _C.textTertiary, fontSize: 12.5),
                ),
              ]),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _quickActionsBar() => Container(
    color: _C.surface,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              color: _C.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: _actions.length,
            itemBuilder: (ctx, i) {
              final a = _actions[i];
              return GestureDetector(
                onTap: () => _send(a.query),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _C.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.primary.withOpacity(0.2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(a.icon, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      a.label,
                      style: const TextStyle(
                        color: _C.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _inputBar() => Container(
    padding: EdgeInsets.fromLTRB(
      16, 10, 16,
      MediaQuery.of(context).padding.bottom + 10,
    ),
    decoration: BoxDecoration(
      color: _C.surface,
      border: const Border(top: BorderSide(color: _C.border)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 120),
          decoration: BoxDecoration(
            color: _C.bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.border),
          ),
          child: TextField(
            controller: _input,
            style: const TextStyle(
              color: _C.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
            maxLines: 5,
            minLines: 1,
            textInputAction: TextInputAction.send,
            onSubmitted: _send,
            decoration: const InputDecoration(
              hintText: 'Kuch poochho... (Sales, P&L, Stock)',
              hintStyle: TextStyle(color: _C.textTertiary, fontSize: 13.5),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46, height: 46,
        decoration: BoxDecoration(
          gradient: _loading ? null : const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          color: _loading ? _C.border : null,
          borderRadius: BorderRadius.circular(23),
          boxShadow: _loading ? [] : [
            BoxShadow(
              color: _C.primary.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(23),
            onTap: _loading ? null : () => _send(_input.text),
            child: Center(
              child: Icon(
                _loading ? Icons.hourglass_top_rounded : Icons.arrow_upward_rounded,
                color: _loading ? _C.textTertiary : Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    ]),
  );

  @override
  void dispose() { _input.dispose(); _scroll.dispose(); super.dispose(); }
}

// ─── Animated Typing Dot ──────────────────────────────────────────────────────
class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(widget.delay / 700, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(
      width: 7, height: 7,
      decoration: const BoxDecoration(color: _C.primary, shape: BoxShape.circle),
    ),
  );

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}