import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para FilteringTextInputFormatter
import 'package:flutter_application_1/ajuda/ajuda.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/admin/logs_page.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/admin/user_management_page.dart';
import 'package:flutter_application_1/providers/permission_provider.dart';
import 'package:flutter_application_1/secondary_company_selection_page.dart';
import 'package:intl/intl.dart'; // Importe para formatar a data
//import 'package:firebase_auth/firebase_auth.dart'; // Para FirebaseAuth.instance.currentUser

import 'package:flutter_application_1/login_page.dart';
import 'package:flutter_application_1/submenus.dart'; // Para a TelaSubPrincipal
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:provider/provider.dart'; // Importa o Provider

// Classe para representar cada botão individualmente
class ButtonData {
  final String text;
  final IconData? iconData; // Agora é IconData (para ícones)
  final VoidCallback? onPressed; // Ação ao clicar no botão
  final Color borderColor; // Cor da borda
  final double borderRadius; // Raio da borda (circunferência)

  ButtonData({
    required this.text,
    this.iconData,
    this.onPressed,
    this.borderColor = Colors.grey, // Cor padrão da borda
    this.borderRadius = 8.0, // Raio padrão da borda
  });
}

// Custom InputFormatter para formato de tópicos (se você quiser usar, descomente no TextField)
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

class TelaPrincipal extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;

  const TelaPrincipal({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
  });

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class ChecklistItem {
  String text;
  bool isChecked;

  ChecklistItem({required this.text, this.isChecked = false});
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  static const double _breakpoint = 700.0;
  final TextEditingController _textEditingController = TextEditingController();
  late final String _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now()); // Inicialização direta

  String _userName = 'Usuário';

  @override
  void initState() {
    super.initState();
    _userName = 'Usuário Logado'; 

    if (_textEditingController.text.isEmpty) {
      _textEditingController.text = '• ';
      _textEditingController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textEditingController.text.length),
      );
    }
    _textEditingController.addListener(_handleTextChange);
  }

  // NOVO MÉTODO: Constrói a lista de botões com base nas permissões
  // Recebe o PermissionProvider como parâmetro
  List<ButtonData> _buildButtonsData(PermissionProvider permissionProvider) {
    List<ButtonData> buttons = []; // Inicia com uma lista vazia

    // Adiciona os botões fixos que sempre aparecem ou que têm lógica de permissão
    buttons.addAll([
      ButtonData(text: 'Home', iconData: Icons.home, onPressed: () => print('Clicou em Home')),
      ButtonData(text: 'Settings', iconData: Icons.settings, onPressed: () => print('Clicou em Configurações')),
      ButtonData(text: 'Profile', iconData: Icons.person, onPressed: () => print('Clicou em Perfil')),
      ButtonData(text: 'Messages', iconData: Icons.message, onPressed: () => print('Clicou em Mensagens')),
      ButtonData(text: 'Help', iconData: Icons.help, onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TelaAjuda(
              mainCompanyId: widget.mainCompanyId,
              secondaryCompanyId: widget.secondaryCompanyId,
            ),
          ),
        );
      }),
    ]);

    // Botões controlados por permissão - CADA UM DENTRO DO SEU 'IF'
    // Verifique se os nomes dos caminhos correspondem EXATAMENTE ao seu Firestore.
    // Ex: "registro_geral" -> "acesso"

    if (permissionProvider.hasAccess(['registro_geral', 'acesso'])) {
      buttons.add(
        ButtonData(text: 'Registro Geral', iconData: Icons.groups, onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TelaSubPrincipal(
                mainCompanyId: widget.mainCompanyId,
                secondaryCompanyId: widget.secondaryCompanyId,
              ),
            ),
          );
        }),
      );
    }

    if (permissionProvider.hasAccess(['administracao_usuarios', 'acesso'])) {
      buttons.add(
        ButtonData(text: 'Administração de Usuários', iconData: Icons.security, onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserManagementPage(
                mainCompanyId: widget.mainCompanyId,
                secondaryCompanyId: widget.secondaryCompanyId,
              ),
            ),
          );
        }),
      );
    }

    if (permissionProvider.hasAccess(['search', 'acesso'])) { // Exemplo de caminho para "Search"
      buttons.add(ButtonData(text: 'Search', iconData: Icons.search, onPressed: () => print('Clicou em Busca')));
    }
    if (permissionProvider.hasAccess(['notifications', 'acesso'])) {
      buttons.add(ButtonData(text: 'Notifications', iconData: Icons.notifications, onPressed: () => print('Clicou em Notificações')));
    }
    
    if (permissionProvider.hasAccess(['calendar', 'acesso'])) {
      buttons.add(ButtonData(text: 'Calendar', iconData: Icons.calendar_today, onPressed: () => print('Clicou em Calendário')));
    }
    
    if (permissionProvider.hasAccess(['camera', 'acesso'])) {
      buttons.add(ButtonData(text: 'Camera', iconData: Icons.camera_alt, onPressed: () => print('Clicou na Câmera')));
    }
    
    if (permissionProvider.hasAccess(['gallery', 'acesso'])) {
      buttons.add(ButtonData(text: 'Gallery', iconData: Icons.photo_library, onPressed: () => print('Clicou em Galeria')));
    }
    
    if (permissionProvider.hasAccess(['location', 'acesso'])) {
      buttons.add(ButtonData(text: 'Location', iconData: Icons.location_on, onPressed: () => print('Clicou em Localização')));
    }
    
    if (permissionProvider.hasAccess(['mail', 'acesso'])) {
      buttons.add(ButtonData(text: 'Mail', iconData: Icons.mail, onPressed: () => print('Clicou em Email')));
    }
    
    if (permissionProvider.hasAccess(['phone', 'acesso'])) {
      buttons.add(ButtonData(text: 'Phone', iconData: Icons.phone, onPressed: () => print('Clicou em Telefone')));
    }
    
    if (permissionProvider.hasAccess(['cloud', 'acesso'])) {
      buttons.add(ButtonData(text: 'Cloud', iconData: Icons.cloud, onPressed: () => print('Clicou em Nuvem')));
    }
    
    if (permissionProvider.hasAccess(['info', 'acesso'])) {
      buttons.add(ButtonData(text: 'Info', iconData: Icons.info, onPressed: () => print('Clicou em Info')));
    }
    
    if (permissionProvider.hasAccess(['star', 'acesso'])) {
      buttons.add(ButtonData(text: 'Star', iconData: Icons.star, onPressed: () => print('Clicou em Estrela')));
    }
    
    if (permissionProvider.hasAccess(['add', 'acesso'])) {
      buttons.add(ButtonData(text: 'Add', iconData: Icons.add, onPressed: () => print('Clicou em Adicionar')));
    }
    
    if (permissionProvider.hasAccess(['delete', 'acesso'])) {
      buttons.add(ButtonData(text: 'Delete', iconData: Icons.delete, onPressed: () => print('Clicou em Deletar')));
    }
    
    if (permissionProvider.hasAccess(['edit', 'acesso'])) {
      buttons.add(ButtonData(text: 'Edit', iconData: Icons.edit, onPressed: () => print('Clicou em Editar')));
    }
    
    // AGORA, O BOTÃO SÓ É ADICIONADO À LISTA SE A PERMISSÃO FOR VERDADEIRA
    if (permissionProvider.hasAccess(['credito', 'acesso'])) {
      buttons.add(
        ButtonData(
          text: 'Crédito',
          iconData: Icons.credit_card,
          onPressed: () {
            // Ação de navegar para a tela de submenus de crédito
            // (Vamos assumir que a tela de submenus é a TelaSubPrincipal por enquanto)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TelaSubPrincipal(
                  mainCompanyId: widget.mainCompanyId,
                  secondaryCompanyId: widget.secondaryCompanyId,
                ),
              ),
            );
          },
        ),
      );
    }
    
    if (permissionProvider.hasAccess(['relatorio', 'acesso'])) {
      buttons.add(ButtonData(text: 'Relatório', iconData: Icons.bar_chart, onPressed: () => print('Clicou em Relatório')));
    }
    
    if (permissionProvider.hasAccess(['relatorio_de_critica', 'acesso'])) {
      buttons.add(ButtonData(text: 'Relatório de Crítica', iconData: Icons.error_outline, onPressed: () => print('Clicou em Relatório de Crítica')));
    }
    
    if (permissionProvider.hasAccess(['etiqueta', 'acesso'])) {
      buttons.add(ButtonData(text: 'Etiqueta', iconData: Icons.label_outline, onPressed: () => print('Clicou em Etiqueta')));
    }
    
    if (permissionProvider.hasAccess(['contatos_geral', 'acesso'])) {
      buttons.add(ButtonData(text: 'Contatos Geral', iconData: Icons.contacts, onPressed: () => print('Clicou em Contatos Geral')));
    }
    
    if (permissionProvider.hasAccess(['portaria', 'acesso'])) {
      buttons.add(ButtonData(text: 'Portaria', iconData: Icons.security, onPressed: () => print('Clicou em Portaria')));
    }
    
    if (permissionProvider.hasAccess(['qualificacao_rg', 'acesso'])) {
      buttons.add(ButtonData(text: 'Qualificação RG', iconData: Icons.verified_user, onPressed: () => print('Clicou em Qualificação RG')));
    }
    
    if (permissionProvider.hasAccess(['area_rg', 'acesso'])) {
      buttons.add(ButtonData(text: 'Área RG', iconData: Icons.area_chart, onPressed: () => print('Clicou em Área RG')));
    }
    
    if (permissionProvider.hasAccess(['tabela_preco_x_rg', 'acesso'])) {
      buttons.add(ButtonData(text: 'Tabela Preço X RG', iconData: Icons.price_change, onPressed: () => print('Clicou em Tabela Preço X RG')));
    }
    
    if (permissionProvider.hasAccess(['modulo_especial', 'acesso'])) {
      buttons.add(ButtonData(text: 'Módulo Especial', iconData: Icons.extension, onPressed: () => print('Clicou em Módulo Especial')));
    }
    
    if (permissionProvider.hasAccess(['crm', 'acesso'])) {
      buttons.add(ButtonData(text: 'CRM', iconData: Icons.support_agent, onPressed: () => print('Clicou em CRM')));
    }
    
    if (permissionProvider.hasAccess(['follow_up', 'acesso'])) {
      buttons.add(ButtonData(text: 'Follow-up', iconData: Icons.follow_the_signs, onPressed: () => print('Clicou em Follow-up')));
    }
    if (permissionProvider.hasAccess(['administracao_usuarios', 'acesso'])) {
      buttons.add(
        ButtonData(
          text: 'Visualizar Logs',
          iconData: Icons.history,
          onPressed: () {
            Navigator.push( // Usamos push para poder voltar
              context,
              MaterialPageRoute(
                builder: (context) => LogsPage( // A página que vamos criar
                  mainCompanyId: widget.mainCompanyId,
                ),
              ),
            );
          },
        ),
      );
    }

    return buttons;
  }

  void _handleTextChange() {
    final text = _textEditingController.text;
    final selection = _textEditingController.selection;

    if (text.endsWith('\n') && !text.endsWith('\n• ') && selection.isCollapsed && selection.end == text.length) {
      if (text.length > 2 && text.substring(text.length - 2, text.length) == '\n•') {
        return;
      }
      _textEditingController.text = '${text}• ';
      _textEditingController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textEditingController.text.length),
      );
    }
  }

  @override
  void dispose() {
    _textEditingController.removeListener(_handleTextChange);
    _textEditingController.dispose();
    super.dispose();
  }
  

  final List<ChecklistItem> _annotations = [
    //ChecklistItem(text: 'Exemplo de anotação 2', isChecked: false),
  ];

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
    final permissionProvider = Provider.of<PermissionProvider>(context);

    // Constrói a lista de botões VÍSIVEIS com base nas permissões
    final List<ButtonData> visibleButtons = _buildButtonsData(permissionProvider);
    final theme = Theme.of(context);

    return TelaBase(
      body: Column(
        children: [
          // Barra superior ocupando a largura total (permanece a mesma, ajustando o nome do usuário)
          Container(
            color: theme.appBarTheme.backgroundColor, 
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                       icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color),
                      tooltip: 'Voltar para seleção de empresa',
                      onPressed: () {
                        // Navega de volta para a SecondaryCompanySelectionPage
                        // Mantenha o usuário logado para que ele possa escolher outra empresa
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SecondaryCompanySelectionPage(
                              mainCompanyId: widget.mainCompanyId,
                            ),
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      backgroundImage: AssetImage('assets/images/logo.jpeg'),
                      radius: 16,
                    ),
                    const SizedBox(width: 8),
                    // Exibir o nome de usuário dinamicamente
                    Text(_userName, style: theme.appBarTheme.titleTextStyle),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Text(_currentDate, style: theme.appBarTheme.titleTextStyle),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth > _breakpoint) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          child: _buildMainContent(isMobile: false, visibleButtons: visibleButtons), // Passa os botões aqui
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: _buildAnnotationSection(),
                      ),
                    ],
                  );
                } else {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        SingleChildScrollView(
                          child: _buildMainContent(isMobile: true, visibleButtons: visibleButtons), // Passa os botões aqui
                        ),
                        const SizedBox(height: 20),
                        _buildAnnotationSection(),
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

  Widget _buildMainContent({required bool isMobile, required List<ButtonData> visibleButtons}) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            // ANTES: color: Colors.blue[100],
            // DEPOIS: Usa a cor de superfície do tema, com uma leve transparência se desejar
            color: theme.colorScheme.surface.withOpacity(0.8),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  Image.asset('assets/images/logo16.png', width: 75, height: 75),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // O texto agora usa a cor 'onSurface' para garantir contraste
                        Text('Empresa Principal ID: ${widget.mainCompanyId}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface)),
                        Text('Empresa Secundária Ativa: ${widget.secondaryCompanyId}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface)),
                        Text('MEGATRON TREINAMENTO E DESENVOLVIMENTO LTDA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface)),
                        Text('CNPJ 12.395.757/0001-00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface)),
                        Text('PRAÇA JOSÉ FRANCISCO JUCATELLI, 151 - JD. BOTÂNICO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface)),
                        Text('RIBEIRÃO PRETO - SP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        _buildBotoesResponsive(isMobile: isMobile, buttonsToDisplay: visibleButtons),
        const SizedBox(height: 40),
      ],
    );
  }


  Widget _buildBotoesResponsive({required bool isMobile, required List<ButtonData> buttonsToDisplay}) {
    final int buttonsPerRow = isMobile ? 2 : 5;
    final theme = Theme.of(context);
    List<Widget> rowsOfButtons = [];

    // USA buttonsToDisplay AQUI
    for (int i = 0; i < buttonsToDisplay.length; i += buttonsPerRow) {
      List<Widget> currentRowButtons = [];
      for (int j = 0; j < buttonsPerRow && (i + j) < buttonsToDisplay.length; j++) {
        final button = buttonsToDisplay[i + j]; // Usa buttonsToDisplay
        currentRowButtons.add(
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: InkWell(
                onTap: button.onPressed,
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(
                      color: button.borderColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(button.borderRadius),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (button.iconData != null)
                        Icon(
                          button.iconData,
                          size: 35,
                          color: theme.colorScheme.primary,
                        ),
                      if (button.iconData != null)
                        const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          button.text,
                          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14),
    //       ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
      rowsOfButtons.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: currentRowButtons,
          ),
        ),
      );
    }
    return Column(children: rowsOfButtons);
  }

  Widget _buildAnnotationSection() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(40.0, 30.0, 20.0, 20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 150, maxHeight: 540),
        decoration: BoxDecoration(
          // ANTES: color: Colors.white,
          // DEPOIS:
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.dividerColor, width: 1.0),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0),
              child: Row(
                children: [
                  Icon(Icons.sticky_note_2, size: 30, color: theme.colorScheme.onSurface),
                  const SizedBox(width: 8),
                  Text(
                    'LEMBRETES',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 1.0,
              color: theme.dividerColor,
              margin: const EdgeInsets.symmetric(horizontal: 12.0),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12.0),
                itemCount: _annotations.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _annotations[index].isChecked,
                          onChanged: (newValue) => _toggleCheckbox(index, newValue),
                        ),
                        Expanded(
                          child: Text(
                            _annotations[index].text,
                            style: TextStyle(
                              decoration: _annotations[index].isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                              color: _annotations[index].isChecked ? Colors.grey : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
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
                    // Usa as cores do tema para o botão
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

  
