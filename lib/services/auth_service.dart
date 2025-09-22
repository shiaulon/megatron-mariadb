import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  // Define o host baseado na plataforma (Web vs. Mobile)
  // Linha CORRETA
  static final String _host = '10.135.59.5';
  //static final String _host = '192.168.1.5';
  //static final String _host = kIsWeb ? 'localhost' : '10.0.2.2';
  static final String _baseUrl = 'http://$_host:8080/auth';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Se o login for bem-sucedido, retorna o corpo da resposta (token, companyIds, etc.)
        return jsonDecode(response.body);
      } else {
        // Se o servidor retornar um erro (ex: 401), lança uma exceção com a mensagem de erro do servidor
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Erro desconhecido no login.');
      }
    } catch (e) {
      // Pega erros de rede (ex: servidor offline) e lança uma exceção mais amigável
      print('Erro de conexão no AuthService: $e');
      throw Exception('Não foi possível se conectar ao servidor. Verifique sua conexão.');
    }
  }
  
  // No futuro, as funções de registrar, duplicar e deletar usuários virão para cá.
}