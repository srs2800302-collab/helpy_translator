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
    ru: 'Ключ хранится в зашифрованном хранилище этого устройства.',
    en: 'The key is stored in encrypted storage on this device.',
    th: 'คีย์ถูกเก็บไว้ในพื้นที่จัดเก็บที่เข้ารหัสของอุปกรณ์นี้',
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

  String get apiKeyRequired => _value(
    ru: 'Введите API key.',
    en: 'Enter an API key.',
    th: 'กรุณาป้อนคีย์ API',
  );

  String get apiKeySaved => _value(
    ru: 'API key сохранён.',
    en: 'API key saved.',
    th: 'บันทึกคีย์ API แล้ว',
  );

  String get apiKeyDeleted => _value(
    ru: 'Сохранённый API key удалён.',
    en: 'Saved API key deleted.',
    th: 'ลบคีย์ API ที่บันทึกไว้แล้ว',
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

  String get sourceTextFieldLabel => _value(
    ru: 'Текст для перевода и проверки',
    en: 'Text to translate and check',
    th: 'ข้อความสำหรับแปลและตรวจสอบ',
  );

  String get translateAndCheck => _value(
    ru: 'Перевести и проверить',
    en: 'Translate and check',
    th: 'แปลและตรวจสอบ',
  );

  String get cancel => _value(ru: 'Отменить', en: 'Cancel', th: 'ยกเลิก');

  String get clearTranslator => _value(
    ru: 'Очистить Translator',
    en: 'Clear Translator',
    th: 'ล้าง Translator',
  );

  String get preparingTranslation => _value(
    ru: 'Подготовка перевода',
    en: 'Preparing translation',
    th: 'กำลังเตรียมการแปล',
  );

  String translatingRoute(String routeId) => _value(
    ru: 'Перевод: $routeId',
    en: 'Translating: $routeId',
    th: 'กำลังแปล: $routeId',
  );

  String get auditingMatrix => _value(
    ru: 'Проверка расхождений матрицы',
    en: 'Auditing matrix differences',
    th: 'กำลังตรวจสอบความแตกต่างของเมทริกซ์',
  );

  String progressCount(int completed, int total) => _value(
    ru: '$completed из $total',
    en: '$completed of $total',
    th: '$completed จาก $total',
  );

  String get results => _value(ru: 'Результаты', en: 'Results', th: 'ผลลัพธ์');

  String get primaryTranslation => _value(
    ru: 'Основной перевод',
    en: 'Primary translation',
    th: 'คำแปลหลัก',
  );

  String get crossCheckTranslation => _value(
    ru: 'Проверочный перевод',
    en: 'Cross-check translation',
    th: 'คำแปลตรวจสอบไขว้',
  );

  String get finalMatrixAssessment => _value(
    ru: 'Итоговая оценка матрицы',
    en: 'Final matrix assessment',
    th: 'การประเมินเมทริกซ์ขั้นสุดท้าย',
  );

  String auditCoverageLabel(String coverageName, int routeCount) {
    return switch (coverageName) {
      'base' => _value(
        ru: 'Базовая проверка — $routeCount маршрута',
        en: 'Base audit — $routeCount routes',
        th: 'การตรวจสอบพื้นฐาน — $routeCount เส้นทาง',
      ),
      'prototype' => _value(
        ru: 'Прототипная проверка — $routeCount маршрутов',
        en: 'Prototype audit — $routeCount routes',
        th: 'การตรวจสอบแบบต้นแบบ — $routeCount เส้นทาง',
      ),
      'blindConsensus' => _value(
        ru: 'Слепая согласованная проверка — $routeCount маршрутов',
        en: 'Blind consensus audit — $routeCount routes',
        th: 'การตรวจสอบแบบแยกข้อมูล — $routeCount เส้นทาง',
      ),
      _ => _value(
        ru: 'Маршрутная проверка — $routeCount маршрутов',
        en: 'Route-isolated audit — $routeCount routes',
        th: 'การตรวจสอบแยกตามเส้นทาง — $routeCount เส้นทาง',
      ),
    };
  }

  String get copyAll =>
      _value(ru: 'Копировать всё', en: 'Copy all', th: 'คัดลอกทั้งหมด');

  String get copied => _value(
    ru: 'Результат скопирован.',
    en: 'Result copied.',
    th: 'คัดลอกผลลัพธ์แล้ว',
  );

  String get issues =>
      _value(ru: 'Расхождения', en: 'Differences', th: 'ความแตกต่าง');

  String get limitations => _value(
    ru: 'Ограничения проверки',
    en: 'Audit limitations',
    th: 'ข้อจำกัดของการตรวจสอบ',
  );

  String get sourceExcerpt => _value(
    ru: 'Фрагмент источника',
    en: 'Source excerpt',
    th: 'ข้อความจากต้นฉบับ',
  );

  String get targetExcerpt => _value(
    ru: 'Фрагмент перевода',
    en: 'Translation excerpt',
    th: 'ข้อความจากคำแปล',
  );

  String get noConcreteIssues => _value(
    ru: 'Конкретные расхождения этим аудитом не обнаружены.',
    en: 'This audit found no concrete differences.',
    th: 'การตรวจสอบนี้ไม่พบความแตกต่างที่เป็นรูปธรรม',
  );

  String get noProofNote => _value(
    ru: 'Это не является доказательством абсолютной эквивалентности.',
    en: 'This is not proof of absolute equivalence.',
    th: 'นี่ไม่ใช่หลักฐานของความเทียบเท่าที่สมบูรณ์',
  );

  String get auditPassDisclosure => _value(
    ru:
        'Запуск выполняет шесть отдельных переводов и две изолированные '
        'проверки готовой матрицы: максимум восемь API-вызовов. '
        'Автоматические повторы запросов не выполняются. Обе проверки '
        'используют одну модель одного API-провайдера и не являются '
        'независимой экспертизой. Ошибка одного прохода не удаляет выводы '
        'другого.',
    en:
        'A run performs six separate translations and two isolated audits of '
        'the completed matrix: at most eight API calls. Requests are never '
        'retried automatically. Both audits use the same model from one API '
        'provider and are not an independent review. A failure in one pass '
        'does not erase the other pass findings.',
    th:
        'การทำงานหนึ่งครั้งประกอบด้วยการแปลแยกกันหกครั้งและการตรวจสอบเมทริกซ์'
        'ที่เสร็จแล้วแบบแยกกันสองรอบ รวมสูงสุดแปดคำขอ API '
        'ระบบจะไม่ลองคำขอซ้ำโดยอัตโนมัติ การตรวจสอบทั้งสองใช้โมเดลเดียวกันจาก'
        'ผู้ให้บริการ API รายเดียวกัน จึงไม่ใช่การตรวจสอบอิสระ '
        'ความล้มเหลวของรอบหนึ่งจะไม่ลบผลของอีกรอบ',
  );

  String primaryObservationCount(int count) => _value(
    ru: 'Наблюдения в основных переводах: $count',
    en: 'Primary translation observations: $count',
    th: 'ข้อสังเกตในคำแปลหลัก: $count',
  );

  String crossCheckObservationCount(int count) => _value(
    ru: 'Наблюдения в проверочных маршрутах: $count',
    en: 'Cross-check observations: $count',
    th: 'ข้อสังเกตในเส้นทางตรวจสอบไขว้: $count',
  );

  String attentionObservationCount(int count) => _value(
    ru: 'Требуют внимания: $count',
    en: 'Requires attention: $count',
    th: 'ต้องตรวจสอบเพิ่มเติม: $count',
  );

  String preservedObservationCount(int count) => _value(
    ru: 'Автоматические проверки согласованы для маршрутов: $count',
    en: 'Automated checks agree for routes: $count',
    th: 'การตรวจสอบอัตโนมัติเห็นพ้องกันในเส้นทาง: $count',
  );

  String observationRelationLabel(String relationName) {
    return switch (relationName) {
      'addition' => _value(
        ru: 'Добавление',
        en: 'Addition',
        th: 'การเพิ่มข้อมูล',
      ),
      'omission' => _value(ru: 'Пропуск', en: 'Omission', th: 'การละข้อมูล'),
      'substitution' => _value(
        ru: 'Замена',
        en: 'Substitution',
        th: 'การแทนที่',
      ),
      'contradiction' => _value(
        ru: 'Противоречие',
        en: 'Contradiction',
        th: 'ความขัดแย้ง',
      ),
      'scopeChange' => _value(
        ru: 'Изменение охвата',
        en: 'Scope change',
        th: 'การเปลี่ยนขอบเขต',
      ),
      'ambiguityResolution' => _value(
        ru: 'Устранение неоднозначности',
        en: 'Ambiguity resolution',
        th: 'การเลือกความหมายจากความกำกวม',
      ),
      'wordingVariation' => _value(
        ru: 'Вариант формулировки',
        en: 'Wording variation',
        th: 'ความแตกต่างของถ้อยคำ',
      ),
      'registerChange' => _value(
        ru: 'Изменение регистра',
        en: 'Register change',
        th: 'การเปลี่ยนระดับภาษา',
      ),
      _ => _value(
        ru: 'Отношение не установлено',
        en: 'Relation not established',
        th: 'ยังไม่สามารถระบุความสัมพันธ์ได้',
      ),
    };
  }

  String observationDimensionLabel(String dimensionName) {
    return switch (dimensionName) {
      'proposition' => _value(
        ru: 'утверждение',
        en: 'proposition',
        th: 'สาระของข้อความ',
      ),
      'negation' => _value(ru: 'отрицание', en: 'negation', th: 'การปฏิเสธ'),
      'modality' => _value(
        ru: 'разрешение или обязательность',
        en: 'permission or obligation',
        th: 'สิทธิ์หรือข้อผูกมัด',
      ),
      'quantity' => _value(
        ru: 'число или количество',
        en: 'number or quantity',
        th: 'ตัวเลขหรือปริมาณ',
      ),
      'time' => _value(
        ru: 'время или срок',
        en: 'time or deadline',
        th: 'เวลาหรือกำหนดเวลา',
      ),
      'condition' => _value(ru: 'условие', en: 'condition', th: 'เงื่อนไข'),
      'actor' => _value(ru: 'участник действия', en: 'actor', th: 'ผู้กระทำ'),
      'object' => _value(ru: 'объект', en: 'object', th: 'วัตถุ'),
      'direction' => _value(
        ru: 'направление действия',
        en: 'direction',
        th: 'ทิศทางของการกระทำ',
      ),
      'cause' => _value(ru: 'причина', en: 'cause', th: 'สาเหตุ'),
      'restriction' => _value(
        ru: 'ограничение',
        en: 'restriction',
        th: 'ข้อจำกัด',
      ),
      'ambiguity' => _value(
        ru: 'неоднозначность',
        en: 'ambiguity',
        th: 'ความกำกวม',
      ),
      'terminology' => _value(
        ru: 'терминология',
        en: 'terminology',
        th: 'คำศัพท์เฉพาะ',
      ),
      'specificity' => _value(
        ru: 'степень конкретности',
        en: 'specificity',
        th: 'ระดับความเฉพาะเจาะจง',
      ),
      'register' => _value(ru: 'регистр речи', en: 'register', th: 'ระดับภาษา'),
      'style' => _value(ru: 'стиль', en: 'style', th: 'รูปแบบ'),
      'formality' => _value(
        ru: 'формальность',
        en: 'formality',
        th: 'ความเป็นทางการ',
      ),
      'lexicalChoice' => _value(
        ru: 'лексический выбор',
        en: 'lexical choice',
        th: 'การเลือกคำ',
      ),
      'other' => _value(
        ru: 'иная смысловая характеристика',
        en: 'other semantic dimension',
        th: 'มิติความหมายอื่น',
      ),
      _ => _value(
        ru: 'неустановленная характеристика',
        en: 'unknown semantic dimension',
        th: 'มิติความหมายที่ยังไม่ทราบ',
      ),
    };
  }

  String meaningPreservationLabel(String preservationName) {
    return switch (preservationName) {
      'preserved' => _value(
        ru: 'Проверки согласованы',
        en: 'Checks agree',
        th: 'ผลการตรวจสอบสอดคล้องกัน',
      ),
      'altered' => _value(
        ru: 'Смысл изменён',
        en: 'Meaning altered',
        th: 'ความหมายเปลี่ยนไป',
      ),
      _ => _value(
        ru: 'Сохранность смысла не установлена',
        en: 'Meaning preservation not established',
        th: 'ยังไม่สามารถยืนยันการคงความหมายได้',
      ),
    };
  }

  String observationEvidenceExplanation({
    required String preservationName,
    required String dimensionName,
    required String verificationStatusName,
    required bool isCrossCheck,
  }) {
    final String dimension = observationDimensionLabel(dimensionName);
    final String finding = switch (verificationStatusName) {
      'confirmed' => switch (preservationName) {
        'preserved' => _value(
          ru:
              'Два изолированных прохода согласованно подтвердили сохранение '
              'смысла по характеристике «$dimension». Это согласие одной '
              'модели, а не доказательство абсолютной эквивалентности.',
          en:
              'Two isolated passes consistently confirmed preserved meaning '
              'for $dimension. This is agreement by one model, not proof of '
              'absolute equivalence.',
          th:
              'การตรวจสอบแบบแยกกันสองรอบยืนยันตรงกันว่าความหมายในมิติ $dimension '
              'ยังคงเดิม นี่คือความสอดคล้องจากโมเดลเดียว ไม่ใช่หลักฐานของ'
              'ความเทียบเท่าอย่างสมบูรณ์',
        ),
        'altered' => _value(
          ru:
              'Два изолированных прохода согласованно подтвердили изменение '
              'смысла по характеристике «$dimension».',
          en:
              'Two isolated passes consistently confirmed a meaning change '
              'for $dimension.',
          th:
              'การตรวจสอบแบบแยกกันสองรอบยืนยันตรงกันว่าความหมายเปลี่ยนไปในมิติ '
              '$dimension',
        ),
        _ => _value(
          ru:
              'Даже при совпадении проходов сохранность смысла по '
              'характеристике «$dimension» не установлена.',
          en:
              'Even with matching passes, meaning preservation for $dimension '
              'was not established.',
          th:
              'แม้ผลทั้งสองรอบตรงกัน แต่ยังไม่สามารถยืนยันการคงความหมายในมิติ '
              '$dimension ได้',
        ),
      },
      'conflict' => _value(
        ru:
            'Два изолированных прохода дали разные выводы. Система не выбирает '
            'более благоприятный или более строгий результат.',
        en:
            'The two isolated passes disagreed. The system does not select the '
            'more favorable or harsher result.',
        th:
            'การตรวจสอบแบบแยกกันสองรอบให้ผลไม่ตรงกัน ระบบจะไม่เลือกผลที่เป็น'
            'ประโยชน์กว่าหรือเข้มงวดกว่า',
      ),
      _ => _value(
        ru:
            'Один из проходов не дал валидного подтверждения. Доступное '
            'заключение и точные фрагменты сохранены, но не повышены до '
            'подтверждённого результата.',
        en:
            'One pass did not provide valid confirmation. The available '
            'finding and exact excerpts were preserved but not upgraded to a '
            'confirmed result.',
        th:
            'การตรวจสอบหนึ่งรอบไม่สามารถให้การยืนยันที่ถูกต้องได้ '
            'ระบบเก็บข้อสรุปและข้อความอ้างอิงที่มีไว้ '
            'แต่ไม่ยกระดับเป็นผลที่ยืนยันแล้ว',
      ),
    };
    final String routeNote = isCrossCheck
        ? _value(
            ru:
                'Это проверочный маршрут: наблюдение показывает '
                'нестабильность цепочки, но само по себе не доказывает '
                'ошибку основного перевода.',
            en:
                'This is a cross-check route: the observation shows chain '
                'instability but does not by itself prove a primary error.',
            th:
                'นี่คือเส้นทางตรวจสอบไขว้ ข้อสังเกตแสดงความไม่เสถียรของลำดับการแปล '
                'แต่เพียงอย่างเดียวยังไม่พิสูจน์ว่าคำแปลหลักผิด',
          )
        : _value(
            ru:
                'Это основной маршрут: наблюдение относится к переводу '
                'непосредственно из текста пользователя.',
            en:
                'This is a primary route: the observation concerns a '
                'translation made directly from the user text.',
            th: 'นี่คือเส้นทางหลัก ข้อสังเกตเกี่ยวข้องกับคำแปลโดยตรงจากข้อความของผู้ใช้',
          );
    return '$finding $routeNote';
  }

  String observationVerificationLabel({
    required String statusName,
    required String candidateTuple,
    required String? verifierTuple,
  }) {
    return switch (statusName) {
      'confirmed' => _value(
        ru:
            'Два изолированных прохода согласованы: $candidateTuple. Они '
            'используют одну модель одного API-провайдера.',
        en:
            'The two isolated passes agree: $candidateTuple. They use one model '
            'from one API provider.',
        th:
            'การตรวจสอบแบบแยกกันสองรอบสอดคล้องกัน: $candidateTuple '
            'ทั้งสองรอบใช้โมเดลเดียวกันจากผู้ให้บริการ API รายเดียวกัน',
      ),
      'conflict' => _value(
        ru:
            'Изолированные проходы расходятся: $candidateTuple и '
            '${verifierTuple ?? 'UNKNOWN'}. Конфликт не повышается до '
            'положительного результата.',
        en:
            'The isolated passes disagree: $candidateTuple and '
            '${verifierTuple ?? 'UNKNOWN'}. The conflict cannot be upgraded '
            'to a positive result.',
        th:
            'ผลการตรวจสอบที่แยกจากกันไม่ตรงกัน: $candidateTuple และ '
            '${verifierTuple ?? 'UNKNOWN'} ระบบจะไม่ยกระดับความขัดแย้งนี้เป็นผลเชิงบวก',
      ),
      _ => _value(
        ru:
            'Маршрут не получил подтверждение двух проходов. Доступное '
            'доказательство сохранено как непроверенное.',
        en:
            'The route did not receive confirmation from both passes. The '
            'available evidence was preserved as unverified.',
        th:
            'เส้นทางนี้ไม่ได้รับการยืนยันจากทั้งสองรอบ '
            'หลักฐานที่มีถูกเก็บไว้ในสถานะยังไม่ยืนยัน',
      ),
    };
  }

  String auditLimitationLabel(String limitationCode) {
    if (limitationCode.startsWith('AUDIT_PASS_A_')) {
      return _auditPassFailureLabel(
        passName: 'A',
        reasonCode: limitationCode.substring('AUDIT_PASS_A_'.length),
      );
    }

    if (limitationCode.startsWith('AUDIT_PASS_B_')) {
      return _auditPassFailureLabel(
        passName: 'B',
        reasonCode: limitationCode.substring('AUDIT_PASS_B_'.length),
      );
    }

    return switch (limitationCode) {
      'INSUFFICIENT_CONTEXT' => _value(
        ru: 'Недостаточно контекста для надёжного вывода.',
        en: 'There is not enough context for a reliable conclusion.',
        th: 'บริบทไม่เพียงพอสำหรับข้อสรุปที่น่าเชื่อถือ',
      ),
      'SOURCE_AMBIGUITY' => _value(
        ru: 'Исходный текст допускает несколько прочтений.',
        en: 'The source text allows more than one reading.',
        th: 'ข้อความต้นฉบับตีความได้มากกว่าหนึ่งแบบ',
      ),
      'CROSS_LANGUAGE_EQUIVALENCE_UNCERTAIN' => _value(
        ru:
            'Эквивалентность между языками невозможно подтвердить '
            'по имеющимся данным.',
        en:
            'Cross-language equivalence cannot be confirmed from the '
            'available evidence.',
        th: 'หลักฐานที่มีไม่เพียงพอสำหรับยืนยันความเทียบเท่าระหว่างภาษา',
      ),
      'IDIOM_OR_CULTURAL_EQUIVALENCE_UNCERTAIN' => _value(
        ru:
            'Идиоматическую или культурную эквивалентность невозможно '
            'подтвердить без дополнительного контекста.',
        en:
            'Idiomatic or cultural equivalence cannot be confirmed without '
            'additional context.',
        th:
            'ไม่สามารถยืนยันความเทียบเท่าด้านสำนวนหรือวัฒนธรรม '
            'ได้หากไม่มีบริบทเพิ่มเติม',
      ),
      'EVIDENCE_INSUFFICIENT' => _value(
        ru: 'Доказательств недостаточно для классификации.',
        en: 'The evidence is insufficient for classification.',
        th: 'หลักฐานไม่เพียงพอสำหรับการจัดหมวดหมู่',
      ),
      'OTHER_UNVERIFIABLE' => _value(
        ru: 'Проверка не смогла подтвердить результат.',
        en: 'The audit could not verify the result.',
        th: 'การตรวจสอบไม่สามารถยืนยันผลลัพธ์ได้',
      ),
      'AUDIT_EVIDENCE_NOT_GROUNDED' => _value(
        ru:
            'Аудит вернул фрагмент, которого нет в тексте указанного '
            'маршрута. Такая находка не принята.',
        en:
            'The audit returned an excerpt that is not present in the '
            'specified route text. That finding was not accepted.',
        th:
            'การตรวจสอบส่งคืนข้อความที่ไม่อยู่ในข้อความของเส้นทางที่ระบุ '
            'ระบบจึงไม่ยอมรับข้อสังเกตนั้น',
      ),
      'AUDIT_RESPONSE_INVALID' => _value(
        ru:
            'Ответ проверки для одного маршрута имел неверный формат. '
            'Остальные маршруты сохранены.',
        en:
            'The audit response for one route had an invalid format. The other '
            'routes were preserved.',
        th:
            'คำตอบการตรวจสอบของเส้นทางหนึ่งมีรูปแบบไม่ถูกต้อง '
            'ระบบเก็บผลของเส้นทางอื่นไว้',
      ),
      'AUDIT_PASSES_DISAGREE' => _value(
        ru:
            'Два изолированных прохода одной модели дали разные выводы. Ни '
            'один вывод не выбран автоматически.',
        en:
            'Two isolated passes by the same model disagreed. Neither finding '
            'was selected automatically.',
        th:
            'การตรวจสอบแบบแยกกันสองรอบจากโมเดลเดียวให้ผลไม่ตรงกัน '
            'ระบบไม่เลือกข้อสรุปใดโดยอัตโนมัติ',
      ),
      'AUDIT_SIGNALS_DISAGREE' => _value(
        ru:
            'Изолированные проверки дали разные выводы. Положительный '
            'результат заблокирован.',
        en:
            'The isolated checks produced different conclusions. A positive '
            'result was blocked.',
        th:
            'การตรวจสอบที่แยกจากกันให้ข้อสรุปไม่ตรงกัน '
            'ระบบจึงปิดกั้นผลเชิงบวก',
      ),
      'AUDIT_CONFLICT_UNRESOLVED' => _value(
        ru:
            'Дополнительная слепая проверка не разрешила конфликт. Маршрут '
            'остаётся неопределённым.',
        en:
            'The additional blind check did not resolve the conflict. The '
            'route remains indeterminate.',
        th:
            'การตรวจสอบแบบแยกข้อมูลเพิ่มเติมไม่สามารถแก้ข้อขัดแย้งได้ '
            'เส้นทางนี้จึงยังไม่สามารถสรุปได้',
      ),
      'SEMANTIC_FRAME_UNKNOWN' => _value(
        ru:
            'Один из семантических профилей содержит неизвестное значение. '
            'Положительный результат запрещён.',
        en:
            'One semantic profile contains an unknown value. A positive '
            'result is not allowed.',
        th:
            'โปรไฟล์ความหมายอย่างน้อยหนึ่งรายการมีค่าที่ไม่ทราบ '
            'ระบบจึงไม่อนุญาตผลเชิงบวก',
      ),
      'SEMANTIC_ANALYSIS_UNRESOLVED' => _value(
        ru:
            'Атомарный анализ источника или перевода содержит неизвестные '
            'или недостаточно обоснованные элементы.',
        en:
            'The source or target atomic analysis contains unknown or '
            'insufficiently grounded elements.',
        th:
            'การวิเคราะห์เชิงอะตอมของต้นฉบับหรือคำแปลมีองค์ประกอบที่ไม่ทราบ '
            'หรือมีหลักฐานไม่เพียงพอ',
      ),
      'AUDIT_EVIDENCE_CONFLICT' => _value(
        ru:
            'Поиск контрпримера, двустороннее сопоставление и проверка '
            'доказательств дали несовместимые результаты.',
        en:
            'The counterexample search, bidirectional mapping, and evidence '
            'verification produced incompatible results.',
        th:
            'การค้นหาตัวอย่างโต้แย้ง การจับคู่สองทิศทาง '
            'และการตรวจสอบหลักฐานให้ผลที่ไม่สอดคล้องกัน',
      ),
      'AUDIT_VERIFIER_UNRESOLVED' => _value(
        ru:
            'Нейтральный проверяющий не смог подтвердить или отклонить '
            'предоставленные доказательства.',
        en:
            'The neutral verifier could not support or reject the supplied '
            'evidence.',
        th: 'ผู้ตรวจสอบเป็นกลางไม่สามารถยืนยันหรือปฏิเสธหลักฐานที่ให้มาได้',
      ),
      'AUDIT_EVIDENCE_CONTRACT_REJECTED' => _value(
        ru:
            'Ответ проверяющего нарушил доказательный контракт и не '
            'использован для положительного или отрицательного вывода.',
        en:
            'The verifier response violated the evidence contract and was not '
            'used for a positive or negative conclusion.',
        th:
            'คำตอบของผู้ตรวจสอบไม่เป็นไปตามสัญญาหลักฐาน '
            'จึงไม่ถูกใช้เพื่อสรุปผลเชิงบวกหรือเชิงลบ',
      ),
      'AUDIT_PROVIDER_HTTP_400' => _value(
        ru:
            'Сервис аудита отклонил запрос с HTTP 400. Повтор не выполнялся, '
            'поскольку ошибка не является временной.',
        en:
            'The audit service rejected the request with HTTP 400. It was not '
            'retried because the failure is not transient.',
        th:
            'บริการตรวจสอบปฏิเสธคำขอด้วย HTTP 400 '
            'ระบบไม่ลองซ้ำเพราะไม่ใช่ข้อผิดพลาดชั่วคราว',
      ),
      'AUDIT_PROVIDER_HTTP_500' => _value(
        ru:
            'Сервис аудита продолжил возвращать HTTP 500 после единственного '
            'разрешённого повтора.',
        en:
            'The audit service continued to return HTTP 500 after the single '
            'allowed retry.',
        th: 'บริการตรวจสอบยังคงส่ง HTTP 500 หลังการลองซ้ำที่อนุญาตหนึ่งครั้ง',
      ),
      'AUDIT_PROVIDER_HTTP_502' => _value(
        ru:
            'Сервис аудита продолжил возвращать HTTP 502 после единственного '
            'разрешённого повтора.',
        en:
            'The audit service continued to return HTTP 502 after the single '
            'allowed retry.',
        th: 'บริการตรวจสอบยังคงส่ง HTTP 502 หลังการลองซ้ำที่อนุญาตหนึ่งครั้ง',
      ),
      'AUDIT_PROVIDER_HTTP_503' => _value(
        ru:
            'Сервис аудита продолжил возвращать HTTP 503 после единственного '
            'разрешённого повтора.',
        en:
            'The audit service continued to return HTTP 503 after the single '
            'allowed retry.',
        th: 'บริการตรวจสอบยังคงส่ง HTTP 503 หลังการลองซ้ำที่อนุญาตหนึ่งครั้ง',
      ),
      'AUDIT_PROVIDER_HTTP_504' => _value(
        ru:
            'Сервис аудита продолжил возвращать HTTP 504 после единственного '
            'разрешённого повтора.',
        en:
            'The audit service continued to return HTTP 504 after the single '
            'allowed retry.',
        th: 'บริการตรวจสอบยังคงส่ง HTTP 504 หลังการลองซ้ำที่อนุญาตหนึ่งครั้ง',
      ),
      'AUDIT_TRANSPORT_FAILURE' => _value(
        ru:
            'Связь с сервисом аудита прервалась. Завершённые переводы '
            'сохранены, но итоговая проверка неполна.',
        en:
            'The audit connection failed. Completed translations were '
            'preserved, but the final audit is incomplete.',
        th:
            'การเชื่อมต่อกับบริการตรวจสอบล้มเหลว ระบบเก็บคำแปลที่เสร็จแล้วไว้ '
            'แต่การตรวจสอบสุดท้ายยังไม่สมบูรณ์',
      ),
      'AUDIT_AUTHORIZATION_FAILURE' => _value(
        ru:
            'Сервис отклонил авторизацию во время аудита. Завершённые '
            'переводы сохранены, но проверить их полностью нельзя.',
        en:
            'The service rejected authorization during the audit. '
            'Completed translations were preserved, but could not be '
            'fully verified.',
        th:
            'บริการปฏิเสธการยืนยันสิทธิ์ระหว่างการตรวจสอบ '
            'ระบบเก็บคำแปลที่เสร็จแล้วไว้ แต่ไม่สามารถตรวจสอบได้ครบถ้วน',
      ),
      'AUDIT_RATE_LIMITED' => _value(
        ru:
            'Во время аудита достигнут лимит запросов. Завершённые '
            'переводы сохранены, но итоговая проверка неполна.',
        en:
            'The request limit was reached during the audit. Completed '
            'translations were preserved, but the final audit is incomplete.',
        th:
            'ถึงขีดจำกัดคำขอระหว่างการตรวจสอบ ระบบเก็บคำแปลที่เสร็จแล้วไว้ '
            'แต่การตรวจสอบสุดท้ายยังไม่สมบูรณ์',
      ),
      'AUDIT_PROVIDER_FAILURE' => _value(
        ru:
            'Сервис аудита завершил запрос с ошибкой. Завершённые '
            'переводы сохранены, но итоговая проверка неполна.',
        en:
            'The audit service failed. Completed translations were '
            'preserved, but the final audit is incomplete.',
        th:
            'บริการตรวจสอบล้มเหลว ระบบเก็บคำแปลที่เสร็จแล้วไว้ '
            'แต่การตรวจสอบสุดท้ายยังไม่สมบูรณ์',
      ),
      _ => _value(
        ru: 'Нераспознанное ограничение проверки: $limitationCode',
        en: 'Unrecognized audit limitation: $limitationCode',
        th: 'ข้อจำกัดการตรวจสอบที่ไม่รู้จัก: $limitationCode',
      ),
    };
  }

  String _auditPassFailureLabel({
    required String passName,
    required String reasonCode,
  }) {
    final String reason = switch (reasonCode) {
      'RESPONSE_INVALID' => _value(
        ru: 'ответ имел неверный формат',
        en: 'the response had an invalid format',
        th: 'คำตอบมีรูปแบบไม่ถูกต้อง',
      ),
      'TRANSPORT_FAILURE' => _value(
        ru: 'соединение с сервисом прервалось',
        en: 'the connection to the service failed',
        th: 'การเชื่อมต่อกับบริการล้มเหลว',
      ),
      'AUTHORIZATION_FAILURE' => _value(
        ru: 'сервис отклонил авторизацию',
        en: 'the service rejected authorization',
        th: 'บริการปฏิเสธการยืนยันสิทธิ์',
      ),
      'RATE_LIMITED' => _value(
        ru: 'достигнут лимит запросов',
        en: 'the request limit was reached',
        th: 'ถึงขีดจำกัดคำขอ',
      ),
      'PROVIDER_FAILURE' => _value(
        ru: 'провайдер завершил запрос с ошибкой',
        en: 'the provider failed the request',
        th: 'ผู้ให้บริการดำเนินคำขอล้มเหลว',
      ),
      _ => _value(
        ru: 'причина не распознана',
        en: 'the reason was not recognized',
        th: 'ไม่ทราบสาเหตุ',
      ),
    };

    return _value(
      ru:
          'Изолированный проход $passName не завершён: $reason. Данные другого '
          'прохода сохранены, если он завершился успешно.',
      en:
          'Isolated pass $passName did not complete: $reason. Findings from the '
          'other pass were preserved when it completed successfully.',
      th:
          'การตรวจสอบแบบแยกรอบ $passName ไม่เสร็จสิ้น: $reason '
          'ระบบเก็บผลของอีกรอบไว้เมื่อรอบนั้นเสร็จสมบูรณ์',
    );
  }

  String verdictLabel(String verdictName) {
    return switch (verdictName) {
      'noCriticalDriftDetected' => _value(
        ru: 'Критические расхождения не обнаружены',
        en: 'No critical drift detected',
        th: 'ไม่พบความคลาดเคลื่อนร้ายแรง',
      ),
      'acceptableVariation' => _value(
        ru: 'Автоматические проверки согласованы',
        en: 'Automated checks agree',
        th: 'ผลการตรวจสอบอัตโนมัติสอดคล้องกัน',
      ),
      'reviewRequired' => _value(
        ru: 'Требуется проверка пользователя',
        en: 'User review required',
        th: 'ผู้ใช้ต้องตรวจสอบ',
      ),
      'unreliable' => _value(
        ru: 'Обнаружено существенное расхождение',
        en: 'Substantial drift detected',
        th: 'พบความคลาดเคลื่อนที่มีนัยสำคัญ',
      ),
      _ => _value(
        ru: 'Проверка требует внимания',
        en: 'Audit needs attention',
        th: 'ผลการตรวจสอบต้องได้รับการพิจารณา',
      ),
    };
  }

  String failureTitle(String failureKind) {
    return switch (failureKind) {
      'validation' => _value(
        ru: 'Проверьте исходный текст',
        en: 'Check the source text',
        th: 'ตรวจสอบข้อความต้นฉบับ',
      ),
      'missingApiKey' => _value(
        ru: 'Не задан Typhoon API key',
        en: 'Typhoon API key is missing',
        th: 'ยังไม่ได้ตั้งค่าคีย์ API ของ Typhoon',
      ),
      'unsupportedLanguage' => _value(
        ru: 'Язык не определён надёжно',
        en: 'Language was not determined reliably',
        th: 'ไม่สามารถระบุภาษาได้อย่างน่าเชื่อถือ',
      ),
      'authorization' => _value(
        ru: 'Typhoon API отклонил ключ',
        en: 'Typhoon API rejected the key',
        th: 'Typhoon API ปฏิเสธคีย์',
      ),
      'rateLimited' => _value(
        ru: 'Превышен лимит запросов',
        en: 'Request limit exceeded',
        th: 'เกินขีดจำกัดคำขอ',
      ),
      'cancelled' => _value(
        ru: 'Операция отменена',
        en: 'Operation cancelled',
        th: 'ยกเลิกการดำเนินการแล้ว',
      ),
      _ => _value(
        ru: 'Translator не смог завершить проверку',
        en: 'Translator could not complete the audit',
        th: 'Translator ไม่สามารถตรวจสอบให้เสร็จได้',
      ),
    };
  }

  String get manualLanguageHint => _value(
    ru:
        'При смешанном или коротком тексте выберите язык вручную. '
        'Выбор языка интерфейса на перевод не влияет.',
    en:
        'For mixed or very short text, select the source language manually. '
        'The interface language does not affect translation.',
    th:
        'สำหรับข้อความผสมหรือสั้นมาก ให้เลือกภาษาต้นฉบับด้วยตนเอง '
        'ภาษาของอินเทอร์เฟซไม่มีผลต่อการแปล',
  );

  String get translatorPlaceholderDescription => _value(
    ru: 'Перевод и проверка расхождений RU / EN / TH',
    en: 'Translation and drift analysis for RU / EN / TH',
    th: 'การแปลและการตรวจสอบความคลาดเคลื่อน RU / EN / TH',
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
