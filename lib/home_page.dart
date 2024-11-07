import 'package:allen/feature_box.dart';
import 'package:allen/openai_service.dart';
import 'package:allen/pallete.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ChatMessage {
  final String text;
  final bool isUserMessage;

  ChatMessage({
    required this.text,
    required this.isUserMessage,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final speechToText = SpeechToText();
  final flutterTts = FlutterTts();
  String lastWords = '';
  final OpenAIService openAIService = OpenAIService();
  String? generatedContent;
  String? generatedImageUrl;
  int start = 200;
  int delay = 200;
  final TextEditingController _messageController = TextEditingController();
  String currentStreamedContent = '';
  final List<ChatMessage> messages = [];
  bool _isLoading = false;
  bool _isVoiceMode = true;
  bool _isListeningPressed = false;
  String _currentVoiceText = '';

  @override
  void initState() {
    super.initState();
    initSpeechToText();
    _initTts();
  }

  Future<void> _initTts() async {
    if (!kIsWeb) {
      await flutterTts.setSharedInstance(true);
    }
    setState(() {});
  }

  Future<void> initSpeechToText() async {
    await speechToText.initialize();
    setState(() {});
  }

  Future<void> startListening() async {
    await speechToText.listen(onResult: onSpeechResult);
    setState(() {});
  }

  Future<void> stopListening() async {
    await speechToText.stop();
    setState(() {});
  }

  Future<void> onSpeechResult(SpeechRecognitionResult result) async {
    setState(() {
      lastWords = result.recognizedWords;
      _currentVoiceText = result.recognizedWords;
    });
  }

  Future<void> systemSpeak(String content) async {
    try {
      if (kIsWeb) {
        await flutterTts.speak(content);
      } else {
        await flutterTts.setSharedInstance(true);
        await flutterTts.speak(content);
      }
    } catch (e) {
      print('TTS Error: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    String userMessage = _messageController.text;
    _messageController.clear();

    setState(() {
      messages.add(ChatMessage(
        text: userMessage,
        isUserMessage: true,
      ));
      currentStreamedContent = '';
      _isLoading = true;
    });

    try {
      String fullResponse = '';
      bool isFirstChunk = true;
      await for (final chunk in openAIService.chatGPTAPI(userMessage)) {
        setState(() {
          fullResponse += chunk;
          if (isFirstChunk) {
            messages.add(ChatMessage(
              text: fullResponse,
              isUserMessage: false,
            ));
            isFirstChunk = false;
          } else {
            messages.last = ChatMessage(
              text: fullResponse,
              isUserMessage: false,
            );
          }
        });
      }
      await systemSpeak(fullResponse);
    } catch (e) {
      setState(() {
        messages.add(ChatMessage(
          text: '抱歉，出现了一些错误：$e',
          isUserMessage: false,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processAIResponse(String userInput) async {
    try {
      String fullResponse = '';
      bool isFirstChunk = true;
      await for (final chunk in openAIService.chatGPTAPI(userInput)) {
        setState(() {
          fullResponse += chunk;
          if (isFirstChunk) {
            messages.add(ChatMessage(
              text: fullResponse,
              isUserMessage: false,
            ));
            isFirstChunk = false;
          } else {
            messages.last = ChatMessage(
              text: fullResponse,
              isUserMessage: false,
            );
          }
        });
      }
      await systemSpeak(fullResponse);
    } catch (e) {
      setState(() {
        messages.add(ChatMessage(
          text: '抱歉，出现了一些错误：$e',
          isUserMessage: false,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    speechToText.stop();
    flutterTts.stop();
    _messageController.dispose();
  }

  Widget _buildBottomInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _isVoiceMode
                ? GestureDetector(
                    onLongPressStart: (_) async {
                      setState(() {
                        _isListeningPressed = true;
                        _currentVoiceText = '';
                      });
                      await startListening();
                    },
                    onLongPressEnd: (_) async {
                      setState(() => _isListeningPressed = false);
                      await stopListening();
                      
                      final finalVoiceText = _currentVoiceText;
                      if (finalVoiceText.isNotEmpty) {
                        setState(() {
                          messages.add(ChatMessage(
                            text: finalVoiceText,
                            isUserMessage: true,
                          ));
                          _isLoading = true;
                        });
                        await _processAIResponse(finalVoiceText);
                      }
                      
                      setState(() {
                        _currentVoiceText = '';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        _isListeningPressed
                            ? (_currentVoiceText.isEmpty
                                ? '正在聆听...'
                                : _currentVoiceText)
                            : '按住说话',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isListeningPressed
                              ? Pallete.firstSuggestionBoxColor
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  )
                : TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '输入消息...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _isVoiceMode ? Icons.keyboard : Icons.mic,
              color: Pallete.firstSuggestionBoxColor,
            ),
            onPressed: () {
              setState(() => _isVoiceMode = !_isVoiceMode);
            },
          ),
          if (!_isVoiceMode)
            IconButton(
              icon: const Icon(
                Icons.send,
                color: Pallete.firstSuggestionBoxColor,
              ),
              onPressed: _sendMessage,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BounceInDown(
          child: const Text('AI Assistant'),
        ),
        leading: const Icon(Icons.menu),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.isEmpty ? 1 : messages.length,
              itemBuilder: (context, index) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ZoomIn(
                          child: Stack(
                            children: [
                              Center(
                                child: Container(
                                  height: 120,
                                  width: 120,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: const BoxDecoration(
                                    color: Pallete.assistantCircleColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Container(
                                height: 123,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: AssetImage(
                                      'assets/images/virtualAssistant.png',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '你好！我是你的AI助手，请问有什么可以帮你的吗？',
                          style: TextStyle(
                            fontSize: 20,
                            color: Pallete.mainFontColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final message = messages[index];
                return Column(
                  children: [
                    Align(
                      alignment: message.isUserMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: message.isUserMessage
                              ? Pallete.firstSuggestionBoxColor
                              : Pallete.assistantCircleColor,
                          borderRadius: BorderRadius.circular(15).copyWith(
                            bottomRight:
                                message.isUserMessage ? Radius.zero : null,
                            bottomLeft:
                                !message.isUserMessage ? Radius.zero : null,
                          ),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: message.isUserMessage
                                ? Colors.white
                                : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    if (_isLoading &&
                        index == messages.length - 1 &&
                        message.isUserMessage)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Pallete.firstSuggestionBoxColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '正在思考中...',
                                style: TextStyle(
                                  color: Pallete.mainFontColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          _buildBottomInput(),
        ],
      ),
    );
  }
}
