import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation.dart';

class StorageService {
  static const String _conversationsKey = 'conversations';
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  Future<List<Conversation>> getConversations() async {
    final String? data = _prefs.getString(_conversationsKey);
    if (data == null) return [];

    List<dynamic> jsonList = json.decode(data);
    return jsonList.map((json) => Conversation.fromJson(json)).toList();
  }

  Future<void> saveConversations(List<Conversation> conversations) async {
    final String data = json.encode(
      conversations.map((conv) => conv.toJson()).toList(),
    );
    await _prefs.setString(_conversationsKey, data);
  }

  Future<void> addConversation(Conversation conversation) async {
    final conversations = await getConversations();
    conversations.insert(0, conversation);
    await saveConversations(conversations);
  }

  Future<void> updateConversation(Conversation conversation) async {
    final conversations = await getConversations();
    final index =
        conversations.indexWhere((conv) => conv.id == conversation.id);
    if (index != -1) {
      conversations[index] = conversation;
      await saveConversations(conversations);
    }
  }

  Future<void> deleteConversation(String id) async {
    final conversations = await getConversations();
    conversations.removeWhere((conv) => conv.id == id);
    await saveConversations(conversations);
  }
}
