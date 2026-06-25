abstract interface class BackgroundExecutionController {
  Future<void> start({
    required String title,
    required String message,
  });

  Future<void> stop();
}
