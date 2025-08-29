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
    // ▼▼▼ CAPTURANDO AS CORES DO TEMA ATIVO ▼▼▼
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // ▼▼▼ 1. VERIFICA QUAL TEMA ESTÁ ATIVO ▼▼▼
    final isDarkMode = theme.brightness == Brightness.dark;

    // ▼▼▼ 2. ESCOLHE A IMAGEM CORRETA COM BASE NO TEMA ▼▼▼
    final String backgroundImage = isDarkMode 
      ? "assets/images/BG_dark.png" // <-- Sua nova imagem para o modo escuro
      : "assets/images/BG.png"; 

    return Scaffold(
      // ANTES: backgroundColor: const Color(0xFFE6F4FB),
      // DEPOIS: Usa a cor de fundo definida no tema
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Container(
        // A imagem de fundo pode ser mantida ou você pode ter uma diferente para o modo escuro
        decoration:  BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: body,
      ),
      bottomNavigationBar: Container(
        // ANTES: color: Colors.blue,
        // DEPOIS: Usa a cor primária do tema
        color: theme.appBarTheme.backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Link do site
            InkWell(
              onTap: () => _launchURL('https://megatronrp.com.br'),
              child: Row(
                children: [
                  // Ícones e textos agora usam a cor 'onPrimary' que contrasta com a cor primária
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
            // Telefones
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
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.green,
                        // ▼▼▼ CORRIGIDO ▼▼▼
                        child: Icon(Icons.phone_in_talk, size: 16, color: Colors.white), // Mantido branco para contraste com o verde
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
            // Direitos Reservados
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
