import 'package:flutter_bloc/flutter_bloc.dart';

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
  }) : super(const TranslatorState.initial());

  final TranslateCanonicalPhrase translateCanonicalPhrase;
  final AuditCanonicalClientRules auditCanonicalClientRules;

  void clearResults() {
    emit(const TranslatorState.initial());
  }

  Future<void> translate(String sentence) async {
    emit(
      state.copyWith(
        status: TranslatorStatus.loading,
        clearResult: true,
        auditResults: const <CanonicalAuditResult>[],
        errorMessage: '',
        auditTotal: 0,
        auditCompleted: 0,
        currentAuditPhrase: '',
      ),
    );

    try {
      final TranslationResult result = await translateCanonicalPhrase(sentence);

      emit(
        state.copyWith(
          status: TranslatorStatus.success,
          result: result,
          auditResults: const <CanonicalAuditResult>[],
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
    }
  }

  Future<void> auditCanonicalRules() async {
    emit(
      state.copyWith(
        status: TranslatorStatus.auditLoading,
        clearResult: true,
        auditResults: const <CanonicalAuditResult>[],
        errorMessage: '',
        auditTotal: 0,
        auditCompleted: 0,
        currentAuditPhrase: 'Подготовка словаря...',
      ),
    );

    try {
      final List<CanonicalAuditResult> results =
          await auditCanonicalClientRules();

      emit(
        state.copyWith(
          status: TranslatorStatus.auditSuccess,
          clearResult: true,
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
    }
  }
}
