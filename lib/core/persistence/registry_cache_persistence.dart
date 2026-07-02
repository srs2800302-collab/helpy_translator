import 'package:shared_preferences/shared_preferences.dart';

final class RegistryCachePersistence {
  const RegistryCachePersistence();

  static const String _key = 'registry_markdown_cache_v1';

  Future<String?> load() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    final String? value = preferences.getString(_key);

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value;
  }

  Future<void> save(String markdown) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.setString(_key, markdown);
  }

  Future<void> clear() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.remove(_key);
  }
}
