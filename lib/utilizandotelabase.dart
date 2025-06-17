import 'package:flutter/material.dart';
import 'reutilizaveis/tela_base.dart'; // importa o widget base

class LoginPage2 extends StatefulWidget {
  const LoginPage2({super.key});

  @override
  State<LoginPage2> createState() => _LoginPage2State();
}

class _LoginPage2State extends State<LoginPage2> {
  bool _obscurePassword = true;

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

              // Campo Usuário
              SizedBox(
                width: 300,
                height: 35,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'USUÁRIO',
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
              const SizedBox(height: 40),

              // Botão Entrar
              SizedBox(
                width: 200,
                height: 40,
                child: OutlinedButton(
                  onPressed: () {},
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
                onPressed: () {},
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
