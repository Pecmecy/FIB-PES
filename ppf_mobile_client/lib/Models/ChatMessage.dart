class ChatMessage {
  int senderId;
  String senderName;
  String message;
  DateTime time;

  ChatMessage(this.senderId, this.senderName, this.message, this.time);

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(json['senderId'] as int, json['senderName'] as String,
        json['content'] as String, json['timestamp'] as DateTime);
  }
}
