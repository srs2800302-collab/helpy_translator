import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_registry_document_interpreter.dart';

void main() {
  group('HelpyRegistryDocumentInterpreter', () {
    test('interprets complete recursive Markdown structure', () {
      const String sourceContent =
          '# Registry\n'
          'Root content.\n'
          '\n'
          '## Domain\n'
          'Domain content.\n'
          '\n'
          '### Rule\n'
          'Rule content.\n'
          '\n'
          '## Reference\n'
          'Reference content.\n';

      final List<HelpyRegistryDocumentNode> roots =
          const HelpyRegistryDocumentInterpreter().interpret(sourceContent);

      expect(roots, hasLength(1));

      final HelpyRegistryDocumentNode root = roots.single;
      final HelpyRegistryDocumentNode domain = root.children.first;
      final HelpyRegistryDocumentNode rule = domain.children.single;
      final HelpyRegistryDocumentNode reference = root.children.last;

      expect(root.headingLevel, 1);
      expect(root.path.segments, <String>['Registry']);
      expect(root.startLine, 1);
      expect(root.endLine, 11);
      expect(root.content, 'Root content.');
      expect(root.children, hasLength(2));

      expect(domain.headingLevel, 2);
      expect(domain.path.segments, <String>['Registry', 'Domain']);
      expect(domain.startLine, 4);
      expect(domain.endLine, 9);
      expect(domain.content, 'Domain content.');

      expect(rule.headingLevel, 3);
      expect(rule.path.segments, <String>['Registry', 'Domain', 'Rule']);
      expect(rule.startLine, 7);
      expect(rule.endLine, 9);
      expect(rule.content, 'Rule content.');
      expect(rule.children, isEmpty);

      expect(reference.headingLevel, 2);
      expect(reference.path.segments, <String>['Registry', 'Reference']);
      expect(reference.startLine, 10);
      expect(reference.endLine, 11);
      expect(reference.content, 'Reference content.');

      expect(() => roots.add(root), throwsUnsupportedError);
      expect(() => root.children.clear(), throwsUnsupportedError);
    });

    test('ignores headings inside fenced code and preserves code content', () {
      const String sourceContent =
          '# Registry\n'
          '```text\n'
          '## Not a Registry node\n'
          '```\n'
          '## Real node\n'
          'Real content.\n';

      final List<HelpyRegistryDocumentNode> roots =
          const HelpyRegistryDocumentInterpreter().interpret(sourceContent);

      expect(roots, hasLength(1));
      expect(roots.single.children, hasLength(1));

      expect(
        roots.single.content,
        '```text\n'
        '## Not a Registry node\n'
        '```',
      );

      expect(roots.single.children.single.path.segments, <String>[
        'Registry',
        'Real node',
      ]);
      expect(roots.single.children.single.startLine, 5);
      expect(roots.single.children.single.endLine, 6);
    });

    test('does not create an artificial line for a trailing newline', () {
      const String sourceContent =
          '# Registry\n'
          'Content.\n';

      final List<HelpyRegistryDocumentNode> roots =
          const HelpyRegistryDocumentInterpreter().interpret(sourceContent);

      expect(roots.single.startLine, 1);
      expect(roots.single.endLine, 2);
      expect(roots.single.content, 'Content.');
    });

    test('rejects nonblank content before the first structural heading', () {
      const String sourceContent =
          'Unowned Registry preamble.\n'
          '# Registry\n'
          'Content.\n';

      expect(
        () => const HelpyRegistryDocumentInterpreter().interpret(sourceContent),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects skipped heading levels', () {
      const String sourceContent =
          '# Registry\n'
          '### Skipped level\n';

      expect(
        () => const HelpyRegistryDocumentInterpreter().interpret(sourceContent),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects duplicate full heading paths', () {
      const String sourceContent =
          '# Registry\n'
          '## Rule\n'
          'First.\n'
          '## Rule\n'
          'Second.\n';

      expect(
        () => const HelpyRegistryDocumentInterpreter().interpret(sourceContent),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an unclosed fenced code block', () {
      const String sourceContent =
          '# Registry\n'
          '```text\n'
          '## Hidden heading\n';

      expect(
        () => const HelpyRegistryDocumentInterpreter().interpret(sourceContent),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
