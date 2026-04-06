import 'package:flutter/material.dart';

class VerifiedBadge extends StatelessWidget {
  final bool isOfficial;
  final double size;
  
  const VerifiedBadge({
    super.key,
    this.isOfficial = false,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: isOfficial
            ? const LinearGradient(
                colors: [
                  Color(0xFFFFD700), // Gold
                  Color(0xFFFFA500), // Darker Gold
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [
                  Color(0xFF1DA1F2), // Blue
                  Color(0xFF0C85D0), // Darker Blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isOfficial 
                ? const Color(0xFFFFD700).withAlpha(77)
                : Colors.blue.withAlpha(77),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        Icons.verified,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }
}

class OfficialBadge extends StatelessWidget {
  final double size;
  
  const OfficialBadge({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD700), // Gold
            Color(0xFFFFA500), // Darker Gold
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            color: Colors.white,
            size: size * 0.7,
          ),
          const SizedBox(width: 4),
          const Text(
            'Official',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
