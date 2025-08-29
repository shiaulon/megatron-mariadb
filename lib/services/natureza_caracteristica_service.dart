// lib/services/natureza_caracteristica_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class NaturezaCaracteristicaService {
  static final String _host = kIsWeb ? 'localhost' : '10.0.2.2';
  static final String _baseUrl = 'http://$_host:8080/natureza-caracteristica';

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> getDados(Map<String, String> filters, String token) async {
    final url = Uri.parse('$_baseUrl/dados').replace(queryParameters: filters);
    final response = await http.get(url, headers: _getHeaders(token));
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao carregar dados da API: ${response.body}');
    }
  }

  Future<void> aplicar(Map<String, dynamic> data, String token) async {
    final url = Uri.parse('$_baseUrl/aplicar');
    final response = await http.post(url, headers: _getHeaders(token), body: jsonEncode(data));
    
    if (response.statusCode != 200) {
      throw Exception('Falha ao aplicar dados na API: ${response.body}');
    }
  }
}