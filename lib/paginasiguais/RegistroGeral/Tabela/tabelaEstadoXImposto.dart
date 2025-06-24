// lib/tabela_estado_imposto.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para FilteringTextInputFormatter
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart'; // Para formatar a data

// Importar os componentes reutilizáveis
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/informacoesInferioresPagina.dart';


//Validator para UF
String? _ufValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'O campo é obrigatório.';
  }
  final List<String> validUFs = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
    'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
    'SP', 'SE', 'TO'
  ];
  if (!validUFs.contains(value.toUpperCase())) {
    return 'UF inválida. Use um formato como SP, RJ, etc.';
  }
  
  return null;

}


// NOVO FORMATTER: PercentageInputFormatter (formata da direita para a esquerda)
class PercentageInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove tudo que não for dígito
    String cleanedText = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (cleanedText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Se tiver apenas 1 ou 2 dígitos, adiciona um 0 na frente para forçar o formato 0,XX
    while (cleanedText.length < 3 && cleanedText.length > 0) {
        // Isso é opcional, mas garante que "1" vira "0,01" se você quiser.
        // Se 1 deve virar 0,01, então não adicione o "0" aqui.
        // Pelo seu exemplo (345 -> 3,45), significa que 2 casas são decimais.
        // Ou seja, o número inteiro está à esquerda da vírgula.
        // Se 345 vira 3,45 e 3456 vira 34,56, então a vírgula está sempre
        // 2 casas da direita para a esquerda.
        break; // Não adiciona 0, apenas formata.
    }


    String formattedText;
    int cursorPosition;

    if (cleanedText.length <= 2) {
      // Se 0 ou 1 ou 2 dígitos (ex: "", "1", "12")
      formattedText = cleanedText; // Ainda não tem vírgula
      cursorPosition = formattedText.length;
    } else {
      // Para 3 ou mais dígitos (ex: "345", "3456")
      // A vírgula sempre estará duas posições da direita para a esquerda
      int integerPartLength = cleanedText.length - 2;
      String integerPart = cleanedText.substring(0, integerPartLength);
      String decimalPart = cleanedText.substring(integerPartLength);

      formattedText = '$integerPart,$decimalPart';
      cursorPosition = formattedText.length; // Cursor no final
    }

    // Se o texto antigo tinha menos caracteres e não tinha vírgula
    // e o novo texto adicionou, ajusta o cursor
    if (oldValue.text.length < formattedText.length &&
        !oldValue.text.contains(',') && formattedText.contains(',')) {
      cursorPosition = newValue.selection.end + 1;
    } else if (oldValue.text.length > formattedText.length &&
               oldValue.text.contains(',') && !formattedText.contains(',')) {
      // Se a vírgula foi removida (ex: 3,45 -> 345)
      cursorPosition = newValue.selection.end - 1;
    } else {
      cursorPosition = newValue.selection.end;
    }


    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}


class PercentageInputFormatter3Antes extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // 1. Limpar a entrada: remover tudo que não for dígito.
    String newText = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Se o texto está vazio, retorna um valor vazio.
    if (newText.isEmpty) {
      return TextEditingValue.empty;
    }

    // 2. Formatar o texto: Adicionar a vírgula duas casas da direita para a esquerda.
    String formattedText;
    int decimalDigits = 2; // Queremos XX,XX, então 2 casas decimais

    if (newText.length <= decimalDigits) {
      // Se 0, 1 ou 2 dígitos (ex: "", "1", "12"), a vírgula ainda não aparece.
      // Apenas exibe o número puro.
      formattedText = newText;
    } else {
      // Para 3 ou mais dígitos (ex: "123", "1234", "12345")
      // A vírgula é inserida 'decimalDigits' posições da direita para a esquerda.
      int integerPartLength = newText.length - decimalDigits;
      String integerPart = newText.substring(0, integerPartLength);
      String decimalPart = newText.substring(integerPartLength);

      formattedText = '$integerPart,$decimalPart';
    }

    // 3. Ajustar a posição do cursor.
    // O objetivo é que o cursor tente manter sua posição lógica
    // na string formatada.

    TextSelection newSelection = newValue.selection; // Posição atual do cursor na nova string (não formatada ainda)

    // Se a vírgula foi inserida onde o cursor estaria, move-o para depois da vírgula.
    // Isso é especialmente importante quando se digita o terceiro dígito (ex: 12 -> 1,23).
    // Se o cursor estava em index 2 (depois do '2' em '12') e a vírgula entra em index 1,
    // o cursor deve pular para index 2 (depois da vírgula em '1,23').
    int oldCleanedLength = oldValue.text.replaceAll(RegExp(r'\D'), '').length;
    int newCleanedLength = newText.length;

    int newCursorOffset = newValue.selection.end; // Posição final do cursor no texto limpo

    if (newCleanedLength > oldCleanedLength) { // Se o usuário digitou
      // Se a vírgula foi inserida entre a posição antiga e nova do cursor
      // (ex: de "12|" para "1,2|3")
      if (newCursorOffset > (newCleanedLength - decimalDigits)) {
        newCursorOffset++; // Pula a vírgula
      }
    } else if (newCleanedLength < oldCleanedLength) { // Se o usuário deletou
      // Se a vírgula foi removida (ex: "1,2|3" para "12|")
      if (newCursorOffset > (newCleanedLength - decimalDigits)) {
        // Nada a fazer, o cursor já deve estar na posição correta ou antes do final.
      }
    }

    // Garante que o cursor não vá para uma posição fora dos limites da nova string formatada.
    if (newCursorOffset < 0) newCursorOffset = 0;
    if (newCursorOffset > formattedText.length) newCursorOffset = formattedText.length;


    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }
}


class PercentageInputFormatter4CasasDecimais extends TextInputFormatter {
  final int decimalDigits = 4; // Casas decimais fixas

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newTextCleaned = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Caso de texto vazio ou apenas zeros
    if (newTextCleaned.isEmpty) {
      return TextEditingValue.empty;
    }

    // Se o usuário digitou apenas zeros e não há outros dígitos, pode ser "0,0000"
    if (int.tryParse(newTextCleaned) == 0) {
      return const TextEditingValue(
        text: '0,0000',
        selection: TextSelection.collapsed(offset: 6), // Cursor no final
      );
    }

    String formattedText;
    int newCursorOffset;

    // Garante que a string limpa tenha pelo menos o número de dígitos decimais
    // para que a vírgula possa ser inserida corretamente da direita para a esquerda.
    // Ex: "1" -> "0001", "12" -> "0012", "123" -> "0123", "1234" -> "1234"
    String tempCleanedText = newTextCleaned.padLeft(decimalDigits, '0');

    // A vírgula sempre será inserida 'decimalDigits' posições da direita para a esquerda.
    // Se a string tem menos que 'decimalDigits' + 1, significa que a parte inteira é '0'
    if (tempCleanedText.length <= decimalDigits) {
        formattedText = '0,$tempCleanedText'; // Ex: "0,0001", "0,0012", "0,0123", "0,1234"
    } else {
        // Divide a string em parte inteira e parte decimal
        int integerPartLength = tempCleanedText.length - decimalDigits;
        String integerPart = tempCleanedText.substring(0, integerPartLength);
        String decimalPart = tempCleanedText.substring(integerPartLength);

        // Remove zeros à esquerda da parte inteira, a menos que seja apenas "0"
        if (integerPart.length > 1 && integerPart.startsWith('0')) {
             integerPart = integerPart.substring(1); // Ex: "01" vira "1"
        }
        if (integerPart.isEmpty) integerPart = '0'; // Garante que não fique vazio se virar "0"

        formattedText = '$integerPart,$decimalPart';
    }


    // --- Ajuste da Posição do Cursor ---
    // A lógica mais simples e robusta para este tipo de formatador
    // é manter o cursor sempre no final.
    // Se o usuário precisa editar no meio, a experiência pode ser prejudicada,
    // mas tentar calcular posições intermediárias com preenchimento de zero e vírgula
    // é extremamente complexo e propenso a bugs visuais.
    newCursorOffset = formattedText.length;

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }
}

class TabelaEstadoXImposto extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole; // Se precisar usar a permissão aqui também

  const TabelaEstadoXImposto({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<TabelaEstadoXImposto> createState() => _TabelaEstadoXImpostoState();
}

class _TabelaEstadoXImpostoState extends State<TabelaEstadoXImposto> {
  static const double _breakpoint = 700.0; // Desktop breakpoint

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String _currentDate;

  // Controllers para os campos da tela "Estado X Imposto"
  final TextEditingController _estadoOrigemController = TextEditingController();
  final TextEditingController _estadoDestinoController = TextEditingController();
  final TextEditingController _aliqInterstadualController = TextEditingController();
  final TextEditingController _aliqInternaDIFALController = TextEditingController();
  final TextEditingController _descontoDiferencaICMSRevendaController = TextEditingController();
  final TextEditingController _descontoDiferencaICMSOutrosController = TextEditingController();
  final TextEditingController _aliqICMSSubstituicaoController = TextEditingController();
  final TextEditingController _aliqAbatimentoICMSController = TextEditingController();
  final TextEditingController _aliqAbatimentoICMSRevendaController = TextEditingController();
  final TextEditingController _aliqAbatimentoICMSConsumidorController = TextEditingController();
  final TextEditingController _mvaSTController = TextEditingController();
  final TextEditingController _mvaSTImportaController = TextEditingController();
  final TextEditingController _ctaContabilSubsTribEntrDebController = TextEditingController();
  final TextEditingController _aliqCombatePobrezaController = TextEditingController();


  // Variáveis para os Radio Buttons (Sim/Não para Cálculo DIFAL Dentro)
  bool? _calculoDIFALDentro = false; // Valor inicial para "Não"

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    _estadoOrigemController.addListener(_updateFieldCounters);
    _estadoDestinoController.addListener(_updateFieldCounters);
    _aliqInterstadualController.addListener(_updateFieldCounters);
    _aliqInternaDIFALController.addListener(_updateFieldCounters);
    _descontoDiferencaICMSRevendaController.addListener(_updateFieldCounters);
    _descontoDiferencaICMSOutrosController.addListener(_updateFieldCounters);
    _aliqICMSSubstituicaoController.addListener(_updateFieldCounters);
    _aliqAbatimentoICMSController.addListener(_updateFieldCounters);
    _aliqAbatimentoICMSRevendaController.addListener(_updateFieldCounters);
    _aliqAbatimentoICMSConsumidorController.addListener(_updateFieldCounters);
    _mvaSTController.addListener(_updateFieldCounters);
    _mvaSTImportaController.addListener(_updateFieldCounters);
    _ctaContabilSubsTribEntrDebController.addListener(_updateFieldCounters);
    _aliqCombatePobrezaController.addListener(_updateFieldCounters);
  }

  void _updateFieldCounters() {
    setState(() {
      // Força a reconstrução para atualizar o suffixText dos CustomInputField
    });
  }

  @override
  void dispose() {
    _estadoOrigemController.dispose();
    _estadoDestinoController.dispose();
    _aliqInterstadualController.dispose();
    _aliqInternaDIFALController.dispose();
    _descontoDiferencaICMSRevendaController.dispose();
    _descontoDiferencaICMSOutrosController.dispose();
    _aliqICMSSubstituicaoController.dispose();
    _aliqAbatimentoICMSController.dispose();
    _aliqAbatimentoICMSRevendaController.dispose();
    _aliqAbatimentoICMSConsumidorController.dispose();
    _mvaSTController.dispose();
    _mvaSTImportaController.dispose();
    _ctaContabilSubsTribEntrDebController.dispose();
    _aliqCombatePobrezaController.dispose();
    super.dispose();
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
          mainCompanyId: widget.mainCompanyId, // Repassa o ID da empresa principal
          secondaryCompanyId: widget.secondaryCompanyId, // Repassa o ID da empresa secundária
          userRole: widget.userRole, // Repassa o papel do usuário
        ),
      ),
    );            },
            currentDate: _currentDate,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth > _breakpoint) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: AppDrawer(
                                parentMaxWidth: constraints.maxWidth,
                          breakpoint: 700.0,
                          mainCompanyId: widget.mainCompanyId, // Passa
                          secondaryCompanyId: widget.secondaryCompanyId, // Passa
                          userRole: widget.userRole,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 20.0, bottom: 0.0),
                                    child: Center(
                                      child: Text(
                                        'Estado X Imposto',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildCentralInputArea(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 15.0, bottom: 8.0),
                          child: Center(
                            child: Text(
                              'Estado X Imposto',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        AppDrawer(
                            parentMaxWidth: constraints.maxWidth,
                          breakpoint: 700.0,
                          mainCompanyId: widget.mainCompanyId, // Passa
                          secondaryCompanyId: widget.secondaryCompanyId, // Passa
                          userRole: widget.userRole,),
                        _buildCentralInputArea(),
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

  Widget _buildCentralInputArea() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Container(
          padding: const EdgeInsets.all(0.0), // Remove o padding externo
          decoration: BoxDecoration(
            color: Colors.blue[100],
            border: Border.all(color: Colors.black, width: 1.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          // UM ÚNICO SingleChildScrollView para toda a área de conteúdo que rola
          child: Column( // A coluna que contém todo o conteúdo rolante e fixo
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded( // Este Expanded empurra o conteúdo fixo para baixo
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 15, bottom: 0), // Padding interno para o conteúdo rolante
                  child: Column( // Coluna para organizar todos os elementos que devem rolar
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Linha 1: Estado Origem, Estado Destino
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 90,),
                          Expanded(
                            child: CustomInputField(
                              inputFormatters: [FilteringTextInputFormatter.deny('1',),FilteringTextInputFormatter.deny('2',),
                              FilteringTextInputFormatter.deny('3',),FilteringTextInputFormatter.deny('4',),FilteringTextInputFormatter.deny('5',),
                              FilteringTextInputFormatter.deny('6',),FilteringTextInputFormatter.deny('7',),FilteringTextInputFormatter.deny('8',),
                              FilteringTextInputFormatter.deny('9',),FilteringTextInputFormatter.deny('0',),],
                              controller: _estadoOrigemController,
                              label: 'Estado Origem',
                              maxLength: 2,
                              suffixText: '${_estadoOrigemController.text.length}/2',
                              
                              validator: ufValidator,
                            ),
                          ),
                          
                          const SizedBox(width: 20), // Espaçamento entre H e Estado Destino
                          Expanded(
                            child: CustomInputField(
                              controller: _estadoDestinoController,
                              inputFormatters: [FilteringTextInputFormatter.deny('1',),FilteringTextInputFormatter.deny('2',),
                              FilteringTextInputFormatter.deny('3',),FilteringTextInputFormatter.deny('4',),FilteringTextInputFormatter.deny('5',),
                              FilteringTextInputFormatter.deny('6',),FilteringTextInputFormatter.deny('7',),FilteringTextInputFormatter.deny('8',),
                              FilteringTextInputFormatter.deny('9',),FilteringTextInputFormatter.deny('0',),],
                              label: 'Estado Destino',
                              maxLength: 2,
                              suffixText: '${_estadoDestinoController.text.length}/2',
                              validator: ufValidator,

                            ),
                          ),
                          SizedBox(width: 90,),

                          
                        ],
                      ),
                      const Divider(height: 6, thickness: 2, color: Colors.blue),

                      SizedBox(height: 5,),
                      // Linha que conterá as duas colunas ICMS e ST
                      Padding(
                        padding: const EdgeInsets.only(right: 8,left: 8),
                        child: IntrinsicHeight( // Permite que as colunas dentro do Row tenham a mesma altura
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start, // Alinha o topo das colunas
                            children: [
                              // Coluna ICMS
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: const Text(
                                        'ICMS',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                        
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20, left: 20),
                                      child: CustomInputField(
                                        controller: _aliqCombatePobrezaController,
                                        label: 'Alíquota Combate a Fundo Pobreza',
                                        maxLength: 5,
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                       inputFormatters: [PercentageInputFormatter3Antes(),],
                                       suffixText: '${_aliqCombatePobrezaController.text.length}/5',
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                        
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20, left: 20),
                                      child: CustomInputField(
                                        controller: _aliqInterstadualController,
                                        label: 'Alíquota Interestadual',
                                        maxLength: 5,
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                       inputFormatters: [PercentageInputFormatter3Antes(),],
                                       suffixText: '${_aliqInterstadualController.text.length}/5',
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                        
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20, left: 20),
                                      child: CustomInputField(
                                        controller: _aliqInternaDIFALController,
                                        label: 'Alíquota Interna - DIFAL',
                                        maxLength: 5,
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                       inputFormatters: [PercentageInputFormatter3Antes(),],
                                       suffixText: '${_aliqInternaDIFALController.text.length}/5',
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                        
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20, left: 20),
                                      child: CustomInputField(
                                        controller: _descontoDiferencaICMSRevendaController,
                                        label: 'Desconto Diferença ICMS Revenda',
                                        maxLength: 7,
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                       inputFormatters: [PercentageInputFormatter4CasasDecimais(),],
                                       suffixText: '${_descontoDiferencaICMSRevendaController.text.length}/7',
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                        
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20, left: 20),
                                      child: CustomInputField(
                                        controller: _descontoDiferencaICMSOutrosController,
                                        label: 'Desconto Diferença ICMS Outros',
                                        maxLength: 7,
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                       inputFormatters: [PercentageInputFormatter4CasasDecimais(),],
                                        suffixText: '${_descontoDiferencaICMSOutrosController.text.length}/7',
                                        validator: (value) {
                                          if (value == null || value.isEmpty) return 'Campo obrigatório';
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 10),


                                    Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(255, 153, 205, 248), // Cor de fundo do container de integração
                                                borderRadius: BorderRadius.circular(5),
                                                border: Border.all(color: Colors.blue, width: 2.0),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(6.0), // Padding interno para o conteúdo
                                                child: Row( // <-- Voltando para Row para manter o texto 'Integração' ao lado
                                                  crossAxisAlignment: CrossAxisAlignment.center, // Centraliza verticalmente o conteúdo da Row
                                                  children: [
                                                    Column(
                                                      children: [
                                                        const Text('Cálculo :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                                        const Text('DIFAL :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                                        const Text('Dentro :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                                      ],
                                                    ),
                                                    // Removido SizedBox(width: 16) para compactar mais, você pode ajustar
                                                    Expanded( // <-- O Expanded é importante para dar espaço aos CheckboxListTile
                                                      child: Column( // Column para empilhar os CheckboxListTile
                                                        crossAxisAlignment: CrossAxisAlignment.start, // Alinha os CheckboxListTile à esquerda
                                                        mainAxisAlignment: MainAxisAlignment.center, // Centraliza os checkboxes na coluna
                                                        children: [
                                                          Row(
                                                  children: [
                                                    Checkbox(
                                                      value: _calculoDIFALDentro == true,
                                                      onChanged: (bool? value) {
                                                        setState(() {
                                                          _calculoDIFALDentro = value;
                                                        });
                                                      },
                                                      activeColor: Colors.blue,
                                                    ),
                                                    const Text('Sim', style: TextStyle(color: Colors.black)),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Checkbox(
                                                      value: _calculoDIFALDentro == false,
                                                      onChanged: (bool? value) {
                                                        setState(() {
                                                          _calculoDIFALDentro = !(value ?? false);
                                                        });
                                                      },
                                                      activeColor: Colors.blue,
                                                    ),
                                                    const Text('Não', style: TextStyle(color: Colors.black)),
                                                  ],
                                                ),]
                                                      ),
                                                    ),
                                                    // Texto de integrações selecionadas movido para a direita, ou pode ser removido se não for essencial aqui
                                                    // Padding(
                                                    //   padding: const EdgeInsets.only(left: 8.0),
                                                    //   child: Text(
                                                    //     'Sel: ${_integracaoSelections.join(', ')}',
                                                    //     style: const TextStyle(color: Colors.white, fontSize: 12),
                                                    //   ),
                                                    // ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 250),
                                      ],
                                    ),
                        
                                    const SizedBox(height: 0),
                                  ],
                                ),
                              ),
                        
                              // Divisor Vertical
                              const VerticalDivider(width: 60, thickness: 2, color: Colors.blue),
                        
                              // Coluna ST - Substituição Tributária ICMS
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: const Text(
                                        'ST - Substituição Tributária ICMS',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                        
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20,  left: 20),
                                      child: CustomInputField(
                                        controller: _aliqICMSSubstituicaoController,
                                        label: 'Aliq. ICMS Substituição',
                                        maxLength: 5,
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        suffixText: '${_aliqICMSSubstituicaoController.text.length}/5',
                                         inputFormatters: [PercentageInputFormatter3Antes(),],
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                        
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20,  left: 20),
                                      child: CustomInputField(
                                        controller: _aliqAbatimentoICMSController,
                                        label: 'Aliq. Abatimento ICMS',
                                        maxLength: 5,
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        suffixText: '${_aliqAbatimentoICMSController.text.length}/5',
                                        inputFormatters: [PercentageInputFormatter3Antes(),],   
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                        
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20,  left: 20),
                                      child: CustomInputField(
                                        controller: _aliqAbatimentoICMSRevendaController,
                                        label: 'Aliq. Abatimento ICMS Revenda',
                                        maxLength: 5,
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        suffixText: '${_aliqAbatimentoICMSRevendaController.text.length}/5',
                                        inputFormatters: [PercentageInputFormatter3Antes(),],   
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                        
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20,  left: 20),
                                      child: CustomInputField(
                                        controller: _aliqAbatimentoICMSConsumidorController,
                                        label: 'Aliq. Abatimento ICMS Consumidor',
                                        maxLength: 5,
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        suffixText: '${_aliqAbatimentoICMSConsumidorController.text.length}/5',
                                        inputFormatters: [PercentageInputFormatter3Antes(),],   
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                        
                                    Row( // MVA-St e MVA-St Importa (com H)
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                      padding: const EdgeInsets.only(left: 20, ),
                                            child: CustomInputField(
                                              controller: _mvaSTController,
                                              label: 'MVA-St',
                                              maxLength: 6,
                                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                                              suffixText: '${_mvaSTController.text.length}/5',
                                                                                inputFormatters: [PercentageInputFormatter3Antes(),],   
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: Padding(
                                      padding: const EdgeInsets.only(  right: 20),
                                            child: CustomInputField(
                                              controller: _mvaSTImportaController,
                                              label: 'MVA-St Importa',
                                              maxLength: 6,
                                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                                              suffixText: '${_mvaSTImportaController.text.length}/5',
                                                                                inputFormatters: [PercentageInputFormatter3Antes(),],   
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                        
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20,  left: 20),
                                      child: CustomInputField(
                                        controller: _ctaContabilSubsTribEntrDebController,
                                        label: 'Cta Contabil Subs.Trib.Entr.Deb',
                                        maxLength: 7,
                                        suffixText: '${_ctaContabilSubsTribEntrDebController.text.length}/7',
                                        validator: (value) {
                                          // **VALIDAÇÃO EXTRA AQUI:** Deve ter exatamente 2 caracteres
                                  if (value == null || value.isEmpty) {
                                    return null;
                                  }
                                  // **VALIDAÇÃO EXTRA AQUI:** Deve ter exatamente 2 caracteres
                                  if (value.length != 7) {
                                    return 'A sigla deve ter exatamente 7 caracteres/dígitos.';
                                  }
                                  return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Botões de Ação - nao mais FIXOS na parte inferior da área central
                      Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton('EXCLUIR', Colors.red),
                      const SizedBox(width: 30),
                      _buildActionButton('SALVAR', Colors.green),
                      
                    ],
                  ),
                ),
              ),
              //BottomInfoContainers(tablePath: 'Tabela > Estado X Imposto'),
                    ],
                  ),
                ),
              ),

              // Botões de Ação - FIXOS na parte inferior da área central
              

              // Informações Inferiores - FIXAS na parte inferior da área central
              const SizedBox(height: 0),
              ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
              /// SE QUISER COLOCAR A BARRA INFERIOR FIXA, COLOCA AQUI
              //////////////////////////////////////////////////////////////////////////////////////////////////////////////
              //BottomInfoContainers(tablePath: 'Tabela > Estado X Imposto'),
            ],
          ),
        ),
      ),
    );
  }

  // Novo método auxiliar para construir CustomInputField com o círculo 'H'
  

  // Função auxiliar para construir botões de ação
  Widget _buildActionButton(String text, Color color) {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState?.validate() ?? false) {
          print('Botão $text pressionado. Formulário válido.');
          _printFormValues();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor, corrija os erros nos campos antes de prosseguir.')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(200, 50),
        side: const BorderSide(width: 1.0, color: Colors.black),
        backgroundColor: color,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  void _printFormValues() {
    print('--- Dados do Formulário Estado X Imposto ---');
    print('Estado Origem: ${_estadoOrigemController.text}');
    print('Estado Destino: ${_estadoDestinoController.text}');
    print('Aliq. Interestadual: ${_aliqInterstadualController.text}');
    print('Aliq. Interna - DIFAL: ${_aliqInternaDIFALController.text}');
    print('Desc. Diferença ICMS Revenda: ${_descontoDiferencaICMSRevendaController.text}');
    print('Desc. Diferença ICMS Outros: ${_descontoDiferencaICMSOutrosController.text}');
    print('Cálculo DIFAL Dentro: ${_calculoDIFALDentro == true ? 'Sim' : 'Não'}');
    print('Aliq. ICMS Substituição: ${_aliqICMSSubstituicaoController.text}');
    print('Aliq. Abatimento ICMS: ${_aliqAbatimentoICMSController.text}');
    print('Aliq. Abatimento MS Consumidor: ${_aliqAbatimentoICMSConsumidorController.text}');
    print('MVA-St: ${_mvaSTController.text}');
    print('MVA-St Importa: ${_mvaSTImportaController.text}');
    print('Cta Contabil Subs.Trib.Entr.Deb: ${_ctaContabilSubsTribEntrDebController.text}');
    print('------------------------------------------');
  }
}