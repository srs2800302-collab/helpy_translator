import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/features/translator/domain/entities/semantic_observation.dart';

void main() {
  test('relation codes round-trip without phrase-specific rules', () {
    for (final SemanticRelation value in SemanticRelation.values) {
      expect(SemanticRelation.parseCode(value.code), value);
    }
  });

  test('dimension codes round-trip without phrase-specific rules', () {
    for (final SemanticDimension value in SemanticDimension.values) {
      expect(SemanticDimension.parseCode(value.code), value);
    }
  });

  test('preservation codes round-trip', () {
    for (final MeaningPreservation value in MeaningPreservation.values) {
      expect(MeaningPreservation.parseCode(value.code), value);
    }
  });

  test('unrecognized codes remain unknown', () {
    expect(
      SemanticRelation.parseCode('UNRECOGNIZED_RELATION'),
      SemanticRelation.unknown,
    );
    expect(
      SemanticDimension.parseCode('UNRECOGNIZED_DIMENSION'),
      SemanticDimension.unknown,
    );
    expect(
      MeaningPreservation.parseCode('UNRECOGNIZED_PRESERVATION'),
      MeaningPreservation.unknown,
    );
  });

  test('code normalization is deterministic', () {
    expect(normalizeSemanticCode(' lexical-choice '), 'LEXICAL_CHOICE');
    expect(normalizeSemanticCode('scope.change'), 'SCOPE_CHANGE');
  });
}
