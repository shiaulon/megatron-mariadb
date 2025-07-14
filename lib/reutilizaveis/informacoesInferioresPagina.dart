// lib/widgets/bottom_info_containers.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Um widget que exibe informações padronizadas na parte inferior.
/// O texto `tablePath` é requerido e pode ser personalizado por página.
class BottomInfoContainers extends StatelessWidget {
  final String tablePath;

  const BottomInfoContainers({
    Key? key,
    required this.tablePath,
  }) : super(key: key);

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication, // Garante que abra fora do app
    )) {
      // Em um app real, você poderia mostrar um SnackBar com o erro.
      throw 'Não foi possível abrir $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(height: 20), // Espaçamento antes do primeiro container
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.blue, width: 2.0),
              color: const Color.fromARGB(255, 153, 205, 248), // Cor de fundo do container
            ),
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'EGB VALVULAS IND C SERV M I E LTDA',
                        style: TextStyle(color: Colors.black),
                      ),
                      const Text(
                        '99.999.999-0001/99',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tablePath, // Usando o parâmetro passado
                        style: const TextStyle(color: Colors.black),
                      ),
                      const Text(
                        '',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.blue, width: 2.0),
              color: const Color.fromARGB(255, 153, 205, 248), // Cor de fundo do container
            ),
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'RESPONSAVEL: MRAFAEL',
                        style: TextStyle(color: Colors.black),
                      ),
                      const Text(
                        'MEGATRON',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MSG:',
                        style: TextStyle(color: Colors.black),
                      ),
                      const Text(
                        'v1.0.00 00',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}