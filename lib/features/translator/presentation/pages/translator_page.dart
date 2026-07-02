import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/translator_cubit.dart';
import '../../domain/entities/registry_node.dart';
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


final class _RegistryExplorerView extends StatelessWidget {
  const _RegistryExplorerView({
    required this.onPhraseSelected,
  });

  final ValueChanged<String> onPhraseSelected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TranslatorCubit, TranslatorState>(
      builder: (BuildContext context, TranslatorState state) {
        final RegistryNode? root = state.registryRoot;

        return ListView(
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
                          context.read<TranslatorCubit>().loadRegistry();
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
              Text('Разделов: ${root.children.length} · Фраз: ${root.totalPhrases}'),
              const SizedBox(height: 12),
              for (final RegistryNode child in root.children)
                _RegistryNodeTile(
                  node: child,
                  onPhraseSelected: onPhraseSelected,
                ),
            ],
          ],
        );
      },
    );
  }
}

final class _RegistryNodeTile extends StatelessWidget {
  const _RegistryNodeTile({
    required this.node,
    required this.onPhraseSelected,
  });

  final RegistryNode node;
  final ValueChanged<String> onPhraseSelected;

  @override
  Widget build(BuildContext context) {
    final bool hasChildren = node.children.isNotEmpty;
    final bool hasPhrases = node.phrases.isNotEmpty;

    if (!hasChildren && !hasPhrases) {
      return ListTile(
        dense: true,
        title: Text(node.title),
        subtitle: Text('line ${node.lineNumber}'),
      );
    }

    return ExpansionTile(
      title: Text(node.title),
      subtitle: Text(
        'line ${node.lineNumber} · phrases ${node.totalPhrases}',
      ),
      childrenPadding: const EdgeInsets.only(left: 12),
      children: <Widget>[
        for (final String phrase in node.phrases)
          ListTile(
            dense: true,
            leading: const Icon(Icons.short_text),
            title: Text(phrase),
            onTap: () {
              onPhraseSelected(phrase);
            },
          ),
        for (final RegistryNode child in node.children)
          _RegistryNodeTile(
            node: child,
            onPhraseSelected: onPhraseSelected,
          ),
      ],
    );
  }
}
