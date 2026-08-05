import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/features/translator/data/network/strict_json_object_parser.dart';
import 'package:helpy_translator/features/translator/domain/errors/translator_exception.dart';

void main() {
  const StrictJsonObjectParser parser = StrictJsonObjectParser();

  test('parses one JSON object and an optional single JSON fence', () {
    expect(parser.parse('{"translation":"Hello"}'), <String, Object?>{
      'translation': 'Hello',
    });
    expect(
      parser.parse('```json\n{"translation":"สวัสดี"}\n```'),
      <String, Object?>{'translation': 'สวัสดี'},
    );
  });

  test('rejects prose around JSON', () {
    expect(
      () => parser.parse('Result: {"translation":"Hello"}'),
      throwsA(
        isA<TranslatorException>().having(
          (TranslatorException error) => error.kind,
          'kind',
          TranslatorFailureKind.invalidResponse,
        ),
      ),
    );
  });

  test('rejects arrays and malformed JSON', () {
    expect(() => parser.parse('[]'), throwsA(isA<TranslatorException>()));
    expect(
      () => parser.parse('{"translation":'),
      throwsA(isA<TranslatorException>()),
    );
  });
}
