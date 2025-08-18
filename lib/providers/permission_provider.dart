import 'package:flutter/material.dart';
import '../services/permission_service.dart'; // Nosso novo serviço
// REMOVIDO: import 'package:cloud_firestore/cloud_firestore.dart';

class PermissionProvider with ChangeNotifier {
  final PermissionService _permissionService = PermissionService();
  Map<String, dynamic> _permissions = {};
  bool _isLoading = false;

  Map<String, dynamic> get permissions => _permissions;
  bool get isLoading => _isLoading;

  // Método principal para carregar as permissões da nossa API
  Future<void> loadUserPermissions(String filialId, String token) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final permissionsData = await _permissionService.getUserPermissions(filialId, token);
      _permissions = permissionsData['acessos'] ?? {};
    } catch (e) {
      print("Erro ao carregar permissões via API: $e");
      _permissions = {}; // Em caso de erro, zera as permissões
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // A lógica de "hasAccess" permanece IDÊNTICA, pois ela já opera sobre o mapa _permissions
  bool hasAccess(List<String> path) {
    if (path.isEmpty) return false;
    
    dynamic currentLevel = _permissions;
    for (String key in path) {
      if (currentLevel is Map<String, dynamic> && currentLevel.containsKey(key)) {
        currentLevel = currentLevel[key];
      } else {
        return false;
      }
    }
    
    return currentLevel == true;
  }

  void clearPermissions() {
    _permissions = {};
    notifyListeners();
  }
}