import 'package:converge/models/game.dart';
import 'package:converge/models/player.dart';
import 'package:converge/views/game_view.dart';
import 'package:converge/widgets/button.dart';
import 'package:flutter/material.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  var _name = "";
  var _gameId = "";

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                HomeTextField(
                  hintText: "Your Name",
                  onChanged: (value) => _name = value,
                  validator: (name) => Player.validateName(name),
                ),
                HomeTextField(
                  hintText: "Game ID (Optional)*",
                  onChanged: (value) => _gameId = value,
                ),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  children: [
                    const Expanded(
                      child: SizedBox(),
                    ),
                    Expanded(
                      flex: 2,
                      child: Button(
                        text: "New / Join",
                        onPressed: () async {
                          if (_formKey.currentState!.validate() == false) {
                            return;
                          }

                          var player = Player(name: _name, isMe: true);
                          Game game;

                          if (_gameId.isEmpty) {
                            game = await Game.createGame(player);
                          } else {
                            game = await Game.joinGame(
                                Game(gameId: _gameId, me: player));
                          }

                          game.addPlayer(Player(name: "yo", isMe: false));
                          game.addPlayer(Player(name: "yo1", isMe: false));
                          game.addPlayer(Player(name: "yo2", isMe: false));

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => GameView(
                                        game: game,
                                      )));
                        },
                      ),
                    ),
                    const Expanded(
                      child: SizedBox(),
                    )
                  ],
                ),
                const SizedBox(
                  height: 24,
                ),
                const Text("* Leave Game ID blank to start new game")
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeTextField extends StatelessWidget {
  const HomeTextField(
      {super.key,
      required this.hintText,
      required this.onChanged,
      this.validator});

  final String hintText;
  final Function(String) onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
          maxLines: 1,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: hintText,
          ),
          validator: validator,
          onChanged: onChanged),
    );
  }
}
