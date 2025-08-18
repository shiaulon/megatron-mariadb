import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();

  String? _token;
  String? _mainCompanyId;
  List<String> _allowedSecondaryCompanies = [];

  // Getters para que outras partes do app possam ler o estado
  bool get isAuthenticated => _token != null;
  String? get token => _token; // <<< GETTER QUE ESTAVA FALTANDO
  String? get mainCompanyId => _mainCompanyId;
  List<String> get allowedSecondaryCompanies => _allowedSecondaryCompanies;

  Future<void> login(String email, String password) async {
    final responseData = await _authService.login(email, password);
    
    _token = responseData['token'];
    _mainCompanyId = responseData['mainCompanyId'];
    _allowedSecondaryCompanies = List<String>.from(responseData['allowedSecondaryCompanies'] ?? []);

    await _storage.write(key: 'token', value: _token);
    
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _mainCompanyId = null;
    _allowedSecondaryCompanies = [];
    await _storage.delete(key: 'token');
    notifyListeners();
  }
}