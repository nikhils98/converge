import 'dart:async';

import 'package:flutter/material.dart';

class Typing extends StatelessWidget {
  const Typing({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OscillatingDot(speed: 1.5, delay: 0),
        OscillatingDot(speed: 1.5, delay: 125),
        OscillatingDot(speed: 1.5, delay: 350),
      ],
    );
  }
}

class OscillatingDot extends StatefulWidget {
  const OscillatingDot({super.key, required this.speed, required this.delay});

  final double speed;
  final int delay;

  @override
  _OscillatingDotState createState() => _OscillatingDotState();
}

class _OscillatingDotState extends State<OscillatingDot>
    with SingleTickerProviderStateMixin {
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
