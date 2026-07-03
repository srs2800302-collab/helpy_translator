import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/background/background_execution_controller.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/persistence/translator_state_persistence.dart';
import '../../../../core/persistence/registry_phrase_status_persistence.dart';
import '../../domain/entities/canonical_audit_result.dart';
import '../../domain/entities/registry_node.dart';
import '../../domain/entities/translation_result.dart';
import '../../domain/usecases/audit_canonical_client_rules.dart';
import '../../domain/usecases/load_registry_tree.dart';
import '../../domain/usecases/translate_canonical_phrase.dart';
import 'translator_state.dart';

final class TranslatorCubit extends Cubit<TranslatorState> {
  TranslatorCubit({
    required this.translateCanonicalPhrase,
    required this.auditCanonicalClientRules,
    required this.backgroundExecutionController,
    required this.persistence,
    required this.loadRegistryTree,
    required this.registryPhraseStatusPersistence,
  }) : super(const TranslatorState.initial());

  final TranslateCanonicalPhrase translateCanonicalPhrase;
  final AuditCanonicalClientRules auditCanonicalClientRules;
  final BackgroundExecutionController backgroundExecutionController;
  final TranslatorStatePersistence persistence;
  final LoadRegistryTree loadRegistryTree;
  final RegistryPhraseStatusPersistence registryPhraseStatusPersistence;

  Future<void> restorePersistedState() async {
    final List<TranslationResult> translationHistory = await persistence
        .loadTranslationHistory();
    final List<TranslationResult> deduplicatedTranslationHistory =
        _deduplicateTranslationHistory(translationHistory);
    if (deduplicatedTranslationHistory.length != translationHistory.length) {
      await persistence.saveTranslationHistory(deduplicatedTranslationHistory);
    }

    final List<CanonicalAuditResult> auditResults = await persistence
        .loadAuditResults();
    final Map<String, PersistedRegistryPhraseRecord> phraseStatusIndex =
        await registryPhraseStatusPersistence.loadIndex();

    emit(
      state.copyWith(
        translationHistory: deduplicatedTranslationHistory,
        auditResults: auditResults,
        auditTotal: auditResults.length,
        auditCompleted: auditResults.length,
        currentAuditPhrase: '',
        registryPhraseStatusIndex: phraseStatusIndex,
      ),
    );
  }

  Future<void> clearResults() async {
    await persistence.clear();

    emit(
      state.copyWith(
        status: TranslatorStatus.initial,
        clearResult: true,
        clearTranslationHistory: true,
        auditResults: const <CanonicalAuditResult>[],
        errorMessage: '',
        auditTotal: 0,
        auditCompleted: 0,
        currentAuditPhrase: '',
      ),
    );
  }

  Future<String> exportRegistryStatuses() {
    return registryPhraseStatusPersistence.exportJson();
  }

  Future<void> importRegistryStatuses(String rawJson) async {
    await registryPhraseStatusPersistence.importJson(rawJson);

    final Map<String, PersistedRegistryPhraseRecord> phraseStatusIndex =
        await registryPhraseStatusPersistence.loadIndex();

    emit(state.copyWith(registryPhraseStatusIndex: phraseStatusIndex));
  }

  Future<void> loadRegistry() async {
    await _loadRegistry(refresh: false);
  }

  Future<void> refreshRegistry() async {
    await _loadRegistry(refresh: true);
  }

  Future<void> _loadRegistry({required bool refresh}) async {
    emit(
      state.copyWith(
        status: TranslatorStatus.registryLoading,
        registryErrorMessage: '',
      ),
    );

    try {
      final RegistryNode root = refresh
          ? await loadRegistryTree.refresh()
          : await loadRegistryTree();
      final Map<String, PersistedRegistryPhraseRecord> phraseStatusIndex =
          await registryPhraseStatusPersistence.loadIndex();

      emit(
        state.copyWith(
          status: TranslatorStatus.registrySuccess,
          registryRoot: root,
          registryPhraseStatusIndex: phraseStatusIndex,
          registryErrorMessage: '',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: TranslatorStatus.failure,
          registryErrorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> translate(String sentence) async {
    emit(
      state.copyWith(
        status: TranslatorStatus.loading,
        errorMessage: '',
        auditTotal: 0,
        auditCompleted: 0,
        currentAuditPhrase: '',
      ),
    );

    await backgroundExecutionController.start(
      title: 'Helpy Translator',
      message: 'Перевод формулировки выполняется в фоне',
    );

    try {
      final TranslationResult result = await translateCanonicalPhrase(sentence);
      final List<TranslationResult> updatedHistory =
          _deduplicateTranslationHistory(<TranslationResult>[
            result,
            ...state.translationHistory,
          ]);

      await persistence.saveTranslationHistory(updatedHistory);

      if (_translationExistsInRegistry(result, state.registryRoot)) {
        await registryPhraseStatusPersistence.saveTranslationResult(result);
      }

      final Map<String, PersistedRegistryPhraseRecord> phraseStatusIndex =
          await registryPhraseStatusPersistence.loadIndex();

      emit(
        state.copyWith(
          status: TranslatorStatus.success,
          result: result,
          translationHistory: updatedHistory,
          registryPhraseStatusIndex: phraseStatusIndex,
          errorMessage: '',
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: TranslatorStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: TranslatorStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    } finally {
      await backgroundExecutionController.stop();
    }
  }

  static bool _translationExistsInRegistry(
    TranslationResult result,
    RegistryNode? root,
  ) {
    if (root == null) {
      return false;
    }

    final String phrase = result.sourceText.trim().isEmpty
        ? result.ru.trim()
        : result.sourceText.trim();

    final String normalizedPhrase =
        RegistryPhraseStatusPersistence.normalizePhrase(phrase);

    if (normalizedPhrase.isEmpty) {
      return false;
    }

    return _nodeContainsPhrase(root, normalizedPhrase);
  }

  static bool _nodeContainsPhrase(RegistryNode node, String normalizedPhrase) {
    for (final String phrase in node.phrases) {
      if (RegistryPhraseStatusPersistence.normalizePhrase(phrase) ==
          normalizedPhrase) {
        return true;
      }
    }

    for (final RegistryNode child in node.children) {
      if (_nodeContainsPhrase(child, normalizedPhrase)) {
        return true;
      }
    }

    return false;
  }

  static List<TranslationResult> _deduplicateTranslationHistory(
    List<TranslationResult> history,
  ) {
    final Set<String> seen = <String>{};
    final List<TranslationResult> result = <TranslationResult>[];

    for (final TranslationResult item in history) {
      final String phrase = item.sourceText.trim().isEmpty
          ? item.ru.trim()
          : item.sourceText.trim();
      final String key = RegistryPhraseStatusPersistence.normalizePhrase(
        phrase,
      );

      if (key.isEmpty || seen.contains(key)) {
        continue;
      }

      seen.add(key);
      result.add(item);
    }

    return List<TranslationResult>.unmodifiable(result);
  }

  Future<void> auditCanonicalRules() async {
    emit(
      state.copyWith(
        status: TranslatorStatus.auditLoading,
        errorMessage: '',
        auditTotal: 0,
        auditCompleted: 0,
        currentAuditPhrase: 'Подготовка словаря...',
      ),
    );

    await backgroundExecutionController.start(
      title: 'Helpy Translator',
      message: 'Проверка канонического словаря выполняется в фоне',
    );

    try {
      final List<CanonicalAuditResult> results =
          await auditCanonicalClientRules(
            onProgress:
                ({
                  required int completed,
                  required int total,
                  required String currentPhrase,
                  required List<CanonicalAuditResult> results,
                }) {
                  persistence.saveAuditResults(results);
                  registryPhraseStatusPersistence.saveAuditResults(results);

                  emit(
                    state.copyWith(
                      status: TranslatorStatus.auditLoading,
                      auditResults: results,
                      auditTotal: total,
                      auditCompleted: completed,
                      currentAuditPhrase: currentPhrase,
                      errorMessage: '',
                    ),
                  );
                },
          );

      await persistence.saveAuditResults(results);
      await registryPhraseStatusPersistence.saveAuditResults(results);
      final Map<String, PersistedRegistryPhraseRecord> phraseStatusIndex =
          await registryPhraseStatusPersistence.loadIndex();

      emit(
        state.copyWith(
          status: TranslatorStatus.auditSuccess,
          auditResults: results,
          auditTotal: results.length,
          auditCompleted: results.length,
          currentAuditPhrase: '',
          registryPhraseStatusIndex: phraseStatusIndex,
          errorMessage: '',
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: TranslatorStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: TranslatorStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    } finally {
      await backgroundExecutionController.stop();
    }
  }
}
