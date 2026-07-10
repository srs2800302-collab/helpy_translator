import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/application/operation_creation/create_registry_engineering_operation.dart';
import '../../operation/presentation/screens/registry_engineering_operation_creation_screen.dart';
import '../../translator/application/translate_phrase.dart';
import '../../translator/presentation/cubit/translator_phrase_cubit.dart';
import '../../translator/presentation/screens/translator_phrase_screen.dart';
import '../language/registry_studio_ui_labels.dart';
import '../language/registry_studio_ui_language.dart';

final class RegistryStudioApp extends StatefulWidget {
  const RegistryStudioApp({
    required this.translatePhrase,
    required this.createRegistryEngineeringOperation,
    super.key,
  });

  final TranslatePhrase translatePhrase;
  final CreateRegistryEngineeringOperation createRegistryEngineeringOperation;

  @override
  State<RegistryStudioApp> createState() => _RegistryStudioAppState();
}

final class _RegistryStudioAppState extends State<RegistryStudioApp> {
  static const int _translatorScreenIndex = 0;
  static const int _operationCreationScreenIndex = 1;

  int _selectedScreenIndex = _translatorScreenIndex;
  RegistryStudioUiLanguage _selectedLanguage = RegistryStudioUiLanguage.ru;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioUiLabels labels = RegistryStudioUiLabels.forLanguage(
      _selectedLanguage,
    );

    return MaterialApp(
      title: labels.appTitle,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text(labels.appTitle)),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  _LanguageSelector(
                    label: labels.languageLabel,
                    selectedLanguage: _selectedLanguage,
                    onChanged: _selectLanguage,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ScreenSelectionButton(
                          label: labels.translatorScreenTitle,
                          isSelected:
                              _selectedScreenIndex == _translatorScreenIndex,
                          onPressed: () =>
                              _selectScreen(_translatorScreenIndex),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ScreenSelectionButton(
                          label: labels.operationCreationScreenTitle,
                          isSelected:
                              _selectedScreenIndex ==
                              _operationCreationScreenIndex,
                          onPressed: () =>
                              _selectScreen(_operationCreationScreenIndex),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: _currentScreen()),
          ],
        ),
      ),
    );
  }

  void _selectLanguage(RegistryStudioUiLanguage language) {
    setState(() {
      _selectedLanguage = language;
    });
  }

  void _selectScreen(int screenIndex) {
    setState(() {
      _selectedScreenIndex = screenIndex;
    });
  }

  Widget _currentScreen() {
    if (_selectedScreenIndex == _operationCreationScreenIndex) {
      return RegistryEngineeringOperationCreationScreen(
        uiLanguage: _selectedLanguage,
        createRegistryEngineeringOperation:
            widget.createRegistryEngineeringOperation,
      );
    }

    return BlocProvider<TranslatorPhraseCubit>(
      create: (_) =>
          TranslatorPhraseCubit(translatePhrase: widget.translatePhrase),
      child: TranslatorPhraseScreen(uiLanguage: _selectedLanguage),
    );
  }
}

final class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.label,
    required this.selectedLanguage,
    required this.onChanged,
  });

  final String label;
  final RegistryStudioUiLanguage selectedLanguage;
  final ValueChanged<RegistryStudioUiLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<RegistryStudioUiLanguage>(
      initialValue: selectedLanguage,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: RegistryStudioUiLanguage.values
          .map(
            (language) => DropdownMenuItem<RegistryStudioUiLanguage>(
              value: language,
              child: Text(language.code),
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

final class _ScreenSelectionButton extends StatelessWidget {
  const _ScreenSelectionButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return FilledButton(onPressed: onPressed, child: Text(label));
    }

    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}
