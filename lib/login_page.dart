import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importe o Firestore
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/menu.dart'; // Sua TelaPrincipal
import 'package:flutter_application_1/secondary_company_selection_page.dart'; // Importe a nova página

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _errorMessage = null;
    });
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null && mounted) {
        String userId = user.uid;

        // 1. Buscar informações do usuário no Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          String? mainCompanyId = userDoc['mainCompanyId'];
          List<dynamic>? allowedSecondaryCompaniesRaw = userDoc['allowedSecondaryCompanies'];
          String? userRole = userDoc['role'];

          // Converter List<dynamic> para List<String> de forma segura
          List<String> allowedSecondaryCompanies = allowedSecondaryCompaniesRaw?.map((item) => item.toString()).toList() ?? [];

          if (mainCompanyId != null && mainCompanyId.isNotEmpty) {
            if (allowedSecondaryCompanies.isNotEmpty) {
              if (allowedSecondaryCompanies.length == 1) {
                // Se houver apenas UMA empresa secundária permitida, navega direto para a TelaPrincipal
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TelaPrincipal(
                      mainCompanyId: mainCompanyId,
                      secondaryCompanyId: allowedSecondaryCompanies.first, // Usa a única empresa
                      userRole: userRole,
                    ),
                  ),
                );
              } else {
                // Se houver MÚLTIPLAS empresas secundárias, navega para a tela de seleção
                Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => SecondaryCompanySelectionPage(
      mainCompanyId: mainCompanyId,
      // allowedSecondaryCompanies: allowedSecondaryCompanies, // Esta linha agora é opcional, mas pode permanecer se não causar erro
      userRole: userRole,
    ),
  ),
);
              }
            } else {
              // Caso o allowedSecondaryCompanies seja nulo ou vazio
              setState(() {
                _errorMessage = 'Este usuário não tem empresas secundárias associadas. Contate o suporte.';
              });
              await FirebaseAuth.instance.signOut(); // Desloga o usuário
            }
          } else {
            // Caso mainCompanyId não esteja definido no perfil do usuário
            setState(() {
              _errorMessage = 'Usuário não associado a nenhuma empresa principal. Contate o suporte.';
            });
            await FirebaseAuth.instance.signOut(); // Desloga o usuário
          }
        } else {
          setState(() {
            _errorMessage = 'Dados do perfil do usuário não encontrados. Contate o suporte.';
          });
          await FirebaseAuth.instance.signOut(); // Desloga o usuário
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'Nenhum usuário encontrado para esse e-mail.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Senha incorreta.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'O formato do e-mail é inválido.';
        } else if (e.code == 'user-disabled') {
          _errorMessage = 'Esta conta de usuário foi desativada.';
        } else {
          _errorMessage = 'Erro de login: ${e.message}';
        }
      });
      print('Erro Firebase Auth: ${e.code} - ${e.message}');
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocorreu um erro inesperado. Tente novamente.';
      });
      print('Erro geral: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Image.asset(
                  'assets/images/logo16.png',
                  width: 330,
                  height: 330,
                ),
              ),
              SizedBox(
                width: 300,
                height: 35,
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'USUÁRIO (E-MAIL)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 300,
                height: 35,
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'SENHA',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 30),
              SizedBox(
                width: 200,
                height: 40,
                child: OutlinedButton(
                  onPressed: _signIn,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text('ENTRAR', style: TextStyle(color: Colors.black)),
                ),
              ),
              TextButton(
                onPressed: () {
                  print('Esqueceu sua senha? clicado');
                },
                child: const Text(
                  'Esqueceu sua senha?',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}