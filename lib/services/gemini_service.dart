import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _apiKey = 'API_KEY';
  static const _model = 'gemini-2.5-flash-preview-05-20';

  static Future<String> getResponse(String prompt) async {
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
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
