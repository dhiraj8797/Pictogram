import 'package:flutter/material.dart';

const Color _bgDark   = Color.fromRGBO(16,  7,  18, 1.0);
const Color _bgMid    = Color.fromRGBO(23,  8,  19, 1.0);
const Color _bgTop    = Color.fromRGBO(37,  4,  20, 1.0);
const Color _pinkGlow = Color.fromRGBO(255, 61, 135, 0.20);

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgDark,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1 – dark linear base
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgTop, _bgMid, _bgDark],
                stops: [0.0, 0.38, 1.0],
              ),
            ),
          ),
          // Layer 2 – pink radial glow at top
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -1.0),
                radius: 1.4,
                colors: [_pinkGlow, Colors.transparent],
                stops: [0.0, 0.28],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
