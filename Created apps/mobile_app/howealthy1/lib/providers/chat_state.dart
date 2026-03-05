import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chat message model.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// Chat messages state notifier.
class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]);

  void addMessage(String text, {required bool isUser}) {
    // Keep max 40 messages (20 turns) to manage memory
    if (state.length >= 40) {
      state = state.sublist(2); // Remove oldest pair
    }
    state = [
      ...state,
      ChatMessage(text: text, isUser: isUser, timestamp: DateTime.now())
    ];
  }

  void clear() {
    state = [];
  }
}

/// Chat messages provider.
final chatMessagesProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>(
        (ref) => ChatNotifier());

/// Chat loading state.
final chatLoadingProvider = StateProvider<bool>((ref) => false);
