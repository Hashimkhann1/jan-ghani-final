import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// `assets/branch_icons/` ka ek custom SVG icon.
///
/// [name] sirf file ka naam (bina folder, bina `.svg`) — e.g. `'ic_cash_in'`.
/// [color] diya jaye to icon usi rang me tint hota hai (srcIn).
///
/// `UnconstrainedBox` isliye — `TextField` ke prefix/suffix slot aur
/// `IconButton` apne child ko badi (min 48 / tight 24) constraints dete hain,
/// jinke andar `SvgPicture` khinch kar bada dikhne lagta hai. Yeh wrapper
/// icon ko hamesha exact [size] par render karta hai, slot chahe jitna bada ho.
class AppIcon extends StatelessWidget {
  final String  name;
  final double  size;
  final Color?  color;

  const AppIcon(
    this.name, {
    super.key,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      child: SizedBox(
        width:  size,
        height: size,
        child: SvgPicture.asset(
          'assets/branch_icons/$name.svg',
          fit: BoxFit.contain,
          colorFilter: color == null
              ? null
              : ColorFilter.mode(color!, BlendMode.srcIn),
        ),
      ),
    );
  }
}
