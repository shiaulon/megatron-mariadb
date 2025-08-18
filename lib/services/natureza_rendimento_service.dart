// lib/services/natureza_rendimento_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class NaturezaRendimentoService {
  static final String _host = kIsWeb ? 'localhost' : '10.0.2.2';
  static final String _baseUrl = 'http://$_host:8080/natureza-rendimento';

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
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Falha ao carregar dados da API: ${response.body}');
    }
  }

  Future<void> saveData(Map<String, dynamic> data, String token) async {
    final url = Uri.parse(_baseUrl);
    final response = await http.post(url, headers: _getHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) {
      throw Exception('Falha ao salvar dados na API: ${response.body}');
    }
  }

  Future<void> deleteData(String id, String token) async {
    final url = Uri.parse('$_baseUrl/$id');
    final response = await http.delete(url, headers: _getHeaders(token));
    if (response.statusCode != 200) {
      throw Exception('Falha ao deletar dados na API: ${response.body}');
    }
  }
}