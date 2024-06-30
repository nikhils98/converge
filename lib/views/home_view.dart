import 'package:flutter/material.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  var _name = "";
  var _gameId = "";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HomeTextField(
            hintText: "Your Name",
            onChanged: (value) => _name = value,
          ),
          HomeTextField(
            hintText: "Game ID (Optional)*",
            onChanged: (value) => _gameId = value,
          ),
          const SizedBox(
            height: 16,
          ),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () async {
                    print(_name + ", " + _gameId);
                  },
                  child: const Text("New / Join"))),
          const SizedBox(
            height: 16,
          ),
          const Text("* Leave Game ID blank to start new game")
        ],
      ),
    );
  }
}

class HomeTextField extends StatelessWidget {
  const HomeTextField(
      {super.key, required this.hintText, required this.onChanged});

  final String hintText;
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
          maxLines: 1,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: hintText,
          ),
          onChanged: onChanged),
    );
  }
}
