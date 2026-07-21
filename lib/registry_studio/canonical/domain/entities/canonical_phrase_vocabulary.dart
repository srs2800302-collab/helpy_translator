import 'package:equatable/equatable.dart';

import 'canonical_phrase_entry.dart';

final class CanonicalPhraseVocabulary extends Equatable {
  factory CanonicalPhraseVocabulary({
    required Iterable<CanonicalPhraseEntry> entries,
  }) {
    final List<CanonicalPhraseEntry> normalizedEntries = entries.toList(
      growable: false,
    );

    final Set<String> entryIdentities = <String>{};

    for (final CanonicalPhraseEntry entry in normalizedEntries) {
      if (!entryIdentities.add(entry.identity)) {
        throw ArgumentError.value(
          entry.identity,
          'entries',
          'Canonical phrase identities must be unique.',
        );
      }
    }

    return CanonicalPhraseVocabulary._(
      entries: List<CanonicalPhraseEntry>.unmodifiable(normalizedEntries),
    );
  }

  const CanonicalPhraseVocabulary._({required this.entries});

  final List<CanonicalPhraseEntry> entries;

  int get uniquePhraseCount {
    return entries
        .map((CanonicalPhraseEntry entry) => entry.phrase)
        .toSet()
        .length;
  }

  List<CanonicalPhraseEntry> entriesForCollection(String collectionId) {
    final String normalizedCollectionId = collectionId.trim();

    return List<CanonicalPhraseEntry>.unmodifiable(
      entries.where(
        (CanonicalPhraseEntry entry) =>
            entry.collectionId == normalizedCollectionId,
      ),
    );
  }

  List<CanonicalPhraseEntry> entriesForExactPhrase(String phrase) {
    final String normalizedPhrase = phrase.trim();

    return List<CanonicalPhraseEntry>.unmodifiable(
      entries.where(
        (CanonicalPhraseEntry entry) => entry.phrase == normalizedPhrase,
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[entries];
}
