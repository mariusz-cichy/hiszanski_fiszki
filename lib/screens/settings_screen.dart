import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import './home_screen.dart';
import '../config/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? selectedPath;

  @override
  void initState() {
    super.initState();
    selectedPath = AppConfig.excelFilePath;
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Wybierz plik Excel',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedPath = result.files.single.path!;
      });
    }
  }

  Future<void> savePath() async {
    if (selectedPath != null && File(selectedPath!).existsSync()) {
      await AppConfig.setExcelFilePath(selectedPath!);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nieprawidłowy plik lub ścieżka.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF200),
      body: Column(
        children: [
          // GÓRNY PASEK
          Container(
            height: 51,
            color: const Color(0xFFC60B1E),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ustawienia',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ŚRODEK
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodyMedium!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Aktualna ścieżka do pliku Excel:'),
                    const SizedBox(height: 10),
                    Text(
                      selectedPath ?? 'Brak ustawionej ścieżki',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: pickFile,
                      child: const Text('Wybierz plik Excel'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: savePath,
                      child: const Text('Zapisz ustawienia'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // DOLNY PASEK
          Container(
            height: 60,
            child: Column(
              children: [
                Container(height: 2, color: const Color(0xFFC60B1E)),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(), // rozciąga się na wysokość Expanded
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
