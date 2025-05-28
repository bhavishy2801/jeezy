import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class ChatStorageService {
  static String _getChatKey() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    return 'chat_history_${user.uid}';
  }

  static Future<void> saveChatHistory(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = messages.map((message) => message.toJson()).toList();
    await prefs.setString(_getChatKey(), jsonEncode(jsonList));
  }

  static Future<List<ChatMessage>> loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_getChatKey());
      
      if (jsonString == null) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getChatKey());
    } catch (e) {
    }
  }
  static Future<void> clearAllChatHistories() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final chatKeys = keys.where((key) => key.startsWith('chat_history_'));
    
    for (final key in chatKeys) {
      await prefs.remove(key);
    }
  }

  static Future<List<ChatMessage>> loadChatHistoryForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('chat_history_$userId');
    
    if (jsonString == null) {
      return [];
    }

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => ChatMessage.fromJson(json)).toList();
  }
}
