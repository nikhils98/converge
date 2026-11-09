class Player {
  String id;
  String name;
  String _word;
  String prevWord;
  final bool _isMe;
  final bool _isReady;

  Player(
      {required this.id,
      required this.name,
      required bool isMe,
      required bool isReady})
      : _isMe = isMe,
        _word = "",
        prevWord = "",
        _isReady = isReady;

  String get word => _word;

  set word(String word) {
    if (word.length > 15) {
      throw ArgumentError('Word cannot be longer than 15 characters');
    }

    _word = word;
  }

  bool get isMe => _isMe;

  bool get isReady => _isReady;

  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return "Name cannot be empty";
    } else if (name.length > 10) {
      return "Name cannot be longer than 10 characters";
    }
    return null;
  }

  factory Player.fromJson(Map<String, dynamic> json, String myId) {
    final player = Player(
        id: json['id'],
        name: json['name'],
        isMe: json['id'] == myId,
        isReady: json['isReady']);

    player.word = json['word'];
    player.prevWord = json['prevWord'];

    return player;
  }
}
