import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyAqJ1QwUjWj1KaZ2gtcvtUKVy8qj4sG_28';
  static const String _apiUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=$_apiKey';

  static Future<String> askGemini(String prompt) async {
    final response = await http.post(
      Uri.parse(_apiUrl),
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
      final data = jsonDecode(response.body);
      final candidates = data['candidates'];
      if (candidates != null && candidates.isNotEmpty) {
        return candidates[0]['content']['parts'][0]['text'] ?? 'No response.';
      }
      return 'No candidates returned.';
    } else {
      print('Gemini API error: ${response.statusCode} - ${response.body}');
      return 'Something went wrong while contacting Gemini.';
    }
  }
}
