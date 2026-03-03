import 'package:flutter/material.dart';
import 'package:jan_ghani_final/utils/app_colors/app_colors.dart';
import 'package:jan_ghani_final/utils/constant/enum_constant/enum_constant.dart';
import 'package:jan_ghani_final/view/todo_note_view/todo_note_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHOW HELPERS
// ─────────────────────────────────────────────────────────────────────────────

Future<NoteModel?> showAddNoteDialog(BuildContext context) {
  return showDialog<NoteModel>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const TodoNoteDialog(),
  );
}

Future<NoteModel?> showEditNoteDialog(BuildContext context, NoteModel note) {
  return showDialog<NoteModel>(
    context: context,
    barrierDismissible: false,
    builder: (_) => TodoNoteDialog(existing: note),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class TodoNoteDialog extends StatefulWidget {
  final NoteModel? existing;

  const TodoNoteDialog({super.key, this.existing});

  @override
  State<TodoNoteDialog> createState() => _TodoNoteDialogState();
}

class _TodoNoteDialogState extends State<TodoNoteDialog> {
  static const _subText = Color(0xFF6C757D);
  static const _tableHeader = Color(0xFF495057);

  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late NotePriority _priority;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.existing?.content ?? '');
    _priority = widget.existing?.priority ?? NotePriority.medium;
    _dueDate = widget.existing?.dueDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) return;

    if (_isEdit) {
      // Mutate existing note in place
      widget.existing!.title = _titleCtrl.text.trim();
      widget.existing!.content = _contentCtrl.text.trim();
      widget.existing!.priority = _priority;
      widget.existing!.dueDate = _dueDate;
      Navigator.pop(context, widget.existing);
    } else {
      // Return new note to caller
      final newNote = NoteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        priority: _priority,
        createdAt: DateTime.now(),
        dueDate: _dueDate,
      );
      Navigator.pop(context, newNote);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 120, vertical: 80),
      child: SizedBox(
        width: 500,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildTitleField(),
              const SizedBox(height: 14),
              _buildContentField(),
              const SizedBox(height: 14),
              _buildPriorityAndDate(),
              const SizedBox(height: 20),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          _isEdit ? 'Edit Note' : 'New Note',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, size: 20, color: _subText),
          splashRadius: 18,
        ),
      ],
    );
  }

  // ── Title ─────────────────────────────────────────────────────────────────
  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Title',
            style:
            TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        _inputField(_titleCtrl, 'Note title...'),
      ],
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────
  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Content',
            style:
            TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _contentCtrl,
            maxLines: 4,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Write your note...',
              hintStyle:
              TextStyle(fontSize: 13, color: Color(0xFFBDBDBD)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  // ── Priority + Due Date ───────────────────────────────────────────────────
  Widget _buildPriorityAndDate() {
    return Row(
      children: [
        // Priority
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Priority',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border:
                  Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<NotePriority>(
                    value: _priority,
                    isExpanded: true,
                    items: NotePriority.values
                        .map((p) => DropdownMenuItem(
                      value: p,
                      child: Row(
                        children: [
                          Icon(Icons.circle,
                              size: 8,
                              color: _priorityColor(p)),
                          const SizedBox(width: 8),
                          Text(_priorityLabel(p),
                              style: const TextStyle(
                                  fontSize: 13)),
                        ],
                      ),
                    ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _priority = v!),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        // Due Date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Due Date',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.primaryColors,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() => _dueDate = picked);
                  }
                },
                child: Container(
                  height: 40,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border:
                    Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                          Icons.calendar_today_outlined,
                          size: 15,
                          color: _subText),
                      const SizedBox(width: 8),
                      Text(
                        _dueDate != null
                            ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                            : 'Pick date',
                        style: TextStyle(
                          fontSize: 13,
                          color: _dueDate != null
                              ? const Color(0xFF212529)
                              : const Color(0xFFBDBDBD),
                        ),
                      ),
                      const Spacer(),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _dueDate = null),
                          child: const Icon(Icons.close,
                              size: 14, color: _subText),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE0E0E0)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
          ),
          child: const Text('Cancel',
              style: TextStyle(color: _tableHeader)),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColors,
            foregroundColor: AppColors.whiteColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
          ),
          child: Text(_isEdit ? 'Save Changes' : 'Add Note'),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _inputField(TextEditingController ctrl, String hint) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: ctrl,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              fontSize: 13, color: Color(0xFFBDBDBD)),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              const BorderSide(color: Color(0xFFE0E0E0))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              const BorderSide(color: Color(0xFFE0E0E0))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: AppColors.primaryColors)),
        ),
      ),
    );
  }

  static Color _priorityColor(NotePriority p) {
    switch (p) {
      case NotePriority.high:
        return AppColors.redColors;
      case NotePriority.medium:
        return const Color(0xFFF59E0B);
      case NotePriority.low:
        return AppColors.primaryColors;
    }
  }

  static String _priorityLabel(NotePriority p) {
    switch (p) {
      case NotePriority.high:
        return 'High';
      case NotePriority.medium:
        return 'Medium';
      case NotePriority.low:
        return 'Low';
    }
  }
}