import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static final String _host = kIsWeb ? 'localhost' : '10.0.2.2';
  static final String _baseUrl = 'http://$_host:8080';

  Future<List<Map<String, dynamic>>> getSecondaryCompaniesDetails(List<String> ids, String token) async {
    if (ids.isEmpty) return [];

    final url = Uri.parse('$_baseUrl/empresas/secundarias?ids=${ids.join(',')}');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Falha ao carregar detalhes das empresas.');
    }
  }
}