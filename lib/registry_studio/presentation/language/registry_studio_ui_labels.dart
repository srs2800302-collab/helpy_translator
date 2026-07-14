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
  });

  factory RegistryStudioUiLabels.forLanguage(
    RegistryStudioUiLanguage language,
  ) {
    return switch (language) {
      RegistryStudioUiLanguage.ru => const RegistryStudioUiLabels(
        appTitle: 'Registry Studio',
        languageLabel: 'Язык',
        translatorScreenTitle: 'Адаптивный переводчик',
        operationCreationScreenTitle: 'Создание инженерной операции',
        translatorPhrase: RegistryStudioTranslatorPhraseLabels(
          title: 'Адаптивный переводчик',
          sourceTextLabel: 'Каноническая формулировка',
          translateButton: 'Перевести',
          clearButton: 'Очистить',
          copyAllButton: 'Копировать всё',
          copyAllSuccessMessage: 'Все варианты скопированы',
          resultsTitle: 'Результаты переводов',
          sourceLanguageRow: 'SOURCE LANGUAGE',
          sourceTextRow: 'SOURCE TEXT',
          verdictRow: 'Вердикт',
          commentRow: 'Аудит и диагностика',
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
      ),
      RegistryStudioUiLanguage.en => const RegistryStudioUiLabels(
        appTitle: 'Registry Studio',
        languageLabel: 'Language',
        translatorScreenTitle: 'Adaptive translator',
        operationCreationScreenTitle: 'Create engineering operation',
        translatorPhrase: RegistryStudioTranslatorPhraseLabels(
          title: 'Adaptive translator',
          sourceTextLabel: 'Canonical wording',
          translateButton: 'Translate',
          clearButton: 'Clear',
          copyAllButton: 'Copy all',
          copyAllSuccessMessage: 'All variants copied',
          resultsTitle: 'Translation results',
          sourceLanguageRow: 'SOURCE LANGUAGE',
          sourceTextRow: 'SOURCE TEXT',
          verdictRow: 'Verdict',
          commentRow: 'Audit and diagnostics',
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
      ),
      RegistryStudioUiLanguage.th => const RegistryStudioUiLabels(
        appTitle: 'Registry Studio',
        languageLabel: 'ภาษา',
        translatorScreenTitle: 'ตัวแปลแบบปรับตามบริบท',
        operationCreationScreenTitle: 'สร้างงานวิศวกรรม',
        translatorPhrase: RegistryStudioTranslatorPhraseLabels(
          title: 'ตัวแปลแบบปรับตามบริบท',
          sourceTextLabel: 'ถ้อยคำมาตรฐาน',
          translateButton: 'แปล',
          clearButton: 'ล้าง',
          copyAllButton: 'คัดลอกทั้งหมด',
          copyAllSuccessMessage: 'คัดลอกผลลัพธ์ทั้งหมดแล้ว',
          resultsTitle: 'ผลการแปล',
          sourceLanguageRow: 'SOURCE LANGUAGE',
          sourceTextRow: 'SOURCE TEXT',
          verdictRow: 'ผลการตัดสิน',
          commentRow: 'การตรวจสอบและการวินิจฉัย',
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
}

final class RegistryStudioTranslatorPhraseLabels {
  const RegistryStudioTranslatorPhraseLabels({
    required this.title,
    required this.sourceTextLabel,
    required this.translateButton,
    required this.clearButton,
    required this.copyAllButton,
    required this.copyAllSuccessMessage,
    required this.resultsTitle,
    required this.sourceLanguageRow,
    required this.sourceTextRow,
    required this.verdictRow,
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
  final String translateButton;
  final String clearButton;
  final String copyAllButton;
  final String copyAllSuccessMessage;
  final String resultsTitle;
  final String sourceLanguageRow;
  final String sourceTextRow;
  final String verdictRow;
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
