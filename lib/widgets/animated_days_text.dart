import 'package:flutter/material.dart';
import 'dart:async';

class AnimatedDaysText extends StatefulWidget {
  final int start;
  final int end;

  const AnimatedDaysText({required this.start, required this.end, Key? key})
      : super(key: key);

  @override
  State<AnimatedDaysText> createState() => _AnimatedDaysTextState();
}

class _AnimatedDaysTextState extends State<AnimatedDaysText> {
  late int displayedValue;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    displayedValue = widget.start;

    final totalDuration = 1500;
    final delay = totalDuration ~/
        (widget.end - widget.start == 0
            ? 1
            : (widget.end - widget.start).abs());

    _timer = Timer.periodic(Duration(milliseconds: delay), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (displayedValue < widget.end) {
          displayedValue++;
        } else if (displayedValue > widget.end) {
          displayedValue--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '$displayedValue',
    );
  }
}
