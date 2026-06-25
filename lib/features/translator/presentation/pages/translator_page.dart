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
  final TextEditingController _controller = TextEditingController(
    text: 'Освободите оборудование от вещей до приезда мастера.',
  );

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Helpy Translator'),
      ),
      body: BlocBuilder<TranslatorCubit, TranslatorState>(
        builder: (BuildContext context, TranslatorState state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              if (state.auditResults.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: StatusSummaryView.fromAuditResults(
                      results: state.auditResults,
                    ),
                  ),
                ),
              if (state.auditResults.isEmpty &&
                  state.translationHistory.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: StatusSummaryView.fromVerdict(
                      state.translationHistory.first.canonicalVerdict,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 8,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Каноническая формулировка',
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
                          : _translate,
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
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: state.status == TranslatorStatus.auditLoading
                    ? null
                    : () {
                        context.read<TranslatorCubit>().auditCanonicalRules();
                      },
                icon: const Icon(Icons.fact_check),
                label: const Text('Проверить весь словарь'),
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
      ),
    );
  }
}
