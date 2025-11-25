import 'package:flutter/material.dart';

class AppTheme {
  // Warna utama aplikasi
  static const Color primaryGreen = Color(0xFF087B42);
  static const Color lightBackground = Colors.white;
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: lightBackground,
    colorScheme: const ColorScheme.light(
      primary: primaryGreen,
      secondary: Color(0xFFDCF0E9),
      surface: Colors.white,
      error: Color(0xFFFF5656),
      onPrimary: Colors.white,
      onSecondary: Color(0xFF44444C),
      onSurface: Color(0xFF44444C),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        fontFamily: 'Poppins',
        color: Color(0xFF44444C),
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Poppins',
        color: Color(0xFF44444C),
      ),
      titleLarge: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        color: Color(0xFF44444C),
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF44444C),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: primaryGreen,
      secondary: Color(0xFF1A4D2E),
      surface: darkSurface,
      error: Color(0xFFFF5656),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
  );
}
