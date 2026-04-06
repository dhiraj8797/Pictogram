import 'dart:ui';
import 'package:flutter/material.dart';

const Color _cardTop    = Color.fromRGBO(255, 255, 255, 0.08);
const Color _cardBottom = Color.fromRGBO(255, 255, 255, 0.04);
const Color _cardBorder = Color.fromRGBO(255, 255, 255, 0.10);

class AuthGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;

  const AuthGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? 22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius ?? 22),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_cardTop, _cardBottom],
            ),
            border: Border.all(color: _cardBorder, width: 0.8),
          ),
          child: child,
        ),
      ),
    );
  }
}
