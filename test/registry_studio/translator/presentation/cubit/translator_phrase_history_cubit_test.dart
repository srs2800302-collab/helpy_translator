import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/application/translate_phrase.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_phrase_history_persistence.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_phrase_provider.dart';
import 'package:helpy_translator/registry_studio/translator/presentation/cubit/translator_phrase_cubit.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_result.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_status.dart';

void main() {
  test('restores prepends persists and clears full history', () async {
    final TranslatorPhraseResult restored = TranslatorPhraseResult(
      sourceLanguage: 'ru',
      sourceText: 'Сохранённая формулировка.',
      status: TranslatorPhraseStatus.needsReview,
    );
    final TranslatorPhraseResult first = TranslatorPhraseResult(
      sourceLanguage: 'en',
      sourceText: 'First new phrase.',
      status: TranslatorPhraseStatus.exact,
    );
    final TranslatorPhraseResult second = TranslatorPhraseResult(
      sourceLanguage: 'th',
      sourceText: 'ข้อความที่สอง',
      status: TranslatorPhraseStatus.equivalent,
    );

    final _MemoryHistoryPersistence persistence = _MemoryHistoryPersistence(
      <TranslatorPhraseResult>[restored],
    );
    final _QueuedProvider provider = _QueuedProvider(<TranslatorPhraseResult>[
      first,
      second,
    ]);
    final TranslatorPhraseCubit cubit = TranslatorPhraseCubit(
      translatePhrase: TranslatePhrase(provider: provider),
      historyPersistence: persistence,
    );
    addTearDown(cubit.close);

    await cubit.restore();

    expect(cubit.state.history, <TranslatorPhraseResult>[restored]);

    await cubit.translatePhrase(sourceText: first.sourceText);

    expect(cubit.state.history, <TranslatorPhraseResult>[first, restored]);
    expect(persistence.savedHistory, <TranslatorPhraseResult>[first, restored]);

    await cubit.translatePhrase(sourceText: second.sourceText);

    expect(cubit.state.history, <TranslatorPhraseResult>[
      second,
      first,
      restored,
    ]);
    expect(persistence.savedHistory, <TranslatorPhraseResult>[
      second,
      first,
      restored,
    ]);

    await cubit.clear();

    expect(cubit.state.history, isEmpty);
    expect(persistence.clearCount, 1);
  });
}

final class _MemoryHistoryPersistence
    implements TranslatorPhraseHistoryPersistence {
  _MemoryHistoryPersistence(this.storedHistory);

  List<TranslatorPhraseResult> storedHistory;
  List<TranslatorPhraseResult> savedHistory = <TranslatorPhraseResult>[];
  int clearCount = 0;

  @override
  Future<List<TranslatorPhraseResult>> load() async {
    return List<TranslatorPhraseResult>.of(storedHistory);
  }

  @override
  Future<void> save(List<TranslatorPhraseResult> history) async {
    savedHistory = List<TranslatorPhraseResult>.of(history);
    storedHistory = List<TranslatorPhraseResult>.of(history);
  }

  @override
  Future<void> clear() async {
    clearCount++;
    storedHistory = <TranslatorPhraseResult>[];
    savedHistory = <TranslatorPhraseResult>[];
  }
}

final class _QueuedProvider implements TranslatorPhraseProvider {
  _QueuedProvider(this.results);

  final List<TranslatorPhraseResult> results;
  int index = 0;

  @override
  Future<TranslatorPhraseResult> translatePhrase({
    required String sourceText,
    String? sourceLanguageHint,
    String? engineerContext,
  }) async {
    return results[index++];
  }
}
