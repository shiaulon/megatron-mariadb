// lib/services/admin_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminService {
  // ATUALIZADO: URL base do servidor para ser mais genérica
  static final String _host = '10.135.59.5';
  //static final String _host = '192.168.1.5';
  //static final String _host = kIsWeb ? 'localhost' : '10.0.2.2';
  
  static final String _serverUrl = 'http://$_host:8080';
  
  // URLs específicas por módulo para melhor organização
  static final String _adminBaseUrl = '$_serverUrl/admin';
  static final String _notificationBaseUrl = '$_serverUrl/notifications'; // <-- URL para as notificações

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // --- MÉTODOS EXISTENTES (sem alteração na lógica) ---
  Future<List<String>> getUserAllowedCompanies(String userId, String token) async {
    final url = Uri.parse('$_adminBaseUrl/users/$userId/allowed-companies'); // Usa a URL de admin
    final response = await http.get(url, headers: _getHeaders(token));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<String>.from(data);
    } else {
      throw Exception('Falha ao buscar filiais permitidas do usuário.');
    }
  }

  Future<List<Map<String, dynamic>>> listUsers(String token) async {
    final url = Uri.parse('$_adminBaseUrl/users'); // Usa a URL de admin
    final response = await http.get(url, headers: _getHeaders(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Falha ao listar usuários.');
    }
  }

  Future<void> savePermissions(String userId, Map<String, dynamic> permissionsByFilial, String token) async {
    final url = Uri.parse('$_adminBaseUrl/users/$userId/permissions'); // Usa a URL de admin
    final response = await http.post(
      url,
      headers: _getHeaders(token),
      body: jsonEncode(permissionsByFilial),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao salvar permissões.');
    }
  }
  
  // ▼▼▼ NOVOS MÉTODOS ADICIONADOS AQUI ▼▼▼

  /// Envia uma mensagem de broadcast para todos os usuários conectados.
  Future<void> enviarMensagemBroadcast(String message, String token) async {
    final url = Uri.parse('$_notificationBaseUrl/broadcast-message'); // <-- Usa a nova URL de notificações
    final response = await http.post(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception('Falha ao enviar mensagem: ${errorData['error']}');
    }
  }

  /// Busca o histórico de mensagens enviadas.
  Future<List<Map<String, dynamic>>> getBroadcastHistory(String token) async {
    final url = Uri.parse('$_notificationBaseUrl/history'); // <-- Usa a nova URL de notificações
    final response = await http.get(
      url,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Falha ao buscar histórico de avisos.');
    }
  }
}