// lib/widgets/custom_input_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para FilteringTextInputFormatter
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';

import 'package:flutter_application_1/registroGeral/manut_rg.dart'; // Ajuste o caminho se for diferente


// --- FORMATTERS E VALIDATORS (Movidos para cá) ---

// Custom Formatter para Data (dd/MM/yyyy)
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    String newText = '';
    String cleanedText = text.replaceAll(RegExp(r'\D'), '');

    for (int i = 0; i < cleanedText.length; i++) {
      if (i == 2 || i == 4) {
        newText += '/';
      }
      newText += cleanedText[i];
    }

    if (newText.length > 10) {
      newText = newText.substring(0, 10);
    }

    final newSelectionOffset =
        newValue.selection.baseOffset + newText.length - text.length;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionOffset),
    );
  }
}

// Custom Formatter para CEP (#####-###)
class CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    String newText = '';
    String cleanedText = text.replaceAll(RegExp(r'\D'), '');

    for (int i = 0; i < cleanedText.length; i++) {
      if (i == 5) {
        newText += '-';
      }
      newText += cleanedText[i];
    }

    if (newText.length > 9) {
      newText = newText.substring(0, 9);
    }

    final newSelectionOffset =
        newValue.selection.baseOffset + newText.length - text.length;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionOffset),
    );
  }
}

// Custom Formatter para CNPJ (XX.XXX.XXX/YYYY-ZZ)
class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    String newText = '';
    String cleanedText = text.replaceAll(RegExp(r'\D'), '');

    for (int i = 0; i < cleanedText.length; i++) {
      if (i == 2 || i == 5) {
        newText += '.';
      } else if (i == 8) {
        newText += '/';
      } else if (i == 12) {
        newText += '-';
      }
      newText += cleanedText[i];
    }

    if (newText.length > 18) {
      newText = newText.substring(0, 18);
    }

    final newSelectionOffset =
        newValue.selection.baseOffset + newText.length - text.length;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionOffset),
    );
  }
}

// Custom Formatter para CPF (XXX.XXX.XXX-XX)
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    String newText = '';
    String cleanedText = text.replaceAll(RegExp(r'\D'), '');

    for (int i = 0; i < cleanedText.length; i++) {
      if (i == 3 || i == 6) {
        newText += '.';
      } else if (i == 9) {
        newText += '-';
      }
      newText += cleanedText[i];
    }

    if (newText.length > 14) {
      newText = newText.substring(0, 14);
    }

    final newSelectionOffset =
        newValue.selection.baseOffset + newText.length - text.length;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionOffset),
    );
  }
}

// Validator para CNPJ
String? cnpjValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'O campo CNPJ é obrigatório.';
  }
  String cnpj = value.replaceAll(RegExp(r'\D'), '');

  if (cnpj.length != 14) {
    return 'CNPJ deve ter 14 dígitos.';
  }

  if (RegExp(r'^(\d)\1*$').hasMatch(cnpj)) {
    return 'CNPJ inválido.';
  }

  List<int> numbers = cnpj.split('').map(int.parse).toList();

  int sum = 0;
  List<int> weight1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  for (int i = 0; i < 12; i++) {
    sum += numbers[i] * weight1[i];
  }
  int remainder = sum % 11;
  int dv1 = remainder < 2 ? 0 : 11 - remainder;

  if (dv1 != numbers[12]) {
    return 'CNPJ inválido.';
  }

  sum = 0;
  List<int> weight2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  for (int i = 0; i < 13; i++) {
    sum += numbers[i] * weight2[i];
  }
  remainder = sum % 11;
  int dv2 = remainder < 2 ? 0 : 11 - remainder;

  if (dv2 != numbers[13]) {
    return 'CNPJ inválido.';
  }

  return null;
}

// Validator para CPF
String? cpfValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'O campo CPF é obrigatório.';
  }
  String cpf = value.replaceAll(RegExp(r'\D'), '');

  if (cpf.length != 11) {
    return 'CPF deve ter 11 dígitos.';
  }

  if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) {
    return 'CPF inválido.';
  }

  List<int> numbers = cpf.split('').map(int.parse).toList();

  int sum = 0;
  for (int i = 0; i < 9; i++) {
    sum += numbers[i] * (10 - i);
  }
  int remainder = sum % 11;
  int dv1 = remainder < 2 ? 0 : 11 - remainder;

  if (dv1 != numbers[9]) {
    return 'CPF inválido.';
  }

  sum = 0;
  for (int i = 0; i < 10; i++) {
    sum += numbers[i] * (11 - i);
  }
  remainder = sum % 11;
  int dv2 = remainder < 2 ? 0 : 11 - remainder;

  if (dv2 != numbers[10]) {
    return 'CPF inválido.';
  }

  return null;
}

// Validator para UF
String? ufValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'O campo UF é obrigatório.';
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

// --- FIM DOS FORMATTERS E VALIDATORS ---


/// Um campo de entrada de texto padronizado para uso em formulários.
class CustomInputField extends StatelessWidget {
  // --- Parâmetros Funcionais ---
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onUserInteraction; // Notifica o pai sobre qualquer alteração ou toque

  // --- Parâmetros de Comportamento ---
  final bool readOnly;
  final bool enabled;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  final VoidCallback? onEditingComplete;

  // --- Parâmetros de Estilo (sobrescrevem o tema se fornecidos) ---
  final String label;
  final String? suffixText;
  final String? hintText;
  final bool isDense;
  final Color? fillColor; // Permite sobrescrever a cor de fundo do tema
  final InputDecoration? decoration;

  const CustomInputField({

    this.onEditingComplete,

    Key? key,
    required this.controller,
    required this.label,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onUserInteraction,
    this.readOnly = false,
    this.enabled = true,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.suffixText,
    this.hintText,
    this.isDense = true,
    this.fillColor,

    this.decoration, // Adicionado ao construtor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Pega o tema de decoração de input definido no AppTheme
    final themeInputDecoration = Theme.of(context).inputDecorationTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        
        // --- Conexões Funcionais ---
        controller: controller,
        focusNode: focusNode,
        validator: validator,

        decoration: decoration ?? // Usa a decoração customizada ou a padrão
            InputDecoration(
              counterText: "", // Esconde o contador de caracteres
              labelText: label,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: readOnly ? Colors.grey[200] : Colors.white,
            ),

        onTap: () {
          onTap?.call();
          onUserInteraction?.call();
        },
        onChanged: (value) {
          onChanged?.call(value);
          if (!readOnly) {
            onUserInteraction?.call();
          }
        },

        onEditingComplete: onEditingComplete, // ALTERAÇÃO 3: Adicione esta linha
        
        // --- Comportamento ---
        readOnly: readOnly,
        enabled: enabled,
        maxLength: maxLength,
        maxLines: maxLines,
        minLines: minLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        
        // --- Estilo ---
        style: const TextStyle(fontSize: 14.0),
        /*decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          suffixText: suffixText,
          counterText: '', // Oculta o contador padrão
          
          // Usa a cor do tema, mas permite que seja sobrescrita se 'fillColor' for passado
          fillColor: fillColor, 
          
          // Usa a densidade do tema, mas permite que seja sobrescrita
          isDense: isDense,
          
          // A cor para o estado desabilitado será gerenciada automaticamente pelo tema,
          // que já define uma cor de preenchimento diferente para campos desabilitados.
        ),*/
      ),
    );
  }
}