import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF090710);
  static const Color sidebarBackground = Color(0xFF100B1A);
  static const Color cardBackground = Color(0x1AFFFFFF); // Glass effect

  // Neon Accents (TaxFlow Pro style)
  static const Color neonPink = Color(0xFFFF007F);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonPurple = Color(0xFFA200FF);

  // Bimbomixer Accents (Yellow & Black Glass)
  static const Color bimboYellow = Color(0xFFFFD700);
  static const Color bimboNeonYellow = Color(0xFFFFF033);
  static const Color bimboBlack = Color(0xFF121212);

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textTertiary = Colors.white38;

  // Status
  static const Color statusActive = Color(0xFF00FF7F);
  static const Color statusPending = Color(0xFFFFC107);
  static const Color statusError = Color(0xFFFF3333);

  // Gradients
  static const LinearGradient pinkPurpleGradient = LinearGradient(
    colors: [neonPink, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanPurpleGradient = LinearGradient(
    colors: [neonCyan, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient yellowNeonGradient = LinearGradient(
    colors: [bimboYellow, bimboNeonYellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}