import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/translator_cubit.dart';
import '../../../../core/persistence/registry_phrase_status_persistence.dart';
import '../../../../core/persistence/registry_work_session_persistence.dart';
import '../../domain/entities/canonical_audit_result.dart';
import '../../domain/entities/registry_node.dart';
import '../../domain/entities/translation_result.dart';
import '../cubit/translator_state.dart';
import '../widgets/canonical_audit_results_view.dart';
import '../widgets/progress_status_card.dart';
import '../widgets/status_summary_view.dart';
import '../widgets/translation_result_view.dart';

final class TranslatorPage extends StatefulWidget {
  const TranslatorPage({super.key});

  @override
  State<TranslatorPage> createState() => _TranslatorPageState();
}

final class _TranslatorPageState extends State<TranslatorPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _translate() {
    FocusScope.of(context).unfocus();
    context.read<TranslatorCubit>().translate(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Helpy Registry Studio'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Перевод'),
              Tab(text: 'Registry'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _TranslationWorkspace(
              controller: _controller,
              onTranslate: _translate,
            ),
            _RegistryExplorerView(
              onPhraseSelected: (String phrase) {
                _controller.text = phrase;
                DefaultTabController.of(context).animateTo(0);
              },
            ),
          ],
        ),
      ),
    );
  }
}

final class _TranslationWorkspace extends StatelessWidget {
  const _TranslationWorkspace({
    required this.controller,
    required this.onTranslate,
  });

  final TextEditingController controller;
  final VoidCallback onTranslate;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TranslatorCubit, TranslatorState>(
      builder: (BuildContext context, TranslatorState state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (state.translationHistory.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: StatusSummaryView.fromTranslationResults(
                    results: state.translationHistory,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 3,
              maxLines: 8,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Формулировка для проверки',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: state.status == TranslatorStatus.loading
                        ? null
                        : onTranslate,
                    child: state.status == TranslatorStatus.loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Перевести'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: state.status == TranslatorStatus.loading ||
                          state.status == TranslatorStatus.auditLoading
                      ? null
                      : () {
                          context.read<TranslatorCubit>().clearResults();
                        },
                  icon: const Icon(Icons.clear),
                  tooltip: 'Очистить результаты',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.status == TranslatorStatus.loading)
              const ProgressStatusCard(
                title: 'Перевод формулировки',
                completed: 0,
                total: 0,
                currentPhrase: '',
              ),
            if (state.status == TranslatorStatus.auditLoading)
              ProgressStatusCard(
                title: 'Проверка канонических формулировок',
                completed: state.auditCompleted,
                total: state.auditTotal,
                currentPhrase: state.currentAuditPhrase,
              ),
            if (state.status == TranslatorStatus.failure)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(state.errorMessage),
                ),
              ),
            if (state.translationHistory.isNotEmpty) ...<Widget>[
              const Text(
                'Результаты переводов',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              for (final result in state.translationHistory)
                TranslationResultView(result: result),
            ],
            if (state.auditResults.isNotEmpty)
              CanonicalAuditResultsView(results: state.auditResults),
          ],
        );
      },
    );
  }
}





final class _RegistryExplorerView extends StatefulWidget {
  const _RegistryExplorerView({
    required this.onPhraseSelected,
  });

  final ValueChanged<String> onPhraseSelected;

  @override
  State<_RegistryExplorerView> createState() => _RegistryExplorerViewState();
}

final class _RegistryExplorerViewState extends State<_RegistryExplorerView>
    with AutomaticKeepAliveClientMixin<_RegistryExplorerView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final RegistryWorkSessionPersistence _workSessionPersistence =
      const RegistryWorkSessionPersistence();

  String _query = '';
  _RegistryStatusFilter _statusFilter = _RegistryStatusFilter.all;
  RegistryWorkSession? _workSession;
  bool _registryLoadRequested = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadWorkSession();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkSession() async {
    final RegistryWorkSession? session = await _workSessionPersistence.load();

    if (!mounted) {
      return;
    }

    setState(() {
      _workSession = session;
    });
  }

  Future<void> _saveOpenedSection(List<String> pathTitles) async {
    await _workSessionPersistence.saveSection(pathTitles: pathTitles);
    await _loadWorkSession();
  }

  Future<void> _saveSelectedPhrase({
    required List<String> pathTitles,
    required String phrase,
  }) async {
    await _workSessionPersistence.savePhrase(
      pathTitles: pathTitles,
      phrase: phrase,
    );

    await _loadWorkSession();
  }

  void _continueWork(RegistryWorkSession session) {
    final String query = session.lastPhrase.trim().isNotEmpty
        ? session.lastPhrase.trim()
        : session.pathTitles.isEmpty
            ? ''
            : session.pathTitles.last.trim();

    if (query.isEmpty) {
      return;
    }

    _searchController.text = query;

    setState(() {
      _query = query;
      _statusFilter = _RegistryStatusFilter.all;
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<TranslatorCubit, TranslatorState>(
      builder: (BuildContext context, TranslatorState state) {
        if (!_registryLoadRequested && state.registryRoot == null) {
          _registryLoadRequested = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.read<TranslatorCubit>().loadRegistry();
            }
          });
        }

        final RegistryNode? root = state.registryRoot;
        final _RegistrySearchResult? searchResult = root == null || _query.isEmpty
            ? null
            : _RegistrySearchEngine.search(root: root, query: _query);

        final List<RegistryNode> baseNodes =
            searchResult?.nodes ?? root?.children ?? <RegistryNode>[];

        final List<RegistryNode> visibleNodes =
            _RegistryStatusFilterEngine.filterNodes(
          nodes: baseNodes,
          filter: _statusFilter,
          phraseStatusIndex: state.registryPhraseStatusIndex,
          translationHistory: state.translationHistory,
          auditResults: state.auditResults,
        );

        final _RegistryVisibleStats visibleStats =
            _RegistryVisibleStats.fromNodes(visibleNodes);

        return ListView(
          key: const PageStorageKey<String>('registry_explorer_scroll'),
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Registry Explorer',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: state.status == TranslatorStatus.registryLoading
                      ? null
                      : () {
                          context.read<TranslatorCubit>().refreshRegistry();
                        },
                  icon: state.status == TranslatorStatus.registryLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: 'Обновить Registry',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_workSession != null)
              _ContinueWorkCard(
                session: _workSession!,
                onContinue: () {
                  _continueWork(_workSession!);
                },
                onOpenTranslation: _workSession!.lastPhrase.trim().isEmpty
                    ? null
                    : () {
                        widget.onPhraseSelected(_workSession!.lastPhrase);
                      },
              ),
            if (_workSession != null) const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск по Registry',
                hintText: 'Контракт, раздел или фраза',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
              onChanged: (String value) {
                setState(() {
                  _query = value.trim();
                });
              },
            ),
            const SizedBox(height: 8),
            _RegistryStatusFilterBar(
              selectedFilter: _statusFilter,
              onChanged: (_RegistryStatusFilter filter) {
                setState(() {
                  _statusFilter = filter;
                });
              },
            ),
            const SizedBox(height: 8),
            if (state.registryErrorMessage.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(state.registryErrorMessage),
                ),
              ),
            if (root == null) ...<Widget>[
              const Text(
                'Нажмите обновить, чтобы скачать Registry из GitHub и построить дерево разделов.',
              ),
            ] else ...<Widget>[
              if (searchResult == null && _statusFilter == _RegistryStatusFilter.all)
                Text('Разделов: ${root.children.length} · Фраз: ${root.totalPhrases}')
              else
                Text(
                  'Показано: ${visibleStats.sections} разделов · '
                  '${visibleStats.phrases} фраз',
                ),
              const SizedBox(height: 12),
              for (final RegistryNode child in visibleNodes)
                _RegistryNodeTile(
                  node: child,
                  phraseStatusIndex: state.registryPhraseStatusIndex,
                  translationHistory: state.translationHistory,
                  auditResults: state.auditResults,
                  searchQuery: _query,
                  pathTitles: const <String>[],
                  onSectionOpened: _saveOpenedSection,
                  onPhraseSelected: ({
                    required String phrase,
                    required List<String> pathTitles,
                  }) async {
                    await _saveSelectedPhrase(
                      pathTitles: pathTitles,
                      phrase: phrase,
                    );

                    widget.onPhraseSelected(phrase);
                  },
                ),
            ],
          ],
        );
      },
    );
  }
}

final class _ContinueWorkCard extends StatelessWidget {
  const _ContinueWorkCard({
    required this.session,
    required this.onContinue,
    required this.onOpenTranslation,
  });

  final RegistryWorkSession session;
  final VoidCallback onContinue;
  final VoidCallback? onOpenTranslation;

  @override
  Widget build(BuildContext context) {
    final String path = session.pathTitles.isEmpty
        ? 'Путь не сохранён'
        : session.pathTitles.join(' → ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Продолжить работу',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(path),
            if (session.lastPhrase.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                session.lastPhrase,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (session.updatedAtIso.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text('Сохранено: ${session.updatedAtIso}'),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: <Widget>[
                FilledButton(
                  onPressed: onContinue,
                  child: const Text('Найти в Registry'),
                ),
                if (onOpenTranslation != null)
                  FilledButton.tonal(
                    onPressed: onOpenTranslation,
                    child: const Text('В перевод'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _RegistryNodeTile extends StatelessWidget {
  const _RegistryNodeTile({
    required this.node,
    required this.phraseStatusIndex,
    required this.translationHistory,
    required this.auditResults,
    required this.searchQuery,
    required this.pathTitles,
    required this.onSectionOpened,
    required this.onPhraseSelected,
  });

  final RegistryNode node;
  final Map<String, PersistedRegistryPhraseRecord> phraseStatusIndex;
  final List<TranslationResult> translationHistory;
  final List<CanonicalAuditResult> auditResults;
  final String searchQuery;
  final List<String> pathTitles;
  final ValueChanged<List<String>> onSectionOpened;
  final Future<void> Function({
    required String phrase,
    required List<String> pathTitles,
  }) onPhraseSelected;

  @override
  Widget build(BuildContext context) {
    final bool hasChildren = node.children.isNotEmpty;
    final bool hasPhrases = node.phrases.isNotEmpty;
    final List<String> currentPath = <String>[...pathTitles, node.title];

    if (!hasChildren && !hasPhrases) {
      return ListTile(
        dense: true,
        title: _HighlightedText(text: node.title, query: searchQuery),
        subtitle: Text(_pathSubtitle(currentPath, node.lineNumber)),
        onTap: () {
          onSectionOpened(currentPath);
        },
      );
    }

    return ExpansionTile(
      key: PageStorageKey<String>('registry_node_${node.id}_$searchQuery'),
      initiallyExpanded: searchQuery.isNotEmpty,
      title: _HighlightedText(text: node.title, query: searchQuery),
      subtitle: Text(
        '${_pathSubtitle(currentPath, node.lineNumber)} · phrases ${node.totalPhrases}',
      ),
      childrenPadding: const EdgeInsets.only(left: 12),
      onExpansionChanged: (bool expanded) {
        if (expanded) {
          onSectionOpened(currentPath);
        }
      },
      children: <Widget>[
        for (final String phrase in node.phrases)
          ListTile(
            dense: true,
            leading: _RegistryPhraseStatusIcon(
              status: _resolvePhraseStatus(
                phrase: phrase,
                phraseStatusIndex: phraseStatusIndex,
                translationHistory: translationHistory,
                auditResults: auditResults,
              ),
            ),
            title: _HighlightedText(text: phrase, query: searchQuery),
            subtitle: Text(currentPath.join(' → ')),
            onTap: () {
              onPhraseSelected(
                phrase: phrase,
                pathTitles: currentPath,
              );
            },
          ),
        for (final RegistryNode child in node.children)
          _RegistryNodeTile(
            node: child,
            phraseStatusIndex: phraseStatusIndex,
            translationHistory: translationHistory,
            auditResults: auditResults,
            searchQuery: searchQuery,
            pathTitles: currentPath,
            onSectionOpened: onSectionOpened,
            onPhraseSelected: onPhraseSelected,
          ),
      ],
    );
  }

  static String _pathSubtitle(List<String> pathTitles, int lineNumber) {
    return '${pathTitles.join(' → ')} · line $lineNumber';
  }

  static _RegistryPhraseStatus resolvePhraseStatusForFilter({
    required String phrase,
    required Map<String, PersistedRegistryPhraseRecord> phraseStatusIndex,
    required List<TranslationResult> translationHistory,
    required List<CanonicalAuditResult> auditResults,
  }) {
    return _resolvePhraseStatus(
      phrase: phrase,
      phraseStatusIndex: phraseStatusIndex,
      translationHistory: translationHistory,
      auditResults: auditResults,
    );
  }

  static _RegistryPhraseStatus _resolvePhraseStatus({
    required String phrase,
    required Map<String, PersistedRegistryPhraseRecord> phraseStatusIndex,
    required List<TranslationResult> translationHistory,
    required List<CanonicalAuditResult> auditResults,
  }) {
    final PersistedRegistryPhraseRecord? persisted =
        phraseStatusIndex[RegistryPhraseStatusPersistence.normalizePhrase(phrase)];

    if (persisted != null) {
      return _RegistryPhraseStatus.fromPersistedStatus(persisted.status);
    }

    for (final TranslationResult result in translationHistory) {
      if (result.sourceText.trim() == phrase.trim() ||
          result.ru.trim() == phrase.trim()) {
        return _RegistryPhraseStatus.fromVerdict(result.canonicalVerdict);
      }
    }

    for (final CanonicalAuditResult result in auditResults) {
      if (result.sourceRu.trim() == phrase.trim()) {
        return _RegistryPhraseStatus.fromAuditStatus(result.status);
      }
    }

    return _RegistryPhraseStatus.unchecked;
  }
}

enum _RegistryStatusFilter {
  all,
  unchecked,
  exact,
  equivalent,
  needsReview,
  drift,
  failed,
}

final class _RegistryStatusFilterBar extends StatelessWidget {
  const _RegistryStatusFilterBar({
    required this.selectedFilter,
    required this.onChanged,
  });

  final _RegistryStatusFilter selectedFilter;
  final ValueChanged<_RegistryStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _chip(label: 'Все', filter: _RegistryStatusFilter.all),
        _chip(label: '⚪ Unchecked', filter: _RegistryStatusFilter.unchecked),
        _chip(label: '✅ Exact', filter: _RegistryStatusFilter.exact),
        _chip(label: '🟢 Eq', filter: _RegistryStatusFilter.equivalent),
        _chip(label: '🟡 Review', filter: _RegistryStatusFilter.needsReview),
        _chip(label: '🔴 Drift', filter: _RegistryStatusFilter.drift),
        _chip(label: '❌ Failed', filter: _RegistryStatusFilter.failed),
      ],
    );
  }

  Widget _chip({
    required String label,
    required _RegistryStatusFilter filter,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedFilter == filter,
      onSelected: (_) {
        onChanged(filter);
      },
    );
  }
}

final class _RegistryStatusFilterEngine {
  const _RegistryStatusFilterEngine._();

  static List<RegistryNode> filterNodes({
    required List<RegistryNode> nodes,
    required _RegistryStatusFilter filter,
    required Map<String, PersistedRegistryPhraseRecord> phraseStatusIndex,
    required List<TranslationResult> translationHistory,
    required List<CanonicalAuditResult> auditResults,
  }) {
    if (filter == _RegistryStatusFilter.all) {
      return nodes;
    }

    final List<RegistryNode> result = <RegistryNode>[];

    for (final RegistryNode node in nodes) {
      final RegistryNode? filtered = _filterNode(
        node: node,
        filter: filter,
        phraseStatusIndex: phraseStatusIndex,
        translationHistory: translationHistory,
        auditResults: auditResults,
      );

      if (filtered != null) {
        result.add(filtered);
      }
    }

    return List<RegistryNode>.unmodifiable(result);
  }

  static RegistryNode? _filterNode({
    required RegistryNode node,
    required _RegistryStatusFilter filter,
    required Map<String, PersistedRegistryPhraseRecord> phraseStatusIndex,
    required List<TranslationResult> translationHistory,
    required List<CanonicalAuditResult> auditResults,
  }) {
    final List<String> phrases = node.phrases.where((String phrase) {
      final _RegistryPhraseStatus status = _RegistryNodeTile.resolvePhraseStatusForFilter(
        phrase: phrase,
        phraseStatusIndex: phraseStatusIndex,
        translationHistory: translationHistory,
        auditResults: auditResults,
      );

      return _matchesFilter(status: status, filter: filter);
    }).toList(growable: false);

    final List<RegistryNode> children = <RegistryNode>[];

    for (final RegistryNode child in node.children) {
      final RegistryNode? filteredChild = _filterNode(
        node: child,
        filter: filter,
        phraseStatusIndex: phraseStatusIndex,
        translationHistory: translationHistory,
        auditResults: auditResults,
      );

      if (filteredChild != null) {
        children.add(filteredChild);
      }
    }

    if (phrases.isEmpty && children.isEmpty) {
      return null;
    }

    return node.copyWith(
      phrases: List<String>.unmodifiable(phrases),
      children: List<RegistryNode>.unmodifiable(children),
    );
  }

  static bool _matchesFilter({
    required _RegistryPhraseStatus status,
    required _RegistryStatusFilter filter,
  }) {
    return switch (filter) {
      _RegistryStatusFilter.all => true,
      _RegistryStatusFilter.unchecked => status == _RegistryPhraseStatus.unchecked,
      _RegistryStatusFilter.exact => status == _RegistryPhraseStatus.exact,
      _RegistryStatusFilter.equivalent => status == _RegistryPhraseStatus.equivalent,
      _RegistryStatusFilter.needsReview => status == _RegistryPhraseStatus.needsReview,
      _RegistryStatusFilter.drift => status == _RegistryPhraseStatus.drift,
      _RegistryStatusFilter.failed => status == _RegistryPhraseStatus.failed,
    };
  }
}

final class _RegistryVisibleStats {
  const _RegistryVisibleStats({
    required this.sections,
    required this.phrases,
  });

  final int sections;
  final int phrases;

  static _RegistryVisibleStats fromNodes(List<RegistryNode> nodes) {
    int sections = 0;
    int phrases = 0;

    void walk(RegistryNode node) {
      sections++;
      phrases += node.phrases.length;

      for (final RegistryNode child in node.children) {
        walk(child);
      }
    }

    for (final RegistryNode node in nodes) {
      walk(node);
    }

    return _RegistryVisibleStats(sections: sections, phrases: phrases);
  }
}

final class _RegistrySearchEngine {
  const _RegistrySearchEngine._();

  static _RegistrySearchResult search({
    required RegistryNode root,
    required String query,
  }) {
    final String normalizedQuery = _normalize(query);
    final List<RegistryNode> nodes = <RegistryNode>[];
    int sectionMatches = 0;
    int phraseMatches = 0;

    for (final RegistryNode child in root.children) {
      final _RegistryNodeSearchResult? result = _filterNode(
        node: child,
        normalizedQuery: normalizedQuery,
      );

      if (result != null) {
        nodes.add(result.node);
        sectionMatches += result.sectionMatches;
        phraseMatches += result.phraseMatches;
      }
    }

    return _RegistrySearchResult(
      nodes: List<RegistryNode>.unmodifiable(nodes),
      sectionMatches: sectionMatches,
      phraseMatches: phraseMatches,
    );
  }

  static _RegistryNodeSearchResult? _filterNode({
    required RegistryNode node,
    required String normalizedQuery,
  }) {
    final bool titleMatches = _normalize(node.title).contains(normalizedQuery);

    final List<String> matchedPhrases = node.phrases.where((String phrase) {
      return _normalize(phrase).contains(normalizedQuery);
    }).toList(growable: false);

    final List<RegistryNode> matchedChildren = <RegistryNode>[];
    int childSectionMatches = 0;
    int childPhraseMatches = 0;

    for (final RegistryNode child in node.children) {
      final _RegistryNodeSearchResult? childResult = _filterNode(
        node: child,
        normalizedQuery: normalizedQuery,
      );

      if (childResult != null) {
        matchedChildren.add(childResult.node);
        childSectionMatches += childResult.sectionMatches;
        childPhraseMatches += childResult.phraseMatches;
      }
    }

    final bool hasMatches =
        titleMatches || matchedPhrases.isNotEmpty || matchedChildren.isNotEmpty;

    if (!hasMatches) {
      return null;
    }

    final RegistryNode filteredNode = node.copyWith(
      phrases: titleMatches ? node.phrases : matchedPhrases,
      children: List<RegistryNode>.unmodifiable(matchedChildren),
    );

    return _RegistryNodeSearchResult(
      node: filteredNode,
      sectionMatches: childSectionMatches + (titleMatches ? 1 : 0),
      phraseMatches: childPhraseMatches + matchedPhrases.length,
    );
  }

  static String _normalize(String value) {
    return value
        .trim()
        .replaceAll('ё', 'е')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }
}

final class _RegistrySearchResult {
  const _RegistrySearchResult({
    required this.nodes,
    required this.sectionMatches,
    required this.phraseMatches,
  });

  final List<RegistryNode> nodes;
  final int sectionMatches;
  final int phraseMatches;
}

final class _RegistryNodeSearchResult {
  const _RegistryNodeSearchResult({
    required this.node,
    required this.sectionMatches,
    required this.phraseMatches,
  });

  final RegistryNode node;
  final int sectionMatches;
  final int phraseMatches;
}

final class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
  });

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) {
      return Text(text);
    }

    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    final int start = lowerText.indexOf(lowerQuery);

    if (start == -1) {
      return Text(text);
    }

    final int end = start + query.length;
    final TextStyle baseStyle = DefaultTextStyle.of(context).style;

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: <TextSpan>[
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }
}

enum _RegistryPhraseStatus {
  exact,
  equivalent,
  needsReview,
  drift,
  failed,
  unchecked;

  static _RegistryPhraseStatus fromPersistedStatus(
    PersistedRegistryPhraseStatus status,
  ) {
    return switch (status) {
      PersistedRegistryPhraseStatus.exact => _RegistryPhraseStatus.exact,
      PersistedRegistryPhraseStatus.equivalent =>
        _RegistryPhraseStatus.equivalent,
      PersistedRegistryPhraseStatus.needsReview =>
        _RegistryPhraseStatus.needsReview,
      PersistedRegistryPhraseStatus.drift => _RegistryPhraseStatus.drift,
      PersistedRegistryPhraseStatus.failed => _RegistryPhraseStatus.failed,
    };
  }

  static _RegistryPhraseStatus fromVerdict(String verdict) {
    return switch (verdict.trim().toUpperCase()) {
      'EXACT' => _RegistryPhraseStatus.exact,
      'EQUIVALENT' => _RegistryPhraseStatus.equivalent,
      'NEEDS_REVIEW' => _RegistryPhraseStatus.needsReview,
      'CANONICAL_DRIFT' => _RegistryPhraseStatus.drift,
      _ => _RegistryPhraseStatus.failed,
    };
  }

  static _RegistryPhraseStatus fromAuditStatus(CanonicalAuditStatus status) {
    return switch (status) {
      CanonicalAuditStatus.exact => _RegistryPhraseStatus.exact,
      CanonicalAuditStatus.equivalent => _RegistryPhraseStatus.equivalent,
      CanonicalAuditStatus.needsReview => _RegistryPhraseStatus.needsReview,
      CanonicalAuditStatus.drift => _RegistryPhraseStatus.drift,
      CanonicalAuditStatus.failed => _RegistryPhraseStatus.failed,
    };
  }
}

final class _RegistryPhraseStatusIcon extends StatelessWidget {
  const _RegistryPhraseStatusIcon({
    required this.status,
  });

  final _RegistryPhraseStatus status;

  @override
  Widget build(BuildContext context) {
    final String icon = switch (status) {
      _RegistryPhraseStatus.exact => '✅',
      _RegistryPhraseStatus.equivalent => '🟢',
      _RegistryPhraseStatus.needsReview => '🟡',
      _RegistryPhraseStatus.drift => '🔴',
      _RegistryPhraseStatus.failed => '❌',
      _RegistryPhraseStatus.unchecked => '⚪',
    };

    return Text(
      icon,
      style: const TextStyle(fontSize: 22),
    );
  }
}
