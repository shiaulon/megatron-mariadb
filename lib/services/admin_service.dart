import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminService {
  static final String _host = kIsWeb ? 'localhost' : '10.0.2.2';
  static final String _baseUrl = 'http://$_host:8080/admin';

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<String>> getUserAllowedCompanies(String userId, String token) async {
    final url = Uri.parse('$_baseUrl/users/$userId/allowed-companies');
    final response = await http.get(url, headers: _getHeaders(token));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<String>.from(data);
    } else {
      throw Exception('Falha ao buscar filiais permitidas do usuário.');
    }
  }


  Future<List<Map<String, dynamic>>> listUsers(String token) async {
    final url = Uri.parse('$_baseUrl/users');
    final response = await http.get(url, headers: _getHeaders(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Falha ao listar usuários.');
    }
  }

  Future<void> savePermissions(String userId, Map<String, dynamic> permissionsByFilial, String token) async {
    final url = Uri.parse('$_baseUrl/users/$userId/permissions');
    final response = await http.post(
      url,
      headers: _getHeaders(token),
      body: jsonEncode(permissionsByFilial),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao salvar permissões.');
    }
  }
}