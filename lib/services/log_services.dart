// lib/services/log_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Enum ATUALIZADO com as novas ações
enum LogAction {
  CREATE,
  UPDATE,
  DELETE,
  LOGIN,
  LOGOUT,
  VIEW,
  GENERATE_REPORT,
  PERMISSION_CHANGE, // <-- NOVO
  ERROR,             // <-- NOVO
}

class LogService {
  static Future<void> addLog({
    required LogAction action,
    String? mainCompanyId, // <-- Torne opcional para logs de erro/login
    String? secondaryCompanyId,
    String? targetCollection,
    String? targetDocId,
    required String details,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    // Permite logs mesmo sem usuário (ex: falha de login)
    final userEmail = user?.email ?? "Usuário Desconhecido";
    final userId = user?.uid ?? "N/A";

    // Se não houver mainCompanyId, não podemos salvar o log na estrutura atual.
    // Em um sistema maior, poderia haver uma coleção de logs "global".
    if (mainCompanyId == null || mainCompanyId.isEmpty) {
      print('Log não salvo: mainCompanyId não fornecido.');
      return;
    }

    try {
      final logCollection = FirebaseFirestore.instance
          .collection('companies')
          .doc(mainCompanyId)
          .collection('logs');

      await logCollection.add({
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
        'userEmail': userEmail,
        'secondaryCompanyId': secondaryCompanyId ?? '',
        'action': action.name,
        'targetCollection': targetCollection ?? '',
        'targetDocId': targetDocId ?? '',
        'details': details,
      });
    } catch (e) {
      print('### Erro CRÍTICO ao salvar log: $e ###');
    }
  }
}