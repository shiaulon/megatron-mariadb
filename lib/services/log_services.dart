// lib/services/log_services.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

enum LogAction { CREATE, UPDATE, DELETE, LOGIN, LOGOUT, ERROR, PERMISSION_CHANGE, GENERATE_REPORT }
enum LogModule { LOGIN, ADMINISTRACAO, TABELA, REGISTRO_GERAL, CREDITO, RELATORIO, CRM }

class LogService {
  static final String _host = kIsWeb ? 'localhost' : '10.0.2.2';
  static final String _baseUrl = 'http://$_host:8080/logs';

  final String _token; 
  LogService(this._token);

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $_token',
    };
  }

  // REMOVIDO: A função addLog não existe mais no frontend.
  Future<void> addReportLog({
    required String reportName,
    required String mainCompanyId,
    required String secondaryCompanyId,
  }) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/report'), // Chama a nova rota
        headers: _getHeaders(),
        body: jsonEncode({
          'reportName': reportName,
          'mainCompanyId': mainCompanyId,
          'secondaryCompanyId': secondaryCompanyId,
        }),
      );
    } catch (e) {
      print("Falha ao enviar log de relatório: $e");
    }
  }

  // A função getLogs continua a mesma, pois é usada pela LogsPage
  Future<List<Map<String, dynamic>>> getLogs({
    String? userEmail,
    String? action,
    String? modulo,
  }) async {
    final queryParams = <String, String>{};
    if (userEmail != null && userEmail.isNotEmpty) queryParams['userEmail'] = userEmail;
    if (action != null) queryParams['action'] = action;
    if (modulo != null) queryParams['modulo'] = modulo;
    
    final url = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
    final response = await http.get(url, headers: _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Falha ao carregar logs da API: ${response.body}');
    }
  }
}