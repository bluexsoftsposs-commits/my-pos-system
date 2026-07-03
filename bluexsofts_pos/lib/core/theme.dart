import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand Colors ──────────────────────────────────────────────
  static const Color primary = Color(0xFF6C5CE7);       // Indigo (brand primary)
  static const Color primaryDark = Color(0xFF131313);    // Near-black surface
  static const Color accent = Color(0xFF6C5CE7);        // Same as primary
  static const Color success = Color(0xFF00B894);        // Success green
  static const Color warning = Color(0xFFFDCB6E);        // Warning amber
  static const Color error = Color(0xFFD63031);          // Error red
  static const Color info = Color(0xFF0891B2);           // Cyan

  // ── Dark Theme Colors (Indigo Nexus "Deep Night") ────────────
  static const Color darkBg = Color(0xFF131313);         // surface / background
  static const Color darkSurface = Color(0xFF201F1F);    // surface-container
  static const Color darkCard = Color(0xFF2A2A2A);       // surface-container-high
  static const Color darkBorder = Color(0xFF474554);     // outline-variant

  // ── Light Theme Colors ───────────────────────────────────────
  static const Color lightBg = Color(0xFFF8F9FD);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFC4C1CA);

  // ── Typography ───────────────────────────────────────────────
  static const _fontFamily = 'Poppins';

  // ── Border Radii ─────────────────────────────────────────────
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 9999;

  // ── Spacing ──────────────────────────────────────────────────
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  // ── Shadows (indigo tint, no pure black) ─────────────────────
  static const _shadowColor = Color(0x66000000);
  static List<BoxShadow> get shadowLevel1 => [
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.06),
      blurRadius: 1,
      offset: const Offset(0, 1),
    ),
  ];
  static List<BoxShadow> get shadowLevel2 => [
    BoxShadow(
      color: _shadowColor.withValues(alpha: 0.4),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> get shadowLevel3 => [
    BoxShadow(
      color: _shadowColor.withValues(alpha: 0.5),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  // ── Text Theme ───────────────────────────────────────────────
  static TextTheme get _textTheme => const TextTheme(
    displayLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 48,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.96,
    ),
    headlineLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.32,
    ),
    titleMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.60,
    ),
  );

  // ── Dark Theme ───────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: _fontFamily,
    textTheme: _textTheme,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFC6BFFF),
      onPrimary: Color(0xFF2900A0),
      primaryContainer: Color(0xFF6C5CE7),
      onPrimaryContainer: Color(0xFFFAF6FF),
      secondary: Color(0xFF4BDDB7),
      onSecondary: Color(0xFF00382B),
      secondaryContainer: Color(0xFF02B894),
      onSecondaryContainer: Color(0xFF004233),
      tertiary: Color(0xFFF0BF63),
      onTertiary: Color(0xFF412D00),
      tertiaryContainer: Color(0xFF926B15),
      onTertiaryContainer: Color(0xFFFFF6EE),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF131313),
      onSurface: Color(0xFFE5E2E1),
      onSurfaceVariant: Color(0xFFC8C4D7),
      outline: Color(0xFF928EA0),
      outlineVariant: Color(0xFF474554),
      inverseSurface: Color(0xFFE5E2E1),
      onInverseSurface: Color(0xFF313030),
      surfaceTint: Color(0xFFC6BFFF),
    ),
    scaffoldBackgroundColor: darkBg,
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
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
      fillColor: Colors.white.withValues(alpha: 0.02),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: Color(0xFFD63031)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: spaceMd, vertical: spaceMd),
      labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      prefixIconColor: Colors.grey[500],
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: _fontFamily),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFFC6BFFF)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkCard,
      selectedColor: const Color(0xFF6C5CE7),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: _fontFamily),
      secondaryLabelStyle: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: _fontFamily),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusFull)),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      padding: const EdgeInsets.symmetric(horizontal: spaceSm, vertical: 6),
    ),
    dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.08), thickness: 1, space: 1),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: const Color(0xFFC6BFFF),
      unselectedItemColor: Colors.grey[600],
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurface,
      indicatorColor: const Color(0xFF6C5CE7).withValues(alpha: 0.20),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFC6BFFF), fontFamily: _fontFamily);
        }
        return TextStyle(fontSize: 12, color: Colors.grey[500], fontFamily: _fontFamily);
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: darkSurface,
      selectedIconTheme: const IconThemeData(color: Color(0xFFC6BFFF)),
      unselectedIconTheme: IconThemeData(color: Colors.grey[500]),
      selectedLabelTextStyle: const TextStyle(color: Color(0xFFC6BFFF), fontWeight: FontWeight.w600, fontFamily: _fontFamily),
      unselectedLabelTextStyle: TextStyle(color: Colors.grey[500], fontFamily: _fontFamily),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      contentTextStyle: const TextStyle(fontFamily: _fontFamily, color: Colors.white, fontSize: 14),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd), borderSide: BorderSide(color: darkBorder)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF6C5CE7),
      foregroundColor: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
    ),
    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: spaceMd, vertical: spaceXs),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
    ),
  );

  // ── Light Theme ──────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: _fontFamily,
    textTheme: _textTheme.copyWith(
      bodyLarge: const TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF1C1B1F)),
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6C5CE7),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFE8E0FF),
      onPrimaryContainer: Color(0xFF1A0066),
      secondary: Color(0xFF00B894),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFB3F5E8),
      onSecondaryContainer: Color(0xFF002018),
      tertiary: Color(0xFFFDCB6E),
      onTertiary: Color(0xFF412D00),
      tertiaryContainer: Color(0xFFFFF3D6),
      onTertiaryContainer: Color(0xFF1A0E00),
      error: Color(0xFFD63031),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: Color(0xFFF8F9FD),
      onSurface: Color(0xFF1C1B1F),
      onSurfaceVariant: Color(0xFF49454F),
      outline: Color(0xFF79747E),
      outlineVariant: Color(0xFFC4C1CA),
    ),
    scaffoldBackgroundColor: lightBg,
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
      surfaceTintColor: Colors.transparent,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightSurface,
      foregroundColor: const Color(0xFF1C1B1F),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1C1B1F),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0F0F4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: Color(0xFFC4C1CA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: Color(0xFFC4C1CA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: Color(0xFFD63031)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: Color(0xFF49454F), fontSize: 14),
      hintStyle: const TextStyle(color: Color(0xFF79747E), fontSize: 14),
      prefixIconColor: const Color(0xFF49454F),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: _fontFamily),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF6C5CE7)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: lightSurface,
      selectedItemColor: const Color(0xFF6C5CE7),
      unselectedItemColor: const Color(0xFF79747E),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFC4C1CA), thickness: 1, space: 1),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF0F0F4),
      selectedColor: const Color(0xFFE8E0FF),
      labelStyle: const TextStyle(color: Color(0xFF1C1B1F), fontSize: 13, fontFamily: _fontFamily),
      secondaryLabelStyle: const TextStyle(color: Color(0xFF49454F), fontSize: 12, fontFamily: _fontFamily),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusFull)),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1C1B1F),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      contentTextStyle: const TextStyle(fontFamily: _fontFamily, color: Colors.white, fontSize: 14),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF6C5CE7),
      foregroundColor: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
    ),
  );

  // ── Gradients ────────────────────────────────────────────────
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [Color(0xFF131313), Color(0xFF1C1B2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get accentGradient => const LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF5847D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get successGradient => const LinearGradient(
    colors: [Color(0xFF00B894), Color(0xFF00A884)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get cardGradientBlue => const LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get cardGradientPurple => const LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF5A4BD1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get cardGradientGreen => const LinearGradient(
    colors: [Color(0xFF00B894), Color(0xFF009B7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get loginGradient => const LinearGradient(
    colors: [Color(0xFF131313), Color(0xFF1C1B2E), Color(0xFF2D1B69)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );
}
