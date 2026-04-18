import 'dart:io';
import 'dart:isolate';

class SyncService {
  Isolate? _isolate;

  Future<void> startSync() async {
    _isolate = await Isolate.spawn(
      _runSyncProcess,
      null,
      debugName: 'SyncIsolate',
    );
    print('✅ Sync background mein chal rahi hai!');
  }

  static Future<void> _runSyncProcess(dynamic _) async {
    final pythonPath = _getPythonPath();
    final scriptPath = _getScriptPath();

    while (true) {
      try {
        print('🚀 Sync process start hua!');

        final process = await Process.start(
          pythonPath,
          [scriptPath],
          runInShell: true,
        );

        // ✅ Output listen karo — warna process turant exit hoga
        process.stdout
            .transform(SystemEncoding().decoder)
            .listen((data) => print('[Sync] $data'));

        process.stderr
            .transform(SystemEncoding().decoder)
            .listen((err) => print('[Sync ERROR] $err'));

        final exitCode = await process.exitCode;
        print('⚠️ Sync process band hua (exit: $exitCode) — restart ho raha hai...');

      } catch (e) {
        print('❌ Sync error: $e');
      }

      await Future.delayed(Duration(seconds: 5));
    }
  }

  void stopSync() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    print('🛑 Sync band ho gayi');
  }

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