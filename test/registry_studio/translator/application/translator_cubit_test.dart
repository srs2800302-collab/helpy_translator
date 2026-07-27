import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_draft_store.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_provider.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_cubit.dart';

void main() {
  test('restores persisted Translator draft independently', () async {
    final _MemoryDraftStore store = _MemoryDraftStore(
      draft: const TranslatorDraft(sourceText: 'Сохранённый текст.'),
    );

    final TranslatorCubit cubit = TranslatorCubit(
      provider: _FakeProvider.success(_report()),
      draftStore: store,
    );
    addTearDown(cubit.close);

    await cubit.restore();

    expect(cubit.state.status, TranslatorViewStatus.idle);
    expect(cubit.state.sourceText, 'Сохранённый текст.');
  });

  test('emits visible stages and stores successful report', () async {
    final TranslatorRunReport report = _report();
    final _MemoryDraftStore store = _MemoryDraftStore();

    final TranslatorCubit cubit = TranslatorCubit(
      provider: _FakeProvider.success(report),
      draftStore: store,
    );
    addTearDown(cubit.close);

    await cubit.restore();
    await cubit.updateSourceText(report.request.sourceText);

    final List<TranslatorState> states = <TranslatorState>[];
    final StreamSubscription<TranslatorState> subscription = cubit.stream
        .listen(states.add);
    addTearDown(subscription.cancel);

    await cubit.translate(accessKey: 'key');

    expect(cubit.state.status, TranslatorViewStatus.success);
    expect(cubit.state.report, report);
    expect(store.draft?.report, report);
    expect(
      states
          .where((TranslatorState state) => state.stage != null)
          .map((TranslatorState state) => state.stage)
          .toSet(),
      containsAll(<TranslatorRunStage>{
        TranslatorRunStage.directTranslation,
        TranslatorRunStage.audit,
      }),
    );
  });

  test(
    'keeps technical failure distinct from incomplete translation',
    () async {
      final TranslatorFailure failure = TranslatorFailure(
        stage: TranslatorFailureStage.transport,
        code: TranslatorFailureCode.rateLimited,
        message: 'Rate limited.',
        completeness: TranslationCompleteness.complete,
        partialBundle: _report().bundle,
      );

      final TranslatorCubit cubit = TranslatorCubit(
        provider: _FakeProvider.failure(failure),
        draftStore: _MemoryDraftStore(),
      );
      addTearDown(cubit.close);

      await cubit.restore();
      await cubit.updateSourceText('Текст.');
      await cubit.translate(accessKey: 'key');

      expect(cubit.state.status, TranslatorViewStatus.failure);
      expect(
        cubit.state.failure?.completeness,
        TranslationCompleteness.complete,
      );
      expect(cubit.state.failure?.code, TranslatorFailureCode.rateLimited);
    },
  );

  test('passes exact multiline source text without trimming', () async {
    const String exactSource = '  First line.\nSecond line.  ';
    final _FakeProvider provider = _FakeProvider.success(_report());
    final TranslatorCubit cubit = TranslatorCubit(
      provider: provider,
      draftStore: _MemoryDraftStore(),
    );
    addTearDown(cubit.close);

    await cubit.restore();
    await cubit.updateSourceText(exactSource);
    await cubit.translate(accessKey: 'key');

    expect(provider.lastRequest?.sourceText, exactSource);
    expect(cubit.state.sourceText, exactSource);
  });

  test('cancel stops active operation and preserves input', () async {
    final _ControlledOperation operation = _ControlledOperation();
    final TranslatorCubit cubit = TranslatorCubit(
      provider: _SingleOperationProvider(operation),
      draftStore: _MemoryDraftStore(),
    );
    addTearDown(cubit.close);

    await cubit.restore();
    await cubit.updateSourceText('Текст.');

    final Future<void> running = cubit.translate(accessKey: 'key');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, TranslatorViewStatus.running);

    await cubit.cancel();
    operation.completeCancelled();
    await running;

    expect(operation.cancelled, isTrue);
    expect(cubit.state.status, TranslatorViewStatus.cancelled);
    expect(cubit.state.sourceText, 'Текст.');
  });

  test('persists a partial bundle and retries only semantic audit', () async {
    final TranslatorRunReport report = _report();
    final _MemoryDraftStore store = _MemoryDraftStore();
    final _RetryCapableProvider provider = _RetryCapableProvider(report);
    final TranslatorCubit cubit = TranslatorCubit(
      provider: provider,
      draftStore: store,
    );
    addTearDown(cubit.close);

    await cubit.restore();
    await cubit.updateSourceText(report.request.sourceText);
    await cubit.translate(accessKey: 'key');

    expect(cubit.state.status, TranslatorViewStatus.failure);
    expect(cubit.state.partialBundle, report.bundle);
    expect(cubit.state.canRetryAudit, isTrue);
    expect(store.draft?.partialBundle, report.bundle);
    expect(provider.fullRunCount, 1);
    expect(provider.auditOnlyRunCount, 0);

    await cubit.retryAudit(accessKey: 'key');

    expect(cubit.state.status, TranslatorViewStatus.success);
    expect(cubit.state.report, report);
    expect(cubit.state.partialBundle, isNull);
    expect(store.draft?.report, report);
    expect(store.draft?.partialBundle, isNull);
    expect(provider.fullRunCount, 1);
    expect(provider.auditOnlyRunCount, 1);
  });

  test('clear affects only Translator state and store', () async {
    final _MemoryDraftStore store = _MemoryDraftStore(
      draft: const TranslatorDraft(sourceText: 'Черновик.'),
    );

    final TranslatorCubit cubit = TranslatorCubit(
      provider: _FakeProvider.success(_report()),
      draftStore: store,
    );
    addTearDown(cubit.close);

    await cubit.restore();
    await cubit.clear();

    expect(cubit.state.status, TranslatorViewStatus.idle);
    expect(cubit.state.sourceText, isEmpty);
    expect(store.clearCount, 1);
  });
}

TranslatorRunReport _report() {
  final TranslatorWorkRequest request = TranslatorWorkRequest(
    sourceText: 'Исходный текст.',
  );

  return TranslatorRunReport(
    request: request,
    bundle: TranslationBundle(
      sourceLanguage: TranslationLanguage.ru,
      sourceText: request.sourceText,
      ru: request.sourceText,
      en: 'Source text.',
      th: 'ข้อความต้นฉบับ',
    ),
    audit: TranslationAudit(),
    createdAt: DateTime.utc(2026, 7, 26, 6),
  );
}

final class _MemoryDraftStore implements TranslatorDraftStore {
  _MemoryDraftStore({this.draft});

  TranslatorDraft? draft;
  int clearCount = 0;

  @override
  Future<TranslatorDraft?> load() async => draft;

  @override
  Future<void> save(TranslatorDraft draft) async {
    this.draft = draft;
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
    draft = null;
  }
}

final class _FakeProvider implements TranslatorProvider {
  _FakeProvider.success(TranslatorRunReport report)
    : _operation = _CompletedOperation.success(report);

  _FakeProvider.failure(TranslatorFailure failure)
    : _operation = _CompletedOperation.failure(failure);

  final TranslatorOperation _operation;
  TranslatorWorkRequest? lastRequest;

  @override
  TranslatorOperation start({
    required TranslatorWorkRequest request,
    required String accessKey,
  }) {
    lastRequest = request;
    return _operation;
  }
}

final class _CompletedOperation implements TranslatorOperation {
  _CompletedOperation.success(TranslatorRunReport report)
    : _report = report,
      _failure = null;

  _CompletedOperation.failure(TranslatorFailure failure)
    : _report = null,
      _failure = failure;

  final TranslatorRunReport? _report;
  final TranslatorFailure? _failure;
  final StreamController<TranslatorRunStage> _progressController =
      StreamController<TranslatorRunStage>(sync: true);

  bool _started = false;

  @override
  Future<TranslatorRunReport> get result async {
    if (_started) {
      throw StateError('Test TranslatorOperation result was requested twice.');
    }

    _started = true;

    for (final TranslatorRunStage stage in TranslatorRunStage.values) {
      _progressController.add(stage);
      await Future<void>.delayed(Duration.zero);
    }

    await _progressController.close();

    final TranslatorFailure? failure = _failure;
    if (failure != null) {
      throw TranslatorProviderException(failure);
    }

    return _report!;
  }

  @override
  Stream<TranslatorRunStage> get progress => _progressController.stream;

  @override
  void cancel() {}
}

final class _RetryCapableProvider
    implements TranslatorProvider, TranslatorAuditRetryProvider {
  _RetryCapableProvider(this.report);

  final TranslatorRunReport report;
  int fullRunCount = 0;
  int auditOnlyRunCount = 0;

  @override
  TranslatorOperation start({
    required TranslatorWorkRequest request,
    required String accessKey,
  }) {
    fullRunCount += 1;
    return _PartialThenFailureOperation(report.bundle);
  }

  @override
  TranslatorOperation startAudit({
    required TranslatorWorkRequest request,
    required TranslationBundle bundle,
    required String accessKey,
  }) {
    auditOnlyRunCount += 1;
    expect(bundle, report.bundle);
    expect(request, report.request);
    return _CompletedOperation.success(report);
  }
}

final class _PartialThenFailureOperation
    implements TranslatorOperation, TranslatorPartialBundleOperation {
  _PartialThenFailureOperation(this.bundle);

  final TranslationBundle bundle;
  final StreamController<TranslatorRunStage> _progressController =
      StreamController<TranslatorRunStage>(sync: true);
  final StreamController<TranslationBundle> _partialController =
      StreamController<TranslationBundle>(sync: true);

  @override
  Stream<TranslatorRunStage> get progress => _progressController.stream;

  @override
  Stream<TranslationBundle> get partialBundles => _partialController.stream;

  @override
  Future<TranslatorRunReport> get result async {
    _progressController.add(TranslatorRunStage.directTranslation);
    await Future<void>.delayed(Duration.zero);
    _partialController.add(bundle);
    await Future<void>.delayed(Duration.zero);
    _progressController.add(TranslatorRunStage.audit);
    await Future<void>.delayed(Duration.zero);
    await _progressController.close();
    await _partialController.close();

    throw TranslatorProviderException(
      TranslatorFailure(
        stage: TranslatorFailureStage.transport,
        code: TranslatorFailureCode.networkFailure,
        message: 'Network interrupted.',
        completeness: TranslationCompleteness.complete,
        partialBundle: bundle,
      ),
    );
  }

  @override
  void cancel() {}
}

final class _SingleOperationProvider implements TranslatorProvider {
  const _SingleOperationProvider(this.operation);

  final TranslatorOperation operation;

  @override
  TranslatorOperation start({
    required TranslatorWorkRequest request,
    required String accessKey,
  }) => operation;
}

final class _ControlledOperation implements TranslatorOperation {
  final Completer<TranslatorRunReport> _completer =
      Completer<TranslatorRunReport>();

  bool cancelled = false;

  @override
  Future<TranslatorRunReport> get result => _completer.future;

  @override
  Stream<TranslatorRunStage> get progress =>
      const Stream<TranslatorRunStage>.empty();

  @override
  void cancel() {
    cancelled = true;
  }

  void completeCancelled() {
    if (_completer.isCompleted) {
      return;
    }

    _completer.completeError(
      TranslatorProviderException(
        TranslatorFailure(
          stage: TranslatorFailureStage.transport,
          code: TranslatorFailureCode.cancelled,
          message: 'Cancelled.',
          completeness: TranslationCompleteness.translationIncomplete,
        ),
      ),
    );
  }
}
