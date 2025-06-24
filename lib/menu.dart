import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para FilteringTextInputFormatter
import 'package:flutter_application_1/secondary_company_selection_page.dart';
import 'package:intl/intl.dart'; // Importe para formatar a data
import 'package:firebase_auth/firebase_auth.dart'; // Para FirebaseAuth.instance.currentUser

import 'package:flutter_application_1/login_page.dart';
import 'package:flutter_application_1/submenus.dart'; // Para a TelaSubPrincipal
import 'package:flutter_application_1/reutilizaveis/tela_base.dart'; // importa o widget base
// import 'relacao_aberta_osm.dart'; // Se esta tela existir e for usada, certifique-se de que ela também aceite os parâmetros de empresa e permissão.

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
  // ADICIONADOS OS NOVOS PARÂMETROS
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole; // Para controlar permissões de menu

  const TelaPrincipal({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole, // Torna opcional, mas é bom ter
  });

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  static const double _breakpoint = 700.0;
  final TextEditingController _textEditingController = TextEditingController();
  late final List<ButtonData> _buttonsData;
  late String _currentDate;

  // Variável para armazenar o nome de usuário (ex: MRAFAEL)
  String _userName = 'Usuário';

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Tenta obter o nome de exibição do usuário logado ou email
    _userName = FirebaseAuth.instance.currentUser?.displayName ?? FirebaseAuth.instance.currentUser?.email?.split('@').first.toUpperCase() ?? 'Usuário';

    // Inicializa _buttonsData
    _buttonsData = _buildButtonsData(); // Chamada de um novo método para construir a lista de botões

    if (_textEditingController.text.isEmpty) {
      _textEditingController.text = '• ';
      _textEditingController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textEditingController.text.length),
      );
    }
    _textEditingController.addListener(_handleTextChange);
  }

  // NOVO MÉTODO: Constrói a lista de botões com base nas permissões
  List<ButtonData> _buildButtonsData() {
    // Acessa o userRole via widget.userRole
    final String? role = widget.userRole;

    List<ButtonData> buttons = [
      ButtonData(text: 'Home', iconData: Icons.home, onPressed: () => print('Clicou em Home')),
      ButtonData(text: 'Settings', iconData: Icons.settings, onPressed: () => print('Clicou em Configurações')),
      ButtonData(text: 'Profile', iconData: Icons.person, onPressed: () => print('Clicou em Perfil')),
      ButtonData(text: 'Messages', iconData: Icons.message, onPressed: () => print('Clicou em Mensagens')),
    ];

    // Exemplo de botão com permissão: 'Registro Geral' visível apenas para 'admin' e 'gerente'
    if (role == 'admin' || role == 'gerente') {
      buttons.add(
        ButtonData(text: 'Registro Geral', iconData: Icons.groups, onPressed: () {
          // Passa todos os parâmetros para a próxima tela
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TelaSubPrincipal(
                mainCompanyId: widget.mainCompanyId,
                secondaryCompanyId: widget.secondaryCompanyId,
                userRole: role,
              ),
            ),
          );
        }),
      );
    }

    // Exemplo: Botão 'Administração de Usuários' visível apenas para 'admin'
    if (role == 'admin') {
      buttons.add(
        ButtonData(text: 'Administração de Usuários', iconData: Icons.security, onPressed: () {
          print('Clicou em Admin Usuários (Apenas Admin)');
          // Exemplo: Navegar para uma tela de administração de usuários
          // Navigator.push(context, MaterialPageRoute(builder: (context) => UserAdminScreen(...)));
        }),
      );
    }

    // Adicione mais botões e suas lógicas de permissão aqui
    buttons.addAll([
      ButtonData(text: 'Search', iconData: Icons.search, onPressed: () => print('Clicou em Busca')),
      ButtonData(text: 'Notifications', iconData: Icons.notifications, onPressed: () => print('Clicou em Notificações')),
      ButtonData(text: 'Calendar', iconData: Icons.calendar_today, onPressed: () => print('Clicou em Calendário')),
      ButtonData(text: 'Camera', iconData: Icons.camera_alt, onPressed: () => print('Clicou na Câmera')),
      ButtonData(text: 'Gallery', iconData: Icons.photo_library, onPressed: () => print('Clicou em Galeria')),
      ButtonData(text: 'Location', iconData: Icons.location_on, onPressed: () => print('Clicou em Localização')),
      ButtonData(text: 'Mail', iconData: Icons.mail, onPressed: () => print('Clicou em Email')),
      ButtonData(text: 'Phone', iconData: Icons.phone, onPressed: () => print('Clicou em Telefone')),
      ButtonData(text: 'Cloud', iconData: Icons.cloud, onPressed: () => print('Clicou em Nuvem')),
      ButtonData(text: 'Help', iconData: Icons.help, onPressed: () => print('Clicou em Ajuda')),
      ButtonData(text: 'Info', iconData: Icons.info, onPressed: () => print('Clicou em Info')),
      ButtonData(text: 'Star', iconData: Icons.star, onPressed: () => print('Clicou em Estrela')),
      ButtonData(text: 'Add', iconData: Icons.add, onPressed: () => print('Clicou em Adicionar')),
      ButtonData(text: 'Delete', iconData: Icons.delete, onPressed: () => print('Clicou em Deletar')),
      ButtonData(text: 'Edit', iconData: Icons.edit, onPressed: () => print('Clicou em Editar')),
    ]);

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

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: Column(
        children: [
          // Barra superior ocupando a largura total (permanece a mesma, ajustando o nome do usuário)
          Container(
            color: Colors.lightBlue,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black), // Ícone de voltar
                      tooltip: 'Voltar para seleção de empresa',
                      onPressed: () {
                        // Navega de volta para a SecondaryCompanySelectionPage
                        // Mantenha o usuário logado para que ele possa escolher outra empresa
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SecondaryCompanySelectionPage(
                              mainCompanyId: widget.mainCompanyId,
                              // allowedSecondaryCompanies NÃO É MAIS NECESSÁRIO AQUI, pois será buscado
                              userRole: widget.userRole,
                            ),
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      backgroundImage: AssetImage('assets/images/user.png'),
                      radius: 16,
                    ),
                    const SizedBox(width: 8),
                    // Exibir o nome de usuário dinamicamente
                    Text(_userName, style: const TextStyle(fontSize: 16, color: Colors.black)),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Text(_currentDate, style: const TextStyle(color: Colors.black)),
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
                          child: _buildMainContent(isMobile: false),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: _buildTextField(),
                      ),
                    ],
                  );
                } else {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        SingleChildScrollView(
                          child: _buildMainContent(isMobile: true),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(),
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

  Widget _buildMainContent({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Image.asset(
                'assets/images/logo16.png',
                width: 75,
                height: 75,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exibir os IDs da empresa selecionada
                    Text(
                      'Empresa Principal ID: ${widget.mainCompanyId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Empresa Secundária Ativa: ${widget.secondaryCompanyId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Seu Cargo: ${widget.userRole ?? 'Não Definido'}', // Mostra o cargo
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    // Você pode buscar o nome completo da empresa e CNPJ aqui se quiser
                    // usando os IDs (mainCompanyId, secondaryCompanyId) e Firestore.
                    // Por enquanto, mantendo os dados fixos abaixo.
                    const Text(
                      'MEGATRON TREINAMENTO E DESENVOLVIMENTO LTDA',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Text(
                      'CNPJ 12.395.757/0001-00',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Text(
                      'PRAÇA JOSÉ FRANCISCO JUCATELLI, 151 - JD. BOTÂNICO',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Text(
                      'RIBEIRÃO PRETO - SP',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        _buildBotoesResponsive(isMobile: isMobile),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTextField() {
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.sticky_note_2,
                    size: 30,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 8),
                  const Text(
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
              child: TextField(
                controller: _textEditingController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Digite suas anotações aqui...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12.0),
                ),
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotoesResponsive({required bool isMobile}) {
    final int buttonsPerRow = isMobile ? 2 : 5;

    List<Widget> rowsOfButtons = [];

    for (int i = 0; i < _buttonsData.length; i += buttonsPerRow) {
      List<Widget> currentRowButtons = [];
      for (int j = 0; j < buttonsPerRow && (i + j) < _buttonsData.length; j++) {
        final button = _buttonsData[i + j];
        currentRowButtons.add(
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: InkWell(
                onTap: button.onPressed,
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[100],
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
                          color: Colors.blueAccent,
                        ),
                      if (button.iconData != null)
                        const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          button.text,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
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
}