import 'package:converge/views/home_view.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  runApp(const MainApp());
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightColorScheme = ColorScheme.fromSeed(
        seedColor: Colors.yellow, brightness: Brightness.light);

    final darkColorScheme = ColorScheme.fromSeed(
        seedColor: Colors.yellow, brightness: Brightness.dark);

    return MaterialApp(
      title: "Converge",
      theme: _getThemeData(lightColorScheme),
      home: const HomeView(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _getThemeData(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
      )),
    );
  }
}
