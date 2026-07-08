import 'engineering_workflow_confirmation.dart';
import 'engineering_workflow_instance.dart';

final class EngineeringOrchestrator {
  const EngineeringOrchestrator();

  EngineeringWorkflowInstance startConfirmedWorkflow({
    required String workflowInstanceId,
    required EngineeringWorkflowConfirmation confirmation,
    required String activeRuntimeCompositionFingerprint,
  }) {
    return EngineeringWorkflowInstance.started(
      workflowInstanceId: workflowInstanceId,
      workflow: confirmation.workflow,
      activeRuntimeCompositionFingerprint: activeRuntimeCompositionFingerprint,
      runtimeAuditReferences: _runtimeAuditReferencesFor(confirmation),
    );
  }
}

List<String> _runtimeAuditReferencesFor(
  EngineeringWorkflowConfirmation confirmation,
) {
  final List<String> references = <String>[
    confirmation.confirmationReference,
    ...confirmation.runtimeAuditReferences,
  ];

  final Set<String> seen = <String>{};
  final List<String> unique = <String>[];

  for (final String reference in references) {
    if (seen.add(reference)) {
      unique.add(reference);
    }
  }

  return List<String>.unmodifiable(unique);
}
