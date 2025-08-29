import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class ManutRgService {
  static final String _host = kIsWeb ? 'localhost' : '10.0.2.2';
  static final String _baseUrl = 'http://$_host:8080/manut-rg';

  void _handleError(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Falha na operação da API.');
    } catch (_) {
      throw Exception('Falha na operação da API (Status: ${response.statusCode})');
    }
  }

  // --- Funções Principais ---
  Future<Map<String, dynamic>> getRgCompleto(String id, String token) async {
    final url = Uri.parse('$_baseUrl/$id');
    final response = await http.get(url, headers: _getHeaders(token));
    if (response.statusCode == 200) return jsonDecode(response.body);
    if (response.statusCode == 404) return {};
    _handleError(response);
    return {};
  }

  Future<void> saveData(Map<String, dynamic> data, String token) async {
    final url = Uri.parse(_baseUrl);
    final response = await http.post(url, headers: _getHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) _handleError(response);
  }

  // --- Funções Auxiliares (Dropdowns, etc) ---
  Future<List<Map<String, dynamic>>> getDadosAuxiliares(String path, String token) async {
    final url = Uri.parse('http://$_host:8080/$path');
    final response = await http.get(url, headers: _getHeaders(token));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    _handleError(response);
    return [];
  }

  Future<List<Map<String, dynamic>>> getRgSuggestions(String token) async {
    final url = Uri.parse('$_baseUrl/suggestions');
    final response = await http.get(url, headers: _getHeaders(token));
    if (response.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    _handleError(response);
    return [];
  }

  Future<String> getNextCodigo(String token) async {
    final url = Uri.parse('$_baseUrl/next-code');
    final response = await http.get(url, headers: _getHeaders(token));
    if (response.statusCode == 200) return jsonDecode(response.body)['nextCode'].toString();
    _handleError(response);
    return '';
  }

  // --- CRUD Genérico para Sub-Tabelas ---
  Future<void> addSubItem(String rgId, String path, Map<String, dynamic> data, String token) async {
    final url = Uri.parse('$_baseUrl/$rgId/$path');
    final response = await http.post(url, headers: _getHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) _handleError(response);
  }

  Future<void> updateSubItem(String itemId, String path, Map<String, dynamic> data, String token) async {
    final url = Uri.parse('$_baseUrl/$path/$itemId');
    final response = await http.put(url, headers: _getHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) _handleError(response);
  }

  Future<void> deleteSubItem(String itemId, String path, String token) async {
    final url = Uri.parse('$_baseUrl/$path/$itemId');
    final response = await http.delete(url, headers: _getHeaders(token));
    if (response.statusCode != 200) _handleError(response);
  }

  // --- Funções Auxiliares ---

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // Função genérica para lidar com respostas de erro da API
  

  // --- REGISTRO GERAL (DADOS PRINCIPAIS) ---

  

  

  // --- TELEFONES ---

  Future<void> addTelefone(String rgId, Map<String, dynamic> data, String token) async {
    final url = Uri.parse('$_baseUrl/$rgId/telefones');
    final response = await http.post(url, headers: _getHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  Future<void> deleteTelefone(String telefoneId, String token) async {
    final url = Uri.parse('$_baseUrl/telefones/$telefoneId');
    final response = await http.delete(url, headers: _getHeaders(token));
    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  // --- SÓCIOS (COMPOSIÇÃO ACIONÁRIA) ---

  Future<void> addSocio(String rgId, Map<String, dynamic> data, String token) async {
    final url = Uri.parse('$_baseUrl/$rgId/socios');
    final response = await http.post(url, headers: _getHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  Future<void> deleteSocio(String socioId, String token) async {
    final url = Uri.parse('$_baseUrl/socios/$socioId');
    final response = await http.delete(url, headers: _getHeaders(token));
    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  // --- CONTATOS ---

  Future<void> addContato(String rgId, Map<String, dynamic> data, String token) async {
    final url = Uri.parse('$_baseUrl/$rgId/contatos');
    final response = await http.post(url, headers: _getHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  Future<void> deleteContato(String contatoId, String token) async {
    final url = Uri.parse('$_baseUrl/contatos/$contatoId');
    final response = await http.delete(url, headers: _getHeaders(token));
    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  // --- REFERÊNCIAS BANCÁRIAS ---

  Future<void> addReferenciaBancaria(String rgId, Map<String, dynamic> data, String token) async {
    final url = Uri.parse('$_baseUrl/$rgId/referencias-bancarias');
    final response = await http.post(url, headers: _getHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  Future<void> deleteReferenciaBancaria(String refId, String token) async {
    final url = Uri.parse('$_baseUrl/referencias-bancarias/$refId');
    final response = await http.delete(url, headers: _getHeaders(token));
    if (response.statusCode != 200) {
      _handleError(response);
    }
  }
  
  // --- REFERÊNCIAS COMERCIAIS ---
  
  Future<void> addReferenciaComercial(String rgId, Map<String, dynamic> data, String token) async {
    final url = Uri.parse('$_baseUrl/$rgId/referencias-comerciais');
    final response = await http.post(url, headers: _getHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  Future<void> deleteReferenciaComercial(String refId, String token) async {
    final url = Uri.parse('$_baseUrl/referencias-comerciais/$refId');
    final response = await http.delete(url, headers: _getHeaders(token));
    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  Future<List<Map<String, dynamic>>> getCidades(String token) async {
    // Assumindo que você tem um endpoint /cidades
    final url = Uri.parse('http://$_host:8080/cidades');
    final response = await http.get(url, headers: _getHeaders(token));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      _handleError(response);
      return [];
    }
  }
  
  // Você criará endpoints similares para Cargos e Situações no backend
  Future<List<Map<String, dynamic>>> getCargos(String token) async {
    final url = Uri.parse('http://$_host:8080/cargos'); // CRIAR ESTE ENDPOINT
    final response = await http.get(url, headers: _getHeaders(token));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      _handleError(response);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSituacoes(String token) async {
    final url = Uri.parse('http://$_host:8080/situacoes'); // CRIAR ESTE ENDPOINT
    final response = await http.get(url, headers: _getHeaders(token));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      _handleError(response);
      return [];
    }
  }

  // --- Funções para sugestões de busca e novo código ---

  

  
  
  // --- Funções de ATUALIZAÇÃO para sub-tabelas ---
  
  Future<void> updateTelefone(String telefoneId, Map<String, dynamic> data, String token) async {
    final url = Uri.parse('$_baseUrl/telefones/$telefoneId'); // CRIAR ESTE ENDPOINT (PUT)
    final response = await http.put(url, headers: _getHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  // --- SÓCIOS (UPDATE) ---
  Future<void> updateSocio(String socioId, Map<String, dynamic> data, String token) async {
    final url = Uri.parse('$_baseUrl/socios/$socioId');
    final response = await http.put(url, headers: _getHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  // --- CONTATOS (UPDATE) ---
  Future<void> updateContato(String contatoId, Map<String, dynamic> data, String token) async {
    final url = Uri.parse('$_baseUrl/contatos/$contatoId');
    final response = await http.put(url, headers: _getHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  // --- REFERÊNCIAS BANCÁRIAS (UPDATE) ---
  Future<void> updateReferenciaBancaria(String refId, Map<String, dynamic> data, String token) async {
    final url = Uri.parse('$_baseUrl/referencias-bancarias/$refId');
    final response = await http.put(url, headers: _getHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  // --- REFERÊNCIAS COMERCIAIS (UPDATE) ---
  Future<void> updateReferenciaComercial(String refId, Map<String, dynamic> data, String token) async {
    final url = Uri.parse('$_baseUrl/referencias-comerciais/$refId');
    final response = await http.put(url, headers: _getHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  // ▼▼▼ ADICIONE ESTE NOVO MÉTODO ▼▼▼
  Future<String> getNextCodigoInterno(String token) async {
    final url = Uri.parse('$_baseUrl/next-internal-code');
    final response = await http.get(url, headers: _getHeaders(token));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['nextCode'].toString();
    }
    _handleError(response);
    return '';
  }
  // ▲▲▲ FIM DO NOVO MÉTODO ▲▲▲

  // ▼▼▼ ADICIONE ESTE NOVO MÉTODO ▼▼▼
  Future<List<Map<String, dynamic>>> getAllRegistros(String token) async {
    final url = Uri.parse(_baseUrl); // A rota GET base ('/')
    final response = await http.get(url, headers: _getHeaders(token));
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Falha ao carregar todos os registros da API: ${response.body}');
    }
  }
  // ▲▲▲ FIM DO NOVO MÉTODO ▲▲▲
}