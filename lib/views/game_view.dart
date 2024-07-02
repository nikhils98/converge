import 'package:converge/models/game.dart';
import 'package:converge/models/player.dart';
import 'package:flutter/material.dart';

class GameView extends StatefulWidget {
  const GameView({super.key, required this.game});

  final Game game;

  @override
  _GameViewState createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  @override
  Widget build(BuildContext context) {
    var game = widget.game;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Game ${game.gameId}"),
        ),
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  PlayerCell(
                    player: game.players[0],
                  ),
                  if (game.players.length >= 3)
                    PlayerCell(player: game.players[2])
                ],
              ),
            ),
            if (game.players.length >= 2)
              Expanded(
                child: Row(
                  children: [
                    PlayerCell(player: game.players[1]),
                    if (game.players.length >= 4)
                      PlayerCell(player: game.players[3])
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}

class PlayerCell extends StatelessWidget {
  const PlayerCell({
    super.key,
    required this.player,
  });

  final Player player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final current = theme.textTheme.displaySmall;
    final previous = theme.textTheme.bodyLarge;

    final borderColor = theme.colorScheme.outline;

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 0.1, color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: Text(player.name)),
              Expanded(
                  flex: 2,
                  child: Center(
                      child: Text(
                    player.word,
                    style: current,
                  ))),
              Expanded(
                  flex: 1,
                  child: Center(
                      child: Text(
                    player.prevWord,
                    style: previous,
                  )))
            ],
          ),
        ),
      ),
    );
  }
}
