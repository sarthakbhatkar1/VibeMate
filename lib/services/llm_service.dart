import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

class LLMService {
  LlamaParent? _llamaParent;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Copy model from assets to temp directory
    final tempDir = await getTemporaryDirectory();
    final modelPath = '${tempDir.path}/phi-3.5-mini.gguf';
    if (!await File(modelPath).exists()) {
      final byteData = await rootBundle.load('assets/models/phi-3.5-mini.gguf');
      await File(modelPath).writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }

    final contextParams = ContextParams()
      ..nCtx = 4096
      ..nThreads = 4;

    final samplerParams = SamplerParams()
      ..temp = 0.7
      ..topK = 50
      ..topP = 0.95;

    final loadCommand = LlamaLoad(
      path: modelPath,
      modelParams: ModelParams(),
      contextParams: contextParams,
      samplingParams: samplerParams,
      format: ChatMLFormat(),
    );

    _llamaParent = LlamaParent(loadCommand);
    await _llamaParent!.init();

    _initialized = true;
    print('Phi-3.5-mini SLM initialized successfully.');
  }

  Future<String> generateResponse(String userInput, {String context = '', int mood = 3}) async {
    if (!_initialized || _llamaParent == null) {
      throw Exception('LLMService not initialized or _llamaParent is null.');
    }

    // Build full prompt with system, history (context), and user input
    String systemPrompt = "You are VibeMate, an empathetic AI companion. The user's mood is $mood on a scale of 1 (very low) to 5 (very high). Adjust your tone: supportive and uplifting if low, cheerful if high. Keep responses concise, helpful, and end with an emoji if appropriate.";
    String fullPrompt = '<s><|system|>\n$systemPrompt<|end|>\n';

    // Format context (history)
    if (context.isNotEmpty) {
      List<String> turns = context.split('. ');
      for (int i = 0; i < turns.length; i++) {
        if (turns[i].startsWith('User:')) {
          fullPrompt += '<|user|>\n${turns[i].substring(6)}<|end|>\n';
        } else if (turns[i].startsWith('Companion:')) {
          fullPrompt += '<|assistant|>\n${turns[i].substring(11)}<|end|>\n';
        }
      }
    }

    fullPrompt += '<|user|>\n$userInput<|end|>\n<|assistant|>\n';

    // Generate response
    final completer = Completer<String>();
    final responseBuffer = StringBuffer();
    StreamSubscription? subscription;

    subscription = _llamaParent!.stream.listen(
          (token) {
        responseBuffer.write(token);
      },
      onDone: () {
        completer.complete(responseBuffer.toString().trim());
      },
      onError: (error) {
        completer.completeError(error);
      },
    );

    _llamaParent!.sendPrompt(fullPrompt);

    final response = await completer.future;
    await subscription?.cancel();
    return response;
  }

  void dispose() {
    _llamaParent?.dispose();
    _initialized = false;
  }
}