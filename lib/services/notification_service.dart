// lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NotificationService {
  // --- Padrão Singleton ---
  // Isso garante que sempre teremos a mesma instância desta classe.
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    // Inicializa a _wsUrl aqui dentro do construtor
    _wsUrl = 'ws://$_serverIp:8080/ws';
  }
  // --- Fim do Padrão Singleton ---

  bool _isConnected = false;

  //final String _serverIp = '192.168.1.250';
  final String _serverIp = '10.135.59.5';
   late final String _wsUrl; // Agora será inicializada corretamente

  WebSocketChannel? _channel;
  //final String _wsUrl = 'ws://localhost:8080/ws'; // Use o IP do seu servidor aqui

  // --- Stream para comunicar mensagens para a UI ---
  // A UI vai "ouvir" esta stream para saber quando mostrar um popup.
  
  // --- Fim da Stream ---

  void connect() {
    if (_isConnected && _channel != null) {
      print('WebSocket já está conectado.');
      return;
    }

    try {
      // Esta linha agora vai funcionar
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _isConnected = true;
      print('CONECTADO ao servidor de notificações em: $_wsUrl');

      _channel?.stream.listen(
        (message) {
          print('MENSAGEM RECEBIDA: $message'); // Bom para depuração
          showGlobalNotificationPopup(message);
        },
        onDone: () {
          _isConnected = false;
          print('DESCONECTADO. Tentando reconectar em 5 segundos...');
          Future.delayed(const Duration(seconds: 5), () => connect());
        },
        onError: (error) {
          _isConnected = false;
          print('ERRO no WebSocket: $error. Tentando reconectar em 5 segundos...');
          Future.delayed(const Duration(seconds: 5), () => connect());
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('Erro ao tentar conectar ao WebSocket: $e');
      _isConnected = false;
      // Adiciona uma tentativa de reconexão também em caso de falha na conexão inicial
      Future.delayed(const Duration(seconds: 5), () => connect());
    }
  }

  void dispose() {
    _channel?.sink.close();
    _isConnected = false;
    print('Conexão WebSocket fechada.');
  }
}

  // Função para mostrar o popup de forma global
void showGlobalNotificationPopup(String message) {
  // Usa a GlobalKey para obter o contexto atual do navegador
  final BuildContext? context = navigatorKey.currentContext;

  if (context != null) {
    showDialog(
      context: context,
      // PASSO 2 DA SOLUÇÃO: Impede o fechamento ao clicar fora
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 10),
              Text('Aviso do Sistema'),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

}