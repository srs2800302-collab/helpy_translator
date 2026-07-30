import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../application/translator_draft_store.dart';
import '../domain/translator_models.dart';

final class JsonFileTranslatorDraftStore implements TranslatorDraftStore {
  const JsonFileTranslatorDraftStore({this.applicationSupportDirectory});

  static const String directoryName = 'registry_studio';
  static const String fileName = 'translator_draft_v1.json';
  static const String _currentVersion = 'v3';
  static const String _structuredVersion = 'v2';
  static const String _legacyVersion = 'v1';

  final Directory? applicationSupportDirectory;

  @override
  Future<TranslatorDraft?> load() async {
    final File file = await _file();

    if (!await file.exists()) {
      return null;
    }

    try {
      final Object? decoded = jsonDecode(await file.readAsString());
      final Map<String, Object?> state = _map(decoded, 'Translator draft');

      const Set<String> expectedKeys = <String>{
        'version',
        'sourceText',
        'sourceLanguageHint',
        'report',
      };

      final Object? version = state['version'];

      if (state.keys.length != expectedKeys.length ||
          !state.keys.toSet().containsAll(expectedKeys) ||
          version is! String ||
          (version != _currentVersion &&
              version != _structuredVersion &&
              version != _legacyVersion)) {
        throw const FormatException('Translator draft schema is invalid.');
      }

      final String draftVersion = version as String;
      final Object? sourceText = state['sourceText'];
      final Object? sourceLanguageHint = state['sourceLanguageHint'];
      final Object? report = state['report'];

      if (sourceText is! String ||
          (sourceLanguageHint != null && sourceLanguageHint is! String) ||
          (report != null && report is! Map<Object?, Object?>)) {
        throw const FormatException(
          'Translator draft field types are invalid.',
        );
      }

      return TranslatorDraft(
        sourceText: sourceText,
        sourceLanguageHint: sourceLanguageHint == null
            ? null
            : TranslationLanguage.fromCode(sourceLanguageHint as String),
        report: report == null
            ? null
            : _decodeReport(
                _map(report, 'Translator report'),
                version: draftVersion,
              ),
      );
    } on FormatException {
      return _discardInvalid(file);
    } on ArgumentError {
      return _discardInvalid(file);
    }
  }

  @override
  Future<void> save(TranslatorDraft draft) async {
    final File file = await _file();
    await file.parent.create(recursive: true);

    final File temporary = File('${file.path}.tmp');

    if (await temporary.exists()) {
      await temporary.delete();
    }

    final Map<String, Object?> state = <String, Object?>{
      'version': _currentVersion,
      'sourceText': draft.sourceText,
      'sourceLanguageHint': draft.sourceLanguageHint?.code,
      'report': draft.report == null ? null : _encodeReport(draft.report!),
    };

    try {
      await temporary.writeAsString('${jsonEncode(state)}\n', flush: true);
      await temporary.rename(file.path);
    } catch (_) {
      if (await temporary.exists()) {
        await temporary.delete();
      }
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    await _deleteDraftFiles(await _file());
  }

  static Future<Never> _discardInvalid(File file) async {
    await _deleteDraftFiles(file);
    throw const FormatException('Translator draft is invalid and was removed.');
  }

  static Future<void> _deleteDraftFiles(File file) async {
    if (await file.exists()) {
      await file.delete();
    }

    final File temporary = File('${file.path}.tmp');

    if (await temporary.exists()) {
      await temporary.delete();
    }
  }

  Future<File> _file() async {
    final Directory supportDirectory;

    if (applicationSupportDirectory != null) {
      supportDirectory = applicationSupportDirectory!;
    } else {
      supportDirectory = await getApplicationSupportDirectory();
    }

    return File(
      '${supportDirectory.path}'
      '${Platform.pathSeparator}'
      '$directoryName'
      '${Platform.pathSeparator}'
      '$fileName',
    );
  }

  static Map<String, Object?> _encodeReport(TranslatorRunReport report) {
    return <String, Object?>{
      'request': <String, Object?>{
        'sourceText': report.request.sourceText,
        'sourceLanguageHint': report.request.sourceLanguageHint?.code,
        'engineerContext': report.request.engineerContext,
      },
      'bundle': report.bundle.nineSections,
      'audit': <String, Object?>{
        'findings': report.audit.findings
            .map(_encodeFinding)
            .toList(growable: false),
      },
      'createdAt': report.createdAt.toUtc().toIso8601String(),
    };
  }

  static TranslatorRunReport _decodeReport(
    Map<String, Object?> value, {
    required String version,
  }) {
    const Set<String> expectedKeys = <String>{
      'request',
      'bundle',
      'audit',
      'createdAt',
    };

    if (value.keys.length != expectedKeys.length ||
        !value.keys.toSet().containsAll(expectedKeys)) {
      throw const FormatException('Translator report schema is invalid.');
    }

    final Map<String, Object?> request = _map(
      value['request'],
      'Translator report request',
    );
    final Map<String, Object?> bundle = _map(
      value['bundle'],
      'Translator report bundle',
    );
    final Map<String, Object?> audit = _map(
      value['audit'],
      'Translator report audit',
    );

    final Object? createdAt = value['createdAt'];

    if (createdAt is! String) {
      throw const FormatException(
        'Translator report createdAt must be a string.',
      );
    }

    final TranslatorWorkRequest workRequest = TranslatorWorkRequest(
      sourceText: _string(request['sourceText'], 'request.sourceText'),
      sourceLanguageHint: request['sourceLanguageHint'] == null
          ? null
          : TranslationLanguage.fromCode(
              _string(
                request['sourceLanguageHint'],
                'request.sourceLanguageHint',
              ),
            ),
      engineerContext: request['engineerContext'] == null
          ? null
          : _string(request['engineerContext'], 'request.engineerContext'),
    );

    final TranslationBundle translationBundle = TranslationBundle(
      sourceLanguage: TranslationLanguage.fromCode(
        _string(bundle['SOURCE LANGUAGE'], 'bundle.SOURCE LANGUAGE'),
      ),
      sourceText: _string(bundle['SOURCE TEXT'], 'bundle.SOURCE TEXT'),
      ru: _string(bundle['RU'], 'bundle.RU'),
      en: _string(bundle['EN'], 'bundle.EN'),
      th: _string(bundle['TH'], 'bundle.TH'),
      enToRu: _string(bundle['EN_TO_RU'], 'bundle.EN_TO_RU'),
      thToRu: _string(bundle['TH_TO_RU'], 'bundle.TH_TO_RU'),
      enToTh: _string(bundle['EN_TO_TH'], 'bundle.EN_TO_TH'),
      thToEn: _string(bundle['TH_TO_EN'], 'bundle.TH_TO_EN'),
    );

    final TranslationAudit translationAudit;

    if (version == _legacyVersion) {
      translationAudit = _decodeLegacyAudit(audit);
    } else {
      translationAudit = _decodeStructuredAudit(
        audit,
        bundle: translationBundle,
        version: version,
      );
    }

    return TranslatorRunReport(
      request: workRequest,
      bundle: translationBundle,
      audit: translationAudit,
      createdAt: DateTime.parse(createdAt).toUtc(),
    );
  }

  static Map<String, Object?> _encodeFinding(TranslationFinding finding) {
    if (finding.isLegacy) {
      return <String, Object?>{
        'kind': 'legacy',
        'category': finding.category.code,
        'message': finding.legacyMessage,
      };
    }

    if (finding.isRussianOnly) {
      return <String, Object?>{
        'kind': 'russianOnly',
        'category': finding.category.code,
        'section': finding.section!.code,
        'sourceFragment': finding.sourceFragment,
        'translationFragment': finding.translationFragment,
        'reason': finding.reason,
        'impact': finding.impact,
        'correctVariant': finding.correctVariant,
        'sourceAmbiguity': finding.sourceAmbiguity,
      };
    }

    return <String, Object?>{
      'kind': 'multilingual',
      'category': finding.category.code,
      'section': finding.section!.code,
      'sourceFragment': finding.sourceFragment,
      'translationFragment': finding.translationFragment,
      'reason': _encodeLocalizedText(finding.localizedReason!),
      'impact': _encodeLocalizedText(finding.localizedImpact!),
      'correctVariant': finding.correctVariant,
      'sourceAmbiguity': finding.localizedSourceAmbiguity == null
          ? null
          : _encodeLocalizedText(finding.localizedSourceAmbiguity!),
    };
  }

  static Map<String, Object?> _encodeLocalizedText(
    LocalizedEvidenceText value,
  ) {
    return <String, Object?>{'ru': value.ru, 'en': value.en, 'th': value.th};
  }

  static TranslationAudit _decodeLegacyAudit(Map<String, Object?> audit) {
    const Set<String> expectedKeys = <String>{
      'meaningFindings',
      'terminologyFindings',
      'styleFindings',
      'ambiguityFindings',
    };
    _requireExactKeys(audit, expectedKeys, 'Legacy Translator audit');

    return TranslationAudit(
      meaningFindings: _strings(
        audit['meaningFindings'],
        'audit.meaningFindings',
      ),
      terminologyFindings: _strings(
        audit['terminologyFindings'],
        'audit.terminologyFindings',
      ),
      styleFindings: _strings(audit['styleFindings'], 'audit.styleFindings'),
      ambiguityFindings: _strings(
        audit['ambiguityFindings'],
        'audit.ambiguityFindings',
      ),
    );
  }

  static TranslationAudit _decodeStructuredAudit(
    Map<String, Object?> audit, {
    required TranslationBundle bundle,
    required String version,
  }) {
    const Set<String> expectedKeys = <String>{'findings'};
    _requireExactKeys(audit, expectedKeys, 'Translator audit');

    final Object? rawFindings = audit['findings'];

    if (rawFindings is! List<Object?>) {
      throw const FormatException('audit.findings must be an array.');
    }

    final List<TranslationFinding> findings = <TranslationFinding>[
      for (int index = 0; index < rawFindings.length; index += 1)
        _decodeFinding(rawFindings[index], index, bundle, version: version),
    ];

    try {
      return TranslationAudit(findings: findings);
    } on ArgumentError catch (error) {
      throw FormatException('audit.findings is invalid: ${error.message}');
    }
  }

  static TranslationFinding _decodeFinding(
    Object? value,
    int index,
    TranslationBundle bundle, {
    required String version,
  }) {
    final String name = 'audit.findings[$index]';
    final Map<String, Object?> finding = _map(value, name);
    final String kind = _string(finding['kind'], '$name.kind');
    final String categoryCode = _string(finding['category'], '$name.category');
    final TranslationFindingCategory category = _category(
      categoryCode,
      '$name.category',
    );

    if (category.code != categoryCode) {
      throw FormatException('$name.category is not canonical.');
    }

    if (kind == 'legacy') {
      const Set<String> expectedKeys = <String>{'kind', 'category', 'message'};
      _requireExactKeys(finding, expectedKeys, name);

      return TranslationFinding.legacy(
        category: category,
        message: _string(finding['message'], '$name.message'),
      );
    }

    final bool russianOnly =
        (version == _structuredVersion && kind == 'structured') ||
        (version == _currentVersion && kind == 'russianOnly');
    final bool multilingual =
        version == _currentVersion && kind == 'multilingual';

    if (!russianOnly && !multilingual) {
      throw FormatException('$name.kind is invalid for draft $version.');
    }

    const Set<String> expectedKeys = <String>{
      'kind',
      'category',
      'section',
      'sourceFragment',
      'translationFragment',
      'reason',
      'impact',
      'correctVariant',
      'sourceAmbiguity',
    };
    _requireExactKeys(finding, expectedKeys, name);

    final String sectionCode = _string(finding['section'], '$name.section');
    final TranslationLanguage section = _language(sectionCode, '$name.section');

    if (section.code != sectionCode) {
      throw FormatException('$name.section is not canonical.');
    }

    final String sourceFragment = _string(
      finding['sourceFragment'],
      '$name.sourceFragment',
    );
    final String translationFragment = _string(
      finding['translationFragment'],
      '$name.translationFragment',
    );

    final String directText = switch (section) {
      TranslationLanguage.ru => bundle.ru,
      TranslationLanguage.en => bundle.en,
      TranslationLanguage.th => bundle.th,
    };

    if (!bundle.sourceText.contains(sourceFragment) ||
        !directText.contains(translationFragment)) {
      throw FormatException('$name is not grounded in its stored bundle.');
    }

    if (russianOnly) {
      return TranslationFinding(
        category: category,
        section: section,
        sourceFragment: sourceFragment,
        translationFragment: translationFragment,
        reason: _string(finding['reason'], '$name.reason'),
        impact: _string(finding['impact'], '$name.impact'),
        correctVariant: _string(
          finding['correctVariant'],
          '$name.correctVariant',
        ),
        sourceAmbiguity: _string(
          finding['sourceAmbiguity'],
          '$name.sourceAmbiguity',
        ),
      );
    }

    return TranslationFinding.multilingual(
      category: category,
      section: section,
      sourceFragment: sourceFragment,
      translationFragment: translationFragment,
      reason: _decodeLocalizedText(finding['reason'], '$name.reason'),
      impact: _decodeLocalizedText(finding['impact'], '$name.impact'),
      correctVariant: _string(
        finding['correctVariant'],
        '$name.correctVariant',
      ),
      sourceAmbiguity: finding['sourceAmbiguity'] == null
          ? null
          : _decodeLocalizedText(
              finding['sourceAmbiguity'],
              '$name.sourceAmbiguity',
            ),
    );
  }

  static LocalizedEvidenceText _decodeLocalizedText(
    Object? value,
    String name,
  ) {
    final Map<String, Object?> localized = _map(value, name);
    const Set<String> expectedKeys = <String>{'ru', 'en', 'th'};
    _requireExactKeys(localized, expectedKeys, name);

    return LocalizedEvidenceText(
      ru: _canonicalLocalizedString(localized['ru'], '$name.ru'),
      en: _canonicalLocalizedString(localized['en'], '$name.en'),
      th: _canonicalLocalizedString(localized['th'], '$name.th'),
    );
  }

  static String _canonicalLocalizedString(Object? value, String name) {
    if (value is! String) {
      throw FormatException('$name must be a nonempty string.');
    }

    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      throw FormatException('$name must be a nonempty string.');
    }

    if (trimmed != value) {
      throw FormatException('$name must not contain outer whitespace.');
    }

    return value;
  }

  static TranslationFindingCategory _category(String value, String name) {
    try {
      return TranslationFindingCategory.fromCode(value);
    } on ArgumentError catch (error) {
      throw FormatException('$name is invalid: ${error.message}');
    }
  }

  static TranslationLanguage _language(String value, String name) {
    try {
      return TranslationLanguage.fromCode(value);
    } on ArgumentError catch (error) {
      throw FormatException('$name is invalid: ${error.message}');
    }
  }

  static void _requireExactKeys(
    Map<String, Object?> value,
    Set<String> expected,
    String name,
  ) {
    final Set<String> actual = value.keys.toSet();

    if (actual.length != expected.length || !actual.containsAll(expected)) {
      throw FormatException('$name has an invalid key set.');
    }
  }

  static Map<String, Object?> _map(Object? value, String name) {
    if (value is! Map<Object?, Object?> ||
        value.keys.any((Object? key) => key is! String)) {
      throw FormatException('$name must be a JSON object.');
    }

    return value.cast<String, Object?>();
  }

  static String _string(Object? value, String name) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$name must be a nonempty string.');
    }

    return value;
  }

  static List<String> _strings(Object? value, String name) {
    if (value is! List<Object?> ||
        value.any((Object? item) => item is! String)) {
      throw FormatException('$name must be an array of strings.');
    }

    return value.cast<String>();
  }
}
