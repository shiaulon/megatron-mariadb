import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/firebase_options.dart'; // Mantenha este import
import 'package:flutter_application_1/firestore_initializer.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaCest.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaNatureza.dart';
import 'package:flutter_application_1/submenus.dart';
import 'login_page.dart';
import 'menu.dart'; // Certifique-se de que TelaPrincipal está importada

void main() async {
  // Garante que os widgets do Flutter estejam inicializados antes de qualquer coisa
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Inicializa o Firebase APENAS UMA VEZ aqui
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //await FirestoreInitializer().initializeFirestoreData();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget { // <--- Voltou a ser StatelessWidget
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    //const String mainCompanyId = 'ID_EMPRESA_PRINCIPAL_TESTE';
    //const String secondaryCompanyId = 'ID_EMPRESA_SECUNDARIA_TESTE';
    //const String userRole = 'admin'; // ou 'user', etc.
    // Agora que o Firebase já foi inicializado no main(),
    // podemos ir direto para o MaterialApp.
    return MaterialApp(
      title: 'Megatron Login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      //home: const TabelaCest(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId, userRole: userRole), // Inicia na LoginPage
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}