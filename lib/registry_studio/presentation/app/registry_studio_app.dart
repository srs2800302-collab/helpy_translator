import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/application/operation_creation/create_registry_engineering_operation.dart';
import '../../core/application/operation_status/transition_registry_engineering_operation_status.dart';
import '../../core/application/related_context/prepare_registry_related_context.dart';
import '../../core/application/related_context/prepare_registry_resolved_related_context.dart';
import '../../core/domain/entities/registry_entity.dart';
import '../../core/domain/value_objects/registry_relation.dart';
import '../../guard/presentation/screens/registry_studio_guard_record_screen.dart';
import '../../operation/presentation/screens/registry_engineering_operation_workspace_screen.dart';
import '../../operation/presentation/screens/registry_related_context_preparation_screen.dart';
import '../../translator/application/translate_phrase.dart';
import '../../translator/presentation/cubit/translator_phrase_cubit.dart';
import '../../translator/presentation/screens/translator_phrase_screen.dart';
import '../language/registry_studio_ui_labels.dart';
import '../language/registry_studio_ui_language.dart';
import 'package:helpy_translator/core/persistence/registry_work_session_persistence.dart';
import '../../core/application/related_context/registry_resolved_related_context.dart';
import '../../core/domain/value_objects/registry_entity_id.dart';

final class RegistryStudioApp extends StatefulWidget {
  const RegistryStudioApp({
    required this.translatePhrase,
    required this.createRegistryEngineeringOperation,
    required this.transitionRegistryEngineeringOperationStatus,
    this.workSessionPersistence,
    this.guardRecordEntity,
    this.relatedContextPrimary,
    this.relatedContextRelations = const <RegistryRelation>[],
    this.availableRelatedEntities = const <RegistryEntity>[],
    this.prepareRegistryRelatedContext,
    this.prepareRegistryResolvedRelatedContext,
    super.key,
  }) : assert(
         relatedContextPrimary == null ||
             (prepareRegistryRelatedContext != null &&
                 prepareRegistryResolvedRelatedContext != null),
         'Related context use cases are required when primary entity is provided.',
       );

  final TranslatePhrase translatePhrase;
  final CreateRegistryEngineeringOperation createRegistryEngineeringOperation;
  final TransitionRegistryEngineeringOperationStatus
  transitionRegistryEngineeringOperationStatus;
  final RegistryWorkSessionPersistence? workSessionPersistence;

  final RegistryEntity? guardRecordEntity;
  final RegistryEntity? relatedContextPrimary;
  final Iterable<RegistryRelation> relatedContextRelations;
  final Iterable<RegistryEntity> availableRelatedEntities;
  final PrepareRegistryRelatedContext? prepareRegistryRelatedContext;
  final PrepareRegistryResolvedRelatedContext?
  prepareRegistryResolvedRelatedContext;

  @override
  State<RegistryStudioApp> createState() => _RegistryStudioAppState();
}

final class _RegistryStudioAppState extends State<RegistryStudioApp> {
  static const int _translatorScreenIndex = 0;
  static const int _operationWorkspaceScreenIndex = 1;
  static const int _relatedContextScreenIndex = 2;
  static const int _guardRecordScreenIndex = 3;

  static const Key _relatedContextScreenButtonKey = Key(
    'registry_studio_related_context_screen_button',
  );
  static const Key _guardRecordScreenButtonKey = Key(
    'registry_studio_guard_record_screen_button',
  );

  int _selectedScreenIndex = _translatorScreenIndex;
  RegistryResolvedRelatedContext? _resolvedRelatedContext;
  RegistryStudioUiLanguage _selectedLanguage = RegistryStudioUiLanguage.ru;

  bool get _hasGuardRecordInput => widget.guardRecordEntity != null;

  bool get _hasRelatedContextInput {
    return widget.relatedContextPrimary != null &&
        widget.prepareRegistryRelatedContext != null &&
        widget.prepareRegistryResolvedRelatedContext != null;
  }

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
                              _operationWorkspaceScreenIndex,
                          onPressed: () =>
                              _selectScreen(_operationWorkspaceScreenIndex),
                        ),
                      ),
                      if (_hasGuardRecordInput) ...<Widget>[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ScreenSelectionButton(
                            key: _guardRecordScreenButtonKey,
                            label: labels.guardRecord.title,
                            isSelected:
                                _selectedScreenIndex == _guardRecordScreenIndex,
                            onPressed: () =>
                                _selectScreen(_guardRecordScreenIndex),
                          ),
                        ),
                      ],
                      if (_hasRelatedContextInput) ...<Widget>[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ScreenSelectionButton(
                            key: _relatedContextScreenButtonKey,
                            label: labels.relatedContextPreparation.title,
                            isSelected:
                                _selectedScreenIndex ==
                                _relatedContextScreenIndex,
                            onPressed: () =>
                                _selectScreen(_relatedContextScreenIndex),
                          ),
                        ),
                      ],
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
    if (_selectedScreenIndex == _guardRecordScreenIndex &&
        _hasGuardRecordInput) {
      return RegistryStudioGuardRecordScreen(
        uiLanguage: _selectedLanguage,
        entity: widget.guardRecordEntity!,
      );
    }

    if (_selectedScreenIndex == _relatedContextScreenIndex &&
        _hasRelatedContextInput) {
      return RegistryRelatedContextPreparationScreen(
        uiLanguage: _selectedLanguage,
        primary: widget.relatedContextPrimary!,
        relations: widget.relatedContextRelations,
        availableRelatedEntities: widget.availableRelatedEntities,
        prepareRegistryRelatedContext: widget.prepareRegistryRelatedContext!,
        prepareRegistryResolvedRelatedContext:
            widget.prepareRegistryResolvedRelatedContext!,
        onContextPrepared: (RegistryResolvedRelatedContext context) {
          setState(() {
            _resolvedRelatedContext = context;
          });
        },
      );
    }

    if (_selectedScreenIndex == _operationWorkspaceScreenIndex) {
      return RegistryEngineeringOperationWorkspaceScreen(
        workSessionPersistence: widget.workSessionPersistence,
        revisionPrimaryEntityId:
            (widget.relatedContextPrimary ?? widget.guardRecordEntity)?.id,
        revisionRelatedEntityIds:
            _resolvedRelatedContext?.resolvedRelatedEntities.map(
              (RegistryEntity entity) => entity.id,
            ) ??
            const <RegistryEntityId>[],
        uiLanguage: _selectedLanguage,
        createRegistryEngineeringOperation:
            widget.createRegistryEngineeringOperation,
        transitionRegistryEngineeringOperationStatus:
            widget.transitionRegistryEngineeringOperationStatus,
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
    super.key,
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
