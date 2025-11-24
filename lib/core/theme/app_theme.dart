import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global styling untuk aplikasi (warna, font, komponen).
class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6FAFF),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2563EB),
        secondary: Color(0xFF16A34A),
        error: Color(0xFFDC2626),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
