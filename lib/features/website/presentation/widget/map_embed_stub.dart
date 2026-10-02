import 'package:flutter/material.dart';

/// Non-web: map nahi — khali jagah.
class MapEmbed extends StatelessWidget {
  final double lat;
  final double lng;
  final int zoom;
  const MapEmbed(
      {super.key, required this.lat, required this.lng, this.zoom = 16});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
