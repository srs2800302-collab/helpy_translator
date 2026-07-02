import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

final class RegistryWorkSession {
  const RegistryWorkSession({
    required this.pathTitles,
    required this.lastPhrase,
    required this.updatedAtIso,
  });

  final List<String> pathTitles;
  final String lastPhrase;
  final String updatedAtIso;

  bool get hasData => pathTitles.isNotEmpty || lastPhrase.trim().isNotEmpty;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'pathTitles': pathTitles,
      'lastPhrase': lastPhrase,
      'updatedAtIso': updatedAtIso,
    };
  }

  static RegistryWorkSession fromJson(Map<String, dynamic> json) {
    final Object? rawPath = json['pathTitles'];

    return RegistryWorkSession(
      pathTitles: rawPath is List<dynamic>
          ? rawPath.whereType<String>().toList(growable: false)
          : const <String>[],
      lastPhrase: _string(json['lastPhrase']),
      updatedAtIso: _string(json['updatedAtIso']),
    );
  }

  static String _string(Object? value) {
    return value is String ? value : '';
  }
}

final class RegistryWorkSessionPersistence {
  const RegistryWorkSessionPersistence();

  static const String _key = 'registry_work_session_v1';

  Future<RegistryWorkSession?> load() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? raw = preferences.getString(_key);

    if (raw == null || raw.isEmpty) {
      return null;
    }

    final Object? decoded = jsonDecode(raw);

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final RegistryWorkSession session = RegistryWorkSession.fromJson(decoded);

    return session.hasData ? session : null;
  }

  Future<void> saveSection({
    required List<String> pathTitles,
  }) async {
    await _save(
      RegistryWorkSession(
        pathTitles: pathTitles,
        lastPhrase: '',
        updatedAtIso: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> savePhrase({
    required List<String> pathTitles,
    required String phrase,
  }) async {
    await _save(
      RegistryWorkSession(
        pathTitles: pathTitles,
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
