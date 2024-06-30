import 'package:converge/models/player.dart';
import 'package:converge/utils.dart';

class Game {
  final String _gameId;
  late List<Player> _players;

  Game({required String gameId, required Player me}) : _gameId = gameId {
    if (!me.isMe) {
      throw ArgumentError('First player must be the game creator');
    }

    _players = [me];
  }

  String get gameId => _gameId;

  List<Player> get players => _players;

  void addPlayer(Player player) {
    if (player.isMe) {
      throw ArgumentError('There can only be one game creator');
    }
    _players.add(player);
  }

  static Future<Game> createGame(Player me) async {
    var game = Game(gameId: generateRandomString(6), me: me);
    return game;
  }

  static Future<Game> joinGame(Game game) async {
    return game;
  }
}
