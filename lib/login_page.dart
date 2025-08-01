import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/menu.dart';
import 'package:flutter_application_1/secondary_company_selection_page.dart';
import 'package:flutter_application_1/services/log_services.dart';
import 'package:provider/provider.dart'; // Importe o Provider
import 'package:flutter_application_1/providers/permission_provider.dart'; // Importe o PermissionProvider

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
    String? mainCompanyIdForLog; // Variável para guardar o ID para o log de erro
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
          mainCompanyIdForLog = userDoc['mainCompanyId'];
          String? mainCompanyId = userDoc['mainCompanyId'];
          List<dynamic>? allowedSecondaryCompaniesRaw = userDoc['allowedSecondaryCompanies'];
          // String? userRole = userDoc['role']; // Este campo não será mais usado diretamente para permissões

          List<String> allowedSecondaryCompanies = allowedSecondaryCompaniesRaw?.map((item) => item.toString()).toList() ?? [];

          // NOVO: Carregar as permissões do usuário (sem activeSecondaryCompanyId)
          final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
          if (mainCompanyId != null && mainCompanyId.isNotEmpty) {
            await LogService.addLog(
            action: LogAction.LOGIN,
            mainCompanyId: mainCompanyId,
            details: 'Usuário ${user.email} realizou login com sucesso.',
            // secondaryCompanyId pode ser adicionado após a seleção da filial
          );
      if (allowedSecondaryCompanies.isNotEmpty) {
        if (allowedSecondaryCompanies.length == 1) {
          final activeCompanyId = allowedSecondaryCompanies.first;
          // AGORA: Carrega as permissões para a única filial permitida
          await permissionProvider.loadUserPermissions(userId, activeCompanyId);

          Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TelaPrincipal(
                      mainCompanyId: mainCompanyId,
                      secondaryCompanyId: allowedSecondaryCompanies.first, // Usa a única empresa
                    ),
                  ),
                );
              } else {
                // Navega para a tela de seleção, as permissões serão carregadas lá
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SecondaryCompanySelectionPage(
                mainCompanyId: mainCompanyId,
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
      await LogService.addLog(
        action: LogAction.ERROR,
        // Se já tivermos o ID da empresa, usamos. Senão, pode ser nulo.
        mainCompanyId: mainCompanyIdForLog,
        details: 'FALHA na tentativa de login para o email ${_emailController.text}. Erro: ${e.message}',
      );
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
        await LogService.addLog(
        action: LogAction.ERROR,
        mainCompanyId: mainCompanyIdForLog,
        details: 'FALHA inesperada no login para o email ${_emailController.text}. Erro: ${e.toString()}',
      );
      setState(() {
        _errorMessage = 'Ocorreu um erro inesperado. Tente novamente.';
      });
      print('Erro geral: $e');
    }
  }

  Future<bool> _showAlert() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Esqueceu sua senha?'),
          content: Text('Entre em contato com o gerenciador do sistema por meio dos números na parte inferior da pagina'),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop(true); // Retorna true (quer excluir)
              },
            ),
          ],
        );
      },
    ) ?? false; // Retorna false se o diálogo for fechado de outra forma
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
                  onSubmitted: (_) => _signIn(),
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
                  onSubmitted: (_) => _signIn(),
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
                  _showAlert();
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