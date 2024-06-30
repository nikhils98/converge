class Player {
  late String _name;
  String _word;
  String _prevWord;
  final bool _isMe;

  Player({required name, required bool isMe})
      : _isMe = isMe,
        _word = "",
        _prevWord = "" {
    this.name = name;
  }

  String get name => _name;

  set name(String name) {
    if (name.length > 10) {
      throw ArgumentError('Name cannot be longer than 10 characters');
    }

    _name = name;
  }

  String get word => _word;

  set word(String word) {
    if (word.length > 15) {
      throw ArgumentError('Word cannot be longer than 15 characters');
    }

    _prevWord = _word.isEmpty ? "" : _word;
    _word = word;
  }

  String get prevWord => _prevWord;

  bool get isMe => _isMe;
}
