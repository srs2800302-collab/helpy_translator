import 'registry_studio_ui_language.dart';

final class RegistryStudioUiLabels {
  const RegistryStudioUiLabels({
    required this.appTitle,
    required this.languageLabel,
    required this.translatorScreenTitle,
    required this.operationCreationScreenTitle,
    required this.translatorPhrase,
    required this.operationCreation,
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
          sourceTextLabel: 'Формулировка или текст',
          sourceLanguageHintLabel: 'Подсказка языка',
          sourceLanguageHintHelper: 'Например: ru, en, th',
          engineerContextLabel: 'Контекст инженера',
          translateButton: 'Перевести',
          clearButton: 'Очистить',
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
        ),
      ),
      RegistryStudioUiLanguage.en => const RegistryStudioUiLabels(
        appTitle: 'Registry Studio',
        languageLabel: 'Language',
        translatorScreenTitle: 'Phrase translation',
        operationCreationScreenTitle: 'Create engineering operation',
        translatorPhrase: RegistryStudioTranslatorPhraseLabels(
          title: 'Phrase translation',
          sourceTextLabel: 'Phrase or text',
          sourceLanguageHintLabel: 'Language hint',
          sourceLanguageHintHelper: 'Example: ru, en, th',
          engineerContextLabel: 'Engineer context',
          translateButton: 'Translate',
          clearButton: 'Clear',
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
        ),
      ),
      RegistryStudioUiLanguage.th => const RegistryStudioUiLabels(
        appTitle: 'Registry Studio',
        languageLabel: 'ภาษา',
        translatorScreenTitle: 'แปลถ้อยคำ',
        operationCreationScreenTitle: 'สร้างงานวิศวกรรม',
        translatorPhrase: RegistryStudioTranslatorPhraseLabels(
          title: 'แปลถ้อยคำ',
          sourceTextLabel: 'ถ้อยคำหรือข้อความ',
          sourceLanguageHintLabel: 'คำใบ้ภาษา',
          sourceLanguageHintHelper: 'เช่น: ru, en, th',
          engineerContextLabel: 'บริบทของวิศวกร',
          translateButton: 'แปล',
          clearButton: 'ล้าง',
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
  });

  final String title;
  final String operationIdLabel;
  final String problemStatementLabel;
  final String createButton;
  final String createdTitle;
  final String statusLabel;
  final String operationIdRequiredError;
  final String problemStatementRequiredError;
}
