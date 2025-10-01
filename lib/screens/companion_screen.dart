// companion_screen.dart (major changes: fixed input with TextField and send button, added chat history display, improved title in AppBar and intro, integrated addMessage calls)
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:vibration/vibration.dart';
import '../constants.dart';
import '../services/speech_service.dart';
import '../services/llm_service.dart';
import '../services/chat_service.dart';

class CompanionScreen extends StatefulWidget {
  @override
  _CompanionScreenState createState() => _CompanionScreenState();
}

class _CompanionScreenState extends State<CompanionScreen> with TickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  final LLMService _llmService = LLMService();
  final Flutter3DController _modelController = Flutter3DController();
  final SpeechToText _speech = SpeechToText();
  final TextEditingController _textController = TextEditingController();
  bool _isInitialized = false;
  bool _isListening = false;
  String _recognizedText = '';
  late AnimationController _animationController;
  late AnimationController _particleController;
  late AnimationController _micPulseController;
  bool _modelLoaded = false;
  double _micPulseSize = 1.0;
  List<Offset> _particles = [];
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(seconds: 1));
    _particleController = AnimationController(vsync: this, duration: Duration(milliseconds: 2000))..repeat();
    _micPulseController = AnimationController(vsync: this, duration: Duration(milliseconds: 500))..repeat(reverse: true);
    _micPulseController.addListener(() {
      setState(() {
        _micPulseSize = 1.0 + (_micPulseController.value * 0.3);
      });
    });
    _confettiController = ConfettiController(duration: Duration(seconds: 1));
    _initServices();
    _initModel();
    _initParticles();
  }

  void _initParticles() {
    _particles = List.generate(30, (index) => Offset(
      50 + (300 * (index / 30)) + (50 * (index % 2)),
      50 + (400 * (index / 10).floor()) + (50 * (index % 2)),
    ));
  }

  Future<void> _initModel() async {
    // Model loading handled by Flutter3DViewer onLoad callback
  }

  Future<void> _initServices() async {
    await _speech.initialize(onStatus: (status) => print('Speech status: $status'));
    await _speechService.init();
    await Provider.of<ChatService>(context, listen: false).init();
    await _llmService.init();
    _showIntro();
    setState(() => _isInitialized = true);
  }

  void _showIntro() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryTeal, AppColors.secondaryIndigo],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.png', height: 100),
                  SizedBox(height: 20),
                  Text(
                    'VibeMate AI Companion',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Sync with Your Soul, Find Your Calm. 😊',
                    style: TextStyle(fontSize: 18, color: AppColors.white70),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  Text(
                    'Disclaimer: This app provides general support only. Not a substitute for professional mental health care. Contact a therapist or hotline (e.g., 988 in the US) if needed.',
                    style: TextStyle(fontSize: 14, color: AppColors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Start Chatting'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startListening() async {
    setState(() => _isListening = true);
    _animationController.repeat();
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          setState(() => _recognizedText = result.recognizedWords);
          _speech.stop();
          if (_recognizedText.isNotEmpty) {
            Provider.of<ChatService>(context, listen: false).addMessage(_recognizedText, true);
            _processInput(_recognizedText).then((_) {
              setState(() => _isListening = false);
              _animationController.stop();
              _animationController.reset();
            });
          } else {
            setState(() => _isListening = false);
            _animationController.stop();
            _animationController.reset();
          }
        }
      },
      listenFor: Duration(seconds: 10),
      onSoundLevelChange: (level) {
        setState(() {
          _micPulseSize = 1.0 + (level * 0.3);
        });
      },
    );
  }

  Future<void> _processInput(String input) async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    int mood = chatService.currentMood;
    String chatContext = chatService.context;
    String response = await _llmService.generateResponse(input, context: chatContext, mood: mood);

    chatService.addMessage(response, false);
    await _speechService.speak(response);

    if (mood >= 4) {
      _confettiController.play();
      Vibration.vibrate(duration: 200);
    }
  }

  void _onAvatarTap() {
    _animationController.forward(from: 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You got this! 😊', style: TextStyle(color: AppColors.white))),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 30),
            SizedBox(width: 10),
            Text('VibeMate AI Companion'),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryTeal, AppColors.secondaryIndigo],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          CustomPaint(
            painter: ParticlePainter(_particles, _particleController.value, Provider.of<ChatService>(context).currentMood),
            child: Container(),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: [AppColors.primaryTeal, AppColors.secondaryIndigo, AppColors.lightTeal],
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primaryTeal, AppColors.lightTeal],
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('How\'s your vibe today? (1-5)', style: TextStyle(color: AppColors.white, fontSize: 16)),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.secondaryIndigo,
                          inactiveTrackColor: AppColors.white30,
                          thumbColor: AppColors.secondaryIndigo,
                          overlayColor: AppColors.secondaryIndigo.withOpacity(0.2),
                          trackHeight: 4.0,
                        ),
                        child: Slider(
                          value: Provider.of<ChatService>(context).currentMood.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          onChanged: (value) {
                            Provider.of<ChatService>(context, listen: false).updateMood(value.toInt());
                            setState(() {});
                          },
                          label: _getMoodEmoji(Provider.of<ChatService>(context).currentMood),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Consumer<ChatService>(
                    builder: (context, chatService, child) {
                      return ListView.builder(
                        itemCount: chatService.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatService.messages[index];
                          return Align(
                            alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: message.isUser ? AppColors.secondaryIndigo : AppColors.lightTeal,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                message.text,
                                style: TextStyle(color: AppColors.white),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: GestureDetector(
                      onTap: _onAvatarTap,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white30, width: 2),
                          boxShadow: [BoxShadow(color: AppColors.black26, blurRadius: 8, spreadRadius: 2)],
                        ),
                        child: ClipOval(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            child: _modelLoaded
                                ? Flutter3DViewer(
                              controller: _modelController,
                              src: 'assets/models/avatar_3d.glb',
                              enableTouch: true,
                              progressBarColor: AppColors.secondaryIndigo,
                              onLoad: (String address) {
                                setState(() => _modelLoaded = true);
                                print('3D Model loaded successfully at: $address');
                              },
                              onError: (error) {
                                print('Model load error: $error');
                                if (error.contains('404') || error.contains('not found')) {
                                  print('Check asset path: assets/models/avatar_3d.glb');
                                } else if (error.contains('corrupt') || error.contains('invalid')) {
                                  print('GLB file may be corrupted; re-export from Ready Player Me');
                                }
                              },
                            )
                                : Lottie.asset(
                              'assets/animations/avatar.json',
                              controller: _animationController,
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Fixed input box at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryTeal, AppColors.secondaryIndigo],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: AppColors.black26, blurRadius: 10, spreadRadius: 2)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: TextStyle(color: AppColors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Speak your heart... 😊',
                        hintStyle: TextStyle(color: AppColors.white70),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.mic, color: AppColors.white, size: 28),
                    onPressed: _startListening,
                    splashColor: AppColors.lightTeal,
                    splashRadius: 24,
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: AppColors.white, size: 28),
                    onPressed: () {
                      if (_textController.text.isNotEmpty) {
                        final input = _textController.text.trim();
                        _textController.clear();
                        Provider.of<ChatService>(context, listen: false).addMessage(input, true);
                        _processInput(input);
                      }
                    },
                    splashColor: AppColors.lightTeal,
                    splashRadius: 24,
                  ),
                ],
              ),
            ),
          ),
          if (_isListening)
            Positioned(
              right: 16,
              bottom: 16,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 500),
                width: 70 * _micPulseSize,
                height: 70 * _micPulseSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryTeal.withOpacity(0.3),
                ),
                child: FloatingActionButton(
                  onPressed: null,
                  child: Icon(Icons.stop, color: AppColors.white),
                  backgroundColor: AppColors.errorRed,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 1: return '😢';
      case 2: return '😔';
      case 3: return '😐';
      case 4: return '😊';
      case 5: return '😄';
      default: return '';
    }
  }

  @override
  void dispose() {
    _speechService.stopAll();
    _animationController.dispose();
    _particleController.dispose();
    _micPulseController.dispose();
    _confettiController.dispose();
    _speech.stop();
    _textController.dispose();
    _llmService.dispose();
    super.dispose();
  }
}

class ParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double animationValue;
  final int mood;

  ParticlePainter(this.particles, this.animationValue, this.mood);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.secondaryIndigo.withOpacity(0.5);
    final moodColor = mood <= 2 ? AppColors.errorRed : mood >= 4 ? AppColors.lightTeal : AppColors.white;
    paint.color = moodColor.withOpacity(0.3 + (mood / 10));

    for (var particle in particles) {
      final animOffset = Offset(
        particle.dx + sin(animationValue + particle.dx) * (mood * 2),
        particle.dy + cos(animationValue + particle.dy) * (mood * 2),
      );
      canvas.drawCircle(animOffset, 5.0 + (mood / 5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}