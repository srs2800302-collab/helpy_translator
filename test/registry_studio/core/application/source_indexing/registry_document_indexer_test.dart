import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/source_indexing/registry_document_indexer.dart';
import 'package:helpy_translator/registry_studio/core/application/source_indexing/registry_document_node.dart';

void main() {
  const RegistryDocumentIndexer indexer = RegistryDocumentIndexer();

  group('RegistryDocumentIndexer', () {
    test(
      'indexes complete hierarchy with skipped levels and exact sections',
      () {
        const String source =
            'Document preamble\n'
            '# Registry\n'
            'Root text\n'
            '## Domain A\n'
            'Domain text\n'
            '#### Deep item\n'
            'Deep text\n'
            '### Direct item\n'
            'Direct text\n'
            '## Domain B\n'
            'Final text\n';

        final List<RegistryDocumentNode> roots = indexer.index(source);

        expect(roots, hasLength(1));

        final RegistryDocumentNode registry = roots.single;
        final RegistryDocumentNode domainA = registry.children.first;
        final RegistryDocumentNode deepItem = domainA.children.first;
        final RegistryDocumentNode directItem = domainA.children.last;
        final RegistryDocumentNode domainB = registry.children.last;

        expect(registry.title, 'Registry');
        expect(registry.headingLevel, 1);
        expect(registry.headingPath, <String>['Registry']);
        expect(registry.startLine, 2);
        expect(registry.endLine, 11);
        expect(
          registry.sourceText,
          '# Registry\n'
          'Root text\n'
          '## Domain A\n'
          'Domain text\n'
          '#### Deep item\n'
          'Deep text\n'
          '### Direct item\n'
          'Direct text\n'
          '## Domain B\n'
          'Final text\n',
        );

        expect(domainA.headingPath, <String>['Registry', 'Domain A']);
        expect(domainA.startLine, 4);
        expect(domainA.endLine, 9);

        expect(deepItem.headingPath, <String>[
          'Registry',
          'Domain A',
          'Deep item',
        ]);
        expect(deepItem.startLine, 6);
        expect(deepItem.endLine, 7);
        expect(deepItem.sourceText, '#### Deep item\nDeep text\n');

        expect(directItem.headingPath, <String>[
          'Registry',
          'Domain A',
          'Direct item',
        ]);
        expect(directItem.startLine, 8);
        expect(directItem.endLine, 9);

        expect(domainB.headingPath, <String>['Registry', 'Domain B']);
        expect(domainB.startLine, 10);
        expect(domainB.endLine, 11);
      },
    );

    test('preserves duplicate titles under different parents', () {
      const String source =
          '# Registry\n'
          '## First\n'
          '### Rules\n'
          'first\n'
          '## Second\n'
          '### Rules\n'
          'second\n';

      final RegistryDocumentNode registry = indexer.index(source).single;

      final RegistryDocumentNode firstRules =
          registry.children.first.children.single;
      final RegistryDocumentNode secondRules =
          registry.children.last.children.single;

      expect(firstRules.title, 'Rules');
      expect(firstRules.headingPath, <String>['Registry', 'First', 'Rules']);
      expect(secondRules.title, 'Rules');
      expect(secondRules.headingPath, <String>['Registry', 'Second', 'Rules']);
      expect(firstRules.startLine, 3);
      expect(secondRules.startLine, 6);
    });

    test('preserves CRLF source text and trailing newline', () {
      const String source =
          '# Registry\r\n'
          '## Section\r\n'
          'content\r\n';

      final RegistryDocumentNode registry = indexer.index(source).single;
      final RegistryDocumentNode section = registry.children.single;

      expect(registry.startLine, 1);
      expect(registry.endLine, 3);
      expect(registry.sourceText, source);

      expect(section.startLine, 2);
      expect(section.endLine, 3);
      expect(section.sourceText, '## Section\r\ncontent\r\n');
    });

    test('ignores heading syntax inside backtick and tilde fences', () {
      const String source =
          '# Registry\n'
          '```markdown\n'
          '## Not a section\n'
          '```\n'
          '## Real section\n'
          '~~~\n'
          '### Also not a section\n'
          '~~~\n'
          'content\n';

      final RegistryDocumentNode registry = indexer.index(source).single;

      expect(registry.children, hasLength(1));
      expect(registry.children.single.title, 'Real section');
      expect(registry.children.single.children, isEmpty);
      expect(registry.children.single.startLine, 5);
      expect(registry.children.single.endLine, 9);
    });

    test('ignores text before the first heading', () {
      const String source =
          'Preamble line one\n'
          'Preamble line two\n'
          '## First section\n'
          'content\n';

      final RegistryDocumentNode section = indexer.index(source).single;

      expect(section.title, 'First section');
      expect(section.startLine, 3);
      expect(section.endLine, 4);
      expect(section.sourceText, '## First section\ncontent\n');
    });

    test('returns an empty index when the document has no headings', () {
      final List<RegistryDocumentNode> nodes = indexer.index(
        'Plain Registry text\nwithout Markdown headings.\n',
      );

      expect(nodes, isEmpty);
      expect(
        () => nodes.add(
          RegistryDocumentNode(
            title: 'Synthetic',
            headingLevel: 1,
            headingPath: const <String>['Synthetic'],
            startLine: 1,
            endLine: 1,
            sourceText: '# Synthetic',
            children: const <RegistryDocumentNode>[],
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('rejects an empty document', () {
      expect(() => indexer.index(' \r\n '), throwsFormatException);
    });

    test('returns immutable heading paths and child collections', () {
      const String source =
          '# Registry\n'
          '## Section\n'
          'content\n';

      final RegistryDocumentNode registry = indexer.index(source).single;
      final RegistryDocumentNode section = registry.children.single;

      expect(() => registry.children.add(section), throwsUnsupportedError);
      expect(() => section.headingPath.add('Mutation'), throwsUnsupportedError);
    });
  });
}
