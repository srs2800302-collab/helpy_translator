import 'dart:convert';
import 'dart:io';

import 'package:path_provider_android/path_provider_android.dart';

import '../application/translator_draft_store.dart';
import '../domain/translator_models.dart';

final class JsonFileTranslatorDraftStore implements TranslatorDraftStore {
  const JsonFileTranslatorDraftStore({this.applicationSupportDirectory});

  static const String directoryName = 'registry_studio';
  static const String fileName = 'translator_draft_v1.json';
  static const String _version = 'v1';

  final Directory? applicationSupportDirectory;

  @override
  Future<TranslatorDraft?> load() async {
    final File file = await _file();

    if (!await file.exists()) {
      return null;
    }

    final Object? decoded = jsonDecode(await file.readAsString());
    final Map<String, Object?> state = _map(decoded, 'Translator draft');
    const Set<String> expectedKeys = <String>{
      'version',
      'sourceText',
      'sourceLanguageHint',
      'report',
    };

    if (state.keys.length != expectedKeys.length ||
        !state.keys.toSet().containsAll(expectedKeys) ||
        state['version'] != _version) {
      throw const FormatException('Translator draft schema is invalid.');
    }

    final Object? sourceText = state['sourceText'];
    final Object? legacySourceLanguageHint = state['sourceLanguageHint'];
    final Object? report = state['report'];

    if (sourceText is! String ||
        (legacySourceLanguageHint != null &&
            legacySourceLanguageHint is! String) ||
        (report != null && report is! Map<Object?, Object?>)) {
      throw const FormatException('Translator draft field types are invalid.');
    }

    return TranslatorDraft(
      sourceText: sourceText,
      report: report == null
          ? null
          : _decodeReport(
              (report as Map<Object?, Object?>).cast<String, Object?>(),
            ),
    );
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
      'version': _version,
      'sourceText': draft.sourceText,
      'sourceLanguageHint': null,
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
    final File file = await _file();

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
      final String? path = await PathProviderAndroid()
          .getApplicationSupportPath();

      if (path == null || path.trim().isEmpty) {
        throw StateError(
          'Android application support directory is unavailable.',
        );
      }

      supportDirectory = Directory(path);
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
        'sourceLanguageHint': null,
        'engineerContext': report.request.engineerContext,
      },
      'bundle': report.bundle.directSections,
      'audit': <String, Object?>{
        'meaningFindings': report.audit.meaningFindings,
        'terminologyFindings': report.audit.terminologyFindings,
        'styleFindings': report.audit.styleFindings,
        'ambiguityFindings': report.audit.ambiguityFindings,
      },
      'createdAt': report.createdAt.toUtc().toIso8601String(),
    };
  }

  static TranslatorRunReport _decodeReport(Map<String, Object?> value) {
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

    const Set<String> directBundleKeys = <String>{
      'SOURCE LANGUAGE',
      'SOURCE TEXT',
      'RU',
      'EN',
      'TH',
    };
    const Set<String> legacyReverseKeys = <String>{
      'EN_TO_RU',
      'TH_TO_RU',
      'EN_TO_TH',
      'TH_TO_EN',
    };
    final Set<String> allowedBundleKeys = <String>{
      ...directBundleKeys,
      ...legacyReverseKeys,
    };

    if (!bundle.keys.toSet().containsAll(directBundleKeys) ||
        bundle.keys.any((String key) => !allowedBundleKeys.contains(key))) {
      throw const FormatException(
        'Translator report bundle schema is invalid.',
      );
    }

    final Object? createdAt = value['createdAt'];

    if (createdAt is! String) {
      throw const FormatException(
        'Translator report createdAt must be a string.',
      );
    }

    final TranslatorWorkRequest workRequest = TranslatorWorkRequest(
      sourceText: _string(request['sourceText'], 'request.sourceText'),
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
    );
    final TranslationAudit translationAudit = TranslationAudit(
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

    return TranslatorRunReport(
      request: workRequest,
      bundle: translationBundle,
      audit: translationAudit,
      createdAt: DateTime.parse(createdAt).toUtc(),
    );
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
