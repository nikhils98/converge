import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  const Button({super.key, required this.text, required this.onPressed});

  final String text;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outline;

    final borderSide = BorderSide(
      width: 2,
      color: borderColor,
    );

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: borderSide,
          left: borderSide,
          right: borderSide,
          bottom: BorderSide(width: 8, color: borderColor),
        ),
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
        ),
      ),
    );
  }
}
