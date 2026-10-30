import 'package:flutter/material.dart';

const forest = Color(0xFF365744);
const warmWhite = Color(0xFFF7F4EE);
const ink = Color(0xFF1E2D25);
const muted = Color(0xFF647068);
const softGreen = Color(0xFFEAF0E7);
const outline = Color(0xFFD7DFD5);

ThemeData campTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  scaffoldBackgroundColor: warmWhite,
  colorScheme: const ColorScheme.light(
    primary: forest,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: ink,
    secondary: forest,
    outline: outline,
    error: Color(0xFFAF352F),
    errorContainer: Color(0xFFFDEDE9),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 14, height: 20 / 14, color: ink),
    titleLarge: TextStyle(
      fontSize: 26,
      height: 32 / 26,
      fontWeight: FontWeight.bold,
      color: ink,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
      textStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: outline),
    ),
  ),
);
