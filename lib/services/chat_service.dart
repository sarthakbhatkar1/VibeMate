// chat_service.dart (unchanged, but used more in UI now)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatService extends ChangeNotifier {
  List<ChatMessage> _messages = [];
  String _context = '';
  int _currentMood = 3;  // Default neutral (1-5 scale)
  late SharedPreferences _prefs;

  List<ChatMessage> get messages => _messages;
  int get currentMood => _currentMood;
  String get context => _context;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _currentMood = _prefs.getInt('mood') ?? 3;
    notifyListeners();
  }

  void addMessage(String text, bool isUser) {
    _messages.add(ChatMessage(text: text, isUser: isUser));
    if (isUser) {
      _context += ' User: $text. ';
    } else {
      _context += ' Companion: $text. ';
    }
    notifyListeners();
  }

  void updateMood(int mood) {
    _currentMood = mood;
    _prefs.setInt('mood', mood);
    notifyListeners();
  }

  void clearContext() {
    _context = '';
    _messages.clear();
    notifyListeners();
  }
}