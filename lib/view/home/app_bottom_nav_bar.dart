import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
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
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Curved bottom bar background with blur and gradient
          Positioned.fill(
            child: ClipPath(
              clipper: _BottomBarClipper(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.background.withValues(alpha: 0.7),
                        theme.brightness == Brightness.dark
                          ? Colors.black.withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                  child: CustomPaint(
                    painter: _CurvedBarPainter(color: Colors.transparent),
                  ),
                ),
              ),
            ),
          ),
          // Bottom bar items with clipping
          Positioned.fill(
            child: ClipPath(
              clipper: _BottomBarClipper(),
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
                    icon: 'assets/icons/contact.svg',
                    label: 'Contact',
                    index: 1,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),
                  const SizedBox(width: 56), // Space for crown
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
          ),
          // Crown logo (centered, static, no animation or shadow)
          Positioned(
            top: -16,
            left: 0,
            right: 0,
            child: const Center(
              child: StaticCrownLogo(size: 44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String icon,
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
            const SizedBox(height: 16),
            SvgPicture.asset(
              icon,
              height: 24,
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _BottomBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Start from bottom left
    path.moveTo(0, 0);
    // Left straight
    path.lineTo(size.width * 0.25 - 28, 0);
    // Curve up for the logo (deeper by 5px)
    path.cubicTo(
      size.width * 0.25, 0,
      size.width * 0.5 - 44, 0,
      size.width * 0.5 - 28, 23, // was 18, now 23 (5px deeper)
    );
    path.cubicTo(
      size.width * 0.5 - 14, 41, // was 36, now 41 (5px deeper)
      size.width * 0.5 + 14, 41, // was 36, now 41 (5px deeper)
      size.width * 0.5 + 28, 23, // was 18, now 23 (5px deeper)
    );
    path.cubicTo(
      size.width * 0.5 + 44, 0,
      size.width * 0.75, 0,
      size.width * 0.75 + 28, 0,
    );
    // Right straight
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CurvedBarPainter extends CustomPainter {
  final Color color;
  _CurvedBarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    // Start from bottom left
    path.moveTo(0, 0);
    // Left straight
    path.lineTo(size.width * 0.25 - 28, 0);
    // Curve up for the logo (deeper by 5px)
    path.cubicTo(
      size.width * 0.25, 0,
      size.width * 0.5 - 44, 0,
      size.width * 0.5 - 28, 23, // was 18, now 23 (5px deeper)
    );
    path.cubicTo(
      size.width * 0.5 - 14, 41, // was 36, now 41 (5px deeper)
      size.width * 0.5 + 14, 41, // was 36, now 41 (5px deeper)
      size.width * 0.5 + 28, 23, // was 18, now 23 (5px deeper)
    );
    path.cubicTo(
      size.width * 0.5 + 44, 0,
      size.width * 0.75, 0,
      size.width * 0.75 + 28, 0,
    );
    // Right straight
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw shadow for elevation
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.18), 8, false);

    // Draw transparent cutout for the curve area
    final cutoutPath = Path();
    cutoutPath.moveTo(size.width * 0.5 - 32, 0);
    cutoutPath.cubicTo(
      size.width * 0.5 - 24, 0,
      size.width * 0.5 - 10, 32,
      size.width * 0.5, 46,
    );
    cutoutPath.cubicTo(
      size.width * 0.5 + 10, 32,
      size.width * 0.5 + 24, 0,
      size.width * 0.5 + 32, 0,
    );
    cutoutPath.lineTo(size.width * 0.5 + 32, -10);
    cutoutPath.lineTo(size.width * 0.5 - 32, -10);
    cutoutPath.close();
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    // Use BlendMode.clear to make the cutout area transparent
    canvas.drawPath(cutoutPath, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
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