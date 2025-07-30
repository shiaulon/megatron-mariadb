// lib/providers/permission_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/permission_model.dart';

class PermissionProvider with ChangeNotifier {
  UserPermissions _userPermissions = UserPermissions.defaultPermissions();
  String? _currentUserId;
  String? _activeSecondaryCompanyId; // ID da filial ativa

  UserPermissions get permissions => _userPermissions;

  // AGORA: Carrega as permissões para uma filial específica.
  Future<void> loadUserPermissions(String userId, String activeSecondaryCompanyId) async {
    _currentUserId = userId;
    _activeSecondaryCompanyId = activeSecondaryCompanyId;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('permissions')
          .doc(activeSecondaryCompanyId) // Carrega o doc da filial ativa
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        _userPermissions = UserPermissions.fromMap(docSnapshot.data()!);
      } else {
        // Se não houver, usa as padrão e cria o documento para a filial.
        _userPermissions = UserPermissions.defaultPermissions();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('permissions')
            .doc(activeSecondaryCompanyId)
            .set(_userPermissions.toMap());
      }
    } catch (e) {
      print("Erro ao carregar permissões para a filial $activeSecondaryCompanyId: $e");
      _userPermissions = UserPermissions.defaultPermissions();
    } finally {
      notifyListeners();
    }
  }

  // O método hasAccess agora verifica as permissões da filial carregada.
  bool hasAccess(List<String> path) {
    return _userPermissions.hasAccess(path);
  }

  // Os métodos de atualização e salvamento foram removidos daqui,
  // pois a edição será feita diretamente na UserPermissionPage.
}