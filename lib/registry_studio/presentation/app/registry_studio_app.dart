import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../adapters/helpy/infrastructure/service_intake_source_block_extractor.dart';

import '../../core/application/change_impact/registry_dependency_graph.dart';
import '../../core/application/change_impact/resolve_registry_dependency_graph.dart';
import '../../core/application/operation_creation/create_registry_engineering_operation.dart';
import '../../core/application/operation_status/transition_registry_engineering_operation_status.dart';
import '../../core/application/source_comparison/compare_registry_source_text.dart';
import '../../core/application/source_indexing/registry_document_node.dart';
import '../../core/domain/value_objects/registry_entity_id.dart';
import '../../core/domain/value_objects/registry_relation.dart';
import '../../operation/presentation/screens/registry_engineering_operation_workspace_screen.dart';
import '../../translator/application/translate_phrase.dart';
import '../../translator/application/translator_phrase_history_persistence.dart';
import '../../translator/presentation/cubit/translator_phrase_cubit.dart';
import '../../translator/presentation/screens/translator_phrase_screen.dart';
import '../language/registry_studio_ui_labels.dart';
import '../language/registry_studio_ui_language.dart';
import '../screens/registry_document_explorer_screen.dart';
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
    this.resolveRegistryDependencyGraph =
        const ResolveRegistryDependencyGraph(),
    this.registryDocumentNodes,
    this.registrySourceRevision,
    this.serviceIntakeSourceBlocks,
    this.relatedContextRelations = const <RegistryRelation>[],
    super.key,
  });

  final TranslatePhrase translatePhrase;
  final TranslatorPhraseHistoryPersistence? translatorPhraseHistoryPersistence;
  final CreateRegistryEngineeringOperation createRegistryEngineeringOperation;
  final TransitionRegistryEngineeringOperationStatus
  transitionRegistryEngineeringOperationStatus;
  final RegistryWorkSessionPersistence? workSessionPersistence;
  final CompareRegistrySourceText compareRegistrySourceText;
  final ResolveRegistryDependencyGraph resolveRegistryDependencyGraph;
  final Future<List<RegistryDocumentNode>>? registryDocumentNodes;
  final Future<String>? registrySourceRevision;
  final Future<List<ServiceIntakeSourceBlock>>? serviceIntakeSourceBlocks;
  final Iterable<RegistryRelation> relatedContextRelations;

  @override
  State<RegistryStudioApp> createState() => _RegistryStudioAppState();
}

final class _RegistryStudioAppState extends State<RegistryStudioApp> {
  static const int _translatorScreenIndex = 0;
  static const int _operationWorkspaceScreenIndex = 1;
  static const int _registryDocumentScreenIndex = 2;

  static const Key _screenSelectorKey = Key('registry_studio_screen_selector');

  int _selectedScreenIndex = _translatorScreenIndex;
  String? _initialOperationProblemStatement;
  String? _initialOperationWorkingContent;
  RegistryEntityId? _operationPrimaryEntityId;
  List<RegistryEntityId>? _operationRelatedEntityIds;
  RegistryOperationComparisonViewData? _operationComparisonViewData;
  ServiceIntakeSourceBlock? _registryComparisonSource;
  ServiceIntakeSourceBlock? _registryComparisonTarget;
  String? _translatorInitialSourceText;
  String? _translatorSourceContextLabel;
  int _translatorInitialSourceVersion = 0;
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

  bool get _hasRegistryDocumentInput =>
      widget.registryDocumentNodes != null &&
      widget.registrySourceRevision != null;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioUiLabels labels = RegistryStudioUiLabels.forLanguage(
      _selectedLanguage,
    );

    final String selectedScreenLabel = switch (_selectedScreenIndex) {
      _operationWorkspaceScreenIndex => labels.operationWorkspaceScreenTitle,
      _registryDocumentScreenIndex => RegistryDocumentExplorerScreen.titleFor(
        _selectedLanguage,
      ),
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
                    if (_hasRegistryDocumentInput)
                      CheckedPopupMenuItem<int>(
                        value: _registryDocumentScreenIndex,
                        checked:
                            _selectedScreenIndex ==
                            _registryDocumentScreenIndex,
                        child: Text(
                          RegistryDocumentExplorerScreen.titleFor(
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

  void _requestTranslatorFromRegistryNode(RegistryDocumentNode node) {
    final Future<String>? sourceRevisionFuture = widget.registrySourceRevision;

    if (sourceRevisionFuture == null) {
      _openTranslatorFromRegistryNode(node, sourceRevision: null);
      return;
    }

    sourceRevisionFuture
        .then<void>((String sourceRevision) {
          if (!mounted) {
            return;
          }

          _openTranslatorFromRegistryNode(node, sourceRevision: sourceRevision);
        })
        .catchError((Object _) {
          if (!mounted) {
            return;
          }

          _openTranslatorFromRegistryNode(node, sourceRevision: null);
        });
  }

  void _openTranslatorFromRegistryNode(
    RegistryDocumentNode node, {
    required String? sourceRevision,
  }) {
    final String sourceText = node.sourceText.trim();

    if (sourceText.isEmpty) {
      return;
    }

    setState(() {
      _translatorInitialSourceText = sourceText;
      _translatorSourceContextLabel = _registryTranslatorContextLabel(
        node,
        sourceRevision,
      );
      _translatorInitialSourceVersion += 1;
      _selectedScreenIndex = _translatorScreenIndex;
    });
  }

  String _registryTranslatorContextLabel(
    RegistryDocumentNode node,
    String? sourceRevision,
  ) {
    final ({String path, String lines, String revision}) labels =
        switch (_selectedLanguage) {
          RegistryStudioUiLanguage.ru => (
            path: 'Путь',
            lines: 'Строки',
            revision: 'Исходная ревизия',
          ),
          RegistryStudioUiLanguage.en => (
            path: 'Path',
            lines: 'Lines',
            revision: 'Source revision',
          ),
          RegistryStudioUiLanguage.th => (
            path: 'เส้นทาง',
            lines: 'บรรทัด',
            revision: 'รีวิชันต้นทาง',
          ),
        };

    return <String>[
      '${labels.path}: ${node.headingPath.join(' / ')}',
      '${labels.lines}: ${node.startLine}–${node.endLine}',
      if (sourceRevision != null && sourceRevision.trim().isNotEmpty)
        '${labels.revision}: ${sourceRevision.trim()}',
    ].join('\n');
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
      _operationComparisonViewData = null;
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
      _operationComparisonViewData = null;
      _selectedScreenIndex = _operationWorkspaceScreenIndex;
    });
  }

  void _startOperationFromServiceIntakeComparison(
    ServiceIntakeSourceBlock source,
    ServiceIntakeSourceBlock target, {
    required Iterable<ServiceIntakeSourceBlock> allServiceIntakeBlocks,
    required String sourceRevision,
  }) {
    final String lineComparison = widget.compareRegistrySourceText.compare(
      source: source.sourceText,
      target: target.sourceText,
    );
    final RegistryDependencyGraph dependencyGraph = widget
        .resolveRegistryDependencyGraph(
          primaryEntityId: target.identity.entityId,
          seedRelatedEntityIds: <RegistryEntityId>[source.identity.entityId],
          relations: widget.relatedContextRelations,
        );
    final Set<RegistryEntityId> affectedIdentityIds = <RegistryEntityId>{
      target.identity.entityId,
      ...dependencyGraph.affectedEntityIds,
    };
    final List<String> affectedBranchPaths = allServiceIntakeBlocks
        .where(
          (ServiceIntakeSourceBlock block) =>
              affectedIdentityIds.contains(block.identity.entityId),
        )
        .map(
          (ServiceIntakeSourceBlock block) =>
              block.identity.path.segments.join(' / '),
        )
        .toList(growable: false);
    final List<String> unaffectedIdentityExplanations = allServiceIntakeBlocks
        .where(
          (ServiceIntakeSourceBlock block) =>
              !affectedIdentityIds.contains(block.identity.entityId),
        )
        .map(
          (ServiceIntakeSourceBlock block) =>
              '${block.identity.entityId.value}: '
              'нет прямой или транзитивной связи в текущем RegistryDependencyGraph',
        )
        .toList(growable: false);
    final Set<String> comparisonTextLines = <String>{
      for (final String text in <String>[source.sourceText, target.sourceText])
        for (final String line in text.split('\n'))
          if (line.trim().isNotEmpty && !line.trim().startsWith('#'))
            line.trim(),
    };
    final Set<String> semanticCandidateKeys = <String>{};
    final List<String> semanticCandidateExplanations = <String>[];

    for (final ServiceIntakeSourceBlock block in allServiceIntakeBlocks) {
      if (affectedIdentityIds.contains(block.identity.entityId)) {
        continue;
      }

      for (final String line in block.sourceText.split('\n')) {
        final String normalizedLine = line.trim();

        if (normalizedLine.isEmpty ||
            normalizedLine.startsWith('#') ||
            !comparisonTextLines.contains(normalizedLine)) {
          continue;
        }

        final String candidateKey =
            '${block.identity.entityId.value}\n$normalizedLine';

        if (!semanticCandidateKeys.add(candidateKey)) {
          continue;
        }

        semanticCandidateExplanations.add(
          '${block.identity.entityId.value}: "$normalizedLine" — '
          'текстовое совпадение без подтверждённой semantic relation',
        );
      }
    }

    setState(() {
      _initialOperationProblemStatement = <String>[
        'Источник сравнения: ${source.identity.heading}',
        'Источник ID: ${source.identity.entityId.value}',
        'Цель изменения: ${target.identity.heading}',
        'Цель ID: ${target.identity.entityId.value}',
        '',
        'Затронутые Registry identities:',
        ...dependencyGraph.affectedEntityIds.map(
          (RegistryEntityId id) => '- ${id.value}',
        ),
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
      _operationRelatedEntityIds = dependencyGraph.affectedEntityIds;
      _operationComparisonViewData = (
        operationType: 'Service Intake comparison',
        projectAdapter: 'Helpy Service Intake',
        sourceRevision: sourceRevision.trim(),
        sourceHeading: source.identity.heading,
        sourceEntityId: source.identity.entityId,
        sourceRegistryPath: source.identity.path.segments.join(' / '),
        sourceEvidence:
            'H${source.identity.ownerHeadingLevel} '
            '${source.identity.ownerHeading} → '
            'H${source.identity.headingLevel} ${source.identity.heading}; '
            'lines ${source.startLine}–${source.endLine}',
        sourceText: source.sourceText.trim(),
        targetHeading: target.identity.heading,
        targetEntityId: target.identity.entityId,
        targetRegistryPath: target.identity.path.segments.join(' / '),
        targetEvidence:
            'H${target.identity.ownerHeadingLevel} '
            '${target.identity.ownerHeading} → '
            'H${target.identity.headingLevel} ${target.identity.heading}; '
            'lines ${target.startLine}–${target.endLine}',
        targetText: target.sourceText.trim(),
        lineDiff: lineComparison,
        dependencyGraph: dependencyGraph,
        affectedBranchPaths: affectedBranchPaths,
        unaffectedIdentityExplanations: unaffectedIdentityExplanations,
        semanticCandidateExplanations: semanticCandidateExplanations,
      );
      _selectedScreenIndex = _operationWorkspaceScreenIndex;
    });
  }

  void _clearOperationContext() {
    if (_initialOperationWorkingContent == null &&
        _operationPrimaryEntityId == null &&
        _operationRelatedEntityIds == null &&
        _operationComparisonViewData == null) {
      return;
    }

    setState(() {
      _initialOperationWorkingContent = null;
      _operationPrimaryEntityId = null;
      _operationRelatedEntityIds = null;
      _operationComparisonViewData = null;
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
    if (_selectedScreenIndex == _registryDocumentScreenIndex &&
        _hasRegistryDocumentInput) {
      final Future<List<ServiceIntakeSourceBlock>>? sourceBlocks =
          widget.serviceIntakeSourceBlocks;

      if (sourceBlocks == null) {
        return RegistryDocumentExplorerScreen(
          uiLanguage: _selectedLanguage,
          nodes: widget.registryDocumentNodes!,
          sourceRevision: widget.registrySourceRevision!,
          onNodeTranslationRequested: _requestTranslatorFromRegistryNode,
        );
      }

      return FutureBuilder<List<ServiceIntakeSourceBlock>>(
        future: sourceBlocks,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<ServiceIntakeSourceBlock>> snapshot,
            ) {
              final List<ServiceIntakeSourceBlock> blocks =
                  snapshot.data ?? const <ServiceIntakeSourceBlock>[];
              final Map<(int, int), ServiceIntakeSourceBlock> blocksByRange =
                  <(int, int), ServiceIntakeSourceBlock>{
                    for (final ServiceIntakeSourceBlock block in blocks)
                      (block.startLine, block.endLine): block,
                  };

              return RegistryDocumentExplorerScreen(
                uiLanguage: _selectedLanguage,
                nodes: widget.registryDocumentNodes!,
                sourceRevision: widget.registrySourceRevision!,
                onNodeTranslationRequested: _requestTranslatorFromRegistryNode,
                nodeSearchTextBuilder: (RegistryDocumentNode node) {
                  final ServiceIntakeSourceBlock? block =
                      blocksByRange[(node.startLine, node.endLine)];

                  if (block == null) {
                    return null;
                  }

                  return '${block.identity.entityId.value}\n'
                      '${block.identity.path.segments.join(' / ')}';
                },
                nodeActionsBuilder: (BuildContext context, RegistryDocumentNode node) {
                  final ServiceIntakeSourceBlock? block =
                      blocksByRange[(node.startLine, node.endLine)];

                  if (block == null) {
                    return null;
                  }

                  final bool selectedAsSource =
                      _registryComparisonSource?.identity.entityId ==
                      block.identity.entityId;
                  final bool selectedAsTarget =
                      _registryComparisonTarget?.identity.entityId ==
                      block.identity.entityId;
                  final bool comparisonReady =
                      _registryComparisonSource != null &&
                      _registryComparisonTarget != null;

                  final ({
                    String source,
                    String target,
                    String compare,
                    String selectedSource,
                    String selectedTarget,
                    String notSelected,
                  })
                  comparisonLabels = switch (_selectedLanguage) {
                    RegistryStudioUiLanguage.ru => (
                      source: 'Источник',
                      target: 'Цель',
                      compare: 'Сравнить выбранное',
                      selectedSource: 'Выбранный источник',
                      selectedTarget: 'Выбранная цель',
                      notSelected: 'не выбрано',
                    ),
                    RegistryStudioUiLanguage.en => (
                      source: 'Source',
                      target: 'Target',
                      compare: 'Compare selected',
                      selectedSource: 'Selected source',
                      selectedTarget: 'Selected target',
                      notSelected: 'not selected',
                    ),
                    RegistryStudioUiLanguage.th => (
                      source: 'ต้นทาง',
                      target: 'เป้าหมาย',
                      compare: 'เปรียบเทียบรายการที่เลือก',
                      selectedSource: 'ต้นทางที่เลือก',
                      selectedTarget: 'เป้าหมายที่เลือก',
                      notSelected: 'ยังไม่ได้เลือก',
                    ),
                  };

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              key: ValueKey<String>(
                                'service_intake_compare_source_'
                                '${block.identity.entityId.value}',
                              ),
                              onPressed: () {
                                setState(() {
                                  _registryComparisonSource = block;

                                  if (selectedAsTarget) {
                                    _registryComparisonTarget = null;
                                  }
                                });
                                Navigator.of(context).pop();
                              },
                              icon: Icon(
                                selectedAsSource
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                              ),
                              label: Text(comparisonLabels.source),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: ValueKey<String>(
                                'service_intake_compare_target_'
                                '${block.identity.entityId.value}',
                              ),
                              onPressed: () {
                                setState(() {
                                  _registryComparisonTarget = block;

                                  if (selectedAsSource) {
                                    _registryComparisonSource = null;
                                  }
                                });
                                Navigator.of(context).pop();
                              },
                              icon: Icon(
                                selectedAsTarget
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                              ),
                              label: Text(comparisonLabels.target),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        key: ValueKey<String>(
                          'service_intake_start_operation_'
                          '${block.identity.entityId.value}',
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _startOperationFromServiceIntakeSourceBlock(block);
                        },
                        icon: const Icon(Icons.engineering_outlined),
                        label: Text(
                          RegistryStudioUiLabels.forLanguage(
                            _selectedLanguage,
                          ).operationWorkspaceScreenTitle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        key: const Key(
                          'service_intake_source_comparison_action',
                        ),
                        onPressed: comparisonReady
                            ? () async {
                                final ServiceIntakeSourceBlock source =
                                    _registryComparisonSource!;
                                final ServiceIntakeSourceBlock target =
                                    _registryComparisonTarget!;

                                final String sourceRevision =
                                    await widget.registrySourceRevision!;

                                if (!mounted || !context.mounted) {
                                  return;
                                }

                                Navigator.of(context).pop();
                                _startOperationFromServiceIntakeComparison(
                                  source,
                                  target,
                                  allServiceIntakeBlocks: blocks,
                                  sourceRevision: sourceRevision,
                                );
                              }
                            : null,
                        child: Text(comparisonLabels.compare),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${comparisonLabels.selectedSource}: '
                        '${_registryComparisonSource?.identity.heading ?? comparisonLabels.notSelected}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${comparisonLabels.selectedTarget}: '
                        '${_registryComparisonTarget?.identity.heading ?? comparisonLabels.notSelected}',
                      ),
                    ],
                  );
                },
              );
            },
      );
    }

    if (_selectedScreenIndex == _operationWorkspaceScreenIndex) {
      return RegistryEngineeringOperationWorkspaceScreen(
        initialProblemStatement: _initialOperationProblemStatement,
        initialWorkingContent: _initialOperationWorkingContent,
        onInitialProblemStatementConsumed:
            _consumeInitialOperationProblemStatement,
        onWorkSessionCleared: _clearOperationContext,
        workSessionPersistence: widget.workSessionPersistence,
        revisionPrimaryEntityId: _operationPrimaryEntityId,
        revisionRelatedEntityIds: _operationRelatedEntityIds,
        comparisonViewData: _operationComparisonViewData,
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
        initialSourceText: _translatorInitialSourceText,
        sourceContextLabel: _translatorSourceContextLabel,
        initialSourceVersion: _translatorInitialSourceVersion,
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
