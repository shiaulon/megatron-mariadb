// lib/services/estado_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class EstadoService {
  static final String _host = '10.135.59.5';
  //static final String _host = '192.168.1.5';
  //static final String _host = kIsWeb ? 'localhost' : '10.0.2.2';
  static final String _baseUrl = 'http://$_host:8080/estados';

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> getAll(String token) async {
    final url = Uri.parse(_baseUrl);
    final response = await http.get(url, headers: _getHeaders(token));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao carregar estados da API.');
    }
  }

  Future<void> saveData(Map<String, dynamic> data, String token) async {
    final url = Uri.parse(_baseUrl);
    final response = await http.post(url, headers: _getHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) {
      throw Exception('Falha ao salvar estado: ${response.body}');
    }
  }

  Future<void> deleteData(String id, String secondaryCompanyId, String token) async {
    final url = Uri.parse('$_baseUrl/$id?secondaryCompanyId=$secondaryCompanyId');
    final response = await http.delete(url, headers: _getHeaders(token));
    if (response.statusCode != 200) {
      throw Exception('Falha ao excluir estado: ${response.body}');
    }
  }
}