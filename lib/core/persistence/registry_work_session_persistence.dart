import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

final class RegistryWorkSession {
  const RegistryWorkSession({
    required this.pathTitles,
    required this.pathNodeIds,
    required this.lastPhrase,
    required this.updatedAtIso,
  });

  final List<String> pathTitles;
  final List<String> pathNodeIds;
  final String lastPhrase;
  final String updatedAtIso;

  bool get hasData =>
      pathTitles.isNotEmpty ||
      pathNodeIds.isNotEmpty ||
      lastPhrase.trim().isNotEmpty;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'pathTitles': pathTitles,
      'pathNodeIds': pathNodeIds,
      'lastPhrase': lastPhrase,
      'updatedAtIso': updatedAtIso,
    };
  }

  static RegistryWorkSession fromJson(Map<String, dynamic> json) {
    return RegistryWorkSession(
      pathTitles: _stringList(json['pathTitles']),
      pathNodeIds: _stringList(json['pathNodeIds']),
      lastPhrase: _string(json['lastPhrase']),
      updatedAtIso: _string(json['updatedAtIso']),
    );
  }

  static List<String> _stringList(Object? value) {
    return value is List<dynamic>
        ? value.whereType<String>().toList(growable: false)
        : const <String>[];
  }

  static String _string(Object? value) {
    return value is String ? value : '';
  }
}

final class RegistryWorkSessionPersistence {
  const RegistryWorkSessionPersistence();

  static const String _key = 'registry_work_session_v2';

  Future<RegistryWorkSession?> load() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final String? rawV2 = preferences.getString(_key);
    final String? rawV1 = preferences.getString('registry_work_session_v1');
    final String? raw = rawV2 ?? rawV1;

    if (raw == null || raw.isEmpty) {
      return null;
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final RegistryWorkSession session = RegistryWorkSession.fromJson(decoded);

    return session.hasData ? session : null;
  }

  Future<void> saveSection({
    required List<String> pathTitles,
    required List<String> pathNodeIds,
  }) async {
    await _save(
      RegistryWorkSession(
        pathTitles: pathTitles,
        pathNodeIds: pathNodeIds,
        lastPhrase: '',
        updatedAtIso: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> savePhrase({
    required List<String> pathTitles,
    required List<String> pathNodeIds,
    required String phrase,
  }) async {
    await _save(
      RegistryWorkSession(
        pathTitles: pathTitles,
        pathNodeIds: pathNodeIds,
        lastPhrase: phrase,
        updatedAtIso: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> _save(RegistryWorkSession session) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(session.toJson()));
  }
}
