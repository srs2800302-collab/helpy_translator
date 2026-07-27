import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final class RegistryStudioLocalizations {
  const RegistryStudioLocalizations(this.locale);

  static const Locale russian = Locale('ru');
  static const Locale english = Locale('en');
  static const Locale thai = Locale('th');

  static const List<Locale> supportedLocales = <Locale>[russian, english, thai];

  static const LocalizationsDelegate<RegistryStudioLocalizations> delegate =
      _RegistryStudioLocalizationsDelegate();

  final Locale locale;

  static RegistryStudioLocalizations of(BuildContext context) {
    return Localizations.of<RegistryStudioLocalizations>(
          context,
          RegistryStudioLocalizations,
        ) ??
        const RegistryStudioLocalizations(russian);
  }

  String get languageCode => locale.languageCode;

  String _value({required String ru, required String en, required String th}) {
    return switch (languageCode) {
      'en' => en,
      'th' => th,
      _ => ru,
    };
  }

  String get registryStudio => 'Registry Studio';
  String get translator => 'Translator';

  String get changeInterfaceLanguage => _value(
    ru: 'Сменить язык интерфейса',
    en: 'Change interface language',
    th: 'เปลี่ยนภาษาของอินเทอร์เฟซ',
  );

  String get interfaceLanguage => _value(
    ru: 'Язык интерфейса',
    en: 'Interface language',
    th: 'ภาษาของอินเทอร์เฟซ',
  );

  String get russianLanguage => 'Русский';
  String get englishLanguage => 'English';
  String get thaiLanguage => 'ไทย';

  String get apiKeySettings => _value(
    ru: 'Настройки Typhoon API key',
    en: 'Typhoon API key settings',
    th: 'การตั้งค่าคีย์ API ของ Typhoon',
  );

  String get apiKey => 'Typhoon API key';

  String get apiKeyEncryptedOnDevice => _value(
    ru: 'Ключ зашифрованно хранится только на этом устройстве.',
    en: 'The key is stored encrypted on this device only.',
    th: 'คีย์ถูกจัดเก็บแบบเข้ารหัสไว้ในอุปกรณ์นี้เท่านั้น',
  );

  String get restoringSavedKey => _value(
    ru: 'Восстановление сохранённого ключа...',
    en: 'Restoring the saved key...',
    th: 'กำลังกู้คืนคีย์ที่บันทึกไว้...',
  );

  String get showKey =>
      _value(ru: 'Показать ключ', en: 'Show key', th: 'แสดงคีย์');

  String get hideKey =>
      _value(ru: 'Скрыть ключ', en: 'Hide key', th: 'ซ่อนคีย์');

  String get save => _value(ru: 'Сохранить', en: 'Save', th: 'บันทึก');

  String get close => _value(ru: 'Закрыть', en: 'Close', th: 'ปิด');

  String get deleteSavedKey => _value(
    ru: 'Удалить сохранённый ключ',
    en: 'Delete saved key',
    th: 'ลบคีย์ที่บันทึกไว้',
  );

  String get apiKeyRestoreFailure => _value(
    ru:
        'Не удалось восстановить сохранённый API key. '
        'Ключ не был удалён автоматически.',
    en:
        'The saved API key could not be restored. '
        'The key was not deleted automatically.',
    th:
        'ไม่สามารถกู้คืนคีย์ API ที่บันทึกไว้ได้ '
        'ระบบไม่ได้ลบคีย์โดยอัตโนมัติ',
  );

  String get apiKeySaveFailure => _value(
    ru: 'Не удалось сохранить API key в защищённом хранилище.',
    en: 'The API key could not be saved to secure storage.',
    th: 'ไม่สามารถบันทึกคีย์ API ลงในพื้นที่จัดเก็บที่ปลอดภัยได้',
  );

  String get apiKeyDeleteFailure => _value(
    ru: 'Не удалось удалить API key из защищённого хранилища.',
    en: 'The API key could not be deleted from secure storage.',
    th: 'ไม่สามารถลบคีย์ API ออกจากพื้นที่จัดเก็บที่ปลอดภัยได้',
  );

  String get sourceText =>
      _value(ru: 'Исходный текст', en: 'Source text', th: 'ข้อความต้นฉบับ');

  String get sourceTextFieldLabel => _value(
    ru: 'Текст для перевода и семантического аудита',
    en: 'Text for translation and semantic audit',
    th: 'ข้อความสำหรับการแปลและการตรวจสอบเชิงความหมาย',
  );

  String get translateAndCheck => _value(
    ru: 'Перевести и проверить',
    en: 'Translate and check',
    th: 'แปลและตรวจสอบ',
  );

  String get retry => _value(ru: 'Повторить', en: 'Retry', th: 'ลองอีกครั้ง');

  String get cancel => _value(ru: 'Отменить', en: 'Cancel', th: 'ยกเลิก');

  String get clearTranslator => _value(
    ru: 'Очистить Translator',
    en: 'Clear Translator',
    th: 'ล้าง Translator',
  );

  String get restoreWarning => _value(
    ru: 'Предупреждение восстановления',
    en: 'Restore warning',
    th: 'คำเตือนการกู้คืน',
  );

  String get directTranslationStage => _value(
    ru: 'Прямой и обратный перевод RU / EN / TH',
    en: 'Direct and reverse RU / EN / TH translation',
    th: 'การแปลโดยตรงและการแปลย้อนกลับ RU / EN / TH',
  );

  String get auditStage => _value(
    ru: 'Семантический аудит и вердикт',
    en: 'Semantic audit and verdict',
    th: 'การตรวจสอบเชิงความหมายและคำตัดสิน',
  );

  String get preparingTranslation => _value(
    ru: 'Подготовка перевода',
    en: 'Preparing translation',
    th: 'กำลังเตรียมการแปล',
  );

  String stageLabel(String stage) =>
      _value(ru: 'Этап: $stage', en: 'Stage: $stage', th: 'ขั้นตอน: $stage');

  String get partialResultSaved => _value(
    ru:
        'Перевод RU / EN / TH сохранён, '
        'но семантический вердикт не создан.',
    en:
        'The RU / EN / TH translation was saved, '
        'but no semantic verdict was created.',
    th:
        'บันทึกคำแปล RU / EN / TH แล้ว '
        'แต่ยังไม่ได้สร้างคำตัดสินเชิงความหมาย',
  );

  String get directTranslation =>
      _value(ru: 'Прямой перевод', en: 'Direct translation', th: 'คำแปลโดยตรง');

  String get reverseTranslationsForDiagnostics => _value(
    ru: 'Обратные переводы для диагностики',
    en: 'Reverse translations for diagnostics',
    th: 'การแปลย้อนกลับเพื่อการวินิจฉัย',
  );

  String get automaticVerdict => _value(
    ru: 'Семантический вердикт',
    en: 'Semantic verdict',
    th: 'คำตัดสินเชิงความหมาย',
  );

  String get retrySemanticAudit => _value(
    ru: 'Повторить только семантический аудит',
    en: 'Retry semantic audit only',
    th: 'ลองตรวจสอบเชิงความหมายอีกครั้งเท่านั้น',
  );

  String get semanticAuditIncomplete => _value(
    ru: 'Семантический аудит не завершён',
    en: 'Semantic audit is incomplete',
    th: 'การตรวจสอบเชิงความหมายยังไม่เสร็จสมบูรณ์',
  );

  String get canonicalDictionary => _value(
    ru: 'Канонический словарь',
    en: 'Canonical dictionary',
    th: 'พจนานุกรมมาตรฐาน',
  );

  String get notConnected =>
      _value(ru: 'НЕ ПОДКЛЮЧЁН', en: 'NOT CONNECTED', th: 'ยังไม่ได้เชื่อมต่อ');

  String get canonicalVerdictUnavailable => _value(
    ru: 'Канонический вердикт недоступен',
    en: 'Canonical verdict is unavailable',
    th: 'ยังไม่มีคำตัดสินตามพจนานุกรมมาตรฐาน',
  );

  String get meaningPreserved => _value(
    ru: 'Смысл сохранён',
    en: 'Meaning preserved',
    th: 'คงความหมายไว้',
  );

  String get terminologyPreserved => _value(
    ru: 'Терминология сохранена',
    en: 'Terminology preserved',
    th: 'คงคำศัพท์ไว้',
  );

  String get stylePreserved =>
      _value(ru: 'Стиль сохранён', en: 'Style preserved', th: 'คงรูปแบบไว้');

  String get ambiguousWording => _value(
    ru: 'Неоднозначная формулировка',
    en: 'Ambiguous wording',
    th: 'ถ้อยคำกำกวม',
  );

  String get verdictEngineerNotice => _value(
    ru:
        'Вердикт сформирован по семантическим findings без сравнения '
        'со словарём проекта. Итоговое решение принимает инженер.',
    en:
        'The verdict is generated from semantic findings without comparison '
        'with the project dictionary. The engineer makes the final decision.',
    th:
        'คำตัดสินสร้างจากข้อค้นพบเชิงความหมายโดยยังไม่ได้เปรียบเทียบ '
        'กับพจนานุกรมของโครงการ วิศวกรเป็นผู้ตัดสินใจขั้นสุดท้าย',
  );

  String get auditAndDiagnostics => _value(
    ru: 'Аудит и диагностика',
    en: 'Audit and diagnostics',
    th: 'การตรวจสอบและการวินิจฉัย',
  );

  String get meaning => _value(ru: 'Смысл', en: 'Meaning', th: 'ความหมาย');

  String get terminology =>
      _value(ru: 'Терминология', en: 'Terminology', th: 'คำศัพท์');

  String get style => _value(ru: 'Стиль', en: 'Style', th: 'รูปแบบ');

  String get ambiguity =>
      _value(ru: 'Неоднозначность', en: 'Ambiguity', th: 'ความกำกวม');

  String get noViolations => _value(
    ru: 'Нарушений не обнаружено.',
    en: 'No issues found.',
    th: 'ไม่พบปัญหา',
  );

  String get incompleteTranslation => _value(
    ru: 'Перевод неполный',
    en: 'Translation incomplete',
    th: 'คำแปลไม่สมบูรณ์',
  );

  String get translationCancelled => _value(
    ru: 'Перевод отменён',
    en: 'Translation cancelled',
    th: 'ยกเลิกการแปลแล้ว',
  );

  String get checkInput => _value(
    ru: 'Проверьте ввод',
    en: 'Check the input',
    th: 'ตรวจสอบข้อมูลที่ป้อน',
  );

  String get translatorTechnicalError => _value(
    ru: 'Техническая ошибка Translator',
    en: 'Translator technical error',
    th: 'ข้อผิดพลาดทางเทคนิคของ Translator',
  );

  String get validationStage => _value(
    ru: 'проверка ввода',
    en: 'input validation',
    th: 'การตรวจสอบข้อมูลที่ป้อน',
  );

  String get directStage => _value(
    ru: 'прямой перевод',
    en: 'direct translation',
    th: 'การแปลโดยตรง',
  );

  String get semanticAuditStage => _value(
    ru: 'семантический аудит',
    en: 'semantic audit',
    th: 'การตรวจสอบเชิงความหมาย',
  );

  String get typhoonApiStage => 'Typhoon API';

  String get yes => _value(ru: 'ДА', en: 'YES', th: 'ใช่');
  String get no => _value(ru: 'НЕТ', en: 'NO', th: 'ไม่');

  String get translatorPlaceholderDescription => _value(
    ru: 'Перевод и проверка формулировок RU / EN / TH',
    en: 'Translate and validate RU / EN / TH wording',
    th: 'แปลและตรวจสอบถ้อยคำ RU / EN / TH',
  );
}

extension RegistryStudioLocalizationsBuildContext on BuildContext {
  RegistryStudioLocalizations get rsL10n =>
      RegistryStudioLocalizations.of(this);
}

final class _RegistryStudioLocalizationsDelegate
    extends LocalizationsDelegate<RegistryStudioLocalizations> {
  const _RegistryStudioLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return RegistryStudioLocalizations.supportedLocales.any(
      (Locale supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<RegistryStudioLocalizations> load(Locale locale) {
    final Locale normalized = RegistryStudioLocalizations.supportedLocales
        .firstWhere(
          (Locale supported) => supported.languageCode == locale.languageCode,
          orElse: () => RegistryStudioLocalizations.russian,
        );

    return SynchronousFuture<RegistryStudioLocalizations>(
      RegistryStudioLocalizations(normalized),
    );
  }

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<RegistryStudioLocalizations> old,
  ) {
    return false;
  }
}
