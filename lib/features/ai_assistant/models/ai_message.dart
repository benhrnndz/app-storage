// lib/features/ai_assistant/models/ai_message.dart

/// Represents a single conversational message between the student and the AI Academic Assistant.
class AiMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? suggestedActions;

  const AiMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestedActions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'suggestedActions': suggestedActions,
    };
  }

  factory AiMessage.fromMap(Map<String, dynamic> map) {
    return AiMessage(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      suggestedActions: map['suggestedActions'] != null
          ? List<String>.from(map['suggestedActions'])
          : null,
    );
  }
}

