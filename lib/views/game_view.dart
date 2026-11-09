import 'dart:async';

import 'package:converge/models/game.dart';
import 'package:converge/models/player.dart';
import 'package:converge/widgets/countdown.dart';
import 'package:converge/widgets/typing.dart';
import 'package:converge/widgets/victory_alert.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

const uri = 'wss://converge-server.onrender.com/ws';

// const uri = 'ws://${kIsWeb ? "localhost" : "10.0.2.2"}:8080/ws';

class GameView extends StatefulWidget {
  const GameView({super.key, required this.playerName, required this.gameId});

  final String playerName;
  final String gameId;

  @override
  _GameViewState createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  late WebSocketChannel _channel;
  String _word = "";
  bool _isVictoryAlertShowing = false;
  String? _connectionError;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    _connectionError = null;

    final channel = WebSocketChannel.connect(Uri.parse(uri));
    _channel = channel;

    var request = {
      "action": "JoinGame",
      "data": {"gameId": widget.gameId, "playerName": widget.playerName}
    };

    // Wait for the connection to be established before sending, and surface any
    // failure (server down, cold start, no network) as a retryable error rather
    // than letting it crash the app with an unhandled WebSocketChannelException.
    channel.ready.timeout(const Duration(seconds: 30)).then((_) {
      channel.sink.add(jsonEncode(request));
    }).catchError((Object error) {
      if (!mounted) return;
      setState(() {
        _connectionError =
            "Couldn't connect to the server. Please check your internet connection and try again.";
      });
    });
  }

  void _retry() {
    try {
      _channel.sink.close();
    } catch (_) {}
    setState(_connect);
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
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

  void onRestart() {
    var request = {
      "action": "Restart",
    };

    _channel.sink.add(jsonEncode(request));
    _isVictoryAlertShowing = false;
    Navigator.pop(context);
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
              if (_connectionError != null) {
                return _buildMessageScaffold(_connectionError!,
                    showRetry: true);
              }

              if (snapshot.hasError) {
                return _buildMessageScaffold(
                    "Connection lost. Please check your internet connection and try again.",
                    showRetry: true);
              }

              if (!snapshot.hasData) {
                return _buildMessageScaffold(null, showSpinner: true);
              }

              Map<String, dynamic> json;
              try {
                json = jsonDecode(snapshot.data);
              } catch (_) {
                return _buildMessageScaffold(
                    "Something went wrong. Please try again.",
                    showRetry: true);
              }

              if (json["error"] != null) {
                return Scaffold(
                    appBar: AppBar(
                        leading: IconButton(
                            onPressed: () {
                              Navigator.of(context).maybePop();
                            },
                            icon: const Icon(Icons.close))),
                    body: Center(child: Text(json["error"])));
              }

              final game = Game.fromJson(json);

              if (game.isWon && !_isVictoryAlertShowing) {
                _isVictoryAlertShowing = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showDialog(
                      context: context,
                      builder: (context) => VictoryAlert(
                            word: _word,
                            onExit: () {
                              _isVictoryAlertShowing = false;
                              Navigator.pop(context);
                            },
                            onRestart: () => onRestart(),
                          ),
                      barrierDismissible: false);
                });
              } else if (!game.isWon && _isVictoryAlertShowing) {
                _isVictoryAlertShowing = false;
                Navigator.pop(context);
              }

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
                              var notSubmitted = playerMe.word.isEmpty;

                              if (notSubmitted) {
                                onSubmitWord(_word.isEmpty ? "-" : _word);
                              }
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

  Widget _buildMessageScaffold(String? message,
      {bool showSpinner = false, bool showRetry = false}) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                Navigator.of(context).maybePop();
              },
              icon: const Icon(Icons.close))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showSpinner) const CircularProgressIndicator(),
              if (message != null)
                Text(message, textAlign: TextAlign.center),
              if (showRetry) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: _retry, child: const Text("Retry")),
              ],
            ],
          ),
        ),
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
                    const SizedBox(
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
                    child: PlayerWord(
                        player: player,
                        isRunning: isRunning,
                        onSubmitWord: onSubmitWord,
                        onTypeWord: onTypeWord,
                        borderColor: borderColor,
                        onReady: onReady))),
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

class PlayerWord extends StatelessWidget {
  const PlayerWord({
    super.key,
    required this.player,
    required this.isRunning,
    required this.onSubmitWord,
    required this.onTypeWord,
    required this.borderColor,
    required this.onReady,
  });

  final Player player;
  final bool isRunning;
  final Function(String) onSubmitWord;
  final Function(String) onTypeWord;
  final Color borderColor;
  final Function(bool) onReady;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final largeFont = theme.textTheme.displaySmall;

    if (player.isMe) {
      if (player.word.isEmpty) {
        return isRunning
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
                        side: BorderSide(width: 1, color: borderColor)),
                    padding: const EdgeInsets.all(32),
                    backgroundColor: player.isReady
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.surface),
                onPressed: () {
                  onReady(!player.isReady);
                },
                child: const Text("Ready"));
      }

      return Text(
        player.word,
        style: largeFont,
      );
    }

    return isRunning
        ? player.word.isEmpty
            ? const Typing()
            : const SubmittedIcon()
        : Text(
            player.word,
            style: largeFont,
          );
  }
}

class SubmittedIcon extends StatelessWidget {
  const SubmittedIcon({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1000),
            color: theme.colorScheme.secondaryContainer),
        child: Icon(Icons.check));
  }
}
