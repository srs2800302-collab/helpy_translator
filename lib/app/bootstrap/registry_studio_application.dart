import 'package:flutter/material.dart';

import '../shell/registry_studio_shell.dart';

final class RegistryStudioApplication extends StatelessWidget {
  const RegistryStudioApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registry Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const RegistryStudioShell(),
    );
  }
}
