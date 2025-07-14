import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // IMPORTANTE: Adicione este pacote ao seu pubspec.yaml


class TelaBase extends StatelessWidget {
  final Widget body;

  const TelaBase({Key? key, required this.body}) : super(key: key);

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
    return Scaffold(
      
      backgroundColor: const Color(0xFFE6F4FB),
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/BG.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: body,
      ),
      bottomNavigationBar: Container(
        color: Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:  [
            Row(
              children: [
                
                SizedBox(width: 4),
                InkWell(
              onTap: () => _launchURL('https://megatronrp.com.br'),
              child: const Row(
                children: [
                  Icon(Icons.language, size: 16, color: Colors.black),
                  SizedBox(width: 4),
                  Text(
                    'megatronrp.com.br',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.black),
                SizedBox(width: 4),
                Text(
                  '(16) 3917-1618',
                  style: TextStyle(color: Colors.black, fontSize: 12),
                  selectionColor: Colors.black,
                ),
                SizedBox(width: 45,),
                
                SizedBox(width: 4),
                InkWell(
              onTap: () => _launchURL('https://wa.me/5516997611134'),
              child: const Row(
                children: [
                  CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.phone_in_talk, size: 16, color: Colors.black)),
                  SizedBox(width: 4),
                  Text(
                    'SUPORTE (16) 99761-1134',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.info, size: 16, color: Colors.black),
                SizedBox(width: 4),
                Text(
                  'Direitos reservados (Versão 1.0.0)',
                  style: TextStyle(color: Colors.black, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
