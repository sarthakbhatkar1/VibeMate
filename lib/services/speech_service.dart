// speech_service.dart (unchanged)
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  bool _isSpeaking = false;
  String _recognizedText = '';

  Future<void> init() async {
    bool speechAvailable = await _speech.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
    if (!speechAvailable) {
      print('Speech recognition not available - falling back to text input');
    }

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);  // Slower, empathetic pace
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<String> listenForInput() async {
    if (_isListening) return '';
    _isListening = true;
    _recognizedText = '';

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _recognizedText = result.recognizedWords;  // Updated to correct API
          _isListening = false;
          _speech.stop();
        }
      },
      listenFor: Duration(seconds: 10),  // Timeout
      pauseFor: Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
    );

    await Future.doWhile(() => _isListening);  // Wait until done
    return _recognizedText;
  }

  Future<void> speak(String text) async {
    if (_isSpeaking) await _tts.stop();
    _isSpeaking = true;
    await _tts.speak(text);
    await _tts.awaitSpeakCompletion(true);
    _isSpeaking = false;
  }

  void stopAll() {
    _speech.stop();
    _tts.stop();
    _isListening = false;
    _isSpeaking = false;
  }
}