import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = Colors.grey;
    return SizedBox(
      height: 70, // reduced overall height
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Shadow
          Positioned.fill(
            child: CustomPaint(
              painter: _BottomBarShadowPainter(),
            ),
          ),
          // Background
          Positioned.fill(
            child: ClipPath(
              clipper: _BottomBarClipper(),
              child: Container(color: theme.colorScheme.surface),
            ),
          ),
          // Items (no extra clipping to avoid double edge artifact)
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  context,
                  icon: 'assets/icons/home.svg',
                  label: 'Overview',
                  index: 0,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.eco,
                  label: 'Plant',
                  index: 1,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                const SizedBox(width: 56),
                _buildNavItem(
                  context,
                  icon: 'assets/icons/deviceDetails.svg',
                  label: 'Devices',
                  index: 2,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  context,
                  icon: 'assets/icons/profileInfo.svg',
                  label: 'Profile',
                  index: 3,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ],
            ),
          ),
          // Crown logo
          Positioned(
            top: -20, // adjust due to reduced bar height
            left: 0,
            right: 0,
            child: const Center(child: StaticCrownLogo(size: 48)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required dynamic icon,
    required String label,
    required int index,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(height: 10),
            icon is String
                ? SvgPicture.asset(
                    icon,
                    height: 24,
                    color: isActive ? activeColor : inactiveColor,
                  )
                : Icon(
                    icon as IconData,
                    size: 24,
                    color: isActive ? activeColor : inactiveColor,
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _BottomBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // Smooth concave center notch (Figma-like) without overshoot to avoid double edge
    final path = Path();
    final centerX = size.width * 0.5;
    const notchWidth = 92.0; // width for crown
    const notchDepth = 34.0; // increased depth for bigger gap
    final leftEdge = centerX - notchWidth / 2;
    final rightEdge = centerX + notchWidth / 2;

    path.moveTo(0, 0);
    path.lineTo(leftEdge, 0);
    // Left curve into notch
    path.cubicTo(
      leftEdge + notchWidth * 0.15,
      0,
      centerX - notchWidth * 0.30,
      notchDepth,
      centerX,
      notchDepth,
    );
    // Right curve out of notch (mirror)
    path.cubicTo(
      centerX + notchWidth * 0.30,
      notchDepth,
      rightEdge - notchWidth * 0.15,
      0,
      rightEdge,
      0,
    );
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Painter that draws a soft ambient shadow following the bottom bar's custom path
class _BottomBarShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _BottomBarClipper().getClip(size).shift(const Offset(0, 4));
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.10)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StaticCrownLogo extends StatelessWidget {
  final double size;
  const StaticCrownLogo({Key? key, this.size = 56}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        'assets/icons/crown_vector_svg.svg',
        fit: BoxFit.contain,
      ),
    );
  }
}
