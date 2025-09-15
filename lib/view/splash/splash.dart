import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Splash extends StatelessWidget {
  final Color backgroundColor;
  final String assetPath;
  final double? size;

  const Splash({
    super.key,
    this.backgroundColor = Colors.white,
    this.assetPath = 'assets/icons/crown_vector_svg.svg',
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final d = MediaQuery.of(context).size.shortestSide;
    final iconSize = size ?? d * 0.28; // responsive but not huge

    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: SvgPicture.asset(
          assetPath,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
