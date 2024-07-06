import 'package:converge/models/player.dart';

class Game {
  final String _gameId;
  final List<Player> _players;

  Game({required String gameId, required List<Player> players})
      : _gameId = gameId,
        _players = players;

  String get gameId => _gameId;

  List<Player> get players => _players;

  factory Game.fromJson(Map<String, dynamic> json) {
    final playersJson = json["game"]['players'] as List;
    final players = playersJson.map((json) => Player.fromJson(json)).toList();

    return Game(gameId: json["id"], players: players);
  }
}
