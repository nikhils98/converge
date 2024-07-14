import 'package:converge/views/home_view.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
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
