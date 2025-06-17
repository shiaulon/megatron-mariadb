import 'package:flutter/material.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:intl/intl.dart'; // Importe para formatar a data
import 'package:flutter/services.dart'; // Para FilteringTextInputFormatter


class RGMain extends StatefulWidget {
  const RGMain({super.key});

  @override
  State<RGMain> createState() => _RGMainState();
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

// Custom InputFormatter para formato de tópicos (mantido aqui, mas não usado para anotações)
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

// Classe para representar um item da lista de anotações com checkbox
class ChecklistItem {
  String text;
  bool isChecked;

  ChecklistItem({required this.text, this.isChecked = false});
}

class _RGMainState extends State<RGMain> {
  // Define o breakpoint para alternar entre layouts
  static const double _breakpoint = 700.0; // Desktop breakpoint

  // Lista de anotações com checkboxes
  final List<ChecklistItem> _annotations = [
    ChecklistItem(text: 'Exemplo de anotação 1', isChecked: false),
    
  ];

  late String _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Método para exibir o diálogo de confirmação de exclusão
  Future<bool> _showDeleteConfirmationDialog(String annotationText) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Deseja realmente excluir a anotação: "$annotationText"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Não'),
              onPressed: () {
                Navigator.of(context).pop(false); // Retorna false (não quer excluir)
              },
            ),
            TextButton(
              child: const Text('Sim'),
              onPressed: () {
                Navigator.of(context).pop(true); // Retorna true (quer excluir)
              },
            ),
          ],
        );
      },
    ) ?? false; // Retorna false se o diálogo for fechado de outra forma
  }

  // Método para alternar o estado do checkbox e remover se for marcado
  void _toggleCheckbox(int index, bool? newValue) async {
    if (newValue != null) {
      if (newValue == true) { // Se o checkbox está sendo marcado (concluído)
        bool confirmDelete = await _showDeleteConfirmationDialog(_annotations[index].text);
        if (confirmDelete) {
          _removeAnnotation(index);
        } else {
          // Se o usuário cancelar a exclusão, revertemos o estado do checkbox
          setState(() {
            _annotations[index].isChecked = false;
          });
        }
      } else { // Se o checkbox está sendo desmarcado
        setState(() {
          _annotations[index].isChecked = newValue;
        });
      }
    }
  }

  // Método para adicionar uma nova anotação
  void _addAnnotation(String text) {
    if (text.isNotEmpty) {
      setState(() {
        _annotations.add(ChecklistItem(text: text));
      });
    }
  }

  // Método para remover uma anotação
  void _removeAnnotation(int index) {
    setState(() {
      _annotations.removeAt(index);
    });
  }

  // Método para exibir o diálogo de adicionar anotação
  Future<void> _showAddAnnotationDialog() async {
    String newAnnotationText = '';
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // O usuário deve tocar nos botões para fechar
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar Anotação'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  onChanged: (value) {
                    newAnnotationText = value;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Digite sua anotação aqui',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () {
                _addAnnotation(newAnnotationText);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
                      icon: const Icon(Icons.exit_to_app, color: Colors.black),
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
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Menu Lateral (agora flex 1) - ocupará 1/5 do total de 5 partes
                      Expanded(
                        flex: 1, // 1/5 da largura total
                        child: _buildLeftMenu(constraints.maxWidth),
                      ),
                      // Área Central (agora flex 3) - ocupará 3/5 do total
                      Expanded( // <-- ONDE A MUDANÇA OCORRE: Este Expanded é o pai do título e do container azul
                              flex: 3,
                              child: Column( // Column para empilhar o título e o container
                                crossAxisAlignment: CrossAxisAlignment.start, // Alinha os filhos à esquerda (Text e Padding)
                                children: [
                                  Padding( // Título "Rel OSM em Aberta"
                                    padding: const EdgeInsets.only(top: 20.0, bottom: 0.0), // Padding vertical
                                    child: Center( // <-- NOVO: Centraliza o texto APENAS dentro deste Expanded
                                      child: Text(
                                        'Relatório OSM em Aberta',
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
                      // Campo de anotações agora com checkboxes
                      Expanded(
                        flex: 1,
                        child: _buildAnnotationSection(), // Chamando a nova seção de anotações
                      ),
                    ],
                  );
                } else {
                  // Layout para telas pequenas (Mobile) - Empilha menu e campo de texto
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildLeftMenu(constraints.maxWidth),
                        const SizedBox(height: 20),
                        _buildAnnotationSection(), // Seção de anotações abaixo da área de informações
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

  // Constrói o menu lateral
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

  // Constrói uma área central vazia
  Widget _buildCentralEmptyArea() {
    return Container(
      color: Colors.transparent,
      child: const SizedBox.expand(),
    );
  }

  // NOVO MÉTODO: Constrói a seção de anotações com checkboxes
  Widget _buildAnnotationSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40.0, 30.0, 20.0, 20),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 150,
          maxHeight: 540,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1.0),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.sticky_note_2,
                    size: 30,
                    color: Colors.black87,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'LEMBRETES',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 1.0,
              color: Colors.black,
              margin: const EdgeInsets.symmetric(horizontal: 12.0),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12.0),
                itemCount: _annotations.length,
                itemBuilder: (context, index) {
                  return Padding( // Adicionando Padding para espaçamento
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        // Checkbox
                        Checkbox(
                          value: _annotations[index].isChecked,
                          onChanged: (newValue) async { // Agora é um método async
                            _toggleCheckbox(index, newValue);
                          },
                        ),
                        // Texto da anotação
                        Expanded(
                          child: Text(
                            _annotations[index].text,
                            style: TextStyle(
                              decoration: _annotations[index].isChecked
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: _annotations[index].isChecked
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                        ),
                        // O botão de exclusão foi removido daqui
                      ],
                    ),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: _showAddAnnotationDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Anotação'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700], // Cor de fundo do botão
                    foregroundColor: Colors.white, // Cor do texto e ícone
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
