import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Seus imports existentes
import 'package:flutter_application_1/providers/permission_provider.dart';
import 'login_page.dart';

// NOVO: Importe o AuthProvider que criamos
import 'package:flutter_application_1/providers/auth_provider.dart';

// REMOVIDO: Os imports do Firebase não são mais necessários aqui
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_application_1/firebase_options.dart';


void main() async {
  // Garante que os widgets do Flutter estejam inicializados
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // REMOVIDO: A inicialização do Firebase não é mais necessária para o fluxo de login
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(
    MultiProvider(
      providers: [
        // ADICIONADO: O AuthProvider agora está disponível para todo o app
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // MANTIDO: O PermissionProvider continua aqui para as outras partes do seu app
        ChangeNotifierProvider(create: (_) => PermissionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Megatron Login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(), // A tela inicial continua sendo a de Login
      debugShowCheckedModeBanner: false,
    );
  }
}