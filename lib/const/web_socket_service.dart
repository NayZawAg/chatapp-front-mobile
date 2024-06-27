
import 'dart:convert';

import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';


class WebsocketService {
  WebSocketChannel? _channel;

  WebSocketChannel? get getChannel{
    return _channel;
  }

  void connectToWebsocket(int userId, String channelName) async {
    var url = 'ws://127.0.0.1:3000/cable?user_id=$userId';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    var subscriptionMessage = jsonEncode({
      'command': 'subscribe',
      'identifier': jsonEncode({'channel': channelName})
    });

    _channel!.sink.add((subscriptionMessage));
  }

  void sendMessageToWs(Map<String, dynamic> message) {
      if (_channel !=null) {
          final jsonMessage = jsonEncode(message);
          _channel!.sink.add(jsonMessage);
      }
  }

  void disconnectWs(){
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
  }
}
