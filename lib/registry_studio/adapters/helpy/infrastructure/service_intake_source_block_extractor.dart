import 'service_intake_identity_manifest_source.dart';

typedef ServiceIntakeSourceBlock = ({
  ServiceIntakeIdentityManifestEntry identity,
  int startLine,
  int endLine,
  String sourceText,
});

typedef _IndexedHeading = ({
  int position,
  int lineNumber,
  int startOffset,
  int level,
  String title,
});

typedef _SourceIndex = ({List<_IndexedHeading> headings, int lineCount});

final class ServiceIntakeSourceBlockExtractor {
  const ServiceIntakeSourceBlockExtractor();

  static final RegExp _headingPattern = RegExp(r'^(#{1,6})\s+(.+?)\s*$');

  List<ServiceIntakeSourceBlock> extract({
    required String source,
    required Iterable<ServiceIntakeIdentityManifestEntry> identities,
  }) {
    if (source.trim().isEmpty) {
      throw const FormatException(
        'Service intake registry source must not be empty.',
      );
    }

    final List<ServiceIntakeIdentityManifestEntry> manifestEntries = identities
        .toList(growable: false);

    if (manifestEntries.isEmpty) {
      throw ArgumentError.value(
        identities,
        'identities',
        'Service intake source extraction requires manifest entries.',
      );
    }

    final _SourceIndex sourceIndex = _indexSource(source);
    final List<_IndexedHeading> headings = sourceIndex.headings;

    final Map<(int, String), List<_IndexedHeading>> headingsByIdentity =
        <(int, String), List<_IndexedHeading>>{};

    for (final _IndexedHeading heading in headings) {
      headingsByIdentity
          .putIfAbsent((
            heading.level,
            heading.title,
          ), () => <_IndexedHeading>[])
          .add(heading);
    }

    final List<ServiceIntakeSourceBlock> blocks = <ServiceIntakeSourceBlock>[];

    for (final ServiceIntakeIdentityManifestEntry identity in manifestEntries) {
      if (identity.ownerHeadingLevel != 2 || identity.headingLevel != 3) {
        throw const FormatException(
          'Service intake source extraction requires '
          'an H2 owner and an H3 entity locator.',
        );
      }

      final List<_IndexedHeading> ownerMatches =
          headingsByIdentity[(
            identity.ownerHeadingLevel,
            identity.ownerHeading,
          )] ??
          <_IndexedHeading>[];

      if (ownerMatches.length != 1) {
        throw FormatException(
          'Service intake owner heading "${identity.ownerHeading}" '
          'must resolve exactly once; found ${ownerMatches.length}.',
        );
      }

      final _IndexedHeading owner = ownerMatches.single;
      int ownerBoundaryPosition = headings.length;

      for (
        int position = owner.position + 1;
        position < headings.length;
        position += 1
      ) {
        if (headings[position].level <= owner.level) {
          ownerBoundaryPosition = position;
          break;
        }
      }

      final List<_IndexedHeading> entityMatches =
          (headingsByIdentity[(identity.headingLevel, identity.heading)] ??
                  <_IndexedHeading>[])
              .where(
                (_IndexedHeading heading) =>
                    heading.position > owner.position &&
                    heading.position < ownerBoundaryPosition,
              )
              .toList(growable: false);

      if (entityMatches.length != 1) {
        throw FormatException(
          'Service intake entity heading "${identity.heading}" '
          'within owner "${identity.ownerHeading}" '
          'must resolve exactly once; found ${entityMatches.length}.',
        );
      }

      final _IndexedHeading entity = entityMatches.single;
      int boundaryPosition = headings.length;

      for (
        int position = entity.position + 1;
        position < headings.length;
        position += 1
      ) {
        if (headings[position].level <= entity.level) {
          boundaryPosition = position;
          break;
        }
      }

      if (boundaryPosition > ownerBoundaryPosition) {
        boundaryPosition = ownerBoundaryPosition;
      }

      final int endOffset = boundaryPosition < headings.length
          ? headings[boundaryPosition].startOffset
          : source.length;

      final int endLine = boundaryPosition < headings.length
          ? headings[boundaryPosition].lineNumber - 1
          : sourceIndex.lineCount;

      if (endLine < entity.lineNumber || endOffset <= entity.startOffset) {
        throw FormatException(
          'Service intake entity "${identity.entityId.value}" '
          'resolved to an invalid source range.',
        );
      }

      blocks.add((
        identity: identity,
        startLine: entity.lineNumber,
        endLine: endLine,
        sourceText: source.substring(entity.startOffset, endOffset),
      ));
    }

    _ensureNonOverlappingRanges(blocks);

    return List<ServiceIntakeSourceBlock>.unmodifiable(blocks);
  }

  _SourceIndex _indexSource(String source) {
    final List<_IndexedHeading> headings = <_IndexedHeading>[];

    int lineStart = 0;
    int lineNumber = 1;
    int lineCount = 0;

    while (lineStart < source.length) {
      final int newlineOffset = source.indexOf('\n', lineStart);
      final int lineEnd = newlineOffset == -1 ? source.length : newlineOffset;

      String line = source.substring(lineStart, lineEnd);

      if (line.endsWith('\r')) {
        line = line.substring(0, line.length - 1);
      }

      lineCount = lineNumber;

      final RegExpMatch? match = _headingPattern.firstMatch(line.trim());

      if (match != null) {
        headings.add((
          position: headings.length,
          lineNumber: lineNumber,
          startOffset: lineStart,
          level: match.group(1)!.length,
          title: match.group(2)!.trim(),
        ));
      }

      if (newlineOffset == -1) {
        break;
      }

      lineStart = newlineOffset + 1;
      lineNumber += 1;
    }

    return (
      headings: List<_IndexedHeading>.unmodifiable(headings),
      lineCount: lineCount,
    );
  }

  void _ensureNonOverlappingRanges(List<ServiceIntakeSourceBlock> blocks) {
    final List<ServiceIntakeSourceBlock> ordered = blocks.toList()
      ..sort(
        (ServiceIntakeSourceBlock left, ServiceIntakeSourceBlock right) =>
            left.startLine.compareTo(right.startLine),
      );

    for (int index = 1; index < ordered.length; index += 1) {
      final ServiceIntakeSourceBlock previous = ordered[index - 1];
      final ServiceIntakeSourceBlock current = ordered[index];

      if (current.startLine <= previous.endLine) {
        throw FormatException(
          'Service intake source ranges must not overlap: '
          '${previous.identity.entityId.value} and '
          '${current.identity.entityId.value}.',
        );
      }
    }
  }
}
