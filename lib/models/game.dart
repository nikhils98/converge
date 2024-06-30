import 'package:converge/models/player.dart';

class Game {
  final String _gameId;
  late List<Player> _players;

  Game({required String gameId, required Player me}) : _gameId = gameId {
    if (!me.isMe) {
      throw ArgumentError('First player must be the game creator');
    }

    _players = [me];
  }

  get gameId => _gameId;

  get players => _players;

  void addPlayer(Player player) {
    if (player.isMe) {
      throw ArgumentError('There can only be one game creator');
    }
    _players.add(player);
  }
}
