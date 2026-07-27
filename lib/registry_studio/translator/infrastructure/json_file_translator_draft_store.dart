import 'dart:convert';
import 'dart:io';

import 'package:path_provider_android/path_provider_android.dart';

import '../application/translator_draft_store.dart';
import 'translator_report_json_codec.dart';

final class JsonFileTranslatorDraftStore implements TranslatorDraftStore {
  const JsonFileTranslatorDraftStore({this.applicationSupportDirectory});

  static const String directoryName = 'registry_studio';
  static const String fileName = 'translator_draft_v1.json';
  static const String _currentVersion = 'v2';
  static const String _legacyVersion = 'v1';

  final Directory? applicationSupportDirectory;

  @override
  Future<TranslatorDraft?> load() async {
    final File file = await _file();

    if (!await file.exists()) {
      return null;
    }

    final Object? decoded = jsonDecode(await file.readAsString());
    final Map<String, Object?> state = TranslatorReportJsonCodec.map(
      decoded,
      'Translator draft',
    );

    return switch (state['version']) {
      _legacyVersion => _decodeLegacyDraft(state),
      _currentVersion => _decodeCurrentDraft(state),
      _ => throw const FormatException(
        'Translator draft version is unsupported.',
      ),
    };
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
      'report': draft.report == null
          ? null
          : TranslatorReportJsonCodec.encode(draft.report!),
      'partialBundle': draft.partialBundle == null
          ? null
          : TranslatorReportJsonCodec.encodeBundle(draft.partialBundle!),
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

  static TranslatorDraft _decodeLegacyDraft(Map<String, Object?> state) {
    TranslatorReportJsonCodec.requireExactKeys(state, const <String>{
      'version',
      'sourceText',
      'sourceLanguageHint',
      'report',
    }, 'Legacy Translator draft');

    final Object? sourceText = state['sourceText'];
    final Object? legacySourceLanguageHint = state['sourceLanguageHint'];
    final Object? report = state['report'];

    if (sourceText is! String ||
        (legacySourceLanguageHint != null &&
            legacySourceLanguageHint is! String) ||
        (report != null && report is! Map<Object?, Object?>)) {
      throw const FormatException(
        'Legacy Translator draft field types are invalid.',
      );
    }

    return TranslatorDraft(
      sourceText: sourceText,
      report: report == null
          ? null
          : TranslatorReportJsonCodec.decode(
              (report as Map<Object?, Object?>).cast<String, Object?>(),
            ),
    );
  }

  static TranslatorDraft _decodeCurrentDraft(Map<String, Object?> state) {
    TranslatorReportJsonCodec.requireExactKeys(state, const <String>{
      'version',
      'sourceText',
      'report',
      'partialBundle',
    }, 'Translator draft');

    final Object? sourceText = state['sourceText'];
    final Object? report = state['report'];
    final Object? partialBundle = state['partialBundle'];

    if (sourceText is! String ||
        (report != null && report is! Map<Object?, Object?>) ||
        (partialBundle != null && partialBundle is! Map<Object?, Object?>)) {
      throw const FormatException('Translator draft field types are invalid.');
    }

    if (report != null && partialBundle != null) {
      throw const FormatException(
        'Translator draft cannot contain a report and a partial bundle.',
      );
    }

    return TranslatorDraft(
      sourceText: sourceText,
      report: report == null
          ? null
          : TranslatorReportJsonCodec.decode(
              (report as Map<Object?, Object?>).cast<String, Object?>(),
            ),
      partialBundle: partialBundle == null
          ? null
          : TranslatorReportJsonCodec.decodeBundle(
              (partialBundle as Map<Object?, Object?>).cast<String, Object?>(),
            ),
    );
  }
}
