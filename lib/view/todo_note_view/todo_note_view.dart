import 'package:flutter/material.dart';
import 'package:jan_ghani_final/utils/app_colors/app_colors.dart';
import 'package:jan_ghani_final/utils/constant/enum_constant/enum_constant.dart';
import 'package:jan_ghani_final/utils/dialogs/todo_note_dialog/todo_note_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────────────────────────────────────

class NoteModel {
  final String id;
  String title;
  String content;
  NotePriority priority;
  NoteStatus status;
  bool isPinned;
  final DateTime createdAt;
  DateTime? dueDate;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.priority,
    this.status = NoteStatus.pending,
    this.isPinned = false,
    required this.createdAt,
    this.dueDate,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// TODO NOTE VIEW
// ─────────────────────────────────────────────────────────────────────────────

class TodoNoteView extends StatefulWidget {
  const TodoNoteView({super.key});

  @override
  State<TodoNoteView> createState() => _TodoNoteViewState();
}

class _TodoNoteViewState extends State<TodoNoteView> {
  static const _bg = Color(0xFFF8F9FA);
  static const _border = Color(0xFFE9ECEF);
  static const _subText = Color(0xFF6C757D);
  static const _headerText = Color(0xFF212529);
  static const _tableHeader = Color(0xFF495057);

  final _quickAddCtrl = TextEditingController();
  NotePriority _quickPriority = NotePriority.medium;
  String _searchQuery = '';
  String _statusFilter = 'All Status';
  String _priorityFilter = 'All Priority';
  String _assignFilter = 'All Notes';
  String _sortFilter = 'Newest First';
  bool _isGridView = true;

  final List<NoteModel> _notes = [
    NoteModel(
      id: '1',
      title: 'testing the high priority note',
      content: 'testing the high priority note',
      priority: NotePriority.high,
      status: NoteStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
    ),
    NoteModel(
      id: '2',
      title: 'Check the Notes',
      content: 'checking the note tomorrow',
      priority: NotePriority.medium,
      status: NoteStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
      dueDate: DateTime(2026, 2, 28),
    ),
    NoteModel(
      id: '3',
      title: 'Testing Note',
      content: 'this is a testing not',
      priority: NotePriority.medium,
      status: NoteStatus.pending,
      isPinned: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  // ── Computed stats ────────────────────────────────────────────────────────
  int get _total => _notes.length;
  int get _pending => _notes.where((n) => n.status == NoteStatus.pending).length;
  int get _completed => _notes.where((n) => n.status == NoteStatus.completed).length;
  int get _overdue => _notes.where((n) =>
  n.dueDate != null && n.dueDate!.isBefore(DateTime.now()) &&
      n.status != NoteStatus.completed).length;
  int get _pinned => _notes.where((n) => n.isPinned).length;
  int get _highPriority => _notes.where((n) => n.priority == NotePriority.high).length;
  int get _dueToday {
    final today = DateTime.now();
    return _notes.where((n) =>
    n.dueDate != null &&
        n.dueDate!.year == today.year &&
        n.dueDate!.month == today.month &&
        n.dueDate!.day == today.day).length;
  }
  double get _doneRate => _total == 0 ? 0 : (_completed / _total) * 100;

  List<NoteModel> get _filtered {
    return _notes.where((n) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q);
      final matchStatus = _statusFilter == 'All Status' ||
          (_statusFilter == 'Pending' && n.status == NoteStatus.pending) ||
          (_statusFilter == 'Completed' && n.status == NoteStatus.completed);
      final matchPriority = _priorityFilter == 'All Priority' ||
          (_priorityFilter == 'High' && n.priority == NotePriority.high) ||
          (_priorityFilter == 'Medium' && n.priority == NotePriority.medium) ||
          (_priorityFilter == 'Low' && n.priority == NotePriority.low);
      return matchSearch && matchStatus && matchPriority;
    }).toList();
  }

  void _addQuickNote() {
    final text = _quickAddCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _notes.insert(0, NoteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: text,
        content: text,
        priority: _quickPriority,
        createdAt: DateTime.now(),
      ));
      _quickAddCtrl.clear();
    });
  }

  void _deleteNote(String id) => setState(() => _notes.removeWhere((n) => n.id == id));

  void _togglePin(String id) {
    setState(() {
      final n = _notes.firstWhere((n) => n.id == id);
      n.isPinned = !n.isPinned;
    });
  }

  void _toggleComplete(String id) {
    setState(() {
      final n = _notes.firstWhere((n) => n.id == id);
      n.status = n.status == NoteStatus.completed ? NoteStatus.pending : NoteStatus.completed;
    });
  }

  @override
  void dispose() {
    _quickAddCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(),
                  const SizedBox(height: 16),
                  _buildQuickAdd(),
                  const SizedBox(height: 16),
                  _buildStatCards(),
                  const SizedBox(height: 16),
                  _buildSearchAndFilters(),
                  const SizedBox(height: 8),
                  Text('Showing ${_filtered.length} of $_total notes',
                      style: const TextStyle(fontSize: 12, color: _subText)),
                  const SizedBox(height: 12),
                  _isGridView ? _buildGrid() : _buildList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.whiteColor,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFF0FDF4),
            ),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryColors, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('Main Store', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: _subText),
            ]),
          ),
          const SizedBox(width: 16),
          Row(children: const [
            Icon(Icons.calendar_today_outlined, size: 14, color: _subText),
            SizedBox(width: 6),
            Text('Thu, Feb 26', style: TextStyle(fontSize: 13, color: _tableHeader)),
          ]),
          const Spacer(),
          const Icon(Icons.dark_mode_outlined, size: 20, color: _subText),
          const SizedBox(width: 16),
          Row(children: const [
            Icon(Icons.wifi, size: 16, color: AppColors.primaryColors),
            SizedBox(width: 4),
            Text('Online', style: TextStyle(fontSize: 12, color: AppColors.primaryColors, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(width: 16),
          Stack(clipBehavior: Clip.none, children: [
            const Icon(Icons.notifications_outlined, size: 22, color: _subText),
            Positioned(
              top: -4, right: -4,
              child: Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(color: AppColors.redColors, shape: BoxShape.circle),
                child: const Center(child: Text('9+', style: TextStyle(color: AppColors.whiteColor, fontSize: 8, fontWeight: FontWeight.bold))),
              ),
            ),
          ]),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryColors,
            child: const Text('JG', style: TextStyle(color: AppColors.whiteColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Page Header ───────────────────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.sticky_note_2_outlined, color: AppColors.primaryColors, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Todo Notes', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _headerText)),
              Text('Manage tasks and notes for your team', style: TextStyle(fontSize: 13, color: _subText)),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddNoteDialog(),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('New Note'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColors,
            foregroundColor: AppColors.whiteColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  // ── Quick Add ─────────────────────────────────────────────────────────────
  Widget _buildQuickAdd() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.add, size: 18, color: _subText),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _quickAddCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Quick add a note... press Enter',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFFBDBDBD)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _addQuickNote(),
            ),
          ),
          GestureDetector(
            onTap: () => _showPriorityPicker(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _border),
              ),
              child: Row(children: [
                Icon(Icons.circle, size: 8, color: _priorityColor(_quickPriority)),
                const SizedBox(width: 6),
                Text(_priorityLabel(_quickPriority), style: const TextStyle(fontSize: 12, color: _tableHeader)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 14, color: _subText),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _addQuickNote,
            child: Container(
              width: 36, height: 36,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(color: AppColors.primaryColors, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.send, size: 16, color: AppColors.whiteColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat Cards ────────────────────────────────────────────────────────────
  Widget _buildStatCards() {
    final stats = [
      _StatItem(Icons.sticky_note_2_outlined, '$_total', 'Total Notes', const Color(0xFFECFDF5), AppColors.primaryColors),
      _StatItem(Icons.access_time_outlined, '$_pending', 'Pending', const Color(0xFFFFFBEB), const Color(0xFFF59E0B)),
      _StatItem(Icons.check_circle_outline, '$_completed', 'Completed', const Color(0xFFECFDF5), AppColors.primaryColors),
      _StatItem(Icons.warning_amber_outlined, '$_overdue', 'Overdue', const Color(0xFFFFF1F2), AppColors.redColors),
      _StatItem(Icons.push_pin_outlined, '$_pinned', 'Pinned', const Color(0xFFEEF2FF), const Color(0xFF6366F1)),
      _StatItem(Icons.local_fire_department_outlined, '$_highPriority', 'High Priority', const Color(0xFFFFF4EE), const Color(0xFFEA580C)),
      _StatItem(Icons.calendar_today_outlined, '$_dueToday', 'Due Today', const Color(0xFFEEF2FF), const Color(0xFF6366F1)),
      _StatItem(Icons.donut_large_outlined, '${_doneRate.toStringAsFixed(0)}%', 'Done Rate', const Color(0xFFECFDF5), AppColors.primaryColors),
    ];

    return Row(
      children: stats.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: e.key < stats.length - 1 ? 10 : 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: e.value.iconBg, borderRadius: BorderRadius.circular(8)),
                    child: Icon(e.value.icon, color: e.value.iconColor, size: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(e.value.value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _headerText)),
                  const SizedBox(height: 2),
                  Text(e.value.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: _subText)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Search & Filters ──────────────────────────────────────────────────────
  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 40,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search notes...',
                hintStyle: const TextStyle(fontSize: 13, color: _subText),
                prefixIcon: const Icon(Icons.search, size: 18, color: _subText),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryColors)),
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: AppColors.whiteColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _FilterDropdown(value: _statusFilter, items: const ['All Status', 'Pending', 'Completed'], onChanged: (v) => setState(() => _statusFilter = v!)),
        const SizedBox(width: 10),
        _FilterDropdown(value: _priorityFilter, items: const ['All Priority', 'High', 'Medium', 'Low'], onChanged: (v) => setState(() => _priorityFilter = v!)),
        const SizedBox(width: 10),
        _FilterDropdown(value: _assignFilter, prefixIcon: Icons.person_outline, items: const ['All Notes', 'My Notes'], onChanged: (v) => setState(() => _assignFilter = v!)),
        const SizedBox(width: 10),
        _FilterDropdown(value: _sortFilter, items: const ['Newest First', 'Oldest First', 'Priority', 'Due Date'], onChanged: (v) => setState(() => _sortFilter = v!)),
        const SizedBox(width: 10),
        Container(
          height: 40,
          decoration: BoxDecoration(border: Border.all(color: _border), borderRadius: BorderRadius.circular(8), color: AppColors.whiteColor),
          child: Row(
            children: [
              _ViewToggleBtn(icon: Icons.format_list_bulleted, isSelected: !_isGridView, onTap: () => setState(() => _isGridView = false)),
              _ViewToggleBtn(icon: Icons.grid_view, isSelected: _isGridView, onTap: () => setState(() => _isGridView = true)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Grid View — always 3 columns ──────────────────────────────────────────
  Widget _buildGrid() {
    final notes = _filtered;
    if (notes.isEmpty) return _buildEmpty();

    final rows = <Widget>[];
    for (int i = 0; i < notes.length; i += 3) {
      final chunk = notes.sublist(i, (i + 3).clamp(0, notes.length));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...List.generate(3, (j) {
              if (j < chunk.length) {
                return Expanded(
                  child: _NoteCard(
                    note: chunk[j],
                    onDelete: () => _deleteNote(chunk[j].id),
                    onPin: () => _togglePin(chunk[j].id),
                    onComplete: () => _toggleComplete(chunk[j].id),
                    onEdit: () => _showEditNoteDialog(chunk[j]),
                  ),
                );
              }
              return const Expanded(child: SizedBox());
            }).expand((w) => [w, if (w != const Expanded(child: SizedBox())) const SizedBox(width: 12)]).toList()..removeLast(),
          ],
        ),
      );
      if (i + 3 < notes.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }

  // ── List View ─────────────────────────────────────────────────────────────
  Widget _buildList() {
    final notes = _filtered;
    if (notes.isEmpty) return _buildEmpty();
    return Column(
      children: notes.map((n) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _NoteCard(
          note: n,
          onDelete: () => _deleteNote(n.id),
          onPin: () => _togglePin(n.id),
          onComplete: () => _toggleComplete(n.id),
          onEdit: () => _showEditNoteDialog(n),
          isListView: true,
        ),
      )).toList(),
    );
  }

  Widget _buildEmpty() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.sticky_note_2_outlined, size: 48, color: Color(0xFFCED4DA)),
          SizedBox(height: 12),
          Text('No notes found', style: TextStyle(fontSize: 15, color: _subText)),
        ],
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showAddNoteDialog() async {
    final note = await showAddNoteDialog(context);
    if (note != null) setState(() => _notes.insert(0, note));
  }

  void _showEditNoteDialog(NoteModel note) async {
    await showEditNoteDialog(context, note);
    setState(() {});
  }

  void _showPriorityPicker() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 200, 0, 0),
      items: NotePriority.values.map((p) => PopupMenuItem(
        value: p,
        child: Row(children: [
          Icon(Icons.circle, size: 8, color: _priorityColor(p)),
          const SizedBox(width: 8),
          Text(_priorityLabel(p)),
        ]),
      )).toList(),
    ).then((v) { if (v != null) setState(() => _quickPriority = v); });
  }

  static Color _priorityColor(NotePriority p) {
    switch (p) {
      case NotePriority.high: return AppColors.redColors;
      case NotePriority.medium: return const Color(0xFFF59E0B);
      case NotePriority.low: return AppColors.primaryColors;
    }
  }

  static String _priorityLabel(NotePriority p) {
    switch (p) {
      case NotePriority.high: return 'High';
      case NotePriority.medium: return 'Medium';
      case NotePriority.low: return 'Low';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _NoteCard extends StatefulWidget {
  final NoteModel note;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final bool isListView;

  const _NoteCard({
    required this.note,
    required this.onDelete,
    required this.onPin,
    required this.onComplete,
    required this.onEdit,
    this.isListView = false,
  });

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool _isHovered = false;

  bool get _isCompleted => widget.note.status == NoteStatus.completed;

  Color get _topBorderColor {
    if (_isCompleted) return const Color(0xFFADB5BD);
    switch (widget.note.priority) {
      case NotePriority.high: return AppColors.redColors;
      case NotePriority.medium: return const Color(0xFFF59E0B);
      case NotePriority.low: return AppColors.primaryColors;
    }
  }

  Color get _priorityBadgeBg {
    if (_isCompleted) return const Color(0xFFE9ECEF);
    switch (widget.note.priority) {
      case NotePriority.high: return const Color(0xFFFFF1F2);
      case NotePriority.medium: return const Color(0xFFFFFBEB);
      case NotePriority.low: return const Color(0xFFECFDF5);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'less than a minute ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isCompleted ? const Color(0xFFF8F9FA) : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _isHovered ? _topBorderColor.withOpacity(0.4) : const Color(0xFFE9ECEF)),
          boxShadow: _isHovered ? [BoxShadow(color: _topBorderColor.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Colored top border ──────────────────────────────────────────
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: _topBorderColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
            ),
            // ── Body ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: widget.note.isPinned ? const Color(0xFF6366F1) : const Color(0xFFCED4DA),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.note.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _isCompleted ? const Color(0xFFADB5BD) : const Color(0xFF212529),
                            decoration: _isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor: const Color(0xFFADB5BD),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isHovered) ...[
                        _IconBtn(
                          icon: widget.note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          color: widget.note.isPinned ? const Color(0xFF6366F1) : const Color(0xFFADB5BD),
                          onTap: widget.onPin,
                        ),
                        _IconBtn(icon: Icons.edit_outlined, color: const Color(0xFFADB5BD), onTap: widget.onEdit),
                        _IconBtn(icon: Icons.delete_outline, color: AppColors.redColors, onTap: widget.onDelete),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Content
                  Text(
                    widget.note.content,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isCompleted ? const Color(0xFFADB5BD) : const Color(0xFF6C757D),
                      decoration: _isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: const Color(0xFFADB5BD),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Meta row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _priorityBadgeBg, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          _priorityLabel(widget.note.priority),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _isCompleted ? const Color(0xFFADB5BD) : _topBorderColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.note.dueDate != null) ...[
                        const Icon(Icons.calendar_today_outlined, size: 11, color: Color(0xFFADB5BD)),
                        const SizedBox(width: 3),
                        Text(_formatDate(widget.note.dueDate!), style: const TextStyle(fontSize: 11, color: Color(0xFFADB5BD))),
                        const SizedBox(width: 6),
                      ],
                      const Spacer(),
                      const Icon(Icons.access_time, size: 11, color: Color(0xFFADB5BD)),
                      const SizedBox(width: 3),
                      Text(_timeAgo(widget.note.createdAt), style: const TextStyle(fontSize: 11, color: Color(0xFFADB5BD))),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            // ── Divider ──────────────────────────────────────────────────────
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            // ── Complete Button ───────────────────────────────────────────────
            GestureDetector(
              onTap: widget.onComplete,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _isCompleted ?  Colors.transparent : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                      size: 14,
                      color: _isCompleted ? AppColors.primaryColors : const Color(0xFFADB5BD),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isCompleted ? 'Completed' : 'Mark Complete',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _isCompleted ? AppColors.primaryColors : const Color(0xFFADB5BD),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _priorityLabel(NotePriority p) {
    switch (p) {
      case NotePriority.high: return 'high';
      case NotePriority.medium: return 'medium';
      case NotePriority.low: return 'low';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL ICON BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, size: 16, color: color)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIEW TOGGLE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _ViewToggleBtn({required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 38,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColors : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 18, color: isSelected ? AppColors.whiteColor : const Color(0xFF6C757D)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER DROPDOWN
// ─────────────────────────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData? prefixIcon;

  const _FilterDropdown({required this.value, required this.items, required this.onChanged, this.prefixIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.whiteColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefixIcon != null) ...[
            Icon(prefixIcon, size: 15, color: const Color(0xFF6C757D)),
            const SizedBox(width: 4),
          ],
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF6C757D)),
              style: const TextStyle(fontSize: 13, color: Color(0xFF495057)),
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT ITEM DATA
// ─────────────────────────────────────────────────────────────────────────────

class _StatItem {
  final IconData icon;
  final String value;
  final String label;
  final Color iconBg;
  final Color iconColor;
  const _StatItem(this.icon, this.value, this.label, this.iconBg, this.iconColor);
}