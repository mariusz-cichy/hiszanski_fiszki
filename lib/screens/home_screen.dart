import 'package:flutter/material.dart';
import '../screens/learning_screen.dart';
import '../screens/settings_screen.dart';
import '../utils/excel_loader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color topBarColor = const Color(0xFFC60B1E);
  final Color middleColor = const Color(0xFFFFF200);
  final Color bottomBarColor = const Color(0xFFC60B1E);

  List<Map<String, dynamic>> groupedList = [];
  Set<String> expandedGroups = {};

  @override
  void initState() {
    super.initState();
    loadGroups();
  }

  Future<void> loadGroups() async {
    final data = await ExcelLoader.loadGroupedTopicsUnified();
    setState(() {
      groupedList = data;
      expandedGroups = {
        if (data.isNotEmpty) data.first['group'] as String,
      };
    });
  }

  Color _statusToColor(TopicStatus status) {
    switch (status) {
      case TopicStatus.notStarted:
        return Colors.red;
      case TopicStatus.inProgress:
        return Colors.orange;
      case TopicStatus.completed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // GÓRNY PASEK
          Container(
            height: 51,
            color: topBarColor,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.menu, color: Colors.white),
                const Text(
                  'Hiszpański A1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ).then((_) => loadGroups());
                  },
                ),
              ],
            ),
          ),

          // LISTA TEMATÓW
          Expanded(
            child: Container(
              color: middleColor,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // POWTÓRKI
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.replay, color: Colors.blue),
                      title: const Text(
                        'Powtórki',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final flashcards = await ExcelLoader.loadRevisions();

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LearningScreen(
                              title: 'Powtórki',
                              flashcards: flashcards,
                              isRevision: true,
                            ),
                          ),
                        );

                        loadGroups();
                      },
                    ),
                  ),

                  // GRUPY TEMATÓW
                  ...groupedList.map((group) {
                    final groupName = group['group'] as String;
                    final topics =
                        group['topics'] as List<Map<String, dynamic>>;
                    final isExpanded = expandedGroups.contains(groupName);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              groupName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            trailing: Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.black,
                            ),
                            onTap: () {
                              setState(() {
                                isExpanded
                                    ? expandedGroups.remove(groupName)
                                    : expandedGroups.add(groupName);
                              });
                            },
                          ),
                          if (isExpanded)
                            ...topics.map((t) {
                              final topic = t['topic'] as String;
                              final status = t['status'] as TopicStatus;
                              final color = _statusToColor(status);

                              return ListTile(
                                title: Text(topic),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: color,
                                  size: 16,
                                ),
                                onTap: () async {
                                  final flashcards =
                                      await ExcelLoader.loadWordsByTopic(topic);

                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LearningScreen(
                                        title: topic,
                                        flashcards: flashcards,
                                      ),
                                    ),
                                  );

                                  loadGroups();
                                },
                              );
                            }).toList(),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // DOLNY PASEK
          Container(
            height: 60,
            child: Column(
              children: [
                Container(height: 2, color: bottomBarColor),
                Expanded(
                  child: Container(
                    color: bottomBarColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [],
                    ),
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
