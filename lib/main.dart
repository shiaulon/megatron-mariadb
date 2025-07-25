import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/firebase_options.dart'; // Mantenha este import
import 'package:flutter_application_1/firestore_initializer.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaCest.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaNatureza.dart';
import 'package:flutter_application_1/registroGeral/manut_rg.dart';
import 'package:flutter_application_1/submenus.dart';
import 'login_page.dart';
import 'menu.dart'; // Certifique-se de que TelaPrincipal está importada
import 'package:flutter_application_1/models/permission_model.dart';
import 'package:flutter_application_1/providers/permission_provider.dart';
import 'package:provider/provider.dart'; // Importe o Provider


void main() async {
  // Garante que os widgets do Flutter estejam inicializados antes de qualquer coisa
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Inicializa o Firebase APENAS UMA VEZ aqui
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //await FirestoreInitializer().initializeFirestoreData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PermissionProvider()),
        // ... outros providers
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget { // <--- Voltou a ser StatelessWidget
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    /*const String mainCompanyId = 'ID_EMPRESA_PRINCIPAL_TESTE';
    const String secondaryCompanyId = 'ID_EMPRESA_SECUNDARIA_TESTE';
    const String userRole = 'admin'; // ou 'user', etc.*/
    // Agora que o Firebase já foi inicializado no main(),
    // podemos ir direto para o MaterialApp.
    return MaterialApp(
      title: 'Megatron Login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      //home: const PaginaComAbasLaterais(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId, userRole: userRole), // Inicia na LoginPage
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}