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

  String get sourceLanguage =>
      _value(ru: 'Язык источника', en: 'Source language', th: 'ภาษาต้นฉบับ');

  String get detectAutomatically =>
      _value(ru: 'Автоматически', en: 'Automatic', th: 'อัตโนมัติ');

  String get automaticShort => 'AUTO';

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

  String get corruptDraftRemoved => _value(
    ru: 'Сохранённый черновик Translator был повреждён и безопасно удалён.',
    en: 'The saved Translator draft was corrupt and was safely removed.',
    th: 'ฉบับร่าง Translator ที่บันทึกไว้เสียหายและถูกลบออกอย่างปลอดภัย',
  );

  String get directTranslationStage => _value(
    ru: 'Атомарный пакет перевода RU / EN / TH',
    en: 'Atomic RU / EN / TH translation bundle',
    th: 'ชุดการแปลแบบอะตอม RU / EN / TH',
  );

  String get reverseTranslationStage => _value(
    ru: 'Формирование обратных секций',
    en: 'Building reverse sections',
    th: 'กำลังสร้างส่วนการแปลย้อนกลับ',
  );

  String get auditStage => _value(
    ru: 'Попарный семантический аудит',
    en: 'Pairwise semantic audit',
    th: 'การตรวจสอบความหมายแบบรายคู่',
  );

  String get exactCertificationStage => _value(
    ru: 'Независимая проверка кандидата EXACT',
    en: 'Independent EXACT candidate check',
    th: 'การตรวจสอบผู้สมัคร EXACT แบบอิสระ',
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
        'Частичный результат перевода сохранён, '
        'но автоматический вердикт не создан.',
    en:
        'The partial translation result was saved, '
        'but no automatic verdict was created.',
    th:
        'บันทึกผลการแปลบางส่วนแล้ว '
        'แต่ยังไม่ได้สร้างคำตัดสินอัตโนมัติ',
  );

  String get directTranslation => _value(
    ru: 'SOURCE TEXT и прямые секции',
    en: 'SOURCE TEXT and direct sections',
    th: 'SOURCE TEXT และส่วนการแปลโดยตรง',
  );

  String get reverseCheck => _value(
    ru: 'Обратные секции перевода',
    en: 'Reverse translation sections',
    th: 'ส่วนการแปลย้อนกลับ',
  );

  String get automaticVerdict => _value(
    ru: 'Автоматический вердикт перевода',
    en: 'Automatic translation verdict',
    th: 'คำตัดสินการแปลอัตโนมัติ',
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

  String get canonicalStylePreserved => _value(
    ru: 'Канонический стиль сохранён',
    en: 'Canonical style preserved',
    th: 'คงรูปแบบมาตรฐานไว้',
  );

  String get ambiguousWording => _value(
    ru: 'Неоднозначная формулировка',
    en: 'Ambiguous wording',
    th: 'ถ้อยคำกำกวม',
  );

  String get verdictEngineerNotice => _value(
    ru:
        'Вердикт вычислен приложением из структурированных доказательств. '
        'Итоговое решение принимает инженер.',
    en:
        'The application derives the verdict from structured evidence. '
        'The engineer makes the final decision.',
    th:
        'แอปคำนวณคำตัดสินจากหลักฐานแบบมีโครงสร้าง '
        'วิศวกรเป็นผู้ตัดสินใจขั้นสุดท้าย',
  );

  String get auditAndDiagnostics => _value(
    ru: 'Аудит и диагностика',
    en: 'Audit and diagnostics',
    th: 'การตรวจสอบและการวินิจฉัย',
  );

  String get semanticPairAudit => _value(
    ru: 'Попарный семантический аудит',
    en: 'Pairwise semantic audit',
    th: 'การตรวจสอบความหมายแบบรายคู่',
  );

  String get exactCertification => _value(
    ru: 'Сертификация EXACT',
    en: 'EXACT certification',
    th: 'การรับรอง EXACT',
  );

  String get semanticProtocolFallback => _value(
    ru: 'Структурированное доказательство не получено. Требуется проверка.',
    en: 'Structured evidence was not obtained. Review is required.',
    th: 'ไม่ได้รับหลักฐานแบบมีโครงสร้าง จึงต้องตรวจสอบ',
  );

  String get exactVerdictExplanation => _value(
    ru:
        'Все три языковые пары получили CLEAR в общем аудите; независимый '
        'challenger также вернул CLEAR. Поэтому приложение выдало EXACT.',
    en:
        'All three language pairs were CLEAR in the general audit, and the '
        'independent challenger also returned CLEAR. The application therefore '
        'issued EXACT.',
    th: 'คู่ภาษาทั้งสามได้ผล CLEAR จากการตรวจสอบทั่วไป และ challenger อิสระก็ให้ผล CLEAR แอปจึงออกผล EXACT',
  );

  String get equivalentVerdictExplanation => _value(
    ru:
        'Практический смысл сохранён; обнаружено только отклонение '
        'канонического стиля.',
    en:
        'Practical meaning is preserved; only a canonical-style deviation '
        'was found.',
    th: 'ความหมายเชิงปฏิบัติยังคงเดิม พบเพียงความแตกต่างด้านรูปแบบมาตรฐาน',
  );

  String get needsReviewVerdictExplanation => _value(
    ru:
        'Точное практическое соответствие не доказано или независимая '
        'проверка нашла основание для сомнения.',
    en:
        'Exact practical identity was not proven, or the independent check '
        'found a reason for doubt.',
    th: 'ยังพิสูจน์ความตรงกันเชิงปฏิบัติไม่ได้ หรือการตรวจสอบอิสระพบเหตุให้สงสัย',
  );

  String get canonicalDriftVerdictExplanation => _value(
    ru:
        'Общий аудит подтвердил смысловое расхождение, способное изменить '
        'исполнение или приёмку задания.',
    en:
        'The general audit confirmed a semantic mismatch that may change '
        'task execution or acceptance.',
    th: 'การตรวจสอบทั่วไปยืนยันความคลาดเคลื่อนทางความหมายที่อาจเปลี่ยนการปฏิบัติงานหรือการยอมรับงาน',
  );

  String get auditChallengerConflict => _value(
    ru:
        'Общий аудит дал три CLEAR, но независимый challenger не подтвердил '
        'EXACT. Итог безопасно понижен до NEEDS REVIEW.',
    en:
        'The general audit returned three CLEAR results, but the independent '
        'challenger did not certify EXACT. The result was safely downgraded '
        'to NEEDS REVIEW.',
    th: 'การตรวจสอบทั่วไปให้ผล CLEAR ทั้งสามคู่ แต่ challenger อิสระไม่รับรอง EXACT จึงลดผลเป็น NEEDS REVIEW อย่างปลอดภัย',
  );

  String get exactChallengeProtocolFallback => _value(
    ru:
        'Независимый challenger дважды нарушил протокол. EXACT запрещён; '
        'требуется ручная проверка.',
    en:
        'The independent challenger violated the protocol twice. EXACT is '
        'forbidden; manual review is required.',
    th: 'challenger อิสระละเมิดโปรโตคอลสองครั้ง จึงห้าม EXACT และต้องตรวจสอบด้วยตนเอง',
  );

  String get independentExactChallenge => _value(
    ru: 'Независимый challenger EXACT',
    en: 'Independent EXACT challenger',
    th: 'challenger EXACT อิสระ',
  );

  String get modelEvidenceReason => _value(
    ru: 'Краткое обоснование модели',
    en: 'Model evidence reason',
    th: 'เหตุผลหลักฐานจากโมเดล',
  );

  String get evidenceExplanation =>
      _value(ru: 'Пояснение', en: 'Explanation', th: 'คำอธิบาย');

  String semanticAtomLabel(String code) {
    return switch (code) {
      'action' => _value(ru: 'Действие', en: 'Action', th: 'การกระทำ'),
      'object' => _value(ru: 'Объект', en: 'Object', th: 'วัตถุ'),
      'equipment_identity' => _value(
        ru: 'Идентичность оборудования',
        en: 'Equipment identity',
        th: 'เอกลักษณ์ของอุปกรณ์',
      ),
      'actor' => _value(ru: 'Исполнитель', en: 'Actor', th: 'ผู้ดำเนินการ'),
      'role_specificity' => _value(
        ru: 'Точность роли',
        en: 'Role specificity',
        th: 'ความเฉพาะเจาะจงของบทบาท',
      ),
      'polarity' => _value(
        ru: 'Полярность',
        en: 'Polarity',
        th: 'ขั้วความหมาย',
      ),
      'modality' => _value(ru: 'Модальность', en: 'Modality', th: 'มาลา'),
      'permission' => _value(
        ru: 'Разрешение',
        en: 'Permission',
        th: 'การอนุญาต',
      ),
      'obligation' => _value(
        ru: 'Обязательность',
        en: 'Obligation',
        th: 'ข้อผูกพัน',
      ),
      'quantity' => _value(ru: 'Количество', en: 'Quantity', th: 'ปริมาณ'),
      'time' => _value(ru: 'Время', en: 'Time', th: 'เวลา'),
      'condition' => _value(ru: 'Условие', en: 'Condition', th: 'เงื่อนไข'),
      'sequence' => _value(
        ru: 'Последовательность',
        en: 'Sequence',
        th: 'ลำดับ',
      ),
      'scope' => _value(ru: 'Область действия', en: 'Scope', th: 'ขอบเขต'),
      'ambiguity' => _value(
        ru: 'Неоднозначность',
        en: 'Ambiguity',
        th: 'ความกำกวม',
      ),
      'canonical_style' => _value(
        ru: 'Канонический стиль',
        en: 'Canonical style',
        th: 'รูปแบบมาตรฐาน',
      ),
      _ => code,
    };
  }

  String semanticIssueExplanation({
    required String atomCode,
    required String statusCode,
  }) {
    if (atomCode == 'canonical_style' && statusCode == 'X') {
      return _value(
        ru:
            'Практический смысл сохранён, но формулировка не соответствует '
            'каноническому стилю.',
        en:
            'Practical meaning is preserved, but the wording is not in the '
            'canonical style.',
        th: 'ความหมายเชิงปฏิบัติยังคงเดิม แต่ถ้อยคำไม่เป็นไปตามรูปแบบมาตรฐาน',
      );
    }

    if (atomCode == 'ambiguity') {
      return _value(
        ru: 'Формулировка допускает неоднозначное практическое толкование.',
        en: 'The wording permits more than one practical interpretation.',
        th: 'ถ้อยคำอาจตีความในทางปฏิบัติได้มากกว่าหนึ่งแบบ',
      );
    }

    return switch (statusCode) {
      'X' => _value(
        ru: 'Подтверждено практическое расхождение между языковыми версиями.',
        en: 'A practical mismatch between the language versions is confirmed.',
        th: 'ยืนยันความแตกต่างเชิงปฏิบัติระหว่างฉบับภาษา',
      ),
      'U' => _value(
        ru: 'Точное практическое соответствие не доказано.',
        en: 'Exact practical identity has not been proven.',
        th: 'ยังพิสูจน์ความตรงกันเชิงปฏิบัติอย่างแน่นอนไม่ได้',
      ),
      _ => statusCode,
    };
  }

  String semanticIssueImpact({
    required String atomCode,
    required String statusCode,
  }) {
    if (atomCode == 'canonical_style' && statusCode == 'X') {
      return _value(
        ru:
            'На исполнение задания не влияет; перед публикацией требуется '
            'нормализовать формулировку.',
        en:
            'Task execution is unchanged; normalize the wording before '
            'publication.',
        th: 'ไม่กระทบการปฏิบัติงาน แต่ควรปรับถ้อยคำให้เป็นมาตรฐานก่อนเผยแพร่',
      );
    }

    if (atomCode == 'ambiguity') {
      return _value(
        ru:
            'Разные участники могут понять задание по-разному; требуется '
            'ручная проверка контекста.',
        en:
            'Participants may understand the task differently; manual context '
            'review is required.',
        th: 'ผู้เกี่ยวข้องอาจเข้าใจงานต่างกัน จึงต้องตรวจสอบบริบทด้วยตนเอง',
      );
    }

    return switch (statusCode) {
      'X' => _value(
        ru:
            'Расхождение может привести к различному исполнению или приёмке '
            'задания.',
        en: 'The mismatch may cause different task execution or acceptance.',
        th: 'ความแตกต่างอาจทำให้การปฏิบัติงานหรือการยอมรับผลงานไม่ตรงกัน',
      ),
      'U' => _value(
        ru: 'До ручной проверки пакет нельзя безопасно считать идентичным.',
        en:
            'The bundle cannot be safely treated as identical before manual '
            'review.',
        th: 'ยังไม่ควรถือว่าชุดข้อความตรงกันจนกว่าจะตรวจสอบด้วยตนเอง',
      ),
      _ => statusCode,
    };
  }

  String get meaning => _value(ru: 'Смысл', en: 'Meaning', th: 'ความหมาย');

  String get terminology =>
      _value(ru: 'Терминология', en: 'Terminology', th: 'คำศัพท์');

  String get canonicalStyle => _value(
    ru: 'Канонический стиль',
    en: 'Canonical style',
    th: 'รูปแบบมาตรฐาน',
  );

  String get ambiguity =>
      _value(ru: 'Неоднозначность', en: 'Ambiguity', th: 'ความกำกวม');

  String get noViolations => _value(
    ru: 'Нарушений не обнаружено.',
    en: 'No issues found.',
    th: 'ไม่พบปัญหา',
  );

  String get evidenceSection => _value(
    ru: 'Затронутая секция',
    en: 'Affected section',
    th: 'ส่วนที่ได้รับผลกระทบ',
  );

  String get evidenceSourceFragment => _value(
    ru: 'Фрагмент SOURCE TEXT',
    en: 'SOURCE TEXT fragment',
    th: 'ส่วนของ SOURCE TEXT',
  );

  String get evidenceTranslationFragment => _value(
    ru: 'Фрагмент перевода',
    en: 'Translation fragment',
    th: 'ส่วนของคำแปล',
  );

  String get evidenceReason => _value(
    ru: 'Обнаруженное различие',
    en: 'Detected difference',
    th: 'ความแตกต่างที่ตรวจพบ',
  );

  String get evidenceImpact =>
      _value(ru: 'Влияние', en: 'Impact', th: 'ผลกระทบ');

  String get evidenceCorrectVariant => _value(
    ru: 'Корректный вариант',
    en: 'Correct variant',
    th: 'รูปแบบที่ถูกต้อง',
  );

  String get evidenceSourceAmbiguity => _value(
    ru: 'Неоднозначность SOURCE TEXT',
    en: 'SOURCE TEXT ambiguity',
    th: 'ความกำกวมของ SOURCE TEXT',
  );

  String get noSourceAmbiguity =>
      _value(ru: 'Не обнаружена', en: 'None detected', th: 'ไม่พบ');

  String get legacyEvidence => _value(
    ru: 'Устаревшее доказательство',
    en: 'Legacy evidence',
    th: 'หลักฐานเดิม',
  );

  String get legacyEvidenceNotice => _value(
    ru:
        'Это доказательство восстановлено из старого черновика. '
        'Структурированные поля для него недоступны.',
    en:
        'This evidence was restored from an older draft. '
        'Structured fields are unavailable for it.',
    th:
        'หลักฐานนี้กู้คืนมาจากฉบับร่างรุ่นเก่า '
        'จึงไม่มีฟิลด์แบบมีโครงสร้าง',
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

  String get errorCode =>
      _value(ru: 'Код ошибки', en: 'Error code', th: 'รหัสข้อผิดพลาด');

  String get sourceTextRequired => _value(
    ru: 'Введите исходный текст.',
    en: 'Enter the source text.',
    th: 'ป้อนข้อความต้นฉบับ',
  );

  String get accessKeyRequired => _value(
    ru: 'Введите Typhoon API key.',
    en: 'Enter the Typhoon API key.',
    th: 'ป้อนคีย์ API ของ Typhoon',
  );

  String get accessKeyInvalid => _value(
    ru: 'Typhoon API key содержит недопустимые символы.',
    en: 'The Typhoon API key contains invalid characters.',
    th: 'คีย์ API ของ Typhoon มีอักขระที่ไม่ถูกต้อง',
  );

  String get translationResponseInvalid => _value(
    ru: 'Typhoon вернул неполный или некорректный пакет перевода.',
    en: 'Typhoon returned an incomplete or invalid translation bundle.',
    th: 'Typhoon ส่งชุดการแปลที่ไม่สมบูรณ์หรือไม่ถูกต้อง',
  );

  String get sourceLanguageInvalid => _value(
    ru: 'Typhoon вернул некорректный язык источника.',
    en: 'Typhoon returned an invalid source language.',
    th: 'Typhoon ส่งภาษาต้นฉบับที่ไม่ถูกต้อง',
  );

  String get sourceTextChanged => _value(
    ru: 'Typhoon изменил SOURCE TEXT. Результат отклонён.',
    en: 'Typhoon changed SOURCE TEXT. The result was rejected.',
    th: 'Typhoon เปลี่ยน SOURCE TEXT ระบบจึงปฏิเสธผลลัพธ์',
  );

  String get auditResponseInvalid => _value(
    ru: 'Typhoon вернул некорректное структурированное доказательство аудита.',
    en: 'Typhoon returned invalid structured audit evidence.',
    th: 'Typhoon ส่งหลักฐานการตรวจสอบแบบมีโครงสร้างที่ไม่ถูกต้อง',
  );

  String get unauthorizedFailure => _value(
    ru: 'Typhoon отклонил API key. Проверьте сохранённый ключ.',
    en: 'Typhoon rejected the API key. Check the saved key.',
    th: 'Typhoon ปฏิเสธคีย์ API โปรดตรวจสอบคีย์ที่บันทึกไว้',
  );

  String get rateLimitedFailure => _value(
    ru: 'Typhoon временно ограничил частоту запросов. Повторите позже.',
    en: 'Typhoon temporarily rate-limited requests. Retry later.',
    th: 'Typhoon จำกัดอัตราคำขอชั่วคราว โปรดลองอีกครั้งภายหลัง',
  );

  String get serverFailure => _value(
    ru: 'Сервис Typhoon временно недоступен.',
    en: 'The Typhoon service is temporarily unavailable.',
    th: 'บริการ Typhoon ไม่พร้อมใช้งานชั่วคราว',
  );

  String get networkFailure => _value(
    ru: 'Не удалось связаться с Typhoon. Проверьте сеть.',
    en: 'Typhoon could not be reached. Check the network.',
    th: 'ไม่สามารถเชื่อมต่อ Typhoon ได้ โปรดตรวจสอบเครือข่าย',
  );

  String get timeoutFailure => _value(
    ru: 'Typhoon не ответил вовремя. Повторите запрос.',
    en: 'Typhoon did not respond in time. Retry the request.',
    th: 'Typhoon ไม่ตอบกลับภายในเวลาที่กำหนด โปรดลองคำขออีกครั้ง',
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

  String get reverseStage => _value(
    ru: 'обратный перевод',
    en: 'reverse translation',
    th: 'การแปลย้อนกลับ',
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
