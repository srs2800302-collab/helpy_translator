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
        ru: 'Расширенная проверка — $routeCount маршрутов',
        en: 'Expanded audit — $routeCount routes',
        th: 'การตรวจสอบแบบขยาย — $routeCount เส้นทาง',
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
        'Матрица проверена тремя изолированными автоматическими запросами: '
        'анализ источников, анализ переводов и попарное сравнение. При '
        'расхождении выполняется дополнительная слепая проверка только '
        'спорных маршрутов. Проверки не видят выводы друг друга, но используют '
        'одного API-провайдера; это не независимая экспертиза.',
    en:
        'The matrix is checked by three isolated automated requests: source '
        'analysis, target analysis, and pairwise comparison. If they disagree, '
        'an additional blind check runs only for disputed routes. The checks '
        'do not see one another\'s conclusions, but they use one API provider; '
        'this is not an independent review.',
    th:
        'ระบบตรวจสอบเมทริกซ์ด้วยคำขออัตโนมัติที่แยกจากกันสามรายการ: '
        'วิเคราะห์ต้นฉบับ วิเคราะห์คำแปล และเปรียบเทียบเป็นคู่ '
        'หากผลไม่ตรงกัน ระบบจะตรวจสอบเฉพาะเส้นทางที่ขัดแย้งเพิ่มเติม '
        'ผู้ตรวจสอบไม่เห็นผลของกันและกัน แต่ใช้ผู้ให้บริการ API รายเดียวกัน '
        'จึงไม่ใช่การตรวจสอบโดยผู้เชี่ยวชาญอิสระ',
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
              'Семантические профили источника и перевода совпали, а слепой '
              'парный аудитор не нашёл конкретного расхождения по '
              'характеристике «$dimension». Это согласие автоматических '
              'проверок, а не доказательство абсолютной эквивалентности.',
          en:
              'The source and target semantic profiles matched, and the blind '
              'pair judge found no concrete difference in $dimension. This is '
              'agreement between automated checks, not proof of absolute '
              'equivalence.',
          th:
              'โปรไฟล์ความหมายของต้นฉบับและคำแปลตรงกัน และผู้ตรวจสอบคู่แบบ '
              'ไม่เห็นผลอื่นไม่พบความแตกต่างที่ชัดเจนในมิติ $dimension '
              'นี่คือความสอดคล้องของการตรวจสอบอัตโนมัติ '
              'ไม่ใช่หลักฐานความเทียบเท่าอย่างสมบูรณ์',
        ),
        'altered' => _value(
          ru:
              'Изолированные проверки согласованно зафиксировали изменение '
              'смысла в характеристике «$dimension».',
          en:
              'The isolated checks consistently detected a meaning change in '
              '$dimension.',
          th:
              'การตรวจสอบที่แยกจากกันตรวจพบตรงกันว่า '
              'ความหมายเปลี่ยนไปในมิติ $dimension',
        ),
        _ => _value(
          ru:
              'Даже при совпадении автоматических проверок сохранность смысла '
              'по характеристике «$dimension» не установлена.',
          en:
              'Even with agreement between automated checks, meaning '
              'preservation for $dimension was not established.',
          th:
              'แม้ผลการตรวจสอบอัตโนมัติตรงกัน '
              'แต่ยังไม่สามารถยืนยันการคงความหมายในมิติ $dimension ได้',
        ),
      },
      'conflict' => _value(
        ru:
            'Изолированные проверки дали разные выводы. Система не выбирает '
            'более благоприятный результат; маршрут остаётся неопределённым.',
        en:
            'The isolated checks disagreed. The system does not select the '
            'more favorable result; the route remains indeterminate.',
        th:
            'การตรวจสอบที่แยกจากกันให้ผลไม่ตรงกัน '
            'ระบบไม่เลือกผลที่เป็นประโยชน์กว่า '
            'เส้นทางนี้จึงยังไม่สามารถสรุปได้',
      ),
      _ => _value(
        ru: 'Одну или несколько слепых проверок завершить не удалось.',
        en: 'One or more blind checks could not be completed.',
        th: 'ไม่สามารถดำเนินการตรวจสอบแบบแยกข้อมูลอย่างน้อยหนึ่งรายการได้',
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
                'นี่คือเส้นทางตรวจสอบไขว้ ข้อสังเกตแสดงความไม่เสถียร '
                'ของลำดับการแปล แต่เพียงอย่างเดียวยังไม่พิสูจน์ว่า '
                'คำแปลหลักผิด',
          )
        : _value(
            ru:
                'Это основной маршрут: наблюдение относится к переводу '
                'непосредственно из текста пользователя.',
            en:
                'This is a primary route: the observation concerns a '
                'translation made directly from the user text.',
            th:
                'นี่คือเส้นทางหลัก ข้อสังเกตเกี่ยวข้องกับคำแปล '
                'โดยตรงจากข้อความของผู้ใช้',
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
            'Слепые проверки согласованы: $candidateTuple. Они используют '
            'одного API-провайдера и не являются независимой экспертизой.',
        en:
            'The blind checks agree: $candidateTuple. They use one API '
            'provider and are not an independent review.',
        th:
            'ผลการตรวจสอบแบบแยกข้อมูลสอดคล้องกัน: $candidateTuple '
            'การตรวจสอบทั้งหมดใช้ผู้ให้บริการ API รายเดียวกัน '
            'จึงไม่ใช่การตรวจสอบอิสระ',
      ),
      'conflict' => _value(
        ru:
            'Изолированные проверки расходятся: $candidateTuple и '
            '${verifierTuple ?? 'UNKNOWN'}. Конфликт не повышается до '
            'положительного результата.',
        en:
            'The isolated checks disagree: $candidateTuple and '
            '${verifierTuple ?? 'UNKNOWN'}. The conflict cannot be upgraded '
            'to a positive result.',
        th:
            'ผลการตรวจสอบที่แยกจากกันไม่ตรงกัน: $candidateTuple และ '
            '${verifierTuple ?? 'UNKNOWN'} ระบบจะไม่ยกระดับความขัดแย้งนี้ '
            'เป็นผลเชิงบวก',
      ),
      _ => _value(
        ru: 'Одна или несколько слепых проверок не подтвердили маршрут.',
        en: 'One or more blind checks did not verify the route.',
        th: 'การตรวจสอบแบบแยกข้อมูลอย่างน้อยหนึ่งรายการไม่ยืนยันเส้นทางนี้',
      ),
    };
  }

  String auditLimitationLabel(String limitationCode) {
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
            'Ответ аудита для одного из маршрутов имел неверный формат. '
            'Этот маршрут помечен как непроверенный.',
        en:
            'The audit response for one route had an invalid format. '
            'That route was marked as unverified.',
        th:
            'คำตอบการตรวจสอบของเส้นทางหนึ่งมีรูปแบบไม่ถูกต้อง '
            'เส้นทางนั้นจึงถูกทำเครื่องหมายว่ายังไม่ได้รับการยืนยัน',
      ),
      'AUDIT_PASSES_DISAGREE' => _value(
        ru:
            'Два независимых прохода аудита не совпали. Спорная находка '
            'не подтверждена и помечена как неопределённая.',
        en:
            'The two independent audit passes disagreed. The disputed '
            'finding was not confirmed and was marked as indeterminate.',
        th:
            'ผลการตรวจสอบอิสระสองรอบไม่ตรงกัน '
            'ข้อสังเกตที่ขัดแย้งจึงไม่ได้รับการยืนยันและถูกทำเครื่องหมายว่าไม่แน่นอน',
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
        ru: 'Невозможно подтвердить результат',
        en: 'Result cannot be confirmed',
        th: 'ไม่สามารถยืนยันผลลัพธ์ได้',
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
