// gemini_service.dart

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class GeminiService {
  static const _apiKey = 'AIzaSyD56ALDIOiM5jQPBm24R0pBhZXLjC9b0aE';
  static const _model = 'gemini-2.5-flash-preview-05-20';

  // Your existing non-streaming method
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

  // Fixed streaming method for Gemini API
  static Stream<String> getResponseStream(String prompt, {List<ChatMessage>? chatHistory}) {
    final controller = StreamController<String>();
    
    _generateStreamingResponse(prompt, chatHistory, controller);
    
    return controller.stream;
  }

  static void _generateStreamingResponse(
    String prompt, 
    List<ChatMessage>? chatHistory, 
    StreamController<String> controller
  ) async {
    try {
      final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$_model:streamGenerateContent?key=$_apiKey');

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

      final request = http.Request('POST', uri);
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'contents': contents,
      });

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        String buffer = '';
        
        await for (List<int> chunk in streamedResponse.stream) {
          buffer += utf8.decode(chunk);
          
          // Process complete JSON objects in the buffer
          while (buffer.contains('\n')) {
            int newlineIndex = buffer.indexOf('\n');
            String line = buffer.substring(0, newlineIndex).trim();
            buffer = buffer.substring(newlineIndex + 1);
            
            if (line.isNotEmpty) {
              try {
                final json = jsonDecode(line);
                
                if (json['candidates'] != null && 
                    json['candidates'].isNotEmpty &&
                    json['candidates'][0]['content'] != null &&
                    json['candidates'][0]['content']['parts'] != null &&
                    json['candidates'][0]['content']['parts'].isNotEmpty) {
                  
                  final text = json['candidates'][0]['content']['parts'][0]['text'];
                  if (text != null && text.isNotEmpty) {
                    controller.add(text);
                  }
                }
                
                // Check if this is the final chunk
                if (json['candidates'] != null && 
                    json['candidates'].isNotEmpty &&
                    json['candidates'][0]['finishReason'] != null) {
                  controller.close();
                  return;
                }
              } catch (e) {
                // Skip malformed JSON chunks
                continue;
              }
            }
          }
        }
        
        // Process any remaining data in buffer
        if (buffer.trim().isNotEmpty) {
          try {
            final json = jsonDecode(buffer.trim());
            if (json['candidates'] != null && 
                json['candidates'].isNotEmpty &&
                json['candidates'][0]['content'] != null &&
                json['candidates'][0]['content']['parts'] != null &&
                json['candidates'][0]['content']['parts'].isNotEmpty) {
              
              final text = json['candidates'][0]['content']['parts'][0]['text'];
              if (text != null && text.isNotEmpty) {
                controller.add(text);
              }
            }
          } catch (e) {
            // Ignore final parsing errors
          }
        }
        
        controller.close();
      } else {
        final errorBody = await streamedResponse.stream.bytesToString();
        controller.addError(Exception('Gemini API Error: $errorBody'));
      }
    } catch (e) {
      controller.addError(Exception('Failed to get streaming response: $e'));
    }
  }

  // Recommended: Simulated streaming using your existing method
  static Stream<String> getResponseStreamSimulated(String prompt, {List<ChatMessage>? chatHistory}) async* {
    try {
      // Get the full response using your existing method
      final fullResponse = await getResponse(prompt, chatHistory: chatHistory);
      
      // Split into words for more natural streaming
      final words = fullResponse.split(' ');
      
      for (int i = 0; i < words.length; i++) {
        await Future.delayed(Duration(milliseconds: 80)); // Adjust speed as needed
        
        if (i == 0) {
          yield words[i];
        } else {
          yield ' ${words[i]}';
        }
      }
    } catch (e) {
      yield 'Error: ${e.toString()}';
    }
  }

  // Character-by-character streaming simulation
  static Stream<String> getResponseStreamCharByChar(String prompt, {List<ChatMessage>? chatHistory}) async* {
    try {
      // Get the full response using your existing method
      final fullResponse = await getResponse(prompt, chatHistory: chatHistory);
      
      // Stream character by character
      for (int i = 0; i < fullResponse.length; i++) {
        await Future.delayed(Duration(milliseconds: 25)); // Adjust speed as needed
        yield fullResponse[i];
      }
    } catch (e) {
      yield 'Error: ${e.toString()}';
    }
  }
}
