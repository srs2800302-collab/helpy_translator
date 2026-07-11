import 'dart:async';

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
import '../../translator/application/translator_phrase_history_persistence.dart';
import '../../translator/presentation/cubit/translator_phrase_cubit.dart';
import '../../translator/presentation/screens/translator_phrase_screen.dart';
import '../language/registry_studio_ui_labels.dart';
import '../language/registry_studio_ui_language.dart';
import 'package:helpy_translator/core/persistence/registry_work_session_persistence.dart';
import '../../core/application/related_context/registry_resolved_related_context.dart';
import '../../translator/translator_phrase_result.dart';

final class RegistryStudioApp extends StatefulWidget {
  const RegistryStudioApp({
    required this.translatePhrase,
    required this.createRegistryEngineeringOperation,
    required this.transitionRegistryEngineeringOperationStatus,
    this.translatorPhraseHistoryPersistence,
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
  final TranslatorPhraseHistoryPersistence? translatorPhraseHistoryPersistence;
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
  static const Key _screenSelectorKey = Key('registry_studio_screen_selector');

  int _selectedScreenIndex = _translatorScreenIndex;
  RegistryResolvedRelatedContext? _resolvedRelatedContext;
  String? _initialOperationProblemStatement;
  RegistryStudioUiLanguage _selectedLanguage = RegistryStudioUiLanguage.ru;
  late final TranslatorPhraseCubit _translatorPhraseCubit;

  @override
  void initState() {
    super.initState();

    _translatorPhraseCubit = TranslatorPhraseCubit(
      translatePhrase: widget.translatePhrase,
      historyPersistence: widget.translatorPhraseHistoryPersistence,
    );

    unawaited(_translatorPhraseCubit.restore());
  }

  @override
  void dispose() {
    unawaited(_translatorPhraseCubit.close());
    super.dispose();
  }

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

    final String selectedScreenLabel = switch (_selectedScreenIndex) {
      _operationWorkspaceScreenIndex => labels.operationCreationScreenTitle,
      _relatedContextScreenIndex => labels.relatedContextPreparation.title,
      _guardRecordScreenIndex => labels.guardRecord.title,
      _ => labels.translatorScreenTitle,
    };

    return MaterialApp(
      title: labels.appTitle,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text(labels.appTitle),
          actions: <Widget>[
            _LanguageSelector(
              label: labels.languageLabel,
              selectedLanguage: _selectedLanguage,
              onChanged: _selectLanguage,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: PopupMenuButton<int>(
                key: _screenSelectorKey,
                initialValue: _selectedScreenIndex,
                position: PopupMenuPosition.under,
                onSelected: _selectScreen,
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<int>>[
                    CheckedPopupMenuItem<int>(
                      value: _translatorScreenIndex,
                      checked: _selectedScreenIndex == _translatorScreenIndex,
                      child: Text(labels.translatorScreenTitle),
                    ),
                    CheckedPopupMenuItem<int>(
                      value: _operationWorkspaceScreenIndex,
                      checked:
                          _selectedScreenIndex ==
                          _operationWorkspaceScreenIndex,
                      child: Text(labels.operationCreationScreenTitle),
                    ),
                    if (_hasRelatedContextInput)
                      CheckedPopupMenuItem<int>(
                        key: _relatedContextScreenButtonKey,
                        value: _relatedContextScreenIndex,
                        checked:
                            _selectedScreenIndex == _relatedContextScreenIndex,
                        child: Text(labels.relatedContextPreparation.title),
                      ),
                    if (_hasGuardRecordInput)
                      CheckedPopupMenuItem<int>(
                        key: _guardRecordScreenButtonKey,
                        value: _guardRecordScreenIndex,
                        checked:
                            _selectedScreenIndex == _guardRecordScreenIndex,
                        child: Text(labels.guardRecord.title),
                      ),
                  ];
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.view_list_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedScreenLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: _currentScreen()),
          ],
        ),
      ),
    );
  }

  void _requestOperationFromTranslator(TranslatorPhraseResult result) {
    final String? candidate = result.candidateCanonicalPhrase;

    if (candidate == null) {
      return;
    }

    final RegistryStudioTranslatorPhraseLabels labels =
        RegistryStudioUiLabels.forLanguage(_selectedLanguage).translatorPhrase;

    setState(() {
      _initialOperationProblemStatement =
          '${labels.sourceTextRow}:\n'
          '${result.sourceText}\n\n'
          '${labels.canonicalCandidateRow}:\n'
          '$candidate';

      _selectedScreenIndex = _operationWorkspaceScreenIndex;
    });
  }

  void _clearResolvedRelatedContext() {
    if (_resolvedRelatedContext == null) {
      return;
    }

    setState(() {
      _resolvedRelatedContext = null;
    });
  }

  void _consumeInitialOperationProblemStatement() {
    if (_initialOperationProblemStatement == null) {
      return;
    }

    setState(() {
      _initialOperationProblemStatement = null;
    });
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
        initialProblemStatement: _initialOperationProblemStatement,
        onInitialProblemStatementConsumed:
            _consumeInitialOperationProblemStatement,
        onWorkSessionCleared: _clearResolvedRelatedContext,
        workSessionPersistence: widget.workSessionPersistence,
        revisionPrimaryEntityId:
            (widget.relatedContextPrimary ?? widget.guardRecordEntity)?.id,
        revisionRelatedEntityIds: _resolvedRelatedContext
            ?.resolvedRelatedEntities
            .map((RegistryEntity entity) => entity.id),
        uiLanguage: _selectedLanguage,
        createRegistryEngineeringOperation:
            widget.createRegistryEngineeringOperation,
        transitionRegistryEngineeringOperationStatus:
            widget.transitionRegistryEngineeringOperationStatus,
      );
    }

    return BlocProvider<TranslatorPhraseCubit>.value(
      value: _translatorPhraseCubit,
      child: TranslatorPhraseScreen(
        uiLanguage: _selectedLanguage,
        onOperationRequested: _requestOperationFromTranslator,
      ),
    );
  }
}

final class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.label,
    required this.selectedLanguage,
    required this.onChanged,
  });

  static const Key selectorKey = Key('registry_studio_language_selector');

  final String label;
  final RegistryStudioUiLanguage selectedLanguage;
  final ValueChanged<RegistryStudioUiLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<RegistryStudioUiLanguage>(
      key: selectorKey,
      tooltip: label,
      initialValue: selectedLanguage,
      position: PopupMenuPosition.under,
      onSelected: onChanged,
      icon: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
      itemBuilder: (BuildContext context) {
        return RegistryStudioUiLanguage.values
            .map((RegistryStudioUiLanguage language) {
              return CheckedPopupMenuItem<RegistryStudioUiLanguage>(
                value: language,
                checked: language == selectedLanguage,
                child: Text(_languageName(language)),
              );
            })
            .toList(growable: false);
      },
    );
  }

  static String _languageName(RegistryStudioUiLanguage language) {
    return switch (language) {
      RegistryStudioUiLanguage.ru => 'Русский',
      RegistryStudioUiLanguage.en => 'English',
      RegistryStudioUiLanguage.th => 'ไทย',
    };
  }
}
