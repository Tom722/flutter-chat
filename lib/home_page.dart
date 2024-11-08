import 'package:allen/pallete.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import 'models/conversation.dart';
import 'services/storage_service.dart';
import 'services/chat_service.dart';
import 'models/chat_message.dart';
import 'models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<ChatMessage> messages = [];
  bool _isLoading = false;
  bool _isVoiceMode = true;
  bool _isListeningPressed = false;
  String _currentVoiceText = '';
  late StorageService _storageService;
  late SharedPreferences _prefs;
  late Conversation _currentConversation;
  List<Conversation> _conversations = [];

  @override
  void initState() {
    super.initState();
    _initializeStorage();
    initSpeechToText();
    _initTts();
  }

  Future<void> _initializeStorage() async {
    _prefs = await SharedPreferences.getInstance();
    _storageService = StorageService(_prefs);
    _conversations = await _storageService.getConversations();
    if (_conversations.isEmpty) {
      _createNewConversation();
    } else {
      _currentConversation = _conversations.first;
      setState(() {
        messages = _currentConversation.messages;
      });
    }
  }

  Future<void> _createNewConversation() async {
    final newConversation = Conversation(
      id: const Uuid().v4(),
      title: '新会话 ${_conversations.length + 1}',
      createdAt: DateTime.now(),
      messages: [],
    );

    await _storageService.addConversation(newConversation);
    setState(() {
      _conversations.insert(0, newConversation);
      _currentConversation = newConversation;
      messages = [];
    });
  }

  Future<void> _updateCurrentConversation() async {
    _currentConversation = Conversation(
      id: _currentConversation.id,
      title: _currentConversation.title,
      createdAt: _currentConversation.createdAt,
      messages: messages,
    );
    await _storageService.updateConversation(_currentConversation);
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
        // 设置语速
        await flutterTts.setSpeechRate(3);
        // 音调
        await flutterTts.setPitch(0.8);
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
      await _updateCurrentConversation();
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
      await _updateCurrentConversation();
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

  AppBar _buildAppBar() {
    return AppBar(
      title: BounceInDown(
        child: const Text('快际新云'),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Pallete.firstSuggestionBoxColor,
            ),
            child: const Center(
              child: Text(
                '会话列表',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('新建会话'),
            onTap: () {
              _createNewConversation();
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final conversation = _conversations[index];
                return ListTile(
                  leading: const Icon(Icons.chat),
                  title: Text(conversation.title),
                  subtitle: Text(
                    conversation.messages.isEmpty
                        ? '暂无消息'
                        : conversation.messages.last.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: _currentConversation.id == conversation.id,
                  onTap: () {
                    setState(() {
                      _currentConversation = conversation;
                      messages = conversation.messages;
                    });
                    Navigator.pop(context);
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await _storageService.deleteConversation(conversation.id);
                      setState(() {
                        _conversations.removeAt(index);
                        if (_currentConversation.id == conversation.id) {
                          if (_conversations.isEmpty) {
                            _createNewConversation();
                          } else {
                            _currentConversation = _conversations.first;
                            messages = _currentConversation.messages;
                          }
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const Spacer(),
          const Divider(height: 1),
          FutureBuilder<User?>(
            future: StorageService.getUser(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Pallete.firstSuggestionBoxColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              snapshot.data!.username[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snapshot.data!.username,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '在线',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('确认退出'),
                            content: const Text('您确定要退出登录吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  '退出',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && context.mounted) {
                          await StorageService.clearUser();
                          Navigator.of(context).pushReplacementNamed('/login');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout,
                              color: Colors.red[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '退出登录',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(context),
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
                          '你好！我是你的快际新云AI助手，请问有什么可以帮你的吗？',
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
