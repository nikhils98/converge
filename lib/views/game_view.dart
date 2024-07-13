import 'dart:async';

import 'package:converge/models/game.dart';
import 'package:converge/models/player.dart';
import 'package:converge/widgets/button.dart';
import 'package:converge/widgets/countdown.dart';
import 'package:converge/widgets/typing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:converge/utils.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';

class GameView extends StatefulWidget {
  const GameView({super.key, required this.playerName, required this.gameId});

  final String playerName;
  final String gameId;

  @override
  _GameViewState createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  final _channel = WebSocketChannel.connect(
    Uri.parse('wss://converge.dijkstrai.com/ws'),
  );
  String _word = "";
  bool _isRunning = false;

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
      "data": {"gameId": widget.gameId, "playerName": widget.playerName}
    };

    _channel.sink.add(jsonEncode(request));
  }

  void onTypeWord(String value) {
    _word = value;
  }

  void onSubmitWord(String value) {
    var request = {
      "action": "EnterWord",
      "data": {"word": value}
    };

    _channel.sink.add(jsonEncode(request));
  }

  void onReady(bool value) {
    var request = {
      "action": "PlayerReady",
      "data": {"isReady": value}
    };

    _channel.sink.add(jsonEncode(request));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.surface;

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
                return Scaffold(
                    appBar: AppBar(
                        leading: IconButton(
                            onPressed: () {
                              Navigator.of(context).maybePop();
                            },
                            icon: const Icon(Icons.close))),
                    body: const Center(child: CircularProgressIndicator()));
              }

              Map<String, dynamic> json = jsonDecode(snapshot.data);
              final game = Game.fromJson(json);

              final playerMe = game.players.firstWhere((player) => player.isMe);
              final otherPlayers =
                  game.players.where((player) => !player.isMe).toList();

              return Scaffold(
                  appBar: AppBar(
                    title: Row(
                      children: [
                        Text("R${game.round}"),
                        const SizedBox(
                          width: 8,
                        ),
                        if (game.isRunning)
                          Countdown(
                            onCompletion: () {
                              onSubmitWord(_word.isEmpty ? "-" : _word);
                            },
                          )
                      ],
                    ),
                    leading: IconButton(
                        onPressed: () {
                          Navigator.of(context).maybePop();
                        },
                        icon: Icon(Icons.close)),
                    actions: [
                      Text("Game ID: ${game.gameId}"),
                      IconButton(
                          onPressed: () async {
                            await Clipboard.setData(
                                ClipboardData(text: game.gameId));
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Game ID copied')));
                          },
                          icon: Icon(Icons.copy)),
                    ],
                  ),
                  body: otherPlayers.isNotEmpty
                      ? Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  PlayerCell(
                                    onSubmitWord: onSubmitWord,
                                    player: playerMe,
                                    isRunning: game.isRunning,
                                    onReady: onReady,
                                    onTypeWord: onTypeWord,
                                  ),
                                  if (otherPlayers.length >= 3)
                                    PlayerCell(
                                      onSubmitWord: onSubmitWord,
                                      player: otherPlayers[2],
                                      isRunning: game.isRunning,
                                      onReady: onReady,
                                      onTypeWord: onTypeWord,
                                    )
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  PlayerCell(
                                    onSubmitWord: onSubmitWord,
                                    player: otherPlayers[0],
                                    isRunning: game.isRunning,
                                    onReady: onReady,
                                    onTypeWord: onTypeWord,
                                  ),
                                  if (otherPlayers.length >= 2)
                                    PlayerCell(
                                      onSubmitWord: onSubmitWord,
                                      player: game.players[1],
                                      isRunning: game.isRunning,
                                      onReady: onReady,
                                      onTypeWord: onTypeWord,
                                    )
                                ],
                              ),
                            )
                          ],
                        )
                      : const Center(
                          child: Text(
                              "Invite others by copying the code on top right!"),
                        ));
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
  const PlayerCell(
      {super.key,
      required this.player,
      required this.onSubmitWord,
      required this.isRunning,
      required this.onReady,
      required this.onTypeWord});

  final Player player;
  final bool isRunning;
  final Function(String) onSubmitWord;
  final Function(String) onTypeWord;
  final Function(bool) onReady;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final largeFont = theme.textTheme.displaySmall;
    final mediumFont = theme.textTheme.titleMedium;

    final borderColor = theme.colorScheme.outline;

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 0.1, color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                flex: 1,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Icon(
                        Icons.circle_rounded,
                        color: player.isReady ? Colors.green : Colors.red,
                        size: 8,
                      ),
                    ),
                    SizedBox(
                      width: 4,
                    ),
                    Text(
                      player.name,
                      style: mediumFont,
                    ),
                  ],
                )),
            Expanded(
                flex: 2,
                child: Center(
                    child: player.isMe && player.word.isEmpty
                        ? (isRunning
                            ? TextField(
                                onSubmitted: onSubmitWord,
                                onChanged: onTypeWord,
                                style: largeFont,
                                decoration: const InputDecoration(
                                  hintText: "Enter word here",
                                ),
                              )
                            : TextButton(
                                style: TextButton.styleFrom(
                                    shape: CircleBorder(
                                        side: BorderSide(
                                            width: 1, color: borderColor)),
                                    padding: EdgeInsets.all(32),
                                    backgroundColor: player.isReady
                                        ? theme.colorScheme.secondaryContainer
                                        : theme.colorScheme.surface),
                                onPressed: () {
                                  onReady(!player.isReady);
                                },
                                child: Text("Ready")))
                        : player.word.isEmpty && isRunning
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Typing(speed: 1.5, delay: 0),
                                  Typing(speed: 1.5, delay: 125),
                                  Typing(speed: 1.5, delay: 350),
                                ],
                              )
                            : Text(
                                player.word,
                                style: largeFont,
                              ))),
            Expanded(
                flex: 1,
                child: Center(
                    child: Text(
                  player.prevWord.isEmpty ? "..." : player.prevWord,
                  style: mediumFont,
                )))
          ]),
        ),
      ),
    );
  }
}
