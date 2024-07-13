import 'package:converge/models/player.dart';

class Game {
  final String _gameId;
  final List<Player> _players;
  final int _round;
  final bool _isRunning;

  Game(
      {required String gameId,
      required List<Player> players,
      required int round,
      required bool isRunning})
      : _gameId = gameId,
        _players = players,
        _round = round,
        _isRunning = isRunning;

  String get gameId => _gameId;

  List<Player> get players => _players;

  int get round => _round;

  bool get isRunning => _isRunning;

  factory Game.fromJson(Map<String, dynamic> json) {
    final gameJson = json["game"];
    final playersJson = gameJson['players'] as List;
    final players = playersJson
        .map((playerJson) => Player.fromJson(playerJson, json["playerId"]))
        .toList();

    return Game(
        gameId: gameJson["id"],
        round: gameJson["round"],
        isRunning: gameJson["isRunning"],
        players: players);
  }

  @override
  String toString() {
    return "Round: ${round}, running: ${isRunning}";
  }
}
