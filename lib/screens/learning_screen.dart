import 'dart:io';
import 'dart:math';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../config/app_config.dart';
import '../utils/review_logic.dart';
import '../widgets/fa_icon_button.dart';
import '../widgets/animated_days_text.dart';

class LearningScreen extends StatefulWidget {
  final List<Map<String, String>> flashcards;
  final String title;
  final bool isRevision;

  const LearningScreen({
    required this.flashcards,
    required this.title,
    this.isRevision = false,
    Key? key,
  }) : super(key: key);

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final Color topBarColor = const Color(0xFFC60B1E);
  final Color middleColor = const Color(0xFFFFF200);
  final Color bottomBarColor = const Color(0xFFC60B1E);

  int currentIndex = 0;
  bool showAnswer = false;
  bool showFeedback = false;
  int? estimatedDays;
  IconData? levelIcon;
  Color? levelColor;
  final List<Map<String, String>> toRepeat = [];

  late FlutterTts flutterTts;
  List<Map<String, String>> spanishVoices = [];

  final TextEditingController answerController = TextEditingController();
  String userInput = '';
  bool showInputError = false;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setSpeechRate(0.6);
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);
    spanishVoices = await _getSpanishVoices();
  }

  Future<List<Map<String, String>>> _getSpanishVoices() async {
    List<dynamic> voices = await flutterTts.getVoices;
    return voices
        .where((voice) =>
            voice is Map &&
            voice['locale'] == 'es-ES' &&
            (voice['gender'] == 'male' || voice['gender'] == 'female'))
        .map((voice) => {
              'name': voice['name'].toString(),
              'locale': voice['locale'].toString(),
            })
        .toList();
  }

  Future<void> _speak(String text) async {
    if (spanishVoices.isNotEmpty) {
      final random = Random();
      final selectedVoice = spanishVoices[random.nextInt(spanishVoices.length)];
      await flutterTts.setVoice({
        'name': selectedVoice['name']!,
        'locale': selectedVoice['locale']!,
      });
    }
    Future.microtask(() => flutterTts.speak(text));
  }

  bool _isCorrectAnswer() {
    final correct = widget.flashcards[currentIndex]['es'] ?? '';
    return answerController.text.trim().toLowerCase() ==
        correct.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasData = currentIndex < widget.flashcards.length;
    final current = hasData ? widget.flashcards[currentIndex] : null;
    final isInput = current?['type']?.toLowerCase() == 'input';

    if (!hasData) {
      return Scaffold(
        backgroundColor: middleColor,
        body: SafeArea(
          child: Column(
            children: [
              // GÓRNY PASEK
              Container(
                height: 51,
                color: topBarColor,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // ŚRODEK
              const Expanded(
                child: Center(
                  child: Text(
                    "Brak słówek do powtórki",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFC60B1E),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),

              // DOLNY PASEK
              Container(
                height: 60,
                child: Column(
                  children: [
                    Container(height: 2, color: bottomBarColor),
                    const Expanded(
                      child: ColoredBox(
                        color: Colors.white,
                        child: SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: middleColor,
      body: SafeArea(
        child: Column(
          children: [
            // GÓRNY PASEK
            Container(
              height: 51,
              color: topBarColor,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.title}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // ŚRODEK
            Expanded(
              child: Container(
                color: middleColor,
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: widget.flashcards.isEmpty
                      ? const Center(
                          child: Text(
                            "Brak słówek do powtórki",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFFC60B1E),
                              decoration: TextDecoration.none,
                            ),
                          ),
                        )
                      : Align(
                          alignment: Alignment.topLeft,
                          key: ValueKey(currentIndex),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Temat: ${widget.isRevision ? widget.flashcards[currentIndex]['topic'] ?? '' : widget.title}',
                                style: GoogleFonts.rubik(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.flashcards[currentIndex]['pl'] ?? '',
                                style: GoogleFonts.rubik(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (isInput)
                                Column(
                                  children: [
                                    TextField(
                                      controller: answerController,
                                      enabled: !showAnswer,
                                      style: TextStyle(
                                        color: showAnswer
                                            ? (_isCorrectAnswer()
                                                ? Colors.green
                                                : Colors.red)
                                            : Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintText: 'Wpisz po hiszpańsku',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: showAnswer
                                                ? (_isCorrectAnswer()
                                                    ? Colors.green
                                                    : Colors.red)
                                                : Colors.black,
                                            width: 2,
                                          ),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: showAnswer
                                                ? (_isCorrectAnswer()
                                                    ? Colors.green
                                                    : Colors.red)
                                                : Colors.black,
                                            width: 2,
                                          ),
                                        ),
                                        errorText: showInputError && !showAnswer
                                            ? 'Pole nie może być puste'
                                            : null,
                                      ),
                                    ),
                                    if (showAnswer) ...[
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Text(
                                            widget.flashcards[currentIndex]
                                                    ['es'] ??
                                                '',
                                            style: GoogleFonts.rubik(
                                              fontSize: 18,
                                              color: Colors.red,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.volume_up,
                                                color: Colors.red),
                                            onPressed: () async {
                                              final esWord = widget.flashcards[
                                                      currentIndex]['es'] ??
                                                  '';
                                              await _speak(esWord);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                )
                              else if (showAnswer) ...[
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Text(
                                      widget.flashcards[currentIndex]['es'] ??
                                          '',
                                      style: GoogleFonts.rubik(
                                        fontSize: 18,
                                        color: Colors.red,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.volume_up,
                                          color: Colors.red),
                                      onPressed: () async {
                                        final esWord =
                                            widget.flashcards[currentIndex]
                                                    ['es'] ??
                                                '';
                                        await _speak(esWord);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
              ),
            ),
            // PASEK POSTĘPU
            Container(
              height: 40,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LinearProgressIndicator(
                    value: widget.flashcards.isEmpty
                        ? 0
                        : min(currentIndex + 1, widget.flashcards.length) /
                            widget.flashcards.length,
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFFC60B1E)),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.flashcards.isEmpty ? 0 : min(currentIndex + 1, widget.flashcards.length)} z ${widget.flashcards.length}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
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
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: widget.flashcards.isNotEmpty
                            ? showFeedback && estimatedDays != null
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FaIcon(levelIcon!,
                                          color: levelColor!, size: 24),
                                      const SizedBox(width: 10),
                                      estimatedDays == 0
                                          ? Text("Powtórka jeszcze dziś",
                                              style: GoogleFonts.rubik(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                  decoration:
                                                      TextDecoration.none))
                                          : DefaultTextStyle(
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                      "Kolejna powtórka za: "),
                                                  AnimatedDaysText(
                                                      start: 0,
                                                      end: estimatedDays!),
                                                  const Text(" dni"),
                                                ],
                                              ),
                                            ),
                                    ],
                                  )
                                : showAnswer
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          FaIconButton(
                                            icon:
                                                FontAwesomeIcons.solidFaceFrown,
                                            color: Colors.red,
                                            onTap: () => handleReaction('red'),
                                          ),
                                          FaIconButton(
                                            icon: FontAwesomeIcons.solidFaceMeh,
                                            color: Colors.yellow,
                                            onTap: () =>
                                                handleReaction('yellow'),
                                          ),
                                          FaIconButton(
                                            icon:
                                                FontAwesomeIcons.solidFaceSmile,
                                            color: Colors.green,
                                            onTap: () =>
                                                handleReaction('green'),
                                          ),
                                        ],
                                      )
                                    : ElevatedButton(
                                        onPressed: () {
                                          final isInput = widget
                                                  .flashcards[currentIndex]
                                                      ['type']
                                                  ?.toLowerCase() ==
                                              'input';
                                          if (isInput &&
                                              answerController.text
                                                  .trim()
                                                  .isEmpty) {
                                            setState(
                                                () => showInputError = true);
                                            return;
                                          }
                                          setState(() {
                                            showAnswer = true;
                                            userInput =
                                                answerController.text.trim();
                                            showInputError = false;
                                          });
                                          _speak(widget.flashcards[currentIndex]
                                                  ['es'] ??
                                              '');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: bottomBarColor,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Sprawdź'),
                                      )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> handleReaction(String level) async {
    final current = widget.flashcards[currentIndex];
    final rowIndex = await findRowIndexByPolish(current['pl'] ?? '');
    final lastReviewRaw = await getLastReviewByRowIndex(rowIndex);

    final shouldRepeat = await updateReviewData(
      polishWord: current['pl'] ?? '',
      lastReviewRaw: lastReviewRaw ?? '',
      rowIndex: rowIndex,
      level: level,
    );

    final now = DateTime.now();
    DateTime? last = DateTime.tryParse(lastReviewRaw ?? '');
    int interval = 1;

    if (level == 'green') {
      int previous = 1;
      if (last != null) {
        final diff = now.difference(last).inDays;
        if (diff > 0) previous = diff;
      }
      interval = previous * 2;
      final delta = _calculateJitter(interval);
      interval += delta;
      levelIcon = FontAwesomeIcons.solidFaceSmile;
      levelColor = Colors.green;
    } else if (level == 'yellow') {
      interval = 0;
      levelIcon = FontAwesomeIcons.solidFaceMeh;
      levelColor = Colors.yellow;
    } else {
      interval = 0;
      levelIcon = FontAwesomeIcons.solidFaceFrown;
      levelColor = Colors.red;
    }

    setState(() {
      estimatedDays = interval;
      showFeedback = true;
    });

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (widget.isRevision) {
      toRepeat.removeWhere((word) => word['pl'] == current['pl']);
      if (shouldRepeat) {
        toRepeat.add(current);
      }
    }

    if (currentIndex + 1 >= widget.flashcards.length) {
      if (widget.isRevision && toRepeat.isNotEmpty) {
        setState(() {
          widget.flashcards.clear();
          widget.flashcards.addAll(toRepeat);
          currentIndex = 0;
          toRepeat.clear();
          showAnswer = false;
          showFeedback = false;
          estimatedDays = null;
          answerController.clear();
        });
      } else {
        Navigator.pop(context);
      }
      return;
    }

    setState(() {
      currentIndex++;
      showAnswer = false;
      showFeedback = false;
      estimatedDays = null;
      answerController.clear();
    });
  }

  int _calculateJitter(int baseInterval) {
    final random = Random();
    int maxJitter = (baseInterval * 0.25).round();
    if (maxJitter < 1) return 0;
    return random.nextInt(maxJitter * 2 + 1) - maxJitter;
  }

  Future<int> findRowIndexByPolish(String word) async {
    final file = File(AppConfig.excelFilePath!);
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final plCell = row[0];
      if (plCell != null && plCell.value.toString().trim() == word.trim()) {
        return i;
      }
    }
    return -1;
  }

  Future<String?> getLastReviewByRowIndex(int rowIndex) async {
    final file = File(AppConfig.excelFilePath!);
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;
    final cell = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex));
    return cell.value?.toString();
  }
}
