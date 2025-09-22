// lib/login_page.dart (Versão Final e Limpa)
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/log_services.dart';
import 'package:flutter_application_1/services/notification_service.dart';
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
    // 1. Chama a função de login no provider
    await Provider.of<AuthProvider>(context, listen: false).login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    // 2. Após o login, buscamos o estado mais atual do provider
    //    A esta altura, o notifyListeners() já foi chamado
    final authState = Provider.of<AuthProvider>(context, listen: false);
    final mainCompanyId = authState.mainCompanyId;
    final allowedCompanies = authState.allowedSecondaryCompanies;

    final token = authState.token; 

    if (!mounted) return;

    // 3. Verificação de segurança CRUCIAL antes de navegar
    if (mainCompanyId == null || mainCompanyId.isEmpty || token == null || token.isEmpty) { // Validação mais robusta
      throw Exception('Dados de login inválidos recebidos do servidor.');
    }

    NotificationService().connect();
    
    // 4. Lógica de navegação
    if (allowedCompanies.isEmpty) {
       throw Exception('Este usuário não tem empresas secundárias associadas.');
    }

    // Usamos o Navigator.of(context) para garantir o contexto correto
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) {
          if (allowedCompanies.length == 1) {
            return TelaPrincipal(
              mainCompanyId: mainCompanyId,
              secondaryCompanyId: allowedCompanies.first,
            );
          } else {
            // ▼▼▼ PASSE O TOKEN AQUI ▼▼▼
            return SecondaryCompanySelectionPage(
              mainCompanyId: mainCompanyId,
              token: token, // Passando o token explicitamente
            );
          }
        },
      ),
    );

  } catch (e) {
    setState(() {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    });
  } finally {
    // Garante que o loading pare, não importa o que aconteça
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
    // ▼▼▼ CAPTURA O TEMA ATIVO AQUI ▼▼▼
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inputTheme = theme.inputDecorationTheme;

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
                height: 45, // Um pouco mais de altura para melhor visualização
                child: TextField(
                  onSubmitted: (_) => _signIn(),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: colorScheme.onSurface), // Cor do texto digitado
                  decoration: InputDecoration(
                    labelText: 'USUÁRIO (E-MAIL)',
                    labelStyle: inputTheme.labelStyle,
                    border: inputTheme.border,
                    enabledBorder: inputTheme.enabledBorder,
                    focusedBorder: inputTheme.focusedBorder,
                    filled: true,
                    // Usa a cor de fundo do tema
                    fillColor: inputTheme.fillColor, 
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 300,
                height: 45,
                child: TextField(
                  onSubmitted: (_) => _signIn(),
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: colorScheme.onSurface), // Cor do texto digitado
                  decoration: InputDecoration(
                    labelText: 'SENHA',
                    labelStyle: inputTheme.labelStyle,
                    border: inputTheme.border,
                    enabledBorder: inputTheme.enabledBorder,
                    focusedBorder: inputTheme.focusedBorder,
                    filled: true,
                    fillColor: inputTheme.fillColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: colorScheme.onSurface.withOpacity(0.6), // Cor do ícone
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
                    // Usa a cor de erro do tema
                    style: TextStyle(color: colorScheme.error, fontSize: 14), 
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
                          // Usa as cores do tema para o botão
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          side: BorderSide(color: colorScheme.primary)
                        ),
                        child: Text('ENTRAR', style: TextStyle(color: colorScheme.onPrimary)),
                      ),
              ),
              TextButton(
                onPressed: _showAlert,
                child: Text('Esqueceu sua senha?', style: TextStyle(color: colorScheme.onSurface)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}