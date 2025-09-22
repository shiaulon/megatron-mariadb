// lib/reutilizaveis/tela_base.dart

import 'dart:async'; // <-- IMPORTANTE
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_1/services/notification_service.dart';

class TelaBase extends StatefulWidget {
  final Widget body;
  const TelaBase({Key? key, required this.body}) : super(key: key);

  @override
  State<TelaBase> createState() => _TelaBaseState();
}

class _TelaBaseState extends State<TelaBase> {
  

  @override
  void initState() {
    super.initState();
    // Inicia a conexão (só vai conectar de fato na primeira vez).
   // _notificationService.connect();

    
  }

  @override
  void dispose() {
    // Cancela a inscrição para evitar vazamentos de memória.
   
    super.dispose();
  }

  

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Não foi possível abrir $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final String backgroundImage = isDarkMode 
      ? "assets/images/BG_dark.png"
      : "assets/images/BG.png"; 

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration:  BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: widget.body,
      ),
      bottomNavigationBar: Container(
        color: theme.appBarTheme.backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // ... (seu Row com os links e telefones continua aqui, sem alterações)
           children: [
            InkWell(
              onTap: () => _launchURL('https://megatronrp.com.br'),
              child: Row(
                children: [
                  Icon(Icons.language, size: 16, color: theme.appBarTheme.titleTextStyle?.color),
                  const SizedBox(width: 4),
                  Text(
                    'megatronrp.com.br',
                    style: theme.appBarTheme.titleTextStyle?.copyWith(
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: theme.appBarTheme.titleTextStyle?.color),
                const SizedBox(width: 4),
                Text(
                  '(16) 3917-1618',
                  style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 12),
                ),
                const SizedBox(width: 45),
                InkWell(
                  onTap: () => _launchURL('https://wa.me/5516997611134'),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.green,
                        child: Icon(Icons.phone_in_talk, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SUPORTE (16) 99761-1134',
                        style: theme.appBarTheme.titleTextStyle?.copyWith(
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
                Icon(Icons.info, size: 16, color: theme.appBarTheme.titleTextStyle?.color),
                const SizedBox(width: 4),
                Text(
                  'Direitos reservados (Versão 1.0.0)',
                  style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}