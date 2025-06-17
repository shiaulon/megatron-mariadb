// lib/widgets/top_app_bar.dart
import 'package:flutter/material.dart';

/// Um widget reutilizável para a barra superior da aplicação.
/// Permite customizar o comportamento do botão de voltar e a data.
class TopAppBar extends StatelessWidget {
  final VoidCallback onBackPressed;
  final String currentDate;
  final String userName; // Parâmetro para o nome do usuário
  final ImageProvider<Object> userAvatar; // Parâmetro para a imagem do avatar

  const TopAppBar({
    Key? key,
    required this.onBackPressed,
    required this.currentDate,
    this.userName = 'MRAFAEL', // Valor padrão, pode ser sobrescrito
    this.userAvatar = const AssetImage('assets/images/user.png'), // Valor padrão
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.lightBlue,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: onBackPressed, // Usa o callback passado
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundImage: userAvatar, // Usa o parâmetro do avatar
                radius: 16,
              ),
              const SizedBox(width: 8),
              Text(
                userName, // Usa o parâmetro do nome de usuário
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Text(
                currentDate, // Usa a data passada
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}