import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final String text;
  final Widget leading;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;
  final double? height;

  const SocialButton({
    super.key,
    required this.text,
    required this.leading,
    required this.backgroundColor,
    required this.textColor,
    this.onPressed,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 48, // Reduced from 94 to standard height
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Reduced from 24
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 12), // Reduced from 14
            Text(
              text,
              style: TextStyle(
                fontSize: 16, // Reduced from 21
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
