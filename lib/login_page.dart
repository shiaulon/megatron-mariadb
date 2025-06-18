import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importe o Firebase Auth
import 'reutilizaveis/tela_base.dart'; // importa o widget base
import 'menu.dart'; // Certifique-se de que TelaPrincipal está importada

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage; // Para exibir mensagens de erro ao usuário

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Função para lidar com o login
  Future<void> _signIn() async {
    setState(() {
      _errorMessage = null; // Limpa a mensagem de erro anterior
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Se o login for bem-sucedido, navega para a TelaPrincipal
      if (mounted) { // Verifica se o widget ainda está montado
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TelaPrincipal()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Trata erros de autenticação do Firebase
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'Nenhum usuário encontrado para esse e-mail.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Senha incorreta para esse e-mail.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'O formato do e-mail é inválido.';
        } else if (e.code == 'user-disabled') {
          _errorMessage = 'Este usuário foi desativado.';
        }
        else {
          _errorMessage = 'Erro de login: ${e.message}';
        }
      });
      print('Erro Firebase Auth: ${e.code} - ${e.message}');
    } catch (e) {
      // Trata outros erros gerais
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
              // Logo
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Image.asset(
                  'assets/images/logo16.png',
                  width: 330,
                  height: 330,
                ),
              ),

              // Campo Usuário (E-mail)
              SizedBox(
                width: 300,
                height: 35,
                child: TextField(
                  controller: _emailController, // Associa o controller
                  keyboardType: TextInputType.emailAddress, // Teclado otimizado para e-mail
                  decoration: InputDecoration(
                    labelText: 'USUÁRIO (E-MAIL)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Campo Senha
              SizedBox(
                width: 300,
                height: 35,
                child: TextField(
                  controller: _passwordController, // Associa o controller
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

              // Mensagem de erro (se houver)
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 30), // Ajusta espaçamento após a mensagem de erro

              // Botão Entrar
              SizedBox(
                width: 200,
                height: 40,
                child: OutlinedButton(
                  onPressed: _signIn, // Chama a função _signIn
                  child: const Text('ENTRAR', style: TextStyle(color: Colors.black)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              // Esqueceu senha
              TextButton(
                onPressed: () {
                  // Ação para "Esqueceu sua senha?"
                  print('Esqueceu sua senha? clicado');
                  // Você pode navegar para uma tela de recuperação de senha aqui
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