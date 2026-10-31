import 'package:flutter/material.dart';

import 'customer_push_service.dart';

/// Customer portal header mein "Sale notifications" on/off. Jahan push
/// available nahi (desktop/purana browser/key set nahi) wahan kuch nahi dikhata.
class PushToggleButton extends StatefulWidget {
  const PushToggleButton({super.key});

  @override
  State<PushToggleButton> createState() => _PushToggleButtonState();
}

class _PushToggleButtonState extends State<PushToggleButton> {
  bool _on = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (CustomerPushService.available) {
      CustomerPushService.isEnabled().then((v) {
        if (mounted) setState(() => _on = v);
      }).catchError((_) {});
    }
  }

  void _msg(String t) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(t)));

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_on) {
        await CustomerPushService.disable();
        if (mounted) setState(() => _on = false);
        _msg('Notifications band kar di gayin');
      } else {
        final ok = await CustomerPushService.enable();
        if (!mounted) return;
        setState(() => _on = ok);
        _msg(ok
            ? 'Ab aap ki har khareedari par notification aayegi'
            : 'Notification ki ijazat nahi mili (browser settings dekhein)');
      }
    } catch (e) {
      _msg('Notification on nahi ho saki: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!CustomerPushService.available) return const SizedBox.shrink();
    return IconButton(
      tooltip: _on ? 'Sale notifications band karein' : 'Sale notifications on karein',
      onPressed: _busy ? null : _toggle,
      icon: Icon(
        _on ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
        color: _on ? const Color(0xFFED0015) : const Color(0xFF5A6660),
      ),
    );
  }
}
