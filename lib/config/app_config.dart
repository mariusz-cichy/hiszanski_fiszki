import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const _keyExcelPath = 'excelFilePath';
  static String? _excelFilePath;

  static String? get excelFilePath => _excelFilePath;

  static Future<void> setExcelFilePath(String path) async {
    _excelFilePath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyExcelPath, path);
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _excelFilePath = prefs.getString(_keyExcelPath);

    if (_excelFilePath == null || !File(_excelFilePath!).existsSync()) {
      if (Platform.isAndroid) {
        _excelFilePath = await _copyExcelFromAssets();
      } else {
        final homeDir =
            Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
        final localPath = p.join(Directory.current.path, 'fiszki.xlsx');
        final homePath =
            homeDir != null ? p.join(homeDir, 'fiszki.xlsx') : null;
        final fallbackPath = 'd:/fiszki.xlsx';

        if (File(localPath).existsSync()) {
          _excelFilePath = localPath;
        } else if (homePath != null && File(homePath).existsSync()) {
          _excelFilePath = homePath;
        } else if (File(fallbackPath).existsSync()) {
          _excelFilePath = fallbackPath;
        } else {
          _excelFilePath = null;
        }
      }

      if (_excelFilePath != null) {
        await prefs.setString(_keyExcelPath, _excelFilePath!);
      }
    }

    debugPrint('Wybrana ścieżka: $_excelFilePath');
  }

  static Future<String?> _copyExcelFromAssets() async {
    try {
      final byteData = await rootBundle.load('assets/fiszki.xlsx');
      final directory = await getApplicationDocumentsDirectory();
      final filePath = p.join(directory.path, 'fiszki.xlsx');

      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return filePath;
    } catch (e) {
      debugPrint('Błąd kopiowania Excela z assets: $e');
      return null;
    }
  }
}
