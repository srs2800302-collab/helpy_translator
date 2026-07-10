import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/translate_phrase.dart';
import '../cubit/translator_phrase_cubit.dart';
import '../screens/translator_phrase_screen.dart';

final class RegistryStudioTranslatorApp extends StatelessWidget {
  const RegistryStudioTranslatorApp({required this.translatePhrase, super.key});

  final TranslatePhrase translatePhrase;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registry Studio Translator',
      debugShowCheckedModeBanner: false,
      home: BlocProvider<TranslatorPhraseCubit>(
        create: (_) => TranslatorPhraseCubit(translatePhrase: translatePhrase),
        child: const TranslatorPhraseScreen(),
      ),
    );
  }
}
