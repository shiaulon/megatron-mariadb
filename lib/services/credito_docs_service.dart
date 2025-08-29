// lib/services/credito_docs_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class CreditoDocsService {
  static final String _host = kIsWeb ? 'localhost' : '10.0.2.2';
  static final String _baseUrl = 'http://$_host:8080/credito-documentos';

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  void _handleError(http.Response response) {
    throw Exception('Falha na operação: ${response.body}');
  }

  Future<Map<String, dynamic>> getDocumento(String id, String token) async {
    final response = await http.get(Uri.parse('$_baseUrl/$id'), headers: _getHeaders(token));
    if (response.statusCode == 200) return jsonDecode(response.body);
    if (response.statusCode == 404) return {};
    _handleError(response);
    return {};
  }

  Future<List<Map<String, dynamic>>> getAllDocumentos(String token) async {
    final response = await http.get(Uri.parse(_baseUrl), headers: _getHeaders(token));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    _handleError(response);
    return [];
  }

  Future<void> saveData(Map<String, dynamic> data, String token) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _getHeaders(token),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) _handleError(response);
  }

  Future<void> deleteData(String id, String secondaryCompanyId, String token) async {
    final uri = Uri.parse('$_baseUrl/$id?secondaryCompanyId=$secondaryCompanyId');
    final response = await http.delete(uri, headers: _getHeaders(token));
    if (response.statusCode != 200) _handleError(response);
  }
}