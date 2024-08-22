import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ppf_mobile_client/Controllers/ChatController.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:ppf_mobile_client/Models/ChatModels.dart';
import 'package:ppf_mobile_client/Models/Users.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/config.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  final int routeId;
  const ChatScreen({
    super.key,
    required this.userId,
    required this.routeId,
  });

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  List<dynamic> messages = [];
  final TextEditingController _messageController = TextEditingController();
  late ScrollController _scrollController;
  late ChatController _chatController;
  late String hintMessage;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    initChatController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    hintMessage = translation(context).mensaje;
  }

  void initChatController() async {
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'token');
    _chatController =
        ChatController('$chatAPI/connect/${widget.userId}?token=$token');
    _chatController.messageStream.listen((message) {
      try {
        dynamic messageMap = jsonDecode(message);
        if (messageMap['command'] == "GetRoomMessages") {
          debugPrint("Received messages for room: ${widget.routeId}");
          List<dynamic> messagesJson = messageMap["content"];
          debugPrint("Messages: $messagesJson");
          setState(() {
            messages.addAll(messagesJson);
          });
          debugPrint("Messages: $messages");
        }
        if (messageMap['sender'] != '${widget.userId}') {
          debugPrint("Received message from user: ${messageMap['sender']}");
          setState(() {
            messages.add(messageMap);
          });
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    });
    _chatController.getRoomMessages(widget.routeId, widget.userId);
  }

  @override
  void dispose() {
    _chatController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: Theme.of(context).colorScheme.primary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              // Acción cuando se presiona el botón de perfil
            },
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                dynamic message = messages[index];
                if (message['sender'] == "${widget.userId}") {
                  return OutBubble(message: message['content']);
                } else {
                  return FutureBuilder<String>(
                    future: getUserName(message['sender']),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return InBubble(
                          message: message['content'],
                          sender: snapshot.data!,
                        );
                      }
                      return const SizedBox();
                    },
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Container(
            decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow,
                    blurRadius: 10.0,
                  ),
                ],
                borderRadius: BorderRadius.circular(20.0),
                color: Theme.of(context).colorScheme.background),
            child: TextField(
              controller: _messageController,
              autofocus: false,
              style: const TextStyle(fontSize: 18.0),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: hintMessage,
                hintStyle: TextStyle(
                  fontSize: 18.0,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.normal,
                ),
                contentPadding:
                    const EdgeInsets.only(left: 14.0, bottom: 8.0, top: 8.0),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.background,
                    width: 0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.background,
                    width: 0,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.black),
                  onPressed: _sendMessage,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> getUserName(String sender) async {
    User? user = await userController.getUserInformation(int.parse(sender));
    return user?.username ?? translation(context).unknownUser;
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;
    String message = _messageController.text;
    dynamic messageMap = {"content": message, "sender": "${widget.userId}"};
    setState(() {
      messages.add(messageMap);
    });
    _chatController.sendMessage(message, widget.routeId, widget.userId);
    _messageController.clear();
  }
}
