import '../../domain/entities/registry_analysis_history_entry.dart';

abstract interface class RegistryAnalysisHistoryStore {
  Future<List<RegistryAnalysisHistoryEntry>> loadHistory();

  Future<void> appendHistoryEntry(RegistryAnalysisHistoryEntry entry);
}
