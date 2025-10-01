// main.dart (modified slightly for title)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';
import 'screens/companion_screen.dart';
import 'services/speech_service.dart';
import 'services/llm_service.dart';
import 'services/chat_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatService()),
      ],
      child: MaterialApp(
        title: 'VibeMate AI Companion',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryTeal,
            secondary: AppColors.secondaryIndigo,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
          scaffoldBackgroundColor: Colors.transparent,
        ),
        debugShowCheckedModeBanner: false, // Remove debug banner
        home: CompanionScreen(),
      ),
    );
  }
}