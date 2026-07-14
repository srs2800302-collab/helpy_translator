import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../adapters/helpy/infrastructure/service_intake_source_block_extractor.dart';
import '../../adapters/helpy/presentation/screens/service_intake_source_blocks_screen.dart';

import '../../core/application/change_impact/resolve_affected_registry_entity_ids.dart';
import '../../core/application/operation_creation/create_registry_engineering_operation.dart';
import '../../core/application/operation_status/transition_registry_engineering_operation_status.dart';
import '../../core/application/source_comparison/compare_registry_source_text.dart';
import '../../core/domain/value_objects/registry_entity_id.dart';
import '../../core/domain/value_objects/registry_relation.dart';
import '../../operation/presentation/screens/registry_engineering_operation_workspace_screen.dart';
import '../../translator/application/translate_phrase.dart';
import '../../translator/application/translator_phrase_history_persistence.dart';
import '../../translator/presentation/cubit/translator_phrase_cubit.dart';
import '../../translator/presentation/screens/translator_phrase_screen.dart';
import '../language/registry_studio_ui_labels.dart';
import '../language/registry_studio_ui_language.dart';
import 'package:helpy_translator/core/persistence/registry_work_session_persistence.dart';
import '../../translator/translator_phrase_result.dart';

final class RegistryStudioApp extends StatefulWidget {
  const RegistryStudioApp({
    required this.translatePhrase,
    required this.createRegistryEngineeringOperation,
    required this.transitionRegistryEngineeringOperationStatus,
    this.translatorPhraseHistoryPersistence,
    this.workSessionPersistence,
    this.compareRegistrySourceText = const CompareRegistrySourceText(),
    this.resolveAffectedRegistryEntityIds =
        const ResolveAffectedRegistryEntityIds(),
    this.serviceIntakeSourceBlocks,
    this.relatedContextRelations = const <RegistryRelation>[],
    this.automaticOperationCreation = false,
    super.key,
  });

  final TranslatePhrase translatePhrase;
  final TranslatorPhraseHistoryPersistence? translatorPhraseHistoryPersistence;
  final CreateRegistryEngineeringOperation createRegistryEngineeringOperation;
  final TransitionRegistryEngineeringOperationStatus
  transitionRegistryEngineeringOperationStatus;
  final RegistryWorkSessionPersistence? workSessionPersistence;
  final CompareRegistrySourceText compareRegistrySourceText;
  final ResolveAffectedRegistryEntityIds resolveAffectedRegistryEntityIds;
  final Future<List<ServiceIntakeSourceBlock>>? serviceIntakeSourceBlocks;
  final Iterable<RegistryRelation> relatedContextRelations;
  final bool automaticOperationCreation;

  @override
  State<RegistryStudioApp> createState() => _RegistryStudioAppState();
}

final class _RegistryStudioAppState extends State<RegistryStudioApp> {
  static const int _translatorScreenIndex = 0;
  static const int _operationWorkspaceScreenIndex = 1;
  static const int _serviceIntakeSourceScreenIndex = 2;

  static const Key _screenSelectorKey = Key('registry_studio_screen_selector');

  int _selectedScreenIndex = _translatorScreenIndex;
  String? _initialOperationProblemStatement;
  String? _initialOperationWorkingContent;
  RegistryEntityId? _operationPrimaryEntityId;
  List<RegistryEntityId>? _operationRelatedEntityIds;
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

  bool get _hasServiceIntakeSourceInput =>
      widget.serviceIntakeSourceBlocks != null;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioUiLabels labels = RegistryStudioUiLabels.forLanguage(
      _selectedLanguage,
    );

    final String selectedScreenLabel = switch (_selectedScreenIndex) {
      _operationWorkspaceScreenIndex => labels.operationCreationScreenTitle,
      _serviceIntakeSourceScreenIndex =>
        ServiceIntakeSourceBlocksScreen.titleFor(_selectedLanguage),
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
                    if (_hasServiceIntakeSourceInput)
                      CheckedPopupMenuItem<int>(
                        value: _serviceIntakeSourceScreenIndex,
                        checked:
                            _selectedScreenIndex ==
                            _serviceIntakeSourceScreenIndex,
                        child: Text(
                          ServiceIntakeSourceBlocksScreen.titleFor(
                            _selectedLanguage,
                          ),
                        ),
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

      _initialOperationWorkingContent = null;
      _operationPrimaryEntityId = null;
      _operationRelatedEntityIds = null;
      _selectedScreenIndex = _operationWorkspaceScreenIndex;
    });
  }

  void _startOperationFromServiceIntakeSourceBlock(
    ServiceIntakeSourceBlock block,
  ) {
    setState(() {
      _initialOperationProblemStatement =
          '${block.identity.heading}\n'
          '${block.identity.entityId.value}\n\n'
          '${block.sourceText}';
      _initialOperationWorkingContent = null;
      _operationPrimaryEntityId = block.identity.entityId;
      _operationRelatedEntityIds = null;
      _selectedScreenIndex = _operationWorkspaceScreenIndex;
    });
  }

  void _startOperationFromServiceIntakeComparison(
    ServiceIntakeSourceBlock source,
    ServiceIntakeSourceBlock target,
  ) {
    final String lineComparison = widget.compareRegistrySourceText.compare(
      source: source.sourceText,
      target: target.sourceText,
    );
    final List<RegistryEntityId> affectedEntityIds = widget
        .resolveAffectedRegistryEntityIds(
          primaryEntityId: target.identity.entityId,
          seedRelatedEntityIds: <RegistryEntityId>[source.identity.entityId],
          relations: widget.relatedContextRelations,
        );

    setState(() {
      _initialOperationProblemStatement = <String>[
        'Источник сравнения: ${source.identity.heading}',
        'Источник ID: ${source.identity.entityId.value}',
        'Цель изменения: ${target.identity.heading}',
        'Цель ID: ${target.identity.entityId.value}',
        '',
        'Затронутые Registry identities:',
        ...affectedEntityIds.map((RegistryEntityId id) => '- ${id.value}'),
        '',
        'Исходная версия:',
        source.sourceText.trim(),
        '',
        'Предлагаемая версия:',
        target.sourceText.trim(),
        '',
        'Построчные изменения:',
        lineComparison,
      ].join('\n');
      _initialOperationWorkingContent = target.sourceText.trim();
      _operationPrimaryEntityId = target.identity.entityId;
      _operationRelatedEntityIds = affectedEntityIds;
      _selectedScreenIndex = _operationWorkspaceScreenIndex;
    });
  }

  void _clearOperationContext() {
    if (_initialOperationWorkingContent == null &&
        _operationPrimaryEntityId == null &&
        _operationRelatedEntityIds == null) {
      return;
    }

    setState(() {
      _initialOperationWorkingContent = null;
      _operationPrimaryEntityId = null;
      _operationRelatedEntityIds = null;
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
    if (_selectedScreenIndex == _serviceIntakeSourceScreenIndex &&
        _hasServiceIntakeSourceInput) {
      return ServiceIntakeSourceBlocksScreen(
        uiLanguage: _selectedLanguage,
        sourceBlocks: widget.serviceIntakeSourceBlocks!,
        onComparisonRequested: _startOperationFromServiceIntakeComparison,
        onStartOperation: _startOperationFromServiceIntakeSourceBlock,
      );
    }

    if (_selectedScreenIndex == _operationWorkspaceScreenIndex) {
      return RegistryEngineeringOperationWorkspaceScreen(
        initialProblemStatement: _initialOperationProblemStatement,
        initialWorkingContent: _initialOperationWorkingContent,
        automaticOperationCreation: widget.automaticOperationCreation,
        onInitialProblemStatementConsumed:
            _consumeInitialOperationProblemStatement,
        onWorkSessionCleared: _clearOperationContext,
        workSessionPersistence: widget.workSessionPersistence,
        revisionPrimaryEntityId: _operationPrimaryEntityId,
        revisionRelatedEntityIds: _operationRelatedEntityIds,
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
