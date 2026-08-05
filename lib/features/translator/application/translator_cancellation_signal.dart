import '../domain/errors/translator_exception.dart';

final class TranslatorCancellationSignal {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }

  void throwIfCancelled() {
    if (_isCancelled) {
      throw const TranslatorException(
        TranslatorFailureKind.cancelled,
        'Translation was cancelled.',
      );
    }
  }
}
