import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/theme_provider.dart';

class AppColors {
  static const Color bgTop = Color(0xFF0A0010);
  static const Color bgMid = Color(0xFF110018);
  static const Color bgBottom = Color(0xFF1A0028);

  static const Color glass = Color.fromRGBO(255, 255, 255, 0.04);
  static const Color glassHover = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color glassBorder = Color.fromRGBO(255, 255, 255, 0.15);
  static const Color glassReflection = Color.fromRGBO(255, 255, 255, 0.20);
  static const Color white = Colors.white;
  static const Color softWhite = Color(0xFFF3EFFF);
  static const Color pinkGlow = Color(0xFFE0389A);
  static const Color purpleGlow = Color(0xFFCC2299);
}

class GlassBackground extends ConsumerWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(appThemeColorsProvider);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: t.bgGradient,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            left: -40,
            child: _blurBall(
              size: 220,
              color: t.glowColors[0].withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            top: 180,
            right: -40,
            child: _blurBall(
              size: 180,
              color: t.glowColors[1].withValues(alpha: 0.30),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 30,
            child: _blurBall(
              size: 180,
              color: AppColors.softWhite.withValues(alpha: 0.10),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _blurBall({required double size, required Color color}) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double blur;
  final double borderOpacity;
  final double backgroundOpacity;
  final VoidCallback? onTap;
  final bool enableAnimation;
  final Duration animationDuration;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.blur = 18,
    this.borderOpacity = 0.16,
    this.backgroundOpacity = 0.10,
    this.onTap,
    this.enableAnimation = true,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableAnimation && widget.onTap != null) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableAnimation && widget.onTap != null) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enableAnimation) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(
              color: AppColors.glassBorder.withValues(alpha: widget.borderOpacity),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.glass.withValues(alpha: widget.backgroundOpacity),
                AppColors.glass.withValues(alpha: widget.backgroundOpacity * 0.8),
              ],
            ),
          ),
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(16),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.enableAnimation ? _scaleAnimation.value : 1.0,
              child: Opacity(
                opacity: widget.enableAnimation ? _opacityAnimation.value : 1.0,
                child: card,
              ),
            );
          },
        ),
      );
    }

    return card;
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.border,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        child: Stack(
          children: [
            // Main glass container
            ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: width,
                  height: height,
                  padding: padding,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color ?? AppColors.glass,
                        AppColors.glass.withOpacity(0.01),
                      ],
                    ),
                    borderRadius: borderRadius ?? BorderRadius.circular(16),
                    border: border ?? Border.all(color: AppColors.glassBorder, width: 0.8),
                    boxShadow: boxShadow ?? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
            // Reflection overlay
            ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.glassReflection,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5],
                  ),
                  borderRadius: borderRadius ?? BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double? size;
  final Color? iconColor;
  final Color? bgColor;
  final Border? border;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size,
    this.iconColor,
    this.bgColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        width: size ?? 40,
        height: size ?? 40,
        borderRadius: BorderRadius.circular(12),
        color: bgColor ?? AppColors.glass,
        border: border ?? Border.all(color: AppColors.glassBorder, width: 0.8),
        child: Icon(
          icon,
          color: iconColor ?? Colors.white70,
          size: (size ?? 40) * 0.5,
        ),
      ),
    );
  }
}
