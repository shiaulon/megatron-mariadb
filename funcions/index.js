const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Cloud Function para criar um novo usuário e seus documentos de permissão.
 */
exports.createNewUser = functions.region("southamerica-east1").https.onCall(async (data, context) => {
  // 1. Verificação de Segurança: Garante que quem chama é um usuário autenticado.
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "A requisição deve ser feita por um usuário autenticado.",
    );
  }

  // 2. Verificação de Permissão: Garante que quem chama é um administrador.
  const adminUid = context.auth.uid;
  const adminDoc = await admin.firestore().collection("users").doc(adminUid).get();
  if (!adminDoc.exists || adminDoc.data().isAdmin !== true) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Apenas administradores podem criar novos usuários.",
    );
  }

  const {
    email,
    password,
    displayName,
    mainCompanyId,
    allowedSecondaryCompanies,
    adminEmail,
  } = data;

  try {
    // 3. Criar o usuário no Firebase Authentication
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: displayName,
    });

    const newUserUid = userRecord.uid;

    // 4. Criar o documento do usuário no Firestore
    const userDocRef = admin.firestore().collection("users").doc(newUserUid);
    await userDocRef.set({
      email: email,
      displayName: displayName,
      mainCompanyId: mainCompanyId,
      allowedSecondaryCompanies: allowedSecondaryCompanies,
      isAdmin: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: adminEmail,
    });

    // 5. Criar os documentos de permissão para cada filial
    const batch = admin.firestore().batch();
    const defaultPermissions = {
      "registro_geral": {
        "acesso": true,
        "tabelas": {"acesso": true, "controle": true, "pais": true, "estado": true, "estado_x_imposto": true, "cidade": true, "natureza": true, "situacao": true, "cargo": true, "tipo_telefone": true, "tipo_historico": true, "tipo_bem_credito": true, "condicao_pagamento": true, "ibge_x_cidade": true, "como_nos_conheceu": true, "atividade_empresa": true, "tabela_cest": true, "manut_tab_governo_ncm_imposto": true, "fazenda": true, "natureza_rendimento": true},
        "registro_geral_manut": {"acesso": true, "manut_rg": true},
      },
      "credito": {"acesso": true},
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
      "administracao_usuarios": {"acesso": true},
    };

    allowedSecondaryCompanies.forEach((filialId) => {
      const permDocRef = userDocRef.collection("permissions").doc(filialId);
      batch.set(permDocRef, {
        acessos: defaultPermissions,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        updatedBy: adminEmail,
      });
    });

    await batch.commit();

    return {result: `Usuário ${displayName} criado com sucesso.`};
  } catch (error) {
    console.error("Erro ao criar usuário:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Ocorreu um erro ao criar o usuário.",
      error.message,
    );
  }
});

// -----------------------------------------------------------------
// NOVA FUNÇÃO PARA EXCLUIR UM USUÁRIO COMPLETAMENTE
// -----------------------------------------------------------------
exports.deleteUser = functions.region("southamerica-east1").https.onCall(async (data, context) => {
  // Verificação de segurança: Apenas admins podem chamar esta função
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "A requisição deve ser feita por um usuário autenticado.");
  }
  const adminDoc = await admin.firestore().collection("users").doc(context.auth.uid).get();
  if (!adminDoc.exists || adminDoc.data().isAdmin !== true) {
    throw new functions.https.HttpsError("permission-denied", "Apenas administradores podem excluir usuários.");
  }

  const { userIdToDelete, userEmailToDelete } = data;

  if (!userIdToDelete) {
     throw new functions.https.HttpsError("invalid-argument", "O ID do usuário a ser excluído é obrigatório.");
  }

  try {
    // 1. Excluir do Firebase Authentication
    await admin.auth().deleteUser(userIdToDelete);

    const userDocRef = admin.firestore().collection("users").doc(userIdToDelete);
    const permissionsCollectionRef = userDocRef.collection("permissions");

    // 2. Excluir a subcoleção de permissões (em batch)
    const permissionsSnapshot = await permissionsCollectionRef.get();
    const batch = admin.firestore().batch();
    permissionsSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();
    
    // 3. Excluir o documento principal do usuário
    await userDocRef.delete();

    // 4. Registrar a ação no log (OS LOGS SÃO MANTIDOS)
    const logData = {
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      userId: context.auth.uid,
      userEmail: adminDoc.data().email,
      secondaryCompanyId: adminDoc.data().allowedSecondaryCompanies[0] || "", // Filial do admin
      action: "DELETE",
      targetCollection: "users",
      targetDocId: userIdToDelete,
      details: `Admin ${adminDoc.data().email} excluiu o usuário ${userEmailToDelete} (ID: ${userIdToDelete}).`,
    };
    await admin.firestore().collection("companies").doc(adminDoc.data().mainCompanyId).collection("logs").add(logData);

    return { result: `Usuário ${userEmailToDelete} excluído com sucesso.` };

  } catch (error) {
    console.error("Erro ao excluir usuário:", error);
    throw new functions.https.HttpsError("internal", "Ocorreu um erro ao excluir o usuário.", error.message);
  }
});


// -----------------------------------------------------------------
// NOVA FUNÇÃO PARA DUPLICAR UM USUÁRIO
// -----------------------------------------------------------------
exports.duplicateUser = functions.region("southamerica-east1").https.onCall(async (data, context) => {
  // Verificação de segurança: Apenas admins
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "A requisição deve ser feita por um usuário autenticado.");
  }
  const adminDoc = await admin.firestore().collection("users").doc(context.auth.uid).get();
  if (!adminDoc.exists || adminDoc.data().isAdmin !== true) {
    throw new functions.https.HttpsError("permission-denied", "Apenas administradores podem duplicar usuários.");
  }

  const { originalUserId, newEmail, newDisplayName } = data;
  if (!originalUserId || !newEmail || !newDisplayName) {
    throw new functions.https.HttpsError("invalid-argument", "Dados insuficientes para duplicar o usuário.");
  }

  try {
    // 1. Buscar dados do usuário original
    const originalUserDocRef = admin.firestore().collection("users").doc(originalUserId);
    const originalUserDoc = await originalUserDocRef.get();
    if (!originalUserDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Usuário original não encontrado.");
    }
    const originalUserData = originalUserDoc.data();

    // 2. Criar o novo usuário no Authentication com uma senha aleatória
    // O novo usuário precisará usar o fluxo "Esqueci minha senha" para definir uma nova.
    const newUserRecord = await admin.auth().createUser({
      email: newEmail,
      displayName: newDisplayName,
      password: "temporaryPassword" + Date.now(), // Senha temporária
    });

    // 3. Criar o novo documento do usuário no Firestore
    const newUserDocRef = admin.firestore().collection("users").doc(newUserRecord.uid);
    await newUserDocRef.set({
      ...originalUserData, // Copia todos os dados antigos...
      email: newEmail, // ...e sobrescreve com os novos
      displayName: newDisplayName,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: adminDoc.data().email,
    });

    // 4. Copiar todas as permissões do usuário original para o novo
    const batch = admin.firestore().batch();
    const permissionsSnapshot = await originalUserDocRef.collection("permissions").get();
    permissionsSnapshot.docs.forEach((doc) => {
      const newPermissionRef = newUserDocRef.collection("permissions").doc(doc.id);
      batch.set(newPermissionRef, doc.data());
    });
    await batch.commit();

    // 5. Registrar a ação no log
    const logData = {
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      userId: context.auth.uid,
      userEmail: adminDoc.data().email,
      action: "CREATE",
      targetCollection: "users",
      targetDocId: newUserRecord.uid,
      details: `Admin ${adminDoc.data().email} duplicou o usuário ${originalUserData.email} como ${newEmail}.`,
    };
    await admin.firestore().collection("companies").doc(adminDoc.data().mainCompanyId).collection("logs").add(logData);

    return { result: `Usuário ${newDisplayName} criado com sucesso a partir de um modelo. O usuário deve usar a opção 'Esqueci minha senha' para definir uma nova senha.` };
    
  } catch (error) {
    console.error("Erro ao duplicar usuário:", error);
    throw new functions.https.HttpsError("internal", "Ocorreu um erro ao duplicar o usuário.", error.message);
  }
});