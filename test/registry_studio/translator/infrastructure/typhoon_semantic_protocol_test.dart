import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';
import 'package:helpy_translator/registry_studio/translator/infrastructure/typhoon/typhoon_semantic_protocol.dart';

void main() {
  group('translation protocol', () {
    test('parses exact five-key translation JSON', () {
      final TranslationBundle bundle = TyphoonSemanticProtocol.parseTranslation(
        content: jsonEncode(<String, Object?>{
          'SOURCE_LANGUAGE': 'RU',
          'SOURCE_TEXT': 'установить варочную панель',
          'RU': 'установить варочную панель',
          'EN': 'install the cooktop',
          'TH': 'ติดตั้งเตาไฟ',
        }),
        expectedSourceText: 'установить варочную панель',
      );

      expect(bundle.sourceLanguage, TranslationLanguage.ru);
      expect(bundle.en, 'install the cooktop');
      expect(bundle.hasReverseDiagnostics, isFalse);
    });

    test('recovers only the missing source-language section', () {
      final TranslationBundle bundle = TyphoonSemanticProtocol.parseTranslation(
        content: jsonEncode(<String, Object?>{
          'SOURCE_LANGUAGE': 'TH',
          'SOURCE_TEXT': 'อย่าติดตั้งเตาอบ',
          'RU': 'не устанавливать духовку',
          'EN': 'do not install the oven',
        }),
        expectedSourceText: 'อย่าติดตั้งเตาอบ',
      );

      expect(bundle.th, 'อย่าติดตั้งเตาอบ');
    });

    test('rejects missing target field and unknown key', () {
      expect(
        () => TyphoonSemanticProtocol.parseTranslation(
          content: jsonEncode(<String, Object?>{
            'SOURCE_LANGUAGE': 'RU',
            'SOURCE_TEXT': 'текст',
            'RU': 'текст',
            'EN': 'text',
          }),
          expectedSourceText: 'текст',
        ),
        throwsA(isA<TyphoonSemanticProtocolException>()),
      );

      expect(
        () => TyphoonSemanticProtocol.parseTranslation(
          content: jsonEncode(<String, Object?>{
            'SOURCE_LANGUAGE': 'RU',
            'SOURCE_TEXT': 'текст',
            'RU': 'текст',
            'EN': 'text',
            'TH': 'ข้อความ',
            'VERDICT': 'EXACT',
          }),
          expectedSourceText: 'текст',
        ),
        throwsA(isA<TyphoonSemanticProtocolException>()),
      );
    });

    test('rejects changed source text and source-language section', () {
      expect(
        () => TyphoonSemanticProtocol.parseTranslation(
          content: jsonEncode(<String, Object?>{
            'SOURCE_LANGUAGE': 'RU',
            'SOURCE_TEXT': 'другой текст',
            'RU': 'другой текст',
            'EN': 'other text',
            'TH': 'ข้อความอื่น',
          }),
          expectedSourceText: 'исходный текст',
        ),
        throwsA(isA<TyphoonSemanticProtocolException>()),
      );

      expect(
        () => TyphoonSemanticProtocol.parseTranslation(
          content: jsonEncode(<String, Object?>{
            'SOURCE_LANGUAGE': 'RU',
            'SOURCE_TEXT': 'исходный текст',
            'RU': 'переписанный текст',
            'EN': 'source text',
            'TH': 'ข้อความต้นฉบับ',
          }),
          expectedSourceText: 'исходный текст',
        ),
        throwsA(isA<TyphoonSemanticProtocolException>()),
      );
    });
  });

  group('general audit protocol', () {
    test('parses three clear pairs', () {
      final List<TranslationPairAudit> audits =
          TyphoonSemanticProtocol.parseGeneralAudit(
            _auditJson(<String, Map<String, Object?>>{
              for (final TranslationPair pair in TranslationPair.values)
                pair.code: <String, Object?>{
                  'RESULT': 'CLEAR',
                  'ISSUES': <Object?>[],
                },
            }),
          );

      expect(audits, hasLength(3));
      expect(
        audits.every(
          (TranslationPairAudit audit) =>
              audit.result == TranslationPairAuditResult.clear,
        ),
        isTrue,
      );
    });

    test('parses lexical gap as unproven', () {
      final List<TranslationPairAudit>
      audits = TyphoonSemanticProtocol.parseGeneralAudit(
        _auditJson(<String, Map<String, Object?>>{
          'RU_EN': <String, Object?>{'RESULT': 'CLEAR', 'ISSUES': <Object?>[]},
          'RU_TH': <String, Object?>{
            'RESULT': 'UNPROVEN',
            'ISSUES': <Object?>[
              <String, Object?>{'ATOM': 'equipment_identity', 'STATUS': 'U'},
            ],
          },
          'EN_TH': <String, Object?>{
            'RESULT': 'UNPROVEN',
            'ISSUES': <Object?>[
              <String, Object?>{'ATOM': 'equipment_identity', 'STATUS': 'U'},
            ],
          },
        }),
      );

      expect(audits[1].result, TranslationPairAuditResult.unproven);
      expect(
        audits[1].issues.single.atom,
        TranslationSemanticAtom.equipmentIdentity,
      );
    });

    test('rejects inconsistent and oversized issue sets', () {
      expect(
        () => TyphoonSemanticProtocol.parseGeneralAudit(
          _auditJson(<String, Map<String, Object?>>{
            'RU_EN': <String, Object?>{
              'RESULT': 'CLEAR',
              'ISSUES': <Object?>[
                <String, Object?>{'ATOM': 'action', 'STATUS': 'X'},
              ],
            },
            'RU_TH': <String, Object?>{
              'RESULT': 'CLEAR',
              'ISSUES': <Object?>[],
            },
            'EN_TH': <String, Object?>{
              'RESULT': 'CLEAR',
              'ISSUES': <Object?>[],
            },
          }),
        ),
        throwsA(isA<TyphoonSemanticProtocolException>()),
      );

      expect(
        () => TyphoonSemanticProtocol.parseGeneralAudit(
          _auditJson(<String, Map<String, Object?>>{
            'RU_EN': <String, Object?>{
              'RESULT': 'BLOCKED',
              'ISSUES': <Object?>[
                <String, Object?>{'ATOM': 'action', 'STATUS': 'X'},
                <String, Object?>{'ATOM': 'object', 'STATUS': 'X'},
                <String, Object?>{'ATOM': 'scope', 'STATUS': 'X'},
              ],
            },
            'RU_TH': <String, Object?>{
              'RESULT': 'CLEAR',
              'ISSUES': <Object?>[],
            },
            'EN_TH': <String, Object?>{
              'RESULT': 'CLEAR',
              'ISSUES': <Object?>[],
            },
          }),
        ),
        throwsA(isA<TyphoonSemanticProtocolException>()),
      );
    });

    test('rejects fragments and model verdict fields', () {
      expect(
        () => TyphoonSemanticProtocol.parseGeneralAudit(
          jsonEncode(<String, Object?>{
            'RU_EN': <String, Object?>{
              'RESULT': 'CLEAR',
              'ISSUES': <Object?>[],
              'REASON': 'same',
            },
            'RU_TH': <String, Object?>{
              'RESULT': 'CLEAR',
              'ISSUES': <Object?>[],
            },
            'EN_TH': <String, Object?>{
              'RESULT': 'CLEAR',
              'ISSUES': <Object?>[],
            },
          }),
        ),
        throwsA(isA<TyphoonSemanticProtocolException>()),
      );
    });
  });

  group('exact certification protocol', () {
    test('parses clear and not-certified responses', () {
      final ExactPairCertification clear =
          TyphoonSemanticProtocol.parseExactCertification(
            content: '{"RESULT":"CLEAR","ATOM":null}',
            pair: TranslationPair.ruEn,
          );
      final ExactPairCertification blocked =
          TyphoonSemanticProtocol.parseExactCertification(
            content: '{"RESULT":"NOT_CERTIFIED","ATOM":"modality"}',
            pair: TranslationPair.ruTh,
          );

      expect(clear.result, ExactCertificationResult.clear);
      expect(clear.atom, isNull);
      expect(blocked.result, ExactCertificationResult.notCertified);
      expect(blocked.atom, TranslationSemanticAtom.modality);
    });

    test('rejects missing atom, unknown pair output and explanations', () {
      expect(
        () => TyphoonSemanticProtocol.parseExactCertification(
          content: '{"RESULT":"NOT_CERTIFIED","ATOM":null}',
          pair: TranslationPair.enTh,
        ),
        throwsA(isA<TyphoonSemanticProtocolException>()),
      );

      expect(
        () => TyphoonSemanticProtocol.parseExactCertification(
          content: '{"RESULT":"CLEAR","ATOM":null,"REASON":"looks correct"}',
          pair: TranslationPair.enTh,
        ),
        throwsA(isA<TyphoonSemanticProtocolException>()),
      );
    });
  });
}

String _auditJson(Map<String, Map<String, Object?>> pairs) {
  return jsonEncode(<String, Object?>{
    for (final TranslationPair pair in TranslationPair.values)
      pair.code: pairs[pair.code],
  });
}
