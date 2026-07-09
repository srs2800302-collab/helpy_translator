import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      title: 'Registry Studio Clean Rebuild',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: SelectableText(
              'Registry Studio clean rebuild\n\n'
              'Legacy Translator bootstrap removed.\n'
              'Clean runtime composition is not wired yet.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ),
  );
}
