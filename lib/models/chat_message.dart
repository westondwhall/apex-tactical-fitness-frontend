class ChatMessage {
  final String? id;
  final String text;
  final bool isUser;

  ChatMessage({
    this.id,
    required this.text,
    required this.isUser,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString(),
      // Read 'response' first, with fallbacks if needed
      text: json['response'] ?? json['text'] ?? json['message'] ?? '',
      isUser: json['sender'] == 'user',
    );
  }
}