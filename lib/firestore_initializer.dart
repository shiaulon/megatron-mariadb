import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Apenas se for usar FirebaseAuth.instance.currentUser.uid diretamente

class FirestoreInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Função para popular dados iniciais do ERP
  Future<void> initializeFirestoreData() async {
    print("Iniciando a população dos dados do Firestore...");

    try {
      // --- Dados dos Usuários ---
      // IMPORTANTE: Substitua os UIDs pelos UIDs reais dos usuários criados no Firebase Authentication
      final String adminUid = "iCuKVlMRKzPTwnxAddUj5Sfvirj2"; // Ex: 'abcde12345...'
      final String gerenteUid = "1hLeO6MRfgQ9rYDRGE8bJteIgtq2"; // Ex: 'fghij67890...'
      final String funcionarioUid = "pVe6aOf9PshvrfW6zxCZlluu9Nf1"; // Ex: 'klmno11223...'

      // Adicionar/Atualizar documentos na coleção 'users'
      await _firestore.collection('users').doc(adminUid).set({
        'email': 'admin@empresa1.com',
        'mainCompanyId': 'EmpresaA_ID',
        'allowedSecondaryCompanies': ['FilialA1_ID', 'FilialA2_ID'],
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Use merge para não sobrescrever tudo se já existir

      await _firestore.collection('users').doc(gerenteUid).set({
        'email': 'gerente@empresa1.com',
        'mainCompanyId': 'EmpresaA_ID',
        'allowedSecondaryCompanies': ['FilialA1_ID'],
        'role': 'gerente',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore.collection('users').doc(funcionarioUid).set({
        'email': 'funcionario@empresa2.com',
        'mainCompanyId': 'EmpresaB_ID',
        'allowedSecondaryCompanies': ['FilialB1_ID'],
        'role': 'funcionario',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("Dados de usuários populados com sucesso.");

      // --- Dados das Empresas Principais e Secundárias ---

      // Empresa Principal Alpha (EmpresaA_ID)
      await _firestore.collection('companies').doc('EmpresaA_ID').set({
        'name': 'Empresa Principal Alpha',
        'cnpj': '11.111.111/0001-11',
        'address': 'Rua Alpha, 123',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Filial Alpha Unidade 1 (FilialA1_ID)
      await _firestore.collection('companies').doc('EmpresaA_ID')
          .collection('secondaryCompanies').doc('FilialA1_ID').set({
        'name': 'Filial Alpha Unidade 1',
        'cnpj': '11.111.111/0002-11',
        'address': 'Avenida Beta, 456',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Dados de exemplo para FilialA1_ID/data/naturezas
      await _firestore.collection('companies').doc('EmpresaA_ID')
          .collection('secondaryCompanies').doc('FilialA1_ID')
          .collection('data').doc('naturezas').collection('items').doc('01').set({
        'descricao': 'Natureza 01 da Filial A1 - Exemplo',
        'caracteristicas': [
          {'nome': 'País A1.1', 'sequencias': ['Cidade A1.1.1', 'Cidade A1.1.2']},
          {'nome': 'País A1.2', 'sequencias': ['Cidade A1.2.1']},
        ],
        'ultima_atualizacao': FieldValue.serverTimestamp(),
        'criado_por': 'admin@empresa1.com',
      }, SetOptions(merge: true));

      // Filial Alpha Unidade 2 (FilialA2_ID)
      await _firestore.collection('companies').doc('EmpresaA_ID')
          .collection('secondaryCompanies').doc('FilialA2_ID').set({
        'name': 'Filial Alpha Unidade 2',
        'cnpj': '11.111.111/0003-11',
        'address': 'Praça Gama, 789',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Dados de exemplo para FilialA2_ID/data/naturezas
      await _firestore.collection('companies').doc('EmpresaA_ID')
          .collection('secondaryCompanies').doc('FilialA2_ID')
          .collection('data').doc('naturezas').collection('items').doc('01').set({
        'descricao': 'Natureza 01 da Filial A2 - Dados Diferentes',
        'caracteristicas': [
          {'nome': 'País A2.1', 'sequencias': ['Cidade A2.1.1']},
        ],
        'ultima_atualizacao': FieldValue.serverTimestamp(),
        'criado_por': 'admin@empresa1.com',
      }, SetOptions(merge: true));


      // Empresa Principal Beta (EmpresaB_ID)
      await _firestore.collection('companies').doc('EmpresaB_ID').set({
        'name': 'Empresa Principal Beta',
        'cnpj': '22.222.222/0001-22',
        'address': 'Rua Beta, 321',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Filial Beta Única (FilialB1_ID)
      await _firestore.collection('companies').doc('EmpresaB_ID')
          .collection('secondaryCompanies').doc('FilialB1_ID').set({
        'name': 'Filial Beta Única',
        'cnpj': '22.222.222/0002-22',
        'address': 'Alameda Delta, 654',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Dados de exemplo para FilialB1_ID/data/naturezas
      await _firestore.collection('companies').doc('EmpresaB_ID')
          .collection('secondaryCompanies').doc('FilialB1_ID')
          .collection('data').doc('naturezas').collection('items').doc('01').set({
        'descricao': 'Natureza 01 da Filial B1 - Dados Exclusivos',
        'caracteristicas': [
          {'nome': 'País B1.1', 'sequencias': ['Cidade B1.1.1', 'Cidade B1.1.2', 'Cidade B1.1.3']},
        ],
        'ultima_atualizacao': FieldValue.serverTimestamp(),
        'criado_por': 'funcionario@empresa2.com',
      }, SetOptions(merge: true));

      print("Dados de empresas e filiais populados com sucesso.");
      print("A estrutura do Firestore foi criada/atualizada.");

    } catch (e) {
      print("Erro ao popular dados do Firestore: $e");
    }
  }
}