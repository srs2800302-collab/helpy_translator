import '../domain/entities/canonical_dictionary.dart';
import '../domain/entities/canonical_dictionary_entry.dart';
import '../domain/entities/canonical_phrase_entry.dart';
import '../domain/entities/canonical_phrase_vocabulary.dart';

final class BuildCanonicalPhraseVocabulary {
  const BuildCanonicalPhraseVocabulary();

  CanonicalPhraseVocabulary call(CanonicalDictionary dictionary) {
    final List<CanonicalPhraseEntry> phraseEntries = <CanonicalPhraseEntry>[];

    for (final collection in dictionary.collections) {
      for (final CanonicalDictionaryEntry entry in collection.entries) {
        if (entry is CanonicalPhraseEntry) {
          phraseEntries.add(entry);
        }
      }
    }

    return CanonicalPhraseVocabulary(entries: phraseEntries);
  }
}
