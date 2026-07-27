import 'dart:convert';
import 'dart:io';

import 'package:path_provider_android/path_provider_android.dart';

import '../application/translator_history_store.dart';
import '../domain/translator_models.dart';
import 'translator_report_json_codec.dart';

final class JsonFileTranslatorHistoryStore implements TranslatorHistoryStore {
  const JsonFileTranslatorHistoryStore({this.applicationSupportDirectory});

  static const String directoryName = 'registry_studio';
  static const String fileName = 'translator_history_v1.json';
  static const String _currentVersion = 'v1';

  final Directory? applicationSupportDirectory;

  @override
  Future<List<TranslatorHistoryEntry>> load() async {
    final File file = await _file();

    if (!await file.exists()) {
      return const <TranslatorHistoryEntry>[];
    }

    final Object? decoded = jsonDecode(await file.readAsString());
    final Map<String, Object?> state = TranslatorReportJsonCodec.map(
      decoded,
      'Translator history',
    );
    TranslatorReportJsonCodec.requireExactKeys(state, const <String>{
      'version',
      'entries',
    }, 'Translator history');

    if (state['version'] != _currentVersion) {
      throw const FormatException('Translator history version is unsupported.');
    }

    final Object? encodedEntries = state['entries'];

    if (encodedEntries is! List<Object?>) {
      throw const FormatException(
        'Translator history entries must be an array.',
      );
    }

    final List<TranslatorHistoryEntry> entries = encodedEntries
        .map(_decodeEntry)
        .toList(growable: false);
    final Set<String> ids = entries
        .map((TranslatorHistoryEntry entry) => entry.id)
        .toSet();

    if (ids.length != entries.length) {
      throw const FormatException(
        'Translator history contains duplicate entry identifiers.',
      );
    }

    return List<TranslatorHistoryEntry>.unmodifiable(entries);
  }

  @override
  Future<void> save(List<TranslatorHistoryEntry> entries) async {
    final Set<String> ids = entries
        .map((TranslatorHistoryEntry entry) => entry.id)
        .toSet();

    if (ids.length != entries.length) {
      throw ArgumentError.value(
        entries,
        'entries',
        'Translator history entry identifiers must be unique.',
      );
    }

    final File file = await _file();
    await file.parent.create(recursive: true);

    final File temporary = File('${file.path}.tmp');

    if (await temporary.exists()) {
      await temporary.delete();
    }

    final Map<String, Object?> state = <String, Object?>{
      'version': _currentVersion,
      'entries': entries.map(_encodeEntry).toList(growable: false),
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

  static Map<String, Object?> _encodeEntry(TranslatorHistoryEntry entry) {
    return <String, Object?>{
      'id': entry.id,
      'report': TranslatorReportJsonCodec.encode(entry.report),
    };
  }

  static TranslatorHistoryEntry _decodeEntry(Object? value) {
    final Map<String, Object?> entry = TranslatorReportJsonCodec.map(
      value,
      'Translator history entry',
    );
    TranslatorReportJsonCodec.requireExactKeys(entry, const <String>{
      'id',
      'report',
    }, 'Translator history entry');

    return TranslatorHistoryEntry(
      id: TranslatorReportJsonCodec.string(
        entry['id'],
        'Translator history entry id',
      ),
      report: TranslatorReportJsonCodec.decode(
        TranslatorReportJsonCodec.map(
          entry['report'],
          'Translator history entry report',
        ),
      ),
    );
  }
}
