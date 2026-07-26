import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/translator_access_key_store.dart';
import '../application/translator_draft_store.dart';
import '../application/translator_provider.dart';
import '../domain/translator_models.dart';
import 'translator_cubit.dart';

final class TranslatorWorkspaceView extends StatelessWidget {
  const TranslatorWorkspaceView({
    required this.provider,
    required this.draftStore,
    required this.accessKeyStore,
    super.key,
  });

  final TranslatorProvider provider;
  final TranslatorDraftStore draftStore;
  final TranslatorAccessKeyStore accessKeyStore;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TranslatorCubit>(
      create: (_) =>
          TranslatorCubit(provider: provider, draftStore: draftStore)
            ..restore(),
      child: _TranslatorWorkspaceBody(accessKeyStore: accessKeyStore),
    );
  }
}

final class _TranslatorWorkspaceBody extends StatefulWidget {
  const _TranslatorWorkspaceBody({required this.accessKeyStore});

  final TranslatorAccessKeyStore accessKeyStore;

  @override
  State<_TranslatorWorkspaceBody> createState() =>
      _TranslatorWorkspaceBodyState();
}

final class _TranslatorWorkspaceBodyState
    extends State<_TranslatorWorkspaceBody>
    with WidgetsBindingObserver {
  late final TextEditingController _sourceController;
  late final TextEditingController _apiKeyController;
  Timer? _accessKeySaveTimer;
  bool _showApiKey = false;
  bool _accessKeyRestoring = true;
  String? _accessKeyStorageWarning;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sourceController = TextEditingController();
    _apiKeyController = TextEditingController();
    unawaited(_restoreAccessKey());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(_flushAccessKeySave());
    }
  }

  Future<void> _restoreAccessKey() async {
    try {
      final String? accessKey = await widget.accessKeyStore.load();

      if (!mounted) {
        return;
      }

      final String restoredAccessKey = accessKey ?? '';

      _apiKeyController.value = TextEditingValue(
        text: restoredAccessKey,
        selection: TextSelection.collapsed(offset: restoredAccessKey.length),
      );

      setState(() {
        _accessKeyRestoring = false;
        _accessKeyStorageWarning = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _accessKeyRestoring = false;
        _accessKeyStorageWarning =
            'Не удалось восстановить сохранённый API key. '
            'Ключ не был удалён автоматически.';
      });
    }
  }

  void _scheduleAccessKeySave(String accessKey) {
    _accessKeySaveTimer?.cancel();
    _accessKeySaveTimer = Timer(const Duration(milliseconds: 300), () {
      _accessKeySaveTimer = null;
      unawaited(_persistAccessKey(accessKey));
    });
  }

  Future<void> _flushAccessKeySave() async {
    _accessKeySaveTimer?.cancel();
    _accessKeySaveTimer = null;
    await _persistAccessKey(_apiKeyController.text);
  }

  Future<void> _persistAccessKey(
    String accessKey, {
    bool reportFailure = true,
  }) async {
    try {
      if (accessKey.isEmpty) {
        await widget.accessKeyStore.clear();
      } else {
        await widget.accessKeyStore.save(accessKey);
      }

      if (mounted && _accessKeyStorageWarning != null) {
        setState(() {
          _accessKeyStorageWarning = null;
        });
      }
    } catch (_) {
      if (reportFailure && mounted) {
        setState(() {
          _accessKeyStorageWarning =
              'Не удалось сохранить API key в защищённом хранилище.';
        });
      }
    }
  }

  Future<void> _deleteSavedAccessKey() async {
    _accessKeySaveTimer?.cancel();
    _accessKeySaveTimer = null;

    try {
      await widget.accessKeyStore.clear();
      _apiKeyController.clear();

      if (mounted) {
        setState(() {
          _showApiKey = false;
          _accessKeyStorageWarning = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _accessKeyStorageWarning =
              'Не удалось удалить API key из защищённого хранилища.';
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _accessKeySaveTimer?.cancel();
    _accessKeySaveTimer = null;

    final String accessKey = _apiKeyController.text;
    unawaited(_persistAccessKey(accessKey, reportFailure: false));

    _sourceController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TranslatorCubit, TranslatorState>(
      listenWhen: (TranslatorState previous, TranslatorState current) =>
          previous.sourceText != current.sourceText,
      listener: (BuildContext context, TranslatorState state) {
        if (_sourceController.text != state.sourceText) {
          _sourceController.value = TextEditingValue(
            text: state.sourceText,
            selection: TextSelection.collapsed(offset: state.sourceText.length),
          );
        }
      },
      builder: (BuildContext context, TranslatorState state) {
        if (state.status == TranslatorViewStatus.restoring) {
          return const Center(child: CircularProgressIndicator());
        }

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: <Widget>[
              _buildAccessKeyCard(state),
              const SizedBox(height: 12),
              _buildSourceCard(context, state),
              const SizedBox(height: 12),
              _buildActions(context, state),
              if (state.restoreWarning != null) ...<Widget>[
                const SizedBox(height: 12),
                _MessageCard(
                  title: 'Предупреждение восстановления',
                  message: state.restoreWarning!,
                  icon: Icons.warning_amber_outlined,
                ),
              ],
              if (state.isRunning) ...<Widget>[
                const SizedBox(height: 16),
                _ProgressCard(stage: state.stage),
              ],
              if (state.failure != null) ...<Widget>[
                const SizedBox(height: 16),
                _FailureCard(failure: state.failure!),
              ],
              if (state.report != null) ...<Widget>[
                const SizedBox(height: 16),
                _TranslationReportView(report: state.report!),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccessKeyCard(TranslatorState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _apiKeyController,
              enabled: !state.isRunning && !_accessKeyRestoring,
              obscureText: !_showApiKey,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Typhoon API key',
                helperText: _accessKeyRestoring
                    ? 'Восстановление сохранённого ключа...'
                    : 'Ключ зашифрованно хранится на этом устройстве.',
                errorText: _accessKeyStorageWarning,
                prefixIcon: const Icon(Icons.key_outlined),
                suffixIcon: IconButton(
                  tooltip: _showApiKey ? 'Скрыть ключ' : 'Показать ключ',
                  onPressed: _accessKeyRestoring
                      ? null
                      : () {
                          setState(() {
                            _showApiKey = !_showApiKey;
                          });
                        },
                  icon: Icon(
                    _showApiKey ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: _scheduleAccessKeySave,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: state.isRunning || _accessKeyRestoring
                    ? null
                    : _deleteSavedAccessKey,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Удалить сохранённый ключ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceCard(BuildContext context, TranslatorState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Исходная формулировка',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Язык источника',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TranslationLanguage?>(
                  value: state.sourceLanguageHint,
                  isExpanded: true,
                  items: <DropdownMenuItem<TranslationLanguage?>>[
                    const DropdownMenuItem<TranslationLanguage?>(
                      value: null,
                      child: Text('Определить автоматически'),
                    ),
                    ...TranslationLanguage.values.map(
                      (TranslationLanguage language) =>
                          DropdownMenuItem<TranslationLanguage?>(
                            value: language,
                            child: Text(language.code),
                          ),
                    ),
                  ],
                  onChanged: state.isRunning
                      ? null
                      : (TranslationLanguage? language) {
                          context.read<TranslatorCubit>().selectSourceLanguage(
                            language,
                          );
                        },
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sourceController,
              enabled: !state.isRunning,
              minLines: 4,
              maxLines: 10,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Текст для перевода и семантического аудита',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (String value) {
                context.read<TranslatorCubit>().updateSourceText(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, TranslatorState state) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        FilledButton.icon(
          onPressed: state.isRunning || _accessKeyRestoring
              ? null
              : () async {
                  FocusScope.of(context).unfocus();
                  await _flushAccessKeySave();

                  if (!context.mounted) {
                    return;
                  }

                  await context.read<TranslatorCubit>().translate(
                    accessKey: _apiKeyController.text,
                  );
                },
          icon: const Icon(Icons.translate),
          label: Text(
            state.status == TranslatorViewStatus.failure
                ? 'Повторить'
                : 'Перевести и проверить',
          ),
        ),
        if (state.isRunning)
          OutlinedButton.icon(
            onPressed: () {
              context.read<TranslatorCubit>().cancel();
            },
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Отменить'),
          ),
        OutlinedButton.icon(
          onPressed: state.isRunning
              ? null
              : () {
                  context.read<TranslatorCubit>().clear();
                },
          icon: const Icon(Icons.clear),
          label: const Text('Очистить Translator'),
        ),
      ],
    );
  }
}

final class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.stage});

  final TranslatorRunStage? stage;

  @override
  Widget build(BuildContext context) {
    final String label = switch (stage) {
      TranslatorRunStage.directTranslation => 'Прямой перевод RU / EN / TH',
      TranslatorRunStage.reverseTranslation => 'Независимые обратные переводы',
      TranslatorRunStage.audit => 'Семантический аудит и вердикт',
      null => 'Подготовка перевода',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}

final class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.failure});

  final TranslatorFailure failure;

  @override
  Widget build(BuildContext context) {
    final bool incomplete =
        failure.completeness == TranslationCompleteness.translationIncomplete;

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _failureTitle(failure, incomplete: incomplete),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(failure.message),
            const SizedBox(height: 8),
            Text(
              'Этап: ${_failureStageLabel(failure.stage)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (failure.partialBundle != null) ...<Widget>[
              const SizedBox(height: 8),
              const Text(
                'Частичный девятисекционный результат сохранён, '
                'но автоматический вердикт не создан.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _TranslationReportView extends StatelessWidget {
  const _TranslationReportView({required this.report});

  final TranslatorRunReport report;

  @override
  Widget build(BuildContext context) {
    final TranslationBundle bundle = report.bundle;
    final TranslationAudit audit = report.audit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _VerdictCard(audit: audit),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Прямой перевод',
          entries: <MapEntry<String, String>>[
            MapEntry<String, String>(
              '${bundle.sourceLanguage.code} · SOURCE TEXT',
              bundle.sourceText,
            ),
            MapEntry<String, String>('RU', bundle.ru),
            MapEntry<String, String>('EN', bundle.en),
            MapEntry<String, String>('TH', bundle.th),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Независимая обратная проверка',
          entries: <MapEntry<String, String>>[
            MapEntry<String, String>('EN → RU', bundle.enToRu),
            MapEntry<String, String>('TH → RU', bundle.thToRu),
            MapEntry<String, String>('EN → TH', bundle.enToTh),
            MapEntry<String, String>('TH → EN', bundle.thToEn),
          ],
        ),
        const SizedBox(height: 12),
        _AuditFindingsCard(audit: audit),
      ],
    );
  }
}

final class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.audit});

  final TranslationAudit audit;

  @override
  Widget build(BuildContext context) {
    final TranslationVerdict verdict = audit.verdict;
    final ColorScheme colors = Theme.of(context).colorScheme;

    final Color background = switch (verdict) {
      TranslationVerdict.exact => colors.primaryContainer,
      TranslationVerdict.equivalent => colors.secondaryContainer,
      TranslationVerdict.needsReview => colors.tertiaryContainer,
      TranslationVerdict.canonicalDrift => colors.errorContainer,
    };

    return Card(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Text(
              'Автоматический вердикт перевода',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _verdictLabel(verdict),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _BooleanEvidenceRow(
              label: 'Meaning preserved',
              value: audit.meaningPreserved,
            ),
            _BooleanEvidenceRow(
              label: 'Terminology preserved',
              value: audit.terminologyPreserved,
            ),
            _BooleanEvidenceRow(
              label: 'Canonical style preserved',
              value: audit.canonicalStylePreserved,
            ),
            _BooleanEvidenceRow(
              label: 'Ambiguous wording',
              value: audit.ambiguousWording,
              positiveMeansGood: false,
            ),
            const SizedBox(height: 8),
            const Text(
              'Вердикт сформирован автоматически по findings. '
              'Итоговое решение принимает инженер.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

final class _BooleanEvidenceRow extends StatelessWidget {
  const _BooleanEvidenceRow({
    required this.label,
    required this.value,
    this.positiveMeansGood = true,
  });

  final String label;
  final bool value;
  final bool positiveMeansGood;

  @override
  Widget build(BuildContext context) {
    final bool good = positiveMeansGood ? value : !value;

    return Row(
      children: <Widget>[
        Icon(good ? Icons.check_circle_outline : Icons.warning_amber, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(value ? 'YES' : 'NO'),
      ],
    );
  }
}

final class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.entries});

  final String title;
  final List<MapEntry<String, String>> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            for (final MapEntry<String, String> entry in entries) ...<Widget>[
              const Divider(height: 24),
              Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              SelectableText(entry.value),
            ],
          ],
        ),
      ),
    );
  }
}

final class _AuditFindingsCard extends StatelessWidget {
  const _AuditFindingsCard({required this.audit});

  final TranslationAudit audit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Аудит и диагностика',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _FindingGroup(title: 'Смысл', findings: audit.meaningFindings),
            _FindingGroup(
              title: 'Терминология',
              findings: audit.terminologyFindings,
            ),
            _FindingGroup(
              title: 'Канонический стиль',
              findings: audit.styleFindings,
            ),
            _FindingGroup(
              title: 'Неоднозначность',
              findings: audit.ambiguityFindings,
            ),
          ],
        ),
      ),
    );
  }
}

final class _FindingGroup extends StatelessWidget {
  const _FindingGroup({required this.title, required this.findings});

  final String title;
  final List<String> findings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (findings.isEmpty)
            const Text('Нарушений не обнаружено.')
          else
            for (final String finding in findings)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $finding'),
              ),
        ],
      ),
    );
  }
}

String _failureTitle(TranslatorFailure failure, {required bool incomplete}) {
  if (incomplete) {
    return 'Перевод неполный';
  }
  if (failure.code == TranslatorFailureCode.cancelled) {
    return 'Перевод отменён';
  }
  if (failure.stage == TranslatorFailureStage.validation) {
    return 'Проверьте ввод';
  }
  return 'Техническая ошибка Translator';
}

String _verdictLabel(TranslationVerdict verdict) {
  return switch (verdict) {
    TranslationVerdict.exact => 'EXACT',
    TranslationVerdict.equivalent => 'EQUIVALENT',
    TranslationVerdict.needsReview => 'NEEDS REVIEW',
    TranslationVerdict.canonicalDrift => 'CANONICAL DRIFT',
  };
}

String _failureStageLabel(TranslatorFailureStage stage) {
  return switch (stage) {
    TranslatorFailureStage.validation => 'проверка ввода',
    TranslatorFailureStage.directTranslation => 'прямой перевод',
    TranslatorFailureStage.reverseTranslation => 'обратный перевод',
    TranslatorFailureStage.audit => 'семантический аудит',
    TranslatorFailureStage.transport => 'Typhoon API',
  };
}
