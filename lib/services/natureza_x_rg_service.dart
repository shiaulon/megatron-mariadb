// lib/services/natureza_x_rg_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class NaturezaXRgService {
  static final String _host = '10.135.59.5';
  //static final String _host = '192.168.1.5';
  //static final String _host = kIsWeb ? 'localhost' : '10.0.2.2';
  static final String _baseUrl = 'http://$_host:8080/manut-rg/natureza-x-rg';

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getData(String rgId, String naturezaId, String token) async {
    final url = Uri.parse('$_baseUrl/$rgId/$naturezaId');
    final response = await http.get(url, headers: _getHeaders(token));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return {};
    } else {
      throw Exception('Falha ao carregar dados da API.');
    }
  }

  Future<void> saveData(String rgId, Map<String, dynamic> data, String token) async {
    final url = Uri.parse('$_baseUrl/$rgId');
    final response = await http.post(url, headers: _getHeaders(token), body: jsonEncode(data));
    
    if (response.statusCode != 200) {
      throw Exception('Falha ao salvar dados na API: ${response.body}');
    }
  }

  // ▼▼▼ FUNÇÃO DE EXCLUSÃO ADICIONADA ▼▼▼
  Future<void> deleteData(String rgId, String naturezaId, String secondaryCompanyId, String token) async {
    final url = Uri.parse('$_baseUrl/$rgId/$naturezaId?secondaryCompanyId=$secondaryCompanyId');
    final response = await http.delete(url, headers: _getHeaders(token));
    
    if (response.statusCode != 200) {
      throw Exception('Falha ao excluir dados na API: ${response.body}');
    }
  }
}