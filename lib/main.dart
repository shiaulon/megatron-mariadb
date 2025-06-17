import 'package:flutter/material.dart';
import 'package:flutter_application_1/menu.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/ContatosGeral/GeraRGParaListaContatosGeral.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/ContatosGeral/manutencao.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/RG_main.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaControle.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaPais.dart';
import 'package:flutter_application_1/relacao_aberta_osm.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:flutter_application_1/utilizandotelabase.dart';
import 'login_page.dart';

void main() {
  runApp(const MyApp());
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
      home: const TabelaPais(),
      debugShowCheckedModeBanner: false,
    );
  }
}
