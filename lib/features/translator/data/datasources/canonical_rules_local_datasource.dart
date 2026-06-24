import 'package:flutter/services.dart';

abstract interface class CanonicalRulesLocalDataSource {
  Future<List<String>> loadClientRules();
}

final class CanonicalRulesLocalDataSourceImpl
    implements CanonicalRulesLocalDataSource {
  const CanonicalRulesLocalDataSourceImpl();

  @override
  Future<List<String>> loadClientRules() async {
    final String content = await rootBundle.loadString(
      'assets/canonical_client_rules_ru.txt',
    );

    return content
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);
  }
}
