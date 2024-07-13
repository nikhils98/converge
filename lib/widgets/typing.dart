import 'dart:async';

import 'package:flutter/material.dart';

class Typing extends StatefulWidget {
  Typing({required this.speed, required this.delay});

  final double speed;
  final int delay;

  @override
  _TypingState createState() => _TypingState();
}

class _TypingState extends State<Typing> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    Timer(Duration(milliseconds: widget.delay), animate);
  }

  void animate() {
    _controller = AnimationController(
      duration: Duration(milliseconds: (1000 / widget.speed).round()),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: -20).animate(_controller!)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface;

    return Transform.translate(
      offset: Offset(0, _animation?.value ?? 0),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
