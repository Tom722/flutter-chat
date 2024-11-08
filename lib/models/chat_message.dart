class ChatMessage {
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;
  final bool isMarkdown;

  ChatMessage({
    required this.text,
    required this.isUserMessage,
    DateTime? timestamp,
    this.isMarkdown = true,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUserMessage': isUserMessage,
        'timestamp': timestamp.toIso8601String(),
        'isMarkdown': isMarkdown,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'],
        isUserMessage: json['isUserMessage'],
        timestamp: DateTime.parse(json['timestamp']),
        isMarkdown: json['isMarkdown'],
      );
}
