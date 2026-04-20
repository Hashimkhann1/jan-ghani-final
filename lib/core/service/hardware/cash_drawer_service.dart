// lib/core/service/hardware/cash_drawer_service.dart
//
// Black Copper cash drawer — ESC/POS via serial port (RJ11)
// pubspec.yaml: flutter_libserialport: ^0.3.1
//
// !! isSupported safely check karta hai — agar libserialport.dylib
//    install nahi hai toh false return karta hai (app crash nahi hoti) !!

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class CashDrawerService {
  /// ESC/POS open drawer command
  static const List<int> _kOpen = [0x1B, 0x70, 0x00, 0x19, 0xFA];

  static String? _selectedPort;
  static bool?   _supported;   // cached — dylib ek baar check karo

  // ── isSupported ───────────────────────────────────────────────
  /// Returns true only if:
  ///  1. Platform desktop hai (Win/Linux/Mac)
  ///  2. libserialport.dylib/.so/.dll load ho sake
  static bool get isSupported {
    if (_supported != null) return _supported!;

    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return _supported = false;
    }

    try {
      // dylib load test — agar fail hua toh catch kar lo
      SerialPort.availablePorts;
      return _supported = true;
    } catch (_) {
      return _supported = false;
    }
  }

  static List<String> get availablePorts {
    try { return SerialPort.availablePorts; } catch (_) { return []; }
  }

  static String? get selectedPort => _selectedPort;
  static void setPort(String? port) => _selectedPort = port;

  // ── Open Drawer ───────────────────────────────────────────────
  static Future<bool> openDrawer() async {
    if (!isSupported) return false;

    final ports = availablePorts;
    if (ports.isEmpty) return false;

    final portName = _selectedPort ?? ports.first;
    final port     = SerialPort(portName);

    try {
      if (!port.openReadWrite()) return false;

      final config       = SerialPortConfig();
      config.baudRate    = 9600;
      config.bits        = 8;
      config.stopBits    = 1;
      config.parity      = SerialPortParity.none;
      config.setFlowControl(SerialPortFlowControl.none);
      port.config = config;

      port.write(Uint8List.fromList(_kOpen));
      await Future.delayed(const Duration(milliseconds: 150));
      port.close();
      return true;
    } catch (_) {
      try { port.close(); } catch (_) {}
      return false;
    }
  }
}