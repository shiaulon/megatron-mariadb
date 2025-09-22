// lib/services/situacao_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class SituacaoService {
  // ▼▼▼ ADICIONE ESTAS LINHAS ▼▼▼
  // Use o IP do seu servidor aqui
  //static final String _host = '10.135.59.5';
  // Descomente a linha abaixo para rodar localmente
   static final String _host = kIsWeb ? 'localhost' : '10.0.2.2';

  // ▼▼▼ ALTERE ESTA LINHA ▼▼▼
  // Agora ela usa a variável _host, assim como seus outros serviços
  final String _baseUrl = 'http://$_host:8080/situacoes';

  Future<List<Map<String, dynamic>>> getAll(String token) async {
    final url = Uri.parse(_baseUrl);
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao carregar situações: ${response.body}');
    }
  }

  Future<void> saveData(Map<String, dynamic> data, String token) async {
    final url = Uri.parse(_baseUrl);
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao salvar situação: ${response.body}');
    }
  }

  Future<void> deleteData(String id, String secondaryCompanyId, String token) async {
    final url = Uri.parse('$_baseUrl/$id?secondaryCompanyId=$secondaryCompanyId');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao excluir situação: ${response.body}');
    }
  }
}