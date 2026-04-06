import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'glass_widgets.dart';

/// Custom loading indicator with consistent styling
class AppLoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;
  final double strokeWidth;
  
  const AppLoadingIndicator({
    super.key,
    this.size,
    this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size ?? 20.0,
      height: size ?? 20.0,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Colors.white,
        ),
      ),
    );
  }
}

/// Custom button with consistent styling
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;
  final double? borderRadius;
  final Widget? child;
  
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.textColor,
    this.height,
    this.borderRadius,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: borderRadius ?? AppConstants.defaultRadius,
      padding: EdgeInsets.symmetric(vertical: height ?? 16),
      onTap: (isDisabled || isLoading) ? null : onPressed,
      child: isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLoadingIndicator(size: 16),
                const SizedBox(width: 8),
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            )
          : child ?? 
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
    );
  }
}

/// Custom text field with consistent styling
class AppTextField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final int? maxLines;
  final int? maxLength;
  
  const AppTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = false;
  
  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppConstants.defaultRadius,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscureText,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        focusNode: widget.focusNode,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          errorText: widget.errorText,
          prefixIcon: widget.prefixIcon != null 
              ? Icon(widget.prefixIcon, color: Colors.white70)
              : null,
          suffixIcon: widget.suffixIcon != null
              ? Icon(widget.suffixIcon, color: Colors.white70)
              : (widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : null),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
          errorStyle: const TextStyle(color: Colors.redAccent),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

/// Custom snackbar with consistent styling
class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    Color backgroundColor = Colors.green,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? action,
    String? actionLabel,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: action,
                textColor: Colors.white,
              )
            : null,
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message: message, backgroundColor: Colors.green);
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, backgroundColor: Colors.red, duration: const Duration(seconds: 4));
  }

  static void warning(BuildContext context, String message) {
    show(context, message: message, backgroundColor: Colors.orange);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, backgroundColor: Colors.blue);
  }
}

/// Custom error widget with retry functionality
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final Widget? customIcon;
  
  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            customIcon ?? 
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.white70,
                ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              AppButton(
                text: AppConstants.retryButtonText,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Custom empty state widget
class AppEmptyWidget extends StatelessWidget {
  final String message;
  final Widget? customIcon;
  final Widget? action;
  
  const AppEmptyWidget({
    super.key,
    required this.message,
    this.customIcon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            customIcon ?? 
                const Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.white70,
                ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Custom refresh indicator
class AppRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  
  const AppRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? Colors.white,
      child: child,
    );
  }
}

/// Custom app bar with consistent styling
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  
  const AppAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: centerTitle,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Custom bottom navigation bar
class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  
  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 0,
      padding: EdgeInsets.zero,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icons.chat_bubble_outline_rounded),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Utility widget for conditional rendering
class ConditionalWidget extends StatelessWidget {
  final bool condition;
  final Widget child;
  final Widget? fallback;
  
  const ConditionalWidget({
    super.key,
    required this.condition,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return condition ? child : (fallback ?? const SizedBox.shrink());
  }
}

/// Utility widget for spacing
class Spacer extends StatelessWidget {
  final double? height;
  final double? width;
  
  const Spacer({super.key, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
    );
  }
}
