// lib/pages/admin/user_registration_page.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/models/permission_model.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:intl/intl.dart';

class UserRegistrationPage extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;

  const UserRegistrationPage({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
  });

  @override
  State<UserRegistrationPage> createState() => _UserRegistrationPageState();
}

class _UserRegistrationPageState extends State<UserRegistrationPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _allowedSecondaryCompaniesController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  late String _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _allowedSecondaryCompaniesController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // As validações iniciais permanecem as mesmas
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'As senhas não coincidem.';
        _isLoading = false;
      });
      return;
    }

    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _displayNameController.text.isEmpty ||
        _allowedSecondaryCompaniesController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Todos os campos são obrigatórios.';
        _isLoading = false;
      });
      return;
    }

    // A mágica acontece aqui dentro do try-catch
    FirebaseApp? tempApp; // Variável para nosso app temporário
    try {
      // 1. Inicializa um app Firebase secundário com um nome único
      tempApp = await Firebase.initializeApp(
        name: 'userCreationTemp-${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      // 2. Cria o usuário usando a instância de autenticação DESTE app temporário
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? newUser = userCredential.user;

      if (newUser != null) {
        // A sessão do seu app principal AINDA É A DO ADMIN.
        // Agora podemos escrever no Firestore com as permissões corretas.
        
        await newUser.updateDisplayName(_displayNameController.text.trim());

        List<String> allowedSecondaryCompanies = _allowedSecondaryCompaniesController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        if (allowedSecondaryCompanies.isEmpty) {
          throw Exception('É necessário informar pelo menos uma filial.');
        }

        // 3. Escreve no Firestore usando a instância PADRÃO (do admin)
        await FirebaseFirestore.instance.collection('users').doc(newUser.uid).set({
          'email': newUser.email,
          'displayName': _displayNameController.text.trim(),
          'mainCompanyId': widget.mainCompanyId,
          'allowedSecondaryCompanies': allowedSecondaryCompanies,
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': FirebaseAuth.instance.currentUser?.email ?? 'admin_desconhecido',
        });

        UserPermissions defaultUserPermissions = UserPermissions.defaultPermissions();
        WriteBatch batch = FirebaseFirestore.instance.batch();

        for (String filialId in allowedSecondaryCompanies) {
          DocumentReference permissionDocRef = FirebaseFirestore.instance
              .collection('users')
              .doc(newUser.uid)
              .collection('permissions')
              .doc(filialId);

          batch.set(permissionDocRef, defaultUserPermissions.toMap());
        }

        await batch.commit();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuário ${_displayNameController.text.trim()} registrado com sucesso!')),
        );
        _clearFields();
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Erro ao registrar usuário: ';
      if (e.code == 'weak-password') {
        msg += 'A senha é muito fraca.';
      } else if (e.code == 'email-already-in-use') {
        msg += 'Este e-mail já está em uso.';
      } else if (e.code == 'invalid-email') {
        msg += 'O formato do e-mail é inválido.';
      } else {
        msg += e.message ?? 'Erro desconhecido.';
      }
      setState(() {
        _errorMessage = msg;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocorreu um erro inesperado: ${e.toString()}';
      });
    } finally {
      // 4. Garante que o app temporário seja deletado, não importa o que aconteça
      if (tempApp != null) {
        await tempApp.delete();
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearFields() {
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _displayNameController.clear();
    _allowedSecondaryCompaniesController.clear();
    _errorMessage = null;
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: Column(
        children: [
          TopAppBar(
            onBackPressed: () {
              Navigator.pop(context);
            },
            currentDate: _currentDate,
          ),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Registrar Novo Usuário',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.white),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomInputField(
                      controller: _displayNameController,
                      keyboardType: TextInputType.text,
                      label: "Nome de Exibição",
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                    ),
                    
                    const SizedBox(height: 10),
                    CustomInputField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      label: "E-mail",
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                    ),
                    
                    const SizedBox(height: 10),
                    CustomInputField(
                      controller: _passwordController,
                      label: "Senha (mínimo 6 caracteres)",     
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                    ),
                    
                    const SizedBox(height: 10),
                    CustomInputField(
                      controller: _confirmPasswordController,
                      label: "Senha (mínimo 6 caracteres)",
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                    ),
                    
                    const SizedBox(height: 10),
                    CustomInputField(
                      controller: _allowedSecondaryCompaniesController,
                      label: "Filiais Permitidas (separadas por vírgula, ex: filial_a, filial_b)",
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      
                    ),
                    
                    const SizedBox(height: 20),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Registrar Usuário'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}