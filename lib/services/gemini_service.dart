import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class GeminiService {
  static const _apiKey = 'API_KEY';
  static const _model = 'gemini-2.5-flash-preview-05-20';

  static Future<String> getResponse(String prompt, {List<ChatMessage>? chatHistory}) async {
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey');

    List<Map<String, dynamic>> contents = [];
    
    if (chatHistory != null && chatHistory.isNotEmpty) {
      final recentHistory = chatHistory.length > 20 
          ? chatHistory.sublist(chatHistory.length - 20) 
          : chatHistory;
      
      for (var message in recentHistory) {
        contents.add({
          'parts': [{'text': message.message}],
          'role': message.isUser ? 'user' : 'model'
        });
      }
    }

    contents.add({
      'parts': [{'text': prompt}],
      'role': 'user'
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': contents,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Gemini API Error: ${response.body}');
    }
  }
}
