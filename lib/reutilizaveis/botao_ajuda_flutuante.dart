// lib/reutilizaveis/botao_ajuda_flutuante.dart

import 'package:flutter/material.dart';

class BotaoAjudaFlutuante extends StatefulWidget {
  final Widget child;
  final Widget helpContent;

  const BotaoAjudaFlutuante({
    Key? key,
    required this.child,
    required this.helpContent,
  }) : super(key: key);

  @override
  _BotaoAjudaFlutuanteState createState() => _BotaoAjudaFlutuanteState();
}

class _BotaoAjudaFlutuanteState extends State<BotaoAjudaFlutuante> {
  OverlayEntry? _overlayEntry;
  // REMOVIDO: final LayerLink _layerLink = LayerLink();

  void _showHelpPopup() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideHelpPopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTap: _hideHelpPopup,
          behavior: HitTestBehavior.opaque,
          // MUDANÇA AQUI: Trocamos o Stack+Follower por um simples Center
          child: Center(
            child: Material(
              elevation: 6.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500), // Aumentei um pouco o tamanho
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: widget.helpContent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _hideHelpPopup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            // REMOVIDO: O `CompositedTransformTarget` não é mais necessário
            child: FloatingActionButton(
              mini: true,
              tooltip: 'Dúvidas?',
              onPressed: () {
                if (_overlayEntry == null) {
                  _showHelpPopup();
                } else {
                  _hideHelpPopup();
                }
              },
              child: const Icon(Icons.question_mark_rounded),
            ),
          ),
        ),
      ],
    );
  }
}