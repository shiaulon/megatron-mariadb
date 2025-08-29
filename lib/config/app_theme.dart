// lib/config/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF0D47A1),
    scaffoldBackgroundColor: Colors.grey[200],
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1976D2),
      secondary: Color(0xFF42A5F5),
      surface: Colors.white,
      background: Color(0xFFF5F5F5),
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black,
      onBackground: Colors.black,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      color: Color(0xFF42A5F5),
      elevation: 2,
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: Colors.black),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      
      // Borda padrão para todos os estados
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        // ▼▼▼ ALTERAÇÃO AQUI ▼▼▼
        borderSide: const BorderSide(color: Colors.black54, width: 1.5),
      ),

      // Borda para o campo habilitado (sem foco)
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        // ▼▼▼ ALTERAÇÃO AQUI ▼▼▼
        borderSide: const BorderSide(color: Colors.black54, width: 1.5),
      ),

      // Borda para o campo com foco (quando o usuário clica nele)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        // ▼▼▼ ALTERAÇÃO AQUI ▼▼▼
        borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2.5),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade700),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF212121),
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF42A5F5),
      secondary: Color(0xFF1976D2),
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
      error: Colors.redAccent,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      color: Color(0xFF1E1E1E),
      elevation: 2,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade800,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      
      // Borda padrão para o tema escuro
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        // ▼▼▼ ALTERAÇÃO AQUI ▼▼▼
        borderSide: BorderSide(color: Colors.grey.shade600, width: 1.5),
      ),
      
      // Borda para o campo habilitado no tema escuro
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        // ▼▼▼ ALTERAÇÃO AQUI ▼▼▼
        borderSide: BorderSide(color: Colors.grey.shade600, width: 1.5),
      ),
      
      // Borda com foco no tema escuro
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        // ▼▼▼ ALTERAÇÃO AQUI ▼▼▼
        borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 2.5),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade400),
    ),
  );
}