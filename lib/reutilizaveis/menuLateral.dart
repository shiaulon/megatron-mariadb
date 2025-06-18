// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaCidade.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaControle.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaEstado.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaEstadoXImposto.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaNatureza.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaPais.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaSituacao.dart';

// NOVO WIDGET: Item de menu com efeito de hover
class HoverMenuItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSubItem; // Novo parâmetro para diferenciar sub-itens

  const HoverMenuItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.isSubItem = false,
  });

  @override
  State<HoverMenuItem> createState() => _HoverMenuItemState();
}

class _HoverMenuItemState extends State<HoverMenuItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // Define as cores e tamanhos de fonte baseados no estado de hover e se é sub-item
    final Color backgroundColor = _isHovering ? Colors.blue[700]! : Colors.blue[50]!;
    final Color textColor = _isHovering ? Colors.white : Colors.black;
    final Color iconColor = _isHovering ? Colors.white : Colors.black;
    final double fontSize = widget.isSubItem
        ? (_isHovering ? 15.0 : 13.0)
        : (_isHovering ? 16.0 : 14.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        // Usando GestureDetector para onTap, pois ListTile já tem onTap
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), // Duração da animação
          curve: Curves.easeInOut, // Curva da animação
          decoration: BoxDecoration(
            color: backgroundColor, // A cor agora é definida dentro do BoxDecoration
            border: Border(
              bottom:
                  BorderSide(color: Colors.black, width: widget.isSubItem ? 0.5 : 1.0),
            ),
          ),
          child: ListTile(
            leading: widget.isSubItem
                ? null
                : AnimatedContainer(
                    // Esconde o ícone principal para sub-itens
                    duration: const Duration(milliseconds: 200),
                    child: Icon(widget.icon, color: iconColor),
                  ),
            title: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              style: TextStyle(
                fontSize: fontSize,
                color: textColor,
                fontWeight: _isHovering ? FontWeight.bold : FontWeight.normal,
              ),
              child: Text(widget.title),
            ),
            dense: true,
            contentPadding: widget.isSubItem
                ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0)
                : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          ),
        ),
      ),
    );
  }
}

// NOVO WIDGET: Item de menu com sub-itens e efeito de hover
class HoverExpansionTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> subitems;

  const HoverExpansionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.subitems,
  });

  @override
  State<HoverExpansionTile> createState() => _HoverExpansionTileState();
}

class _HoverExpansionTileState extends State<HoverExpansionTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _isHovering ? Colors.blue[700]! : Colors.blue[50]!;
    final Color textColor = _isHovering ? Colors.white : Colors.black;
    final Color iconColor = _isHovering ? Colors.white : Colors.black;
    final double fontSize = _isHovering ? 16.0 : 14.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: backgroundColor, // Color defined within BoxDecoration
          border: const Border(
            bottom: BorderSide(color: Colors.black, width: 1.0),
          ),
        ),
        child: ExpansionTile(
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(widget.icon, color: iconColor),
          ),
          title: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            style: TextStyle(
              fontSize: fontSize,
              color: textColor,
              fontWeight: _isHovering ? FontWeight.bold : FontWeight.normal,
            ),
            child: Text(widget.title),
          ),
          children: widget.subitems,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          childrenPadding: const EdgeInsets.only(left: 30.0),
          iconColor: iconColor, // Use animated icon color for the expansion arrow
          collapsedIconColor: iconColor,
        ),
      ),
    );
  }
}

/// Um widget que representa o menu lateral da aplicação.
/// Ele pode ser usado em qualquer tela que precise do menu padrão.
class AppDrawer extends StatelessWidget {
  final double parentMaxWidth;
  final double breakpoint; // Adicione o breakpoint como parâmetro

  const AppDrawer({
    Key? key,
    required this.parentMaxWidth,
    required this.breakpoint,
  }) : super(key: key);

  // Widget auxiliar para construir itens de menu individuais
  Widget _buildMenuItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return HoverMenuItem(
      title: title,
      icon: icon,
      onTap: onTap,
      isSubItem: false,
    );
  }

  // Widget auxiliar para construir itens de menu com sub-itens
  Widget _buildMenuItemWithSubitems(BuildContext context, String title, IconData icon, List<Widget> subitems) {
    return HoverExpansionTile(
      title: title,
      icon: icon,
      subitems: subitems,
    );
  }

  // Widget auxiliar para construir sub-itens de menu
  Widget _buildSubMenuItem(BuildContext context, String title, VoidCallback onTap) {
    return HoverMenuItem(
      title: title,
      icon: Icons.circle,
      onTap: onTap,
      isSubItem: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: parentMaxWidth > breakpoint
          ? const EdgeInsets.only(right: 10.0, top: 10.0, bottom: 10.0)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.black, width: 1.0),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            child: Text(
              'REGISTRO GERAL',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          _buildMenuItemWithSubitems(context, 'Tabelas', Icons.table_chart, [
            _buildSubMenuItem(context, 'Controle', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TabelaControle()),),),
            _buildSubMenuItem(context, 'País', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TabelaPais()),),),
            _buildSubMenuItem(context, 'Estado', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TabelaEstado()),),),
            _buildSubMenuItem(context, 'Estado x Imposto', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TabelaEstadoXImposto()),),),
            _buildSubMenuItem(context, 'Cidade', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TabelaCidade()),),),
            _buildSubMenuItem(context, 'Natureza', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NaturezaTela()),),),
            _buildSubMenuItem(context, 'Situação', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TabelaSituacao()),),),

          ]),
          _buildMenuItemWithSubitems(context, 'Registro Geral', Icons.app_registration, [
            _buildSubMenuItem(context, 'Manut RG', () => print('Clicou em Manut RG')),
            _buildSubMenuItem(context, 'TEXTO', () => print('Clicou em TEXTO do submenu')),
          ]),
          _buildMenuItem(context, 'Crédito', Icons.credit_card, () => print('Clicou em Crédito')),
          _buildMenuItem(context, 'Relatório', Icons.bar_chart, () => print('Clicou em Relatório')),
          _buildMenuItem(context, 'Relatório de Crítica', Icons.error_outline, () => print('Clicou em Relatório de Crítica')),
          _buildMenuItem(context, 'Etiqueta', Icons.label_outline, () => print('Clicou em Etiqueta')),
          _buildMenuItem(context, 'Contatos Geral', Icons.contacts, () => print('Clicou em Contatos Geral')),
          _buildMenuItem(context, 'Portaria', Icons.security, () => print('Clicou em Portaria')),
          _buildMenuItem(context, 'Qualificação RG', Icons.verified_user, () => print('Clicou em Qualificação RG')),
          _buildMenuItem(context, 'Área RG', Icons.area_chart, () => print('Clicou em Área RG')),
          _buildMenuItem(context, 'Tabela Preço X RG', Icons.price_change, () => print('Clicou em Tabela Preço X RG')),
          _buildMenuItem(context, 'Módulo Especial', Icons.extension, () => print('Clicou em Módulo Especial')),
          _buildMenuItem(context, 'CRM', Icons.support_agent, () => print('Clicou em CRM')),
          _buildMenuItem(context, 'Follow-up', Icons.follow_the_signs, () => print('Clicou em Follow-up')),
        ],
      ),
    );
  }
}