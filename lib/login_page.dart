// lib/login_page.dart (Versão Final e Limpa)
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/log_services.dart';
import 'package:provider/provider.dart';

import 'reutilizaveis/tela_base.dart';
import 'secondary_company_selection_page.dart';
import 'providers/auth_provider.dart';
import 'menu.dart'; // TelaPrincipal

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
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      final mainCompanyId = authProvider.mainCompanyId;
      final allowedCompanies = authProvider.allowedSecondaryCompanies;

     


      if (allowedCompanies.isNotEmpty) {
        if (allowedCompanies.length == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TelaPrincipal(
                mainCompanyId: mainCompanyId!,
                secondaryCompanyId: allowedCompanies.first,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SecondaryCompanySelectionPage(
                mainCompanyId: mainCompanyId!,
              ),
            ),
          );
        }
      } else {
        throw Exception('Este usuário não tem empresas secundárias associadas.');
      }

    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _showAlert() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Esqueceu sua senha?'),
          content: const Text('Entre em contato com o gerenciador do sistema por meio dos números na parte inferior da pagina'),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
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
                child: Image.asset('assets/images/logo16.png', width: 330, height: 330),
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
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : OutlinedButton(
                        onPressed: _signIn,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text('ENTRAR', style: TextStyle(color: Colors.black)),
                      ),
              ),
              TextButton(
                onPressed: _showAlert,
                child: const Text('Esqueceu sua senha?', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}