import 'package:flutter/material.dart';

class VictoryAlert extends StatelessWidget {
  const VictoryAlert(
      {super.key,
      required this.word,
      required this.onExit,
      required this.onRestart});

  final String word;
  final Function() onExit;
  final Function() onRestart;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Converged!'),
      content: Text("The converging word was $word"),
      actions: [
        TextButton(onPressed: onRestart, child: Text('Restart')),
        TextButton(onPressed: onExit, child: Text('Exit'))
      ],
    );
  }
}
