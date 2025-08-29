// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeOption { light, dark, system }

class ThemeProvider with ChangeNotifier {
  final SharedPreferences _prefs; // Armazena a instância recebida
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // O construtor agora recebe a instância do SharedPreferences
  ThemeProvider(this._prefs) {
    _loadTheme();
  }

  void setTheme(ThemeMode themeMode) {
    if (_themeMode != themeMode) {
      _themeMode = themeMode;
      _saveTheme(themeMode);
      notifyListeners();
    }
  }

  // Agora usa a instância _prefs que já temos, sem precisar de 'await'
  void _loadTheme() {
    final themeString = _prefs.getString('themeMode') ?? 'system';
    
    switch (themeString) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
        break;
    }
    // Não precisa de notifyListeners() aqui, pois é chamado no construtor
  }

  // Também usa a instância _prefs
  Future<void> _saveTheme(ThemeMode themeMode) async {
    String themeString;
    switch (themeMode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      default:
        themeString = 'system';
        break;
    }
    await _prefs.setString('themeMode', themeString);
  }
}