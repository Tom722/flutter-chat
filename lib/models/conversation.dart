import 'chat_message.dart';

class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<ChatMessage> messages;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'messages': messages.map((msg) => msg.toJson()).toList(),
      };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'],
        title: json['title'],
        createdAt: DateTime.parse(json['createdAt']),
        messages: (json['messages'] as List)
            .map((msg) => ChatMessage.fromJson(msg))
            .toList(),
      );
} 