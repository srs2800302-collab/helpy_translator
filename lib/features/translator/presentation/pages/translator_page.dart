import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/translator_cubit.dart';
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
            const _RegistryExplorerPlaceholder(),
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

final class _RegistryExplorerPlaceholder extends StatelessWidget {
  const _RegistryExplorerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ListView(
      padding: EdgeInsets.all(16),
      children: <Widget>[
        Text(
          'Registry Explorer',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Text(
          'Здесь будет дерево разделов Registry: заголовки, подразделы, фразы и проверка выбранной ветки.',
        ),
      ],
    );
  }
}
