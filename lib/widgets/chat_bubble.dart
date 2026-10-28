import 'package:flutter/material.dart';

class ChatMessage {
  final String text;
  final bool fromUser;
  ChatMessage(this.text, this.fromUser);
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;
    final color = isUser ? const Color(0xFFE8FDFF) : const Color(0xFF35E4E0);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.white.withValues(alpha: 0.06)
              : color.withValues(alpha: 0.08),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 14),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white70 : color,
            fontFamily: 'monospace',
            fontSize: 14.5,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
