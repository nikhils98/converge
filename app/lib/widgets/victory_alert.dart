import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class VictoryAlert extends StatelessWidget {
  VictoryAlert(
      {super.key,
      required this.word,
      required this.onExit,
      required this.onRestart}) {
    controller.play();
  }

  final String word;
  final Function() onExit;
  final Function() onRestart;
  final controller = ConfettiController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          AlertDialog(
            title: const Text('Converged!'),
            content: Text("The converging word was $word"),
            actions: [
              TextButton(onPressed: onRestart, child: const Text('Restart')),
              TextButton(onPressed: onExit, child: const Text('Exit'))
            ],
          ),
          ConfettiWidget(
            confettiController: controller,
            shouldLoop: true,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 10,
            gravity: 0.05,
          ),
        ],
      ),
    );
  }
}
