import 'package:flutter/material.dart';

class AppButtons {
  static Widget primaryButton({
    required BuildContext context,
    required VoidCallback? onTap,
    required String text,
    bool isFilled = true,
    double horizontalPadding = 24.0,
    Color? textColor,
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    final Color buttonTextColor = textColor ?? (isFilled ? Colors.white : theme.colorScheme.primary);
    
    return StatefulBuilder(
      builder: (context, setState) {
        double scale = 1.0;
        
        return GestureDetector(
          onTapDown: (_) {
            if (!isLoading) {
              setState(() => scale = 0.95);
            }
          },
          onTapUp: (_) {
            if (!isLoading) {
              setState(() => scale = 1.0);
            }
          },
          onTapCancel: () {
            if (!isLoading) {
              setState(() => scale = 1.0);
            }
          },
          onTap: isLoading ? null : onTap,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                decoration: BoxDecoration(
                  color: isFilled ? theme.colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                  border: isFilled
                      ? null
                      : Border.all(
                          color: theme.colorScheme.primary,
                          width: 1.0,
                        ),
                ),
                child: isLoading
                    ? Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(buttonTextColor),
                          ),
                        ),
                      )
                    : Text(
                        text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: buttonTextColor,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
} 