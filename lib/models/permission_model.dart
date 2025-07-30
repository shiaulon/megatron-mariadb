// lib/models/permission_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserPermissions {
  final Map<String, dynamic> acessos;

  UserPermissions({required this.acessos});

  // AGORA: O 'data' recebido é o próprio mapa de acessos do documento da filial.
  factory UserPermissions.fromMap(Map<String, dynamic> data) {
    return UserPermissions(
      acessos: Map<String, dynamic>.from(data['acessos'] ?? {}),
    );
  }

  // AGORA: O mapa retornado será salvo diretamente no documento da filial.
  Map<String, dynamic> toMap() {
    return {
      'acessos': acessos,
      'lastUpdated': FieldValue.serverTimestamp(),
      'updatedBy': FirebaseAuth.instance.currentUser?.email ?? 'admin',
    };
  }

  // Método para obter o valor de uma permissão aninhada (permanece igual)
  bool hasAccess(List<String> path) {
    Map<String, dynamic> current = acessos;
    for (int i = 0; i < path.length; i++) {
      final key = path[i];
      if (!current.containsKey(key)) {
        return false;
      }
      if (i == path.length - 1) {
        return current[key] == true;
      } else {
        if (current[key] is! Map<String, dynamic>) {
          return false;
        }
        current = current[key] as Map<String, dynamic>;
      }
    }
    return false;
  }

  // Permissões padrão para uma NOVA filial
  static UserPermissions defaultPermissions() {
    return UserPermissions(
      acessos: {
        "registro_geral": {
          "acesso": true,
          "tabelas": {
            "acesso": true,
            "controle": true, "pais": true, "estado": true, "estado_x_imposto": true,
            "cidade": true, "natureza": true, "situacao": true, "cargo": true,
            "tipo_telefone": true, "tipo_historico": true, "tipo_bem_credito": true,
            "condicao_pagamento": true, "ibge_x_cidade": true, "como_nos_conheceu": true,
            "atividade_empresa": true, "tabela_cest": true, "manut_tab_governo_ncm_imposto": true,
            "fazenda": true, "natureza_rendimento": true
          },
          "registro_geral_manut": {"acesso": true, "manut_rg": true}
        },
        "credito": {
          "acesso": true,
          "tabelas": { // Adicione este sub-mapa
            "documentos_basicos": true
          }
        },
        "relatorio": {"acesso": true},
        "relatorio_de_critica": {"acesso": true},
        "etiqueta": {"acesso": true},
        "contatos_geral": {"acesso": true},
        "portaria": {"acesso": true},
        "qualificacao_rg": {"acesso": true},
        "area_rg": {"acesso": true},
        "tabela_preco_x_rg": {"acesso": true},
        "modulo_especial": {"acesso": true},
        "crm": {"acesso": true},
        "follow_up": {"acesso": true},
        "administracao_usuarios": {"acesso": true}
      },
    );
  }
}