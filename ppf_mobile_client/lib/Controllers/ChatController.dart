import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatController {
  final String serverUrl;
  late WebSocketChannel _channel;

  ChatController(this.serverUrl) {
    _channel =
        WebSocketChannel.connect(Uri.parse(serverUrl)); // Initialize WebSocket
  }

  void getRoomMessages(int roomId, int userId) {
    String randomMessageId = Random().nextInt(922337254).toString();
    debugPrint("Getting messages for room: $roomId from user: $userId");
    _channel.sink.add(jsonEncode({
      "messageId": randomMessageId,
      "command": "GetRoomMessages",
      "content": "",
      "room": "$roomId",
      "sender": "$userId"
    }));
    return;
  }

  void sendMessage(String message, int roomId, int userId) {
    String randomMessageId = Random().nextInt(922337254).toString();
    debugPrint("Sending message: $message to room: $roomId from user: $userId");
    _channel.sink.add(jsonEncode({
      "messageId": randomMessageId,
      "command": "SendMessage",
      "content": message,
      "room": "$roomId",
      "sender": "$userId"
    }));
  }

  Stream<dynamic> get messageStream => _channel.stream;

  void close() {
    _channel.sink.close();
  }
}
