import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF6C63FF);       // Accent purple
  static const Color primaryDark = Color(0xFF0A0E27);   // Dark blue
  static const Color accent = Color(0xFF6C63FF);        // Purple
  static const Color success = Color(0xFF00D4AA);       // Green
  static const Color warning = Color(0xFFD97706);       // Amber
  static const Color error = Color(0xFFDC2626);         // Red
  static const Color info = Color(0xFF0891B2);          // Cyan

  // Dark theme colors
  static const Color darkBg = Color(0xFF0A0E27);        // Primary dark blue
  static const Color darkSurface = Color(0xFF111936);   // Slightly lighter
  static const Color darkCard = Color(0xFF1A2035);      // Card color
  static const Color darkBorder = Color(0xFF2A3050);    // Border color

  static const _fontFamily = 'Poppins';

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: _fontFamily,
    colorScheme: ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: darkSurface,
      error: error,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: darkBg,
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      prefixIconColor: Colors.grey[500],
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: primary.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: _fontFamily),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkCard,
      selectedColor: primary,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: darkBorder),
    ),
    dividerTheme: DividerThemeData(color: darkBorder, thickness: 1),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primary,
      unselectedItemColor: Colors.grey[600],
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurface,
      indicatorColor: primary.withOpacity(0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primary);
        }
        return TextStyle(fontSize: 12, color: Colors.grey[500]);
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: darkSurface,
      selectedIconTheme: const IconThemeData(color: primary),
      unselectedIconTheme: IconThemeData(color: Colors.grey[500]),
      selectedLabelTextStyle: const TextStyle(color: primary, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: TextStyle(color: Colors.grey[500]),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: const TextStyle(fontFamily: _fontFamily, color: Colors.white),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: _fontFamily,
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: accent,
      error: error,
    ),
  );

  // Gradients
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [Color(0xFF0A0E27), Color(0xFF1A1F4B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get accentGradient => const LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4A42D1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get successGradient => const LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF00A884)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get cardGradientBlue => const LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get cardGradientPurple => const LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get cardGradientGreen => const LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get loginGradient => const LinearGradient(
    colors: [Color(0xFF0A0E27), Color(0xFF1A1F4B), Color(0xFF2D1B69)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );
}
