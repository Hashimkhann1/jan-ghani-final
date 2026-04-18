import 'dart:io';
import 'dart:isolate';

class SyncService {
  Isolate? _isolate;
  Process? _syncProcess;

  // ─── Background Isolate Mein Start Karo ─────
  Future<void> startSync() async {
    // Alag thread mein chalao — UI block nahi hoga
    _isolate = await Isolate.spawn(
      _runSyncProcess,
      null,
      debugName: 'SyncIsolate',
    );
    print('✅ Sync background mein chal rahi hai!');
  }

  // ─── Yeh Alag Thread Mein Chale Ga ──────────
  static Future<void> _runSyncProcess(dynamic _) async {
    final pythonPath = _getPythonPath();
    final scriptPath = _getScriptPath();

    while (true) { // Script crash ho toh restart karo
      try {
        final process = await Process.start(
          pythonPath,
          [scriptPath],
          runInShell: true,
        );

        print('🚀 Sync process start hua!');

        await process.exitCode; // Process khatam hone ka wait
        print('⚠️ Sync process band hua — restart ho raha hai...');

      } catch (e) {
        print('❌ Sync error: $e');
      }

      // 5 second baad restart karo
      await Future.delayed(Duration(seconds: 5));
    }
  }

  // ─── Sync Band Karo ──────────────────────────
  void stopSync() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    print('🛑 Sync band ho gayi');
  }

  // ─── Paths ───────────────────────────────────
  static String _getPythonPath() {
    if (Platform.isMacOS || Platform.isLinux) {
      return '/Users/shahabmustafa/Desktop/jan-ghani-final/python/venv/bin/python3';
    } else if (Platform.isWindows) {
      return r'C:\Users\shahabmustafa\Desktop\jan-ghani-final\python\venv\Scripts\python.exe';
    }
    return 'python3';
  }

  static String _getScriptPath() {
    if (Platform.isMacOS || Platform.isLinux) {
      return '/Users/shahabmustafa/Desktop/jan-ghani-final/python/sync.py';
    } else if (Platform.isWindows) {
      return r'C:\Users\shahabmustafa\Desktop\jan-ghani-final\python\sync.py';
    }
    return 'sync.py';
  }
}