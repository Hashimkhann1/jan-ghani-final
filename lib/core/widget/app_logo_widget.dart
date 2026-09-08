import 'package:flutter/material.dart';

/// App brand logo — `assets/images/jan_ghani.png` ek rounded tile ke andar.
///
/// Logo ka background transparent hai, isliye tile white rakhi gayi hai
/// (halka border ke saath) taake har jagah ek "app icon" ki tarah dikhe.
/// Sidebar, login screen waghera har jagah yahi widget use hota hai.
class AppLogo extends StatelessWidget {
  final double size;
  final double radius;

  /// `true` par koi tile/border nahi — sirf transparent logo.
  final bool bare;

  const AppLogo({
    super.key,
    this.size = 96,
    this.radius = 20,
    this.bare = false,
  });

  @override
  Widget build(BuildContext context) {
    final image = Padding(
      padding: EdgeInsets.all(size * 0.10),
      child: Image.asset(
        'assets/images/jan_ghani.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );

    if (bare) {
      return SizedBox(width: size, height: size, child: image);
    }

    return Container(
      width:  size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border:       Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: image,
    );
  }
}
