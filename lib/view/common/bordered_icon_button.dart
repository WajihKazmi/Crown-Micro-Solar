import 'package:flutter/material.dart';

class BorderedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const BorderedIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          width: 40,
          margin: margin,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: Icon(icon, color: const Color(0xFF2C3E50)),
        ),
      ),
    );
  }
} 