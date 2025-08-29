import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart';

// Mapeamento de códigos IBGE para estados
const Map<String, String> ibgePrefixToState = {
  '11': 'RO', // Rondônia
  '12': 'AC', // Acre
  '13': 'AM', // Amazonas
  '14': 'RR', // Roraima
  '15': 'PA', // Pará
  '16': 'AP', // Amapá
  '17': 'TO', // Tocantins
  '21': 'MA', // Maranhão
  '22': 'PI', // Piauí
  '23': 'CE', // Ceará
  '24': 'RN', // Rio Grande do Norte
  '25': 'PB', // Paraíba
  '26': 'PE', // Pernambuco
  '27': 'AL', // Alagoas
  '28': 'SE', // Sergipe
  '29': 'BA', // Bahia
  '31': 'MG', // Minas Gerais
  '32': 'ES', // Espírito Santo
  '33': 'RJ', // Rio de Janeiro
  '35': 'SP', // São Paulo
  '41': 'PR', // Paraná
  '42': 'SC', // Santa Catarina
  '43': 'RS', // Rio Grande do Sul
  '50': 'MS', // Mato Grosso do Sul
  '51': 'MT', // Mato Grosso
  '52': 'GO', // Goiás
  '53': 'DF', // Distrito Federal
};


class TabelaIBGEXCidade extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole; // Se precisar usar a permissão aqui também

  const TabelaIBGEXCidade({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<TabelaIBGEXCidade> createState() => _TabelaIBGEXCidadeState();
}

class _TabelaIBGEXCidadeState extends State<TabelaIBGEXCidade> {
  static const double _breakpoint = 700.0;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String _currentDate;

  final TextEditingController _dataAtualController = TextEditingController();
  final TextEditingController _ibgeController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _nomeEstadoController = TextEditingController();
  final TextEditingController _nomeCidadeController = TextEditingController();
  final TextEditingController _ufController = TextEditingController();

  String? _integracaoSelection;
  String? _nrgRgErpSelection;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    _ibgeController.addListener(_onIbgeChanged); // ADICIONA O LISTENER AQUI
    _ibgeController.addListener(_updateEmpresaCounter); // Mantém o listener existente
    _nomeCidadeController.addListener(_updateEmpresaCounter);
    _nomeEstadoController.addListener(_updateEmpresaCounter);
    _ufController.addListener(_updateEmpresaCounter);
    _estadoController.addListener(_updateEmpresaCounter);
  }

  // NOVO MÉTODO: Lógica para preencher o estado
  void _onIbgeChanged() {
    final String ibgeText = _ibgeController.text.trim();
    if (ibgeText.length >= 2) {
      final String prefix = ibgeText.substring(0, 2);
      final String? state = ibgePrefixToState[prefix];
      if (state != null) {
        // Usa setState para atualizar o campo de estado
        setState(() {
          _estadoController.text = state;
          //_ufController.text = state; // Também preenche a UF, se for o mesmo conceito
        });
      } else {
        // Se o prefixo não for encontrado, limpa o campo de estado
        setState(() {
          _estadoController.clear();
          _ufController.clear();
        });
      }
    } else {
      // Se o IBGE tiver menos de 2 dígitos, limpa o campo de estado
      setState(() {
        _estadoController.clear();
        _ufController.clear();
      });
    }
  }

  void _updateEmpresaCounter() {
    setState(() {});
  }

  @override
  void dispose() {
    _ibgeController.removeListener(_onIbgeChanged); // REMOVE O LISTENER
    _ibgeController.removeListener(_updateEmpresaCounter); // Remove o listener existente

    _dataAtualController.dispose();
    _ibgeController.dispose();
    _nomeCidadeController.dispose();
    _ufController.dispose();
    _nomeEstadoController.dispose();
    _estadoController.dispose();

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
    );
            },
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
                              child: AppDrawer(parentMaxWidth: constraints.maxWidth,
                          breakpoint: 700.0,
                          mainCompanyId: widget.mainCompanyId, // Passa
                          secondaryCompanyId: widget.secondaryCompanyId, // Passa
                          //userRole: widget.userRole,
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
                                        'IBGE X Estado',
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
                              'IBGE X Estado',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        AppDrawer(parentMaxWidth: constraints.maxWidth,
                          breakpoint: 700.0,
                          mainCompanyId: widget.mainCompanyId, // Passa
                          secondaryCompanyId: widget.secondaryCompanyId, // Passa
                          //userRole: widget.userRole,
                          ),
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

  @override
  Widget _buildCentralInputArea() {
    final theme = Theme.of(context); // Pega o tema
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Container(
          padding: const EdgeInsets.all(0.0),
          decoration: BoxDecoration(
             color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: theme.colorScheme.primary, width: 1.0),
                  ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40,),
                      Padding(
                        padding: const EdgeInsets.only(left: 25, right: 25),
                        child: Row(
                          children: [
                            const SizedBox(width: 150,),
                            Expanded(
                              child: CustomInputField(
                                controller: _ibgeController,
                                label: 'IBGE',
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                maxLength: 7,
                                keyboardType: TextInputType.number,
                                suffixText: '${_ibgeController.text.length}/7',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return null;
                                  }
                                  if (value.length != 7) {
                                    return 'O código IBGE deve ter 7 dígitos.'; // Mensagem de erro mais clara
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 150,),
                          ],
                        ),
                      ),
                      const SizedBox(height: 0),
                      Padding(
                        padding: const EdgeInsets.only(left: 25, right: 25),
                        child: Row(
                          children: [
                            const SizedBox(width: 150,),
                            Expanded(
                              child: CustomInputField(
                                controller: _estadoController,
                                label: 'Estado',
                                // Este campo deve ser readOnly para ser preenchido automaticamente
                                readOnly: true, // Torna o campo somente leitura
                                //fillColor: Colors.grey[200], // Altera a cor de fundo para indicar que é somente leitura
                                inputFormatters: [
                                  // Remover inputFormatters de negação de números, pois o campo será somente leitura
                                  // ou manter se você quiser permitir digitação manual caso a lógica automática falhe,
                                  // mas para preenchimento automático, geralmente é readOnly.
                                ],
                                maxLength: 2,
                                suffixText: '${_estadoController.text.length}/2',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Campo preenchido automaticamente'; // Adapte a mensagem de validação
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 150,),
                          ],
                        ),
                      ),
                      const SizedBox(height: 0,),
                      Padding(
                        padding: const EdgeInsets.only(left: 25, right: 25),
                        child: Row(
                          children: [
                            const SizedBox(width: 150,),
                            Expanded(
                              child: CustomInputField(
                                controller: _nomeEstadoController,
                                label: 'Nome Estado',
                                inputFormatters: [],
                                maxLength: 25,
                                suffixText: '${_nomeEstadoController.text.length}/25',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Campo obrigatório';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 150,),
                          ],
                        ),
                      ),
                      const SizedBox(height: 0,),
                      Padding(
                        padding: const EdgeInsets.only(left: 25, right: 25),
                        child: Row(
                          children: [
                            const SizedBox(width: 150,),
                            Expanded(
                              child: CustomInputField(
                                controller: _nomeCidadeController,
                                label: 'Nome Cidade',
                                maxLength: 40,
                                suffixText: '${_nomeCidadeController.text.length}/40',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Campo obrigatório';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 150,),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 25, right: 25),
                        child: Row(
                          children: [
                            const SizedBox(width: 150,),
                            Expanded(
                              child: CustomInputField(
                                controller: _ufController,
                                label: 'UF',
                                
                                inputFormatters: [
                                  // Manter esta validação se for somente leitura, mas sem os FilteringTextInputFormatter.deny
                                  // A validação agora deve vir da lógica de preenchimento ou ser removida se o campo for sempre preenchido.
                                ],
                                maxLength: 2,
                                suffixText: '${_ufController.text.length}/2',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Campo preenchido automaticamente'; // Adapte a mensagem de validação
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 150,),
                          ],
                        ),
                      ),

                      const SizedBox(height: 45),

                      // Restante dos campos e botões...
                    ],
                  ),
                ),
              ),
              Center(
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              print('--- Dados Salvos ---');
                              print('Data Atual: ${_dataAtualController.text}');
                              print('IBGE: ${_ibgeController.text}');
                              print('Estado: ${_estadoController.text}');
                              print('Nome Estado: ${_nomeEstadoController.text}');
                              print('Nome Cidade: ${_nomeCidadeController.text}');
                              print('UF: ${_ufController.text}');
                              print('Integração: ${_integracaoSelection ?? 'Nenhum selecionado'}');
                              print('Nrg RG ERP: ${_nrgRgErpSelection ?? 'Nenhum selecionado'}');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Por favor, corrija os erros nos campos antes de salvar.'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            fixedSize: const Size(200, 50),
                            side: const BorderSide(
                              width: 1.0,
                              color: Colors.black,
                            ),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: const Text('EXCLUIR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 30),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              print('--- Dados Salvos ---');
                              print('Data Atual: ${_dataAtualController.text}');
                              print('IBGE: ${_ibgeController.text}');
                              print('Estado: ${_estadoController.text}');
                              print('Nome Estado: ${_nomeEstadoController.text}');
                              print('Nome Cidade: ${_nomeCidadeController.text}');
                              print('UF: ${_ufController.text}');
                              print('Integração: ${_integracaoSelection ?? 'Nenhum selecionado'}');
                              print('Nrg RG ERP: ${_nrgRgErpSelection ?? 'Nenhum selecionado'}');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Por favor, corrija os erros nos campos antes de salvar.'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            fixedSize: const Size(200, 50),
                            side: const BorderSide(
                              width: 1.0,
                              color: Colors.black,
                            ),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: const Text('SALVAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 30),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              print('--- Dados Salvos ---');
                              print('Data Atual: ${_dataAtualController.text}');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Por favor, corrija os erros nos campos antes de salvar.'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            fixedSize: const Size(200, 50),
                            side: const BorderSide(
                              width: 1.0,
                              color: Colors.black,
                            ),
                            backgroundColor: Colors.yellow,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: const Text('RELATÓRIO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}