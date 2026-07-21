import '../../domain/entities/canonical_dictionary.dart';

abstract interface class CanonicalDictionaryLoader {
  Future<CanonicalDictionary> loadDictionary();
}
