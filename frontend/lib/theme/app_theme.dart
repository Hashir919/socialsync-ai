import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class AppTheme {
  static const Color primaryBlue = Color(0xFF0A84FF);
  static const Color accentPurple = Color(0xFFBF5AF2);
  static const Color successGreen = Color(0xFF34C759);
  static const Color dangerRed = Color(0xFFFF3B30);
  static const Color warningOrange = Color(0xFFFF9F0A);

  static ThemeData getLightTheme() {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        secondary: primaryBlue,
        tertiary: accentPurple,
        background: Color(0xFFF2F2F7),
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Colors.black,
        onSurface: Colors.black,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32, 
          fontWeight: FontWeight.w700, 
          color: Colors.black,
          letterSpacing: -1.0,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24, 
          fontWeight: FontWeight.w600, 
          color: Colors.black,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18, 
          fontWeight: FontWeight.w600, 
          color: Colors.black,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15, 
          color: Colors.black87,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13, 
          color: Colors.black54,
        ),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData getDarkTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: primaryBlue,
        tertiary: accentPurple,
        background: Colors.black,
        surface: Color(0xFF0A0A0A),
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32, 
          fontWeight: FontWeight.w700, 
          color: Colors.white,
          letterSpacing: -1.0,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24, 
          fontWeight: FontWeight.w600, 
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18, 
          fontWeight: FontWeight.w600, 
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15, 
          color: Colors.white70,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13, 
          color: Colors.white60,
        ),
      ),
      useMaterial3: true,
    );
  }
}

class GlassBox extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;

  const GlassBox({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.08,
    this.color,
    this.borderRadius,
    this.border,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = color ?? (isDark ? Colors.white : Colors.black);
    final defaultBorder = border ?? Border.all(
      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
      width: 0.8,
    );
    final defaultRadius = borderRadius ?? BorderRadius.circular(16);

    return ClipRRect(
      borderRadius: defaultRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: defaultColor.withOpacity(opacity),
            borderRadius: defaultRadius,
            border: defaultBorder,
          ),
          child: child,
        ),
      ),
    );
  }
}
