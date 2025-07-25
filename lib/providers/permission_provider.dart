// lib/providers/permission_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/permission_model.dart';

class PermissionProvider with ChangeNotifier {
  UserPermissions _userPermissions = UserPermissions(acessos: {}); // <-- Volta a ser 'acessos'
  String? _currentUserId;
  // String? _activeSecondaryCompanyId; // REMOVIDO: Não é mais necessário aqui

  // Getter para o modelo completo de permissões
  UserPermissions get allUserPermissions => _userPermissions; // Getter original

  // Método para carregar as permissões do usuário logado (sem activeSecondaryCompanyId)
  Future<void> loadUserPermissions(String userId) async { // <-- REMOVIDO activeSecondaryCompanyId
    _currentUserId = userId;
    // _activeSecondaryCompanyId = activeSecondaryCompanyId; // REMOVIDO

    if (_currentUserId == null) { // Condição simplificada
      _userPermissions = UserPermissions(acessos: {});
      notifyListeners();
      print("Dados insuficientes para carregar permissões: userId está faltando.");
      return;
    }

    try {
      // Carrega o documento user_access que contém as permissões GLOBAIS
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('permissions')
          .doc('user_access') // <-- Documento fixo 'user_access'
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        _userPermissions = UserPermissions.fromMap(docSnapshot.data()!);
      } else {
        // Se user_access não existe, cria um com permissões padrão (globais)
        _userPermissions = UserPermissions.defaultPermissions(); // Usa defaultPermissions global

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('permissions')
            .doc('user_access')
            .set(_userPermissions.toMap(), SetOptions(merge: true));
      }
    } catch (e) {
      print("Erro ao carregar permissões do usuário $userId: $e"); // Mensagem simplificada
      _userPermissions = UserPermissions(acessos: {}); // Em caso de erro, permissões vazias
    } finally {
      notifyListeners();
    }
  }

  // Método para verificar permissão (sem secondaryCompanyId)
  bool hasAccess(List<String> path) { // <-- Não recebe secondaryCompanyId
    // Chama o método hasAccess do UserPermissions model (que não espera filial)
    return _userPermissions.hasAccess(path);
  }

  // Métodos de updatePermission e _savePermissionsToFirestore não estavam no PermissionProvider original
  // Eles pertencem à UserPermissionPage.
}