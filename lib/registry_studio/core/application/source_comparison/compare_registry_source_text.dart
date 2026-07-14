final class CompareRegistrySourceText {
  const CompareRegistrySourceText();

  String compare({required String source, required String target}) {
    final String normalizedSource = source.trim();
    final String normalizedTarget = target.trim();

    if (normalizedSource.isEmpty) {
      throw ArgumentError.value(
        source,
        'source',
        'Registry source text must not be empty.',
      );
    }

    if (normalizedTarget.isEmpty) {
      throw ArgumentError.value(
        target,
        'target',
        'Registry target text must not be empty.',
      );
    }

    final List<String> sourceLines = normalizedSource
        .split('\n')
        .map(
          (String line) =>
              line.endsWith('\r') ? line.substring(0, line.length - 1) : line,
        )
        .toList(growable: false);
    final List<String> targetLines = normalizedTarget
        .split('\n')
        .map(
          (String line) =>
              line.endsWith('\r') ? line.substring(0, line.length - 1) : line,
        )
        .toList(growable: false);

    final List<List<int>> commonSubsequenceLengths = List<List<int>>.generate(
      sourceLines.length + 1,
      (_) => List<int>.filled(targetLines.length + 1, 0),
      growable: false,
    );

    for (
      int sourceIndex = sourceLines.length - 1;
      sourceIndex >= 0;
      sourceIndex -= 1
    ) {
      for (
        int targetIndex = targetLines.length - 1;
        targetIndex >= 0;
        targetIndex -= 1
      ) {
        commonSubsequenceLengths[sourceIndex][targetIndex] =
            sourceLines[sourceIndex] == targetLines[targetIndex]
            ? commonSubsequenceLengths[sourceIndex + 1][targetIndex + 1] + 1
            : commonSubsequenceLengths[sourceIndex + 1][targetIndex] >=
                  commonSubsequenceLengths[sourceIndex][targetIndex + 1]
            ? commonSubsequenceLengths[sourceIndex + 1][targetIndex]
            : commonSubsequenceLengths[sourceIndex][targetIndex + 1];
      }
    }

    final List<String> result = <String>[];
    int sourceIndex = 0;
    int targetIndex = 0;

    while (sourceIndex < sourceLines.length ||
        targetIndex < targetLines.length) {
      if (sourceIndex < sourceLines.length &&
          targetIndex < targetLines.length &&
          sourceLines[sourceIndex] == targetLines[targetIndex]) {
        result.add('  ${sourceLines[sourceIndex]}');
        sourceIndex += 1;
        targetIndex += 1;
        continue;
      }

      if (targetIndex < targetLines.length &&
          (sourceIndex == sourceLines.length ||
              commonSubsequenceLengths[sourceIndex][targetIndex + 1] >=
                  commonSubsequenceLengths[sourceIndex + 1][targetIndex])) {
        result.add('+ ${targetLines[targetIndex]}');
        targetIndex += 1;
        continue;
      }

      result.add('- ${sourceLines[sourceIndex]}');
      sourceIndex += 1;
    }

    return result.join('\n');
  }
}
