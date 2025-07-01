import 'package:flutter/foundation.dart';

class ChatProvider extends ChangeNotifier {
  final List<Map<String, String>> _messages = [];

  List<Map<String, String>> get messages => _messages;

  void addMessage(String role, String text) {
    _messages.add({'role': role, 'text': text});
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
