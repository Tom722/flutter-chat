import 'package:flutter/material.dart';

import 'package:flutter_tts/flutter_tts.dart';

import '../models/chat_message.dart';

import 'package:flutter_markdown/flutter_markdown.dart';

import '../pallete.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;

  final bool isTyping;

  const ChatBubble({
    Key? key,
    required this.message,
    this.isTyping = false,
  }) : super(key: key);

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  final FlutterTts flutterTts = FlutterTts();

  bool isPlaying = false;

  @override
  void initState() {
    super.initState();

    flutterTts.setLanguage("zh-CN");

    // 设置语速

    flutterTts.setSpeechRate(2.5);

    // 设置音调

    flutterTts.setPitch(1.0);

    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          isPlaying = false;
        });
      }
    });

    flutterTts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          isPlaying = false;
        });
      }
    });

    flutterTts.setErrorHandler((error) {
      if (mounted) {
        setState(() {
          isPlaying = false;
        });
      }
    });
  }

  Future<void> _handlePlayStop() async {
    if (isPlaying) {
      // 如果正在播放，则停止

      await flutterTts.stop();

      if (mounted) {
        setState(() {
          isPlaying = false;
        });
      }
    } else {
      // 如果未播放，则开始播放

      if (mounted) {
        setState(() {
          isPlaying = true;
        });
      }

      try {
        await flutterTts.speak(widget.message.text);
      } catch (e) {
        print('TTS Error: $e');

        if (mounted) {
          setState(() {
            isPlaying = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.message.isUserMessage
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: widget.message.isUserMessage
              ? Pallete.firstSuggestionBoxColor
              : Pallete.assistantCircleColor,
          borderRadius: BorderRadius.circular(15).copyWith(
            bottomRight: widget.message.isUserMessage ? Radius.zero : null,
            bottomLeft: !widget.message.isUserMessage ? Radius.zero : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.message.isUserMessage
                ? Text(
                    widget.message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  )
                : MarkdownBody(
                    data: widget.message.text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      code: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 14,
                        height: 1.5,
                        backgroundColor: Colors.transparent,
                      ),
                      codeblockPadding: const EdgeInsets.all(16),
                      codeblockDecoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      blockquote: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.grey[300]!,
                            width: 4,
                          ),
                        ),
                      ),
                      listBullet: const TextStyle(color: Colors.black87),
                    ),
                  ),
            if (!widget.message.isUserMessage && !widget.isTyping) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.stop_circle : Icons.play_circle,
                      color: Colors.black87,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: _handlePlayStop,
                  ),
                  if (isPlaying)
                    Text(
                      '正在播放...',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();

    super.dispose();
  }
}
