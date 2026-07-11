import 'registry_studio_ui_language.dart';

final class RegistryStudioUiLabels {
  const RegistryStudioUiLabels({
    required this.appTitle,
    required this.languageLabel,
    required this.translatorScreenTitle,
    required this.operationCreationScreenTitle,
    required this.translatorPhrase,
    required this.operationCreation,
    required this.operationStatusTransition,
    required this.relatedContextPreparation,
    required this.guardRecord,
  });

  factory RegistryStudioUiLabels.forLanguage(
    RegistryStudioUiLanguage language,
  ) {
    return switch (language) {
      RegistryStudioUiLanguage.ru => const RegistryStudioUiLabels(
        appTitle: 'Registry Studio',
        languageLabel: 'Язык',
        translatorScreenTitle: 'Перевод формулировки',
        operationCreationScreenTitle: 'Создание инженерной операции',
        translatorPhrase: RegistryStudioTranslatorPhraseLabels(
          title: 'Перевод формулировки',
          sourceTextLabel: 'Каноническая формулировка',
          sourceLanguageHintLabel: 'Подсказка языка',
          sourceLanguageHintHelper: 'Например: ru, en, th',
          engineerContextLabel: 'Контекст инженера',
          translateButton: 'Перевести',
          clearButton: 'Очистить',
          additionalParametersLabel: 'Дополнительные параметры',
          resultsTitle: 'Результаты переводов',
          sourceLanguageRow: 'Исходный язык',
          sourceTextRow: 'Исходный текст',
          commentRow: 'Комментарий',
          canonicalCandidateRow: 'Кандидат канонической формулировки',
          exactStatus: 'Точное совпадение',
          equivalentStatus: 'Эквивалентная формулировка',
          needsReviewStatus: 'Нужна проверка',
          canonicalDriftStatus: 'Отклонение от канона',
          failedStatus: 'Ошибка',
        ),
        operationCreation: RegistryStudioOperationCreationLabels(
          title: 'Создание инженерной операции',
          operationIdLabel: 'ID операции',
          problemStatementLabel: 'Постановка проблемы',
          createButton: 'Создать операцию',
          createdTitle: 'Операция создана',
          statusLabel: 'Статус',
          operationIdRequiredError: 'ID операции обязателен.',
          problemStatementRequiredError: 'Постановка проблемы обязательна.',
          persistenceFailedError: 'Не удалось сохранить инженерную операцию.',
        ),
        operationStatusTransition:
            RegistryStudioOperationStatusTransitionLabels(
              title: 'Смена статуса инженерной операции',
              currentOperationTitle: 'Текущая операция',
              operationIdLabel: 'ID операции',
              problemStatementLabel: 'Постановка проблемы',
              currentStatusLabel: 'Текущий статус',
              requestedStatusLabel: 'Запрошенный статус',
              decisionStatementLabel: 'Решение инженера',
              transitionButton: 'Сменить статус',
              transitionedTitle: 'Статус изменён',
              transitionFailedTitle: 'Ошибка смены статуса',
              persistenceFailedError:
                  'Не удалось сохранить новый статус инженерной операции.',
            ),
        relatedContextPreparation:
            RegistryStudioRelatedContextPreparationLabels(
              title: 'Подготовка related context',
              primaryEntityTitle: 'Primary entity',
              relatedContextTitle: 'Related context подготовлен',
              resolvedContextTitle: 'Resolved related context подготовлен',
              prepareButton: 'Подготовить context',
              primaryEntityLabel: 'Primary entity ID',
              pathLabel: 'Path',
              kindLabel: 'Kind',
              matchedRelationsLabel: 'Matched relations',
              relatedEntityIdsLabel: 'Related entity ids',
              resolvedRelatedEntitiesLabel: 'Resolved related entities',
              missingRelatedEntityIdsLabel: 'Missing related entity ids',
              noItemsLabel: 'Нет данных',
              preparationFailedTitle: 'Ошибка подготовки context',
            ),
        guardRecord: RegistryStudioGuardRecordLabels(
          title: 'Guard record',
          entityTitle: 'Registry entity',
          entityIdLabel: 'Entity ID',
          pathLabel: 'Path',
          kindLabel: 'Kind',
          recordTypeLabel: 'Тип записи',
          headingLabel: 'Заголовок',
          summaryLabel: 'Краткое описание',
          sourceEvidenceTitle: 'Source evidence',
          sourceDocumentPathLabel: 'Путь к источнику',
          sourceSnapshotFingerprintLabel: 'Fingerprint источника',
          headingPathLabel: 'Путь заголовков',
          lineRangeLabel: 'Диапазон строк',
        ),
      ),
      RegistryStudioUiLanguage.en => const RegistryStudioUiLabels(
        appTitle: 'Registry Studio',
        languageLabel: 'Language',
        translatorScreenTitle: 'Phrase translation',
        operationCreationScreenTitle: 'Create engineering operation',
        translatorPhrase: RegistryStudioTranslatorPhraseLabels(
          title: 'Phrase translation',
          sourceTextLabel: 'Canonical wording',
          sourceLanguageHintLabel: 'Language hint',
          sourceLanguageHintHelper: 'Example: ru, en, th',
          engineerContextLabel: 'Engineer context',
          translateButton: 'Translate',
          clearButton: 'Clear',
          additionalParametersLabel: 'Additional parameters',
          resultsTitle: 'Translation results',
          sourceLanguageRow: 'Source language',
          sourceTextRow: 'Source text',
          commentRow: 'Comment',
          canonicalCandidateRow: 'Candidate canonical phrase',
          exactStatus: 'Exact match',
          equivalentStatus: 'Equivalent wording',
          needsReviewStatus: 'Needs review',
          canonicalDriftStatus: 'Canonical drift',
          failedStatus: 'Error',
        ),
        operationCreation: RegistryStudioOperationCreationLabels(
          title: 'Create engineering operation',
          operationIdLabel: 'Operation ID',
          problemStatementLabel: 'Problem statement',
          createButton: 'Create operation',
          createdTitle: 'Operation created',
          statusLabel: 'Status',
          operationIdRequiredError: 'Operation ID is required.',
          problemStatementRequiredError: 'Problem statement is required.',
          persistenceFailedError: 'Failed to save the engineering operation.',
        ),
        operationStatusTransition:
            RegistryStudioOperationStatusTransitionLabels(
              title: 'Engineering operation status transition',
              currentOperationTitle: 'Current operation',
              operationIdLabel: 'Operation ID',
              problemStatementLabel: 'Problem statement',
              currentStatusLabel: 'Current status',
              requestedStatusLabel: 'Requested status',
              decisionStatementLabel: 'Engineer decision',
              transitionButton: 'Change status',
              transitionedTitle: 'Status changed',
              transitionFailedTitle: 'Status transition error',
              persistenceFailedError:
                  'Failed to save the new engineering operation status.',
            ),
        relatedContextPreparation:
            RegistryStudioRelatedContextPreparationLabels(
              title: 'Prepare related context',
              primaryEntityTitle: 'Primary entity',
              relatedContextTitle: 'Related context prepared',
              resolvedContextTitle: 'Resolved related context prepared',
              prepareButton: 'Prepare context',
              primaryEntityLabel: 'Primary entity ID',
              pathLabel: 'Path',
              kindLabel: 'Kind',
              matchedRelationsLabel: 'Matched relations',
              relatedEntityIdsLabel: 'Related entity ids',
              resolvedRelatedEntitiesLabel: 'Resolved related entities',
              missingRelatedEntityIdsLabel: 'Missing related entity ids',
              noItemsLabel: 'No items',
              preparationFailedTitle: 'Context preparation error',
            ),
        guardRecord: RegistryStudioGuardRecordLabels(
          title: 'Guard record',
          entityTitle: 'Registry entity',
          entityIdLabel: 'Entity ID',
          pathLabel: 'Path',
          kindLabel: 'Kind',
          recordTypeLabel: 'Record type',
          headingLabel: 'Heading',
          summaryLabel: 'Summary',
          sourceEvidenceTitle: 'Source evidence',
          sourceDocumentPathLabel: 'Source document path',
          sourceSnapshotFingerprintLabel: 'Source snapshot fingerprint',
          headingPathLabel: 'Heading path',
          lineRangeLabel: 'Line range',
        ),
      ),
      RegistryStudioUiLanguage.th => const RegistryStudioUiLabels(
        appTitle: 'Registry Studio',
        languageLabel: 'ภาษา',
        translatorScreenTitle: 'แปลถ้อยคำ',
        operationCreationScreenTitle: 'สร้างงานวิศวกรรม',
        translatorPhrase: RegistryStudioTranslatorPhraseLabels(
          title: 'แปลถ้อยคำ',
          sourceTextLabel: 'ถ้อยคำมาตรฐาน',
          sourceLanguageHintLabel: 'คำใบ้ภาษา',
          sourceLanguageHintHelper: 'เช่น: ru, en, th',
          engineerContextLabel: 'บริบทของวิศวกร',
          translateButton: 'แปล',
          clearButton: 'ล้าง',
          additionalParametersLabel: 'พารามิเตอร์เพิ่มเติม',
          resultsTitle: 'ผลการแปล',
          sourceLanguageRow: 'ภาษาต้นทาง',
          sourceTextRow: 'ข้อความต้นทาง',
          commentRow: 'ความคิดเห็น',
          canonicalCandidateRow: 'ถ้อยคำมาตรฐานที่เสนอ',
          exactStatus: 'ตรงกันทุกประการ',
          equivalentStatus: 'ถ้อยคำเทียบเท่า',
          needsReviewStatus: 'ต้องตรวจสอบ',
          canonicalDriftStatus: 'เบี่ยงเบนจากมาตรฐาน',
          failedStatus: 'ข้อผิดพลาด',
        ),
        operationCreation: RegistryStudioOperationCreationLabels(
          title: 'สร้างงานวิศวกรรม',
          operationIdLabel: 'รหัสงาน',
          problemStatementLabel: 'คำอธิบายปัญหา',
          createButton: 'สร้างงาน',
          createdTitle: 'สร้างงานแล้ว',
          statusLabel: 'สถานะ',
          operationIdRequiredError: 'ต้องระบุรหัสงาน',
          problemStatementRequiredError: 'ต้องระบุคำอธิบายปัญหา',
          persistenceFailedError: 'ไม่สามารถบันทึกงานวิศวกรรมได้',
        ),
        operationStatusTransition:
            RegistryStudioOperationStatusTransitionLabels(
              title: 'เปลี่ยนสถานะงานวิศวกรรม',
              currentOperationTitle: 'งานปัจจุบัน',
              operationIdLabel: 'รหัสงาน',
              problemStatementLabel: 'คำอธิบายปัญหา',
              currentStatusLabel: 'สถานะปัจจุบัน',
              requestedStatusLabel: 'สถานะที่ต้องการ',
              decisionStatementLabel: 'การตัดสินใจของวิศวกร',
              transitionButton: 'เปลี่ยนสถานะ',
              transitionedTitle: 'เปลี่ยนสถานะแล้ว',
              transitionFailedTitle: 'ข้อผิดพลาดในการเปลี่ยนสถานะ',
              persistenceFailedError:
                  'ไม่สามารถบันทึกสถานะใหม่ของงานวิศวกรรมได้',
            ),
        relatedContextPreparation:
            RegistryStudioRelatedContextPreparationLabels(
              title: 'เตรียม related context',
              primaryEntityTitle: 'Primary entity',
              relatedContextTitle: 'เตรียม related context แล้ว',
              resolvedContextTitle: 'เตรียม resolved related context แล้ว',
              prepareButton: 'เตรียม context',
              primaryEntityLabel: 'รหัส primary entity',
              pathLabel: 'Path',
              kindLabel: 'Kind',
              matchedRelationsLabel: 'Matched relations',
              relatedEntityIdsLabel: 'Related entity ids',
              resolvedRelatedEntitiesLabel: 'Resolved related entities',
              missingRelatedEntityIdsLabel: 'Missing related entity ids',
              noItemsLabel: 'ไม่มีข้อมูล',
              preparationFailedTitle: 'ข้อผิดพลาดในการเตรียม context',
            ),
        guardRecord: RegistryStudioGuardRecordLabels(
          title: 'ระเบียน Guard',
          entityTitle: 'Registry entity',
          entityIdLabel: 'Entity ID',
          pathLabel: 'Path',
          kindLabel: 'Kind',
          recordTypeLabel: 'ประเภทระเบียน',
          headingLabel: 'หัวข้อ',
          summaryLabel: 'สรุป',
          sourceEvidenceTitle: 'หลักฐานแหล่งที่มา',
          sourceDocumentPathLabel: 'พาธเอกสารต้นทาง',
          sourceSnapshotFingerprintLabel: 'Fingerprint ของ snapshot',
          headingPathLabel: 'พาธหัวข้อ',
          lineRangeLabel: 'ช่วงบรรทัด',
        ),
      ),
    };
  }

  final String appTitle;
  final String languageLabel;
  final String translatorScreenTitle;
  final String operationCreationScreenTitle;
  final RegistryStudioTranslatorPhraseLabels translatorPhrase;
  final RegistryStudioOperationCreationLabels operationCreation;
  final RegistryStudioOperationStatusTransitionLabels operationStatusTransition;
  final RegistryStudioRelatedContextPreparationLabels relatedContextPreparation;
  final RegistryStudioGuardRecordLabels guardRecord;
}

final class RegistryStudioTranslatorPhraseLabels {
  const RegistryStudioTranslatorPhraseLabels({
    required this.title,
    required this.sourceTextLabel,
    required this.sourceLanguageHintLabel,
    required this.sourceLanguageHintHelper,
    required this.engineerContextLabel,
    required this.translateButton,
    required this.clearButton,
    required this.additionalParametersLabel,
    required this.resultsTitle,
    required this.sourceLanguageRow,
    required this.sourceTextRow,
    required this.commentRow,
    required this.canonicalCandidateRow,
    required this.exactStatus,
    required this.equivalentStatus,
    required this.needsReviewStatus,
    required this.canonicalDriftStatus,
    required this.failedStatus,
  });

  final String title;
  final String sourceTextLabel;
  final String sourceLanguageHintLabel;
  final String sourceLanguageHintHelper;
  final String engineerContextLabel;
  final String translateButton;
  final String clearButton;
  final String additionalParametersLabel;
  final String resultsTitle;
  final String sourceLanguageRow;
  final String sourceTextRow;
  final String commentRow;
  final String canonicalCandidateRow;
  final String exactStatus;
  final String equivalentStatus;
  final String needsReviewStatus;
  final String canonicalDriftStatus;
  final String failedStatus;
}

final class RegistryStudioOperationCreationLabels {
  const RegistryStudioOperationCreationLabels({
    required this.title,
    required this.operationIdLabel,
    required this.problemStatementLabel,
    required this.createButton,
    required this.createdTitle,
    required this.statusLabel,
    required this.operationIdRequiredError,
    required this.problemStatementRequiredError,
    required this.persistenceFailedError,
  });

  final String title;
  final String operationIdLabel;
  final String problemStatementLabel;
  final String createButton;
  final String createdTitle;
  final String statusLabel;
  final String operationIdRequiredError;
  final String problemStatementRequiredError;
  final String persistenceFailedError;
}

final class RegistryStudioOperationStatusTransitionLabels {
  const RegistryStudioOperationStatusTransitionLabels({
    required this.title,
    required this.currentOperationTitle,
    required this.operationIdLabel,
    required this.problemStatementLabel,
    required this.currentStatusLabel,
    required this.requestedStatusLabel,
    required this.decisionStatementLabel,
    required this.transitionButton,
    required this.transitionedTitle,
    required this.transitionFailedTitle,
    required this.persistenceFailedError,
  });

  final String title;
  final String currentOperationTitle;
  final String operationIdLabel;
  final String problemStatementLabel;
  final String currentStatusLabel;
  final String requestedStatusLabel;
  final String decisionStatementLabel;
  final String transitionButton;
  final String transitionedTitle;
  final String transitionFailedTitle;
  final String persistenceFailedError;
}

final class RegistryStudioRelatedContextPreparationLabels {
  const RegistryStudioRelatedContextPreparationLabels({
    required this.title,
    required this.primaryEntityTitle,
    required this.relatedContextTitle,
    required this.resolvedContextTitle,
    required this.prepareButton,
    required this.primaryEntityLabel,
    required this.pathLabel,
    required this.kindLabel,
    required this.matchedRelationsLabel,
    required this.relatedEntityIdsLabel,
    required this.resolvedRelatedEntitiesLabel,
    required this.missingRelatedEntityIdsLabel,
    required this.noItemsLabel,
    required this.preparationFailedTitle,
  });

  final String title;
  final String primaryEntityTitle;
  final String relatedContextTitle;
  final String resolvedContextTitle;
  final String prepareButton;
  final String primaryEntityLabel;
  final String pathLabel;
  final String kindLabel;
  final String matchedRelationsLabel;
  final String relatedEntityIdsLabel;
  final String resolvedRelatedEntitiesLabel;
  final String missingRelatedEntityIdsLabel;
  final String noItemsLabel;
  final String preparationFailedTitle;
}

final class RegistryStudioGuardRecordLabels {
  const RegistryStudioGuardRecordLabels({
    required this.title,
    required this.entityTitle,
    required this.entityIdLabel,
    required this.pathLabel,
    required this.kindLabel,
    required this.recordTypeLabel,
    required this.headingLabel,
    required this.summaryLabel,
    required this.sourceEvidenceTitle,
    required this.sourceDocumentPathLabel,
    required this.sourceSnapshotFingerprintLabel,
    required this.headingPathLabel,
    required this.lineRangeLabel,
  });

  final String title;
  final String entityTitle;
  final String entityIdLabel;
  final String pathLabel;
  final String kindLabel;
  final String recordTypeLabel;
  final String headingLabel;
  final String summaryLabel;
  final String sourceEvidenceTitle;
  final String sourceDocumentPathLabel;
  final String sourceSnapshotFingerprintLabel;
  final String headingPathLabel;
  final String lineRangeLabel;
}
