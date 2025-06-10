import 'dart:io';
import 'dart:math';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';

Future<bool> updateReviewData({
  required String polishWord,
  required String lastReviewRaw,
  required int rowIndex,
  required String level,
}) async {
  final path = AppConfig.excelFilePath;
  if (path == null) return false;

  final file = File(path);
  if (!file.existsSync()) return false;

  final bytes = file.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);
  final sheet = excel.tables[excel.tables.keys.first]!;

  final now = DateTime.now();
  DateTime? lastReviewDate = DateTime.tryParse(lastReviewRaw);
  int nextInterval = 1;

  if (level == 'green') {
    int previous = 1;
    if (lastReviewDate != null) {
      final diff = now.difference(lastReviewDate).inDays;
      if (diff > 0) previous = diff;
    }
    nextInterval = previous * 2;
    nextInterval += _calculateJitter(nextInterval);
  }

  final formattedNow = DateFormat('yyyy-MM-dd').format(now);
  final formattedNextDate = DateFormat('yyyy-MM-dd').format(
    level == 'green' ? now.add(Duration(days: nextInterval)) : now,
  );

  sheet.updateCell(
    CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex), // Powtórki
    TextCellValue(formattedNextDate),
  );
  sheet.updateCell(
    CellIndex.indexByColumnRow(
        columnIndex: 6, rowIndex: rowIndex), // Ostatnia Powtórka
    TextCellValue(formattedNow),
  );

  final updated = excel.encode();
  if (updated != null) {
    file.writeAsBytesSync(updated);
  }

  return level != 'green'; // tylko yellow/red wymagają powtórki jeszcze dziś
}

int _calculateJitter(int base) {
  final rand = Random();
  final maxJitter = (base * 0.25).round();
  if (maxJitter < 1) return 0;
  return rand.nextInt(maxJitter * 2 + 1) - maxJitter;
}
