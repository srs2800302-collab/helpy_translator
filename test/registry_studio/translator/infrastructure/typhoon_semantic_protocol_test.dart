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

    test('rejects a missing source-language section', () {
      expect(
        () => TyphoonSemanticProtocol.parseTranslation(
          content: jsonEncode(<String, Object?>{
            'SOURCE_LANGUAGE': 'TH',
            'SOURCE_TEXT': 'อย่าติดตั้งเตาอบ',
            'RU': 'не устанавливать духовку',
            'EN': 'do not install the oven',
          }),
          expectedSourceText: 'อย่าติดตั้งเตาอบ',
        ),
        throwsA(isA<TyphoonSemanticProtocolException>()),
      );
    });

    test('preserves accepted provider strings exactly', () {
      const String source = 'Маркер  RU — №17';
      const String en = 'Provider  EN — #17';
      const String th = 'ผู้ให้บริการ  TH — 17';

      final TranslationBundle bundle = TyphoonSemanticProtocol.parseTranslation(
        content: jsonEncode(<String, Object?>{
          'SOURCE_LANGUAGE': 'RU',
          'SOURCE_TEXT': source,
          'RU': source,
          'EN': en,
          'TH': th,
        }),
        expectedSourceText: source,
      );

      expect(bundle.sourceText, source);
      expect(bundle.ru, source);
      expect(bundle.en, en);
      expect(bundle.th, th);
    });

    test('rejects changed source and unknown fields', () {
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
  });

  group('general audit protocol', () {
    test('parses three clear pairs', () {
      final List<TranslationPairAudit> audits =
          TyphoonSemanticProtocol.parseGeneralAudit(
            content: _auditJson(<String, Map<String, Object?>>{
              for (final TranslationPair pair in TranslationPair.values)
                pair.code: <String, Object?>{
                  'RESULT': 'CLEAR',
                  'ISSUES': <Object?>[],
                },
            }),
            bundle: _bundle(),
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

    test('preserves lexical-gap evidence and short reason', () {
      final List<TranslationPairAudit> audits =
          TyphoonSemanticProtocol.parseGeneralAudit(
            content: _auditJson(<String, Map<String, Object?>>{
              'RU_EN': <String, Object?>{
                'RESULT': 'CLEAR',
                'ISSUES': <Object?>[],
              },
              'RU_TH': <String, Object?>{
                'RESULT': 'UNPROVEN',
                'ISSUES': <Object?>[
                  <String, Object?>{
                    'ATOM': 'equipment_identity',
                    'STATUS': 'U',
                    'LEFT': 'варочную панель',
                    'RIGHT': 'เตาไฟ',
                    'REASON': 'broader Thai equipment term',
                  },
                ],
              },
              'EN_TH': <String, Object?>{
                'RESULT': 'UNPROVEN',
                'ISSUES': <Object?>[
                  <String, Object?>{
                    'ATOM': 'equipment_identity',
                    'STATUS': 'U',
                    'LEFT': 'cooktop',
                    'RIGHT': 'เตาไฟ',
                    'REASON': 'exact equipment identity is not proven',
                  },
                ],
              },
            }),
            bundle: _bundle(),
          );

      final TranslationPairIssue issue = audits[1].issues.single;
      expect(issue.atom, TranslationSemanticAtom.equipmentIdentity);
      expect(issue.status, TranslationIssueStatus.unknown);
      expect(issue.left, 'варочную панель');
      expect(issue.right, 'เตาไฟ');
      expect(issue.reason, 'broader Thai equipment term');
    });

    test('rejects non-substring evidence and ambiguity X', () {
      expect(
        () => TyphoonSemanticProtocol.parseGeneralAudit(
          content: _auditJson(<String, Map<String, Object?>>{
            'RU_EN': <String, Object?>{
              'RESULT': 'BLOCKED',
              'ISSUES': <Object?>[
                <String, Object?>{
                  'ATOM': 'object',
                  'STATUS': 'X',
                  'LEFT': 'несуществующий фрагмент',
                  'RIGHT': 'cooktop',
                  'REASON': 'different objects',
                },
              ],
            },
            'RU_TH': _clearPair(),
            'EN_TH': _clearPair(),
          }),
          bundle: _bundle(),
        ),
        throwsA(isA<TyphoonSemanticProtocolException>()),
      );

      expect(
        () => TyphoonSemanticProtocol.parseGeneralAudit(
          content: _auditJson(<String, Map<String, Object?>>{
            'RU_EN': <String, Object?>{
              'RESULT': 'BLOCKED',
              'ISSUES': <Object?>[
                <String, Object?>{
                  'ATOM': 'ambiguity',
                  'STATUS': 'X',
                  'LEFT': 'варочную панель',
                  'RIGHT': 'cooktop',
                  'REASON': 'unresolved reading',
                },
              ],
            },
            'RU_TH': _clearPair(),
            'EN_TH': _clearPair(),
          }),
          bundle: _bundle(),
        ),
        throwsA(isA<TyphoonSemanticProtocolException>()),
      );
    });
  });

  group('global exact challenger protocol', () {
    test('parses clear and evidence-bearing unproven responses', () {
      final ExactChallenge clear = TyphoonSemanticProtocol.parseExactChallenge(
        content: '{"RESULT":"CLEAR","DISQUALIFIERS":[]}',
        bundle: _bundle(),
      );
      final ExactChallenge unproven =
          TyphoonSemanticProtocol.parseExactChallenge(
            content: jsonEncode(<String, Object?>{
              'RESULT': 'UNPROVEN',
              'DISQUALIFIERS': <Object?>[
                <String, Object?>{
                  'PAIR': 'EN_TH',
                  'ATOM': 'equipment_identity',
                  'STATUS': 'U',
                  'LEFT': 'cooktop',
                  'RIGHT': 'เตาไฟ',
                  'REASON': 'exact equipment identity is not proven',
                },
              ],
            }),
            bundle: _bundle(),
          );

      expect(clear.result, ExactChallengeResult.clear);
      expect(clear.disqualifiers, isEmpty);
      expect(unproven.result, ExactChallengeResult.unproven);
      expect(unproven.disqualifiers.single.pair, TranslationPair.enTh);
      expect(
        unproven.disqualifiers.single.atom,
        TranslationSemanticAtom.equipmentIdentity,
      );
    });

    test('rejects unknown pair, invalid fragment and verbose reason', () {
      expect(
        () => TyphoonSemanticProtocol.parseExactChallenge(
          content: jsonEncode(<String, Object?>{
            'RESULT': 'BLOCKED',
            'DISQUALIFIERS': <Object?>[
              <String, Object?>{
                'PAIR': 'EN_RU',
                'ATOM': 'object',
                'STATUS': 'X',
                'LEFT': 'cooktop',
                'RIGHT': 'варочную панель',
                'REASON': 'different objects',
              },
            ],
          }),
          bundle: _bundle(),
        ),
        throwsA(isA<TyphoonSemanticProtocolException>()),
      );

      expect(
        () => TyphoonSemanticProtocol.parseExactChallenge(
          content: jsonEncode(<String, Object?>{
            'RESULT': 'UNPROVEN',
            'DISQUALIFIERS': <Object?>[
              <String, Object?>{
                'PAIR': 'RU_TH',
                'ATOM': 'equipment_identity',
                'STATUS': 'U',
                'LEFT': 'варочную панель',
                'RIGHT': 'เตาอบ',
                'REASON': 'identity not proven',
              },
            ],
          }),
          bundle: _bundle(),
        ),
        throwsA(isA<TyphoonSemanticProtocolException>()),
      );

      expect(
        () => TyphoonSemanticProtocol.parseExactChallenge(
          content: jsonEncode(<String, Object?>{
            'RESULT': 'UNPROVEN',
            'DISQUALIFIERS': <Object?>[
              <String, Object?>{
                'PAIR': 'RU_TH',
                'ATOM': 'equipment_identity',
                'STATUS': 'U',
                'LEFT': 'варочную панель',
                'RIGHT': 'เตาไฟ',
                'REASON': List<String>.filled(19, 'word').join(' '),
              },
            ],
          }),
          bundle: _bundle(),
        ),
        throwsA(isA<TyphoonSemanticProtocolException>()),
      );
    });
  });
}

TranslationBundle _bundle() {
  return TranslationBundle(
    sourceLanguage: TranslationLanguage.ru,
    sourceText: 'установить варочную панель',
    ru: 'установить варочную панель',
    en: 'install the cooktop',
    th: 'ติดตั้งเตาไฟ',
  );
}

Map<String, Object?> _clearPair() {
  return <String, Object?>{'RESULT': 'CLEAR', 'ISSUES': <Object?>[]};
}

String _auditJson(Map<String, Map<String, Object?>> pairs) {
  return jsonEncode(<String, Object?>{'PAIR_RESULTS': pairs});
}
