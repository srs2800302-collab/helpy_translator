import 'package:equatable/equatable.dart';

abstract class CanonicalDictionaryEntry extends Equatable {
  const CanonicalDictionaryEntry({
    required this.identity,
    required this.dictionaryId,
    required this.collectionId,
    required this.approvedTextHash,
    required this.sourceDocumentPath,
    required this.sourceRevision,
    required this.sourceSnapshotFingerprint,
    required this.sourceStartLine,
    required this.sourceEndLine,
  });

  final String identity;
  final String dictionaryId;
  final String collectionId;
  final String approvedTextHash;
  final String sourceDocumentPath;
  final String sourceRevision;
  final String sourceSnapshotFingerprint;
  final int sourceStartLine;
  final int sourceEndLine;
}
