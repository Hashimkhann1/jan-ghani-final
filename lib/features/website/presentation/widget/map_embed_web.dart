import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Google Maps ka embed iframe (API key ki zaroorat nahi).
class MapEmbed extends StatelessWidget {
  final double lat;
  final double lng;
  final int zoom;
  const MapEmbed(
      {super.key, required this.lat, required this.lng, this.zoom = 16});

  static final _registered = <String>{};

  String get _viewType => 'jg-map-$lat-$lng-$zoom';

  void _register() {
    if (!_registered.add(_viewType)) return;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      return web.HTMLIFrameElement()
        ..src = 'https://maps.google.com/maps?q=$lat,$lng&z=$zoom&output=embed'
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..loading = 'lazy'
        ..referrerPolicy = 'no-referrer-when-downgrade'
        ..allowFullscreen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    _register();
    return HtmlElementView(viewType: _viewType);
  }
}
