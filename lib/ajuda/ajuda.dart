import 'package:flutter/material.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class TelaAjuda extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole;

  const TelaAjuda({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<TelaAjuda> createState() => _TelaAjudaState();
}

class _TelaAjudaState extends State<TelaAjuda> {
  static const double _breakpoint = 700.0;
  late String _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir o link: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: Column(
        children: [
          TopAppBar(
            onBackPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TelaSubPrincipal(
                    mainCompanyId: widget.mainCompanyId,
                    secondaryCompanyId: widget.secondaryCompanyId,
                    userRole: widget.userRole,
                  ),
                ),
              );
            },
            currentDate: _currentDate,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > _breakpoint) {
                  return _buildDesktopLayout(constraints);
                } else {
                  return _buildMobileLayout();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: AppDrawer(
            parentMaxWidth: constraints.maxWidth,
            breakpoint: _breakpoint,
            mainCompanyId: widget.mainCompanyId,
            secondaryCompanyId: widget.secondaryCompanyId,
            //userRole: widget.userRole,
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
                child: Text('Ajuda & Suporte', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: _buildCentralContent()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 15.0, bottom: 8.0),
            child: Text('Ajuda & Suporte', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          AppDrawer(
            parentMaxWidth: 0,
            breakpoint: _breakpoint,
            mainCompanyId: widget.mainCompanyId,
            secondaryCompanyId: widget.secondaryCompanyId,
            //userRole: widget.userRole,
          ),
          _buildCentralContent(),
        ],
      ),
    );
  }

  Widget _buildCentralContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        children: [
          _buildInfoSistemaCard(),
          const SizedBox(height: 20),
          _buildFaqCard(),
          const SizedBox(height: 20),
          _buildSuporteCard(),
        ],
      ),
    );
  }

  Widget _buildInfoSistemaCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: const ListTile(
        leading: Icon(Icons.info_outline, color: Colors.blue),
        title: Text('Informações do Sistema', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Versão: 1.0.0\nEmpresa: EGB VALVULAS IND C SERV M I E LTDA'),
      ),
    );
  }

  Widget _buildFaqCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        leading: const Icon(Icons.question_answer_outlined, color: Colors.blue),
        title: const Text('Dúvidas Frequentes', style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          _buildFaqItem('Como cadastrar um novo cliente?', 'Vá para a tela de Manutenção RG, preencha os dados na aba "Dados Gerais" e clique em "SALVAR".'),
          _buildFaqItem('Como gerar um relatório?', 'Na tela desejada (ex: Países, Estados), clique no botão amarelo "RELATÓRIO" para gerar o PDF.'),
          _buildFaqItem('Esqueci minha senha, e agora?', 'Na tela de login, clique em "Esqueci minha senha" e siga as instruções enviadas para o seu e-mail.'),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ListTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(answer),
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
    );
  }

  Widget _buildSuporteCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.contact_support_outlined, color: Colors.blue),
            title: Text('Suporte Técnico', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.phone_in_talk, color: Colors.green),
            title: const Text('WhatsApp'),
            subtitle: const Text('(16) 99761-1134'),
            onTap: () {
              const phoneNumber = '5516997611134';
              _launchURL('https://wa.me/$phoneNumber');
            },
          ),
          ListTile(
            leading: const Icon(Icons.alternate_email, color: Colors.red),
            title: const Text('E-mail'),
            subtitle: const Text('suporte@megatronrp.com.br'),
            onTap: () => _launchURL('mailto:suporte@megatronrp.com.br'),
          ),
        ],
      ),
    );
  }
}
