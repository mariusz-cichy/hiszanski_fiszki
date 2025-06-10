import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('Hiszpańskie Fiszki');
    setWindowMinSize(const Size(360, 800));
    setWindowMaxSize(const Size(360, 800));
  }

  await AppConfig.load();

  runApp(FlashcardApp(startInSettings: AppConfig.excelFilePath == null));
}

class FlashcardApp extends StatelessWidget {
  final bool startInSettings;
  const FlashcardApp({super.key, required this.startInSettings});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hiszpańskie Fiszki',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFF200),
        textTheme: GoogleFonts.rubikTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: Colors.black,
                displayColor: Colors.black,
              ),
        ),
      ),
      home: startInSettings ? const SettingsScreen() : const HomeScreen(),
    );
  }
}
