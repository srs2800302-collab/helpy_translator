import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/background/background_execution_controller.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/canonical_audit_result.dart';
import '../../domain/entities/translation_result.dart';
import '../../domain/usecases/audit_canonical_client_rules.dart';
import '../../domain/usecases/translate_canonical_phrase.dart';
import 'translator_state.dart';

final class TranslatorCubit extends Cubit<TranslatorState> {
  TranslatorCubit({
    required this.translateCanonicalPhrase,
    required this.auditCanonicalClientRules,
    required this.backgroundExecutionController,
  }) : super(const TranslatorState.initial());

  final TranslateCanonicalPhrase translateCanonicalPhrase;
  final AuditCanonicalClientRules auditCanonicalClientRules;
  final BackgroundExecutionController backgroundExecutionController;

  void clearResults() {
    emit(const TranslatorState.initial());
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

      emit(
        state.copyWith(
          status: TranslatorStatus.success,
          result: result,
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
    } catch (_) {
      emit(
        state.copyWith(
          status: TranslatorStatus.failure,
          errorMessage: 'Неизвестная ошибка перевода.',
        ),
      );
    } finally {
      await backgroundExecutionController.stop();
    }
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
        onProgress: ({
          required int completed,
          required int total,
          required String currentPhrase,
          required List<CanonicalAuditResult> results,
        }) {
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

      emit(
        state.copyWith(
          status: TranslatorStatus.auditSuccess,
          auditResults: results,
          auditTotal: results.length,
          auditCompleted: results.length,
          currentAuditPhrase: '',
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
    } catch (_) {
      emit(
        state.copyWith(
          status: TranslatorStatus.failure,
          errorMessage: 'Неизвестная ошибка аудита.',
        ),
      );
    } finally {
      await backgroundExecutionController.stop();
    }
  }
}
