import 'package:converge/models/player.dart';
import 'package:converge/views/game_view.dart';
import 'package:converge/widgets/button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: kIsWeb ? 480 : double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            HomeTextField(
                              hintText: "Your Name",
                              onChanged: (value) {
                                _name = value;
                              },
                              validator: (name) => Player.validateName(name),
                            ),
                            HomeTextField(
                                hintText: "Game ID (Optional)*",
                                onChanged: (value) {
                                  setState(() {
                                    _gameId = value;
                                  });
                                }),
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
                                    text: _gameId.isEmpty
                                        ? "New Game"
                                        : "Join Game",
                                    onPressed: () async {
                                      if (_formKey.currentState!.validate() ==
                                          false) {
                                        return;
                                      }

                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => GameView(
                                                    playerName: _name,
                                                    gameId: _gameId,
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
                            const Text(
                                "* Leave Game ID blank to start new game"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                child: const Column(
                  children: [
                    Icon(
                      Icons.arrow_drop_up,
                    ),
                    Text("Rules"),
                  ],
                ),
                onTap: () {
                  _showRulesBottomSheet(context, theme);
                },
                onVerticalDragEnd: (details) {
                  _showRulesBottomSheet(context, theme);
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showRulesBottomSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height / 1.5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        "Rules",
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      const Text(
                        """A fun 2 player game in which the goal is for players to arrive at the same word. Both players start with a random word and in the subsequent rounds try to find the one that has a similar meaning to both the words in the previous round. 
                        
For example John starts with \"red\" and Jane with \"fruit\". In the second round they both may come up with \"apple\" and converge! If not the game continues until a match is found.""",
                      ),
                    ],
                  ),
                  if (!kIsWeb)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: InkWell(
                          child: const Text(
                            "Privacy policy",
                            style: TextStyle(color: Colors.deepPurple),
                          ),
                          onTap: () => launchUrl(
                              Uri.parse("https://converge-dg4.pages.dev/privacy/"))),
                    )
                ],
              ),
            )));
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
