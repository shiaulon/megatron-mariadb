// lib/widgets/custom_input_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para FilteringTextInputFormatter

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
  final TextEditingController controller;
  final String label;
  final String? initialValue;
  final bool readOnly;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final String? suffixText;
  final String? hintText;
  final bool isDense; 
  final Color? fillColor; // <--- Adicione esta linha
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final int? maxLines;
  final int?minLines;
  final void Function(String)? onChanged;

  const CustomInputField({
    Key? key,
    this.onTap, // <--- ADICIONE AQUI NO CONSTRUTOR
    required this.controller,
    required this.label,
    this.initialValue,
    this.readOnly = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.suffixText,
    this.hintText,
    this.isDense = true, // Valor padrão como true, como no seu código
    this.fillColor,
    this.focusNode, // <--- Adicione aqui
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // CORREÇÃO AQUI: Use o operador ?? para garantir um valor não-nulo,
    // ou inicialize o controlador de forma diferente se a intenção for apenas
    // definir o texto uma vez ao criar o widget.
    // A melhor prática para `TextEditingController` em `StatelessWidget`
    // é inicializar seu `text` no construtor do `TextEditingController`
    // se o `initialValue` for uma propriedade do widget.

    // Opção 1: Inicializar o controller no Widget pai e passar ele.
    // Se o controller é criado no pai, você pode fazer:
    // TextEditingController myController = TextEditingController(text: initialValue);
    // Mas como o controller já vem como required, a inicialização deve estar no pai.

    // O problema é que você está tentando ATRIBUIR a `controller.text` dentro do `build`
    // de um `StatelessWidget` quando o `controller` já foi passado.
    // Se a ideia é que o `initialValue` apenas forneça um valor inicial para
    // o `controller` se ele não tiver sido definido externamente,
    // você precisa garantir que essa lógica esteja no código que CRIA o controller.

    // Para resolver o erro de tipo, você pode forçar a conversão para String,
    // mas isso não é seguro se initialValue for realmente null e o campo não aceitar null.
    // controller.text = initialValue!; // Inseguro!

    // Se o controller já tem um valor, e você quer que initialValue o sobrescreva APENAS SE initialValue não for nulo E o controller estiver vazio:
    // Esta é a abordagem mais provável para o seu caso de uso.
    if (initialValue != null && controller.text.isEmpty) {
      controller.text = initialValue!;
    }


    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        onTap: onTap,
        controller: controller,
        focusNode: focusNode,
        readOnly: readOnly,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLength: maxLength,
        textCapitalization: textCapitalization,
        maxLines: maxLines,
        minLines: minLines,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: onChanged,
        decoration: InputDecoration(
          isDense: isDense,
          alignLabelWithHint: true,
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          filled: true,
          fillColor: fillColor ?? Colors.white,
          
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
          counterText: '',
          hintText: hintText,
          suffixText: suffixText,
        ),
        style: const TextStyle(fontSize: 14.0),
      ),
    );
  }
}