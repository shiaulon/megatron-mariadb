import 'package:flutter/material.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:intl/intl.dart'; // Importe para formatar a data
import 'package:flutter/services.dart'; // Para FilteringTextInputFormatter



class Endereco2Carreira132C extends StatefulWidget {
  const Endereco2Carreira132C({super.key});

  @override
  State<Endereco2Carreira132C> createState() => _Endereco2Carreira132CState();
}

// Classe para representar cada botão individualmente (mantida, mas não usada para o menu lateral)
class ButtonData {
  final String text;
  final IconData? iconData;
  final VoidCallback? onPressed;
  final Color borderColor;
  final double borderRadius;

  ButtonData({
    required this.text,
    this.iconData,
    this.onPressed,
    this.borderColor = Colors.grey,
    this.borderRadius = 8.0,
  });
}

// Custom InputFormatter para formato de tópicos (mantido aqui)
class BulletListFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
    ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    if (newValue.text == oldValue.text) {
      return newValue;
    }

    final String text = newValue.text;
    final StringBuffer buffer = StringBuffer();

    List<String> lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      if (line.isNotEmpty && !line.trimLeft().startsWith('• ')) {
        buffer.write('• ');
        buffer.write(line.trimLeft());
      } else {
        buffer.write(line);
      }

      if (i < lines.length - 1) {
        buffer.write('\n');
      }
    }

    final String newFormattedText = buffer.toString();
    final int newSelectionOffset = newFormattedText.length - (text.length - newValue.selection.end);

    return TextEditingValue(
      text: newFormattedText,
      selection: TextSelection.collapsed(offset: newSelectionOffset),
    );
  }
}

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
      child: GestureDetector( // Usando GestureDetector para onTap, pois ListTile já tem onTap
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), // Duração da animação
          curve: Curves.easeInOut, // Curva da animação
          decoration: BoxDecoration(
            color: backgroundColor, // A cor agora é definida dentro do BoxDecoration
            border: Border(
              bottom: BorderSide(color: Colors.black, width: widget.isSubItem ? 0.5 : 1.0),
            ),
          ),
          child: ListTile(
            leading: widget.isSubItem ? null : AnimatedContainer( // Esconde o ícone principal para sub-itens
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


class _Endereco2Carreira132CState extends State<Endereco2Carreira132C> {
  // Define o breakpoint para alternar entre layouts
  static const double _breakpoint = 700.0; // Desktop breakpoint

  // TextEditingController para o campo de texto de lembretes (AGORA AQUI!)
  final TextEditingController _lembretesController = TextEditingController();
  // Variável para armazenar a data atual formatada (AGORA AQUI!)
  late String _currentDate;

  // A lista de dados para os botões não será mais usada na tela principal, mas mantenho a classe ButtonData caso seja usada em outro lugar
  final List<ButtonData> _buttonsData = [];

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Lógica de tópicos para o campo de lembretes (AGORA AQUI!)
    if (_lembretesController.text.isEmpty) {
      _lembretesController.text = '• ';
      _lembretesController.selection = TextSelection.fromPosition(
        TextPosition(offset: _lembretesController.text.length),
      );
    }
    _lembretesController.addListener(_handleLembretesTextChange);
  }

  // Lógica de manipulação de texto de lembretes (AGORA AQUI!)
  void _handleLembretesTextChange() {
    final text = _lembretesController.text;
    final selection = _lembretesController.selection;

    if (text.endsWith('\n') && !text.endsWith('\n• ') && selection.isCollapsed && selection.end == text.length) {
      if (text.length > 2 && text.substring(text.length - 2, text.length) == '\n•') {
        return;
      }
      _lembretesController.text = '${text}• ';
      _lembretesController.selection = TextSelection.fromPosition(
        TextPosition(offset: _lembretesController.text.length),
      );
    }
  }

  @override
  void dispose() {
    _lembretesController.removeListener(_handleLembretesTextChange); // Remove o listener
    _lembretesController.dispose(); // Descarta o controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: Column( // Este Column é o body passado para a TelaBase
        children: [
          // BARRA SUPERIOR
          Container(
            color: Colors.lightBlue,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        print('Logout pressed');
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundImage: AssetImage('assets/images/user.png'),
                      radius: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text('MRAFAEL', style: TextStyle(fontSize: 16, color: Colors.black)),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Text(_currentDate, style: TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            ),
          ),
          // FIM DA BARRA SUPERIOR

          // Área de conteúdo principal (flexível, abaixo da barra superior)
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth > _breakpoint) {
                  // Layout para telas largas (Desktop/Tablet)
                  return Column( // Coluna principal da área de conteúdo
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded( // Expande para o restante do espaço vertical
                        child: Row( // Row para menu, área central e lembretes
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Menu Lateral (flex 1)
                            Expanded(
                              flex: 1,
                              child: _buildLeftMenu(constraints.maxWidth),
                            ),
                            // Área Central: Agora com o retângulo de informações E o título
                            Expanded( // <-- ONDE A MUDANÇA OCORRE: Este Expanded é o pai do título e do container azul
                              flex: 3,
                              child: Column( // Column para empilhar o título e o container
                                crossAxisAlignment: CrossAxisAlignment.start, // Alinha os filhos à esquerda (Text e Padding)
                                children: [
                                  Padding( // Título "Rel OSM em Aberta"
                                    padding: const EdgeInsets.only(top: 20.0, bottom: 0.0), // Padding vertical
                                    child: Center( // <-- NOVO: Centraliza o texto APENAS dentro deste Expanded
                                      child: Text(
                                        'ENDEREÇO 2 CARREIRA 132 C',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded( // O Container azul ocupará o restante do espaço vertical
                                    child: _buildInfoDisplayArea(), // Chamando a área de display de informações
                                  ),
                                ],
                              ),
                            ),
                            // Campo de texto de Lembretes
                            // Removido para foco no menu lateral e para manter o código fiel ao fornecido, caso não seja relevante para a pergunta
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  // Layout para telas pequenas (Mobile)
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // Título "Rel OSM em Aberta" centralizado para mobile
                        Padding(
                          padding: const EdgeInsets.only(top: 15.0, bottom: 8.0),
                          child: Center(
                            child: Text(
                              'Relatório OSM em Aberta',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        _buildLeftMenu(constraints.maxWidth),
                        _buildInfoDisplayArea(), // Área de informações abaixo do menu
                        // Lembretes abaixo da área de informações
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Constrói o menu lateral (sem alterações)
  Widget _buildLeftMenu(double parentMaxWidth) {
    return Container(
      margin: parentMaxWidth > _breakpoint ? const EdgeInsets.only(right: 10.0, top: 10.0, bottom: 10.0) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.black, width: 1.0),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            child: Text(
              'REGISTRO GERAL',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          _buildMenuItem(context, 'Tabelas', Icons.table_chart, () => print('Tabelas')),
          _buildMenuItemWithSubitems(context, 'Registro Geral', Icons.app_registration, [
            _buildSubMenuItem(context, 'Manut RG', () => print('Manut RG')),
            _buildSubMenuItem(context, 'TEXTO', () => print('TEXTO')),
          ]),
          _buildMenuItem(context, 'Crédito', Icons.credit_card, () => print('Crédito')),
          _buildMenuItem(context, 'Relatório', Icons.bar_chart, () => print('Relatório')),
          _buildMenuItem(context, 'Relatório de Crítica', Icons.error_outline, () => print('Relatório de Crítica')),
          _buildMenuItem(context, 'Etiqueta', Icons.label_outline, () => print('Etiqueta')),
          _buildMenuItem(context, 'Contatos Geral', Icons.contacts, () => print('Contatos Geral')),
          _buildMenuItem(context, 'Portaria', Icons.security, () => print('Portaria')),
          _buildMenuItem(context, 'Qualificação RG', Icons.verified_user, () => print('Qualificação RG')),
          _buildMenuItem(context, 'Área RG', Icons.area_chart, () => print('Área RG')),
          _buildMenuItem(context, 'Tabela Preço X RG', Icons.price_change, () => print('Tabela Preço X RG')),
          _buildMenuItem(context, 'Módulo Especial', Icons.extension, () => print('Módulo Especial')),
          _buildMenuItem(context, 'CRM', Icons.support_agent, () => print('CRM')),
          _buildMenuItem(context, 'Follow-up', Icons.follow_the_signs, () => print('Follow-up')),
        ],
      ),
    );
  }

  // ATUALIZADO: Agora retorna um HoverMenuItem
  Widget _buildMenuItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return HoverMenuItem(
      title: title,
      icon: icon,
      onTap: onTap,
      isSubItem: false,
    );
  }

  // ATUALIZADO: Agora retorna um HoverExpansionTile
  Widget _buildMenuItemWithSubitems(BuildContext context, String title, IconData icon, List<Widget> subitems) {
    return HoverExpansionTile(
      title: title,
      icon: icon,
      subitems: subitems,
    );
  }

  // ATUALIZADO: Agora retorna um HoverMenuItem como sub-item
  Widget _buildSubMenuItem(BuildContext context, String title, VoidCallback onTap) {
    return HoverMenuItem(
      title: title,
      icon: Icons.circle, // Sub-items não precisam de um ícone específico, mas o widget HoverMenuItem exige um.
      onTap: onTap,
      isSubItem: true, // Indica que é um sub-item
    );
  }

  // Constrói a área de display de informações (mantido)
  Widget _buildInfoDisplayArea() {
    return Padding(
      padding: const EdgeInsets.all(25), // Padding ao redor do retângulo
      child: Container(
        padding: const EdgeInsets.all(20.0), // Padding interno do container azul
        decoration: BoxDecoration(
          color: Colors.blue[100], // Fundo azul claro
          border: Border.all(color: Colors.black, width: 1.0), // Borda preta
          borderRadius: BorderRadius.circular(10.0), // Cantos arredondados
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  'Conteúdo das informações será adicionado aqui.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
