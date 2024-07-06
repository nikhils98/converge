import 'package:converge/models/game.dart';
import 'package:converge/models/player.dart';
import 'package:flutter/material.dart';
import 'package:converge/utils.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class GameView extends StatefulWidget {
  const GameView({super.key, required this.player, required this.gameId});

  final Player player;
  final String gameId;

  @override
  _GameViewState createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  final _channel = WebSocketChannel.connect(
    Uri.parse('ws://${kIsWeb ? "localhost" : "10.0.2.2"}:8080/ws'),
  );

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    var request = {
      "action": "JoinGame",
      "data": {"gameId": widget.gameId, "playerName": widget.player.name}
    };

    _channel.sink.add(jsonEncode(request));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldPop = await _showConfirmationDialog(context);
        if (shouldPop == true) {
          Navigator.pop(context);
        }
      },
      canPop: false,
      child: SafeArea(
        child: StreamBuilder(
            stream: _channel.stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              Map<String, dynamic> json = jsonDecode(snapshot.data);
              final game = Game.fromJson(json);

              return Scaffold(
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
              );
            }),
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text('Do you want to leave the game?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
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
