import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- IMPORTE O NOVO PACOTE
import '../services/auth_service.dart';
// Remova a importação do flutter_secure_storage se não for usar em mobile
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  // A instância do SharedPreferences será obtida quando precisarmos dela
  // final _storage = const FlutterSecureStorage(); // <-- REMOVA OU COMENTE ESTA LINHA

  String? _token;
  String? _mainCompanyId;
  List<String> _allowedSecondaryCompanies = [];

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get mainCompanyId => _mainCompanyId;
  List<String> get allowedSecondaryCompanies => _allowedSecondaryCompanies;

  Future<void> login(String email, String password) async {
    final responseData = await _authService.login(email, password);
    
    _token = responseData['token'];
    _mainCompanyId = responseData['mainCompanyId'];
    _allowedSecondaryCompanies = List<String>.from(responseData['allowedSecondaryCompanies'] ?? []);

    // ▼▼▼ ALTERAÇÃO PRINCIPAL AQUI ▼▼▼
    // Descomente e altere a lógica de salvamento
    if (_token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!); // Usando SharedPreferences
    }
    
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _mainCompanyId = null;
    _allowedSecondaryCompanies = [];
    
    // ▼▼▼ ALTERAÇÃO AQUI TAMBÉM ▼▼▼
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Usando SharedPreferences para remover

    notifyListeners();
  }
}