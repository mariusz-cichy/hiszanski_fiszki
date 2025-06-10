import 'dart:io';
import 'package:excel/excel.dart';
import '../config/app_config.dart';

enum TopicStatus {
  notStarted, // czerwony
  inProgress, // żółty
  completed, // zielony
}

class ExcelLoader {
  static Future<List<String>> loadAllTopics() async {
    final path = AppConfig.excelFilePath;
    if (path == null) return [];

    final file = File(path);
    if (!file.existsSync()) return [];

    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;

    final Set<String> uniqueTopics = {};
    for (var row in sheet.rows.skip(1)) {
      if (row.length > 3 && row[3]?.value != null) {
        final topic = row[3]!.value.toString().trim();
        if (topic.isNotEmpty) uniqueTopics.add(topic);
      }
    }

    return uniqueTopics.toList();
  }

  static Future<List<Map<String, String>>> loadWordsByTopic(
      String topic) async {
    final path = AppConfig.excelFilePath;
    if (path == null) return [];

    final file = File(path);
    if (!file.existsSync()) return [];

    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;

    final List<Map<String, String>> cards = [];
    for (var row in sheet.rows.skip(1)) {
      if (row.length >= 7 &&
          row[0]?.value != null &&
          row[1]?.value != null &&
          row[3]?.value != null &&
          row[4]?.value != null &&
          row[3]!.value.toString().trim().toLowerCase() ==
              topic.trim().toLowerCase()) {
        final card = {
          'pl': row[0]!.value.toString(),
          'es': row[1]!.value.toString(),
          'type': row[4]!.value.toString().toLowerCase(),
          'topic': row[3]!.value.toString(),
          'lastReview': row.length > 6 ? row[6]?.value?.toString() ?? '' : '',
        };
        cards.add(card);
      }
    }

    return cards;
  }

  static Future<List<Map<String, String>>> loadRevisions() async {
    final path = AppConfig.excelFilePath;
    if (path == null) return [];

    final file = File(path);
    if (!file.existsSync()) return [];

    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;

    final now = DateTime.now();
    final List<Map<String, String>> revisions = [];

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.length >= 7 &&
          row[0]?.value != null &&
          row[1]?.value != null &&
          row[3]?.value != null &&
          row[4]?.value != null &&
          row[5]?.value != null) {
        final planRaw = row[5]?.value?.toString();
        final planDate = DateTime.tryParse(planRaw ?? '');
        if (planDate != null && planDate.isAfter(now)) continue;

        revisions.add({
          'pl': row[0]!.value.toString(),
          'es': row[1]!.value.toString(),
          'type': row[4]!.value.toString().toLowerCase(),
          'topic': row[3]!.value.toString(),
        });
      }
    }

    return revisions;
  }

  static Future<List<Map<String, dynamic>>> loadTopicsWithStatus() async {
    final path = AppConfig.excelFilePath;
    if (path == null) return [];

    final file = File(path);
    if (!file.existsSync()) return [];

    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;

    final Map<String, List<Map<String, String>>> topics = {};

    for (var row in sheet.rows.skip(1)) {
      if (row.length >= 7 &&
          row[0]?.value != null &&
          row[1]?.value != null &&
          row[3]?.value != null) {
        final topic = row[3]!.value.toString().trim();
        final lastReview =
            row.length > 6 ? row[6]?.value?.toString() ?? '' : '';

        topics.putIfAbsent(topic, () => []);
        topics[topic]!.add({
          'pl': row[0]!.value.toString(),
          'es': row[1]!.value.toString(),
          'lastReview': lastReview,
        });
      }
    }

    final List<Map<String, dynamic>> result = [];

    topics.forEach((topic, words) {
      final total = words.length;
      final reviewed = words
          .where(
            (w) =>
                w['lastReview'] != null && w['lastReview']!.trim().isNotEmpty,
          )
          .length;

      TopicStatus status;
      if (reviewed == 0) {
        status = TopicStatus.notStarted;
      } else if (reviewed < total) {
        status = TopicStatus.inProgress;
      } else {
        status = TopicStatus.completed;
      }

      result.add({
        'topic': topic,
        'status': status,
      });
    });

    return result;
  }

  static Future<Map<String, List<Map<String, dynamic>>>>
      loadGroupedTopicsWithStatus() async {
    final path = AppConfig.excelFilePath;
    if (path == null) return {};

    final file = File(path);
    if (!file.existsSync()) return {};

    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;

    final Map<String, Map<String, List<String>>> grouped = {};

    for (var row in sheet.rows.skip(1)) {
      if (row.length >= 9 &&
          row[0]?.value != null &&
          row[1]?.value != null &&
          row[3]?.value != null &&
          row[8]?.value != null) {
        final topic = row[3]!.value.toString().trim();
        final group = row[8]!.value.toString().trim();
        final lastReview =
            row.length > 6 ? row[6]?.value?.toString() ?? '' : '';

        grouped.putIfAbsent(group, () => {});
        grouped[group]!.putIfAbsent(topic, () => []);
        grouped[group]![topic]!.add(lastReview);
      }
    }

    final Map<String, List<Map<String, dynamic>>> result = {};

    grouped.forEach((group, topics) {
      result[group] = topics.entries.map((e) {
        final reviewed = e.value.where((v) => v.trim().isNotEmpty).length;
        final total = e.value.length;

        TopicStatus status;
        if (reviewed == 0) {
          status = TopicStatus.notStarted;
        } else if (reviewed < total) {
          status = TopicStatus.inProgress;
        } else {
          status = TopicStatus.completed;
        }

        return {
          'topic': e.key,
          'status': status,
        };
      }).toList();
    });

    return result;
  }

  static Future<List<Map<String, dynamic>>> loadGroupedTopicsUnified() async {
    final path = AppConfig.excelFilePath;
    if (path == null) return [];

    final file = File(path);
    if (!file.existsSync()) return [];

    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;

    final Map<String, Map<String, List<String>>> grouped = {};

    for (var row in sheet.rows.skip(1)) {
      if (row.length >= 9) {
        final topic = row[3]?.value?.toString().trim() ?? '';
        final group = row[8]?.value?.toString().trim() ?? '';
        final lastReview =
            row.length > 6 ? row[6]?.value?.toString() ?? '' : '';

        if (topic.isEmpty || group.isEmpty) continue;

        grouped.putIfAbsent(group, () => {});
        grouped[group]!.putIfAbsent(topic, () => []);
        grouped[group]![topic]!.add(lastReview);
      }
    }

    final List<Map<String, dynamic>> result = [];

    grouped.forEach((groupName, topicMap) {
      final topics = topicMap.entries.map((entry) {
        final reviewed = entry.value.where((v) => v.trim().isNotEmpty).length;
        final total = entry.value.length;

        TopicStatus status;
        if (reviewed == 0) {
          status = TopicStatus.notStarted;
        } else if (reviewed < total) {
          status = TopicStatus.inProgress;
        } else {
          status = TopicStatus.completed;
        }

        return {
          'topic': entry.key,
          'status': status,
        };
      }).toList();

      result.add({
        'group': groupName,
        'topics': topics,
      });
    });

    return result;
  }
}
