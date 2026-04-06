import 'dart:ui';
import 'package:flutter/material.dart';

const Color _cardTop    = Color.fromRGBO(255, 255, 255, 0.08);
const Color _cardBorder = Color.fromRGBO(255, 255, 255, 0.10);
const Color _pink       = Color.fromRGBO(255, 61,  135, 1.0);

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _cardTop,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _focused ? _pink : _cardBorder,
              width: _focused ? 1.2 : 0.8,
            ),
          ),
          child: Focus(
            onFocusChange: (v) => setState(() => _focused = v),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  color: _focused ? _pink : Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    obscureText: widget.obscureText,
                    keyboardType: widget.keyboardType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: widget.hintText,
                      hintStyle: const TextStyle(
                        color: Colors.white38,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (widget.suffixIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: widget.suffixIcon!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
