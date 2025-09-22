// lib/services/credito_faixas_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class CreditoFaixasService {
  static final String _host = '10.135.59.5';
  //static final String _host = '192.168.1.5';
  //static final String _host = kIsWeb ? 'localhost' : '10.0.2.2';
  static final String _baseUrl = 'http://$_host:8080/credito-faixas';

  Map<String, String> _getHeaders(String token) => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

  void _handleError(http.Response response) {
    throw Exception('Falha na operação: ${response.body}');
  }

  Future<Map<String, dynamic>> getData(String tipoPessoa, String token) async {
    final response = await http.get(Uri.parse('$_baseUrl/$tipoPessoa'), headers: _getHeaders(token));
    if (response.statusCode == 200) return jsonDecode(response.body);
    if (response.statusCode == 404) return {};
    _handleError(response);
    return {};
  }

  Future<void> saveData(Map<String, dynamic> data, String token) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _getHeaders(token),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) _handleError(response);
  }

  Future<void> deleteData(String tipoPessoa, String token) async {
    final response = await http.delete(Uri.parse('$_baseUrl/$tipoPessoa'), headers: _getHeaders(token));
    if (response.statusCode != 200) _handleError(response);
  }
}