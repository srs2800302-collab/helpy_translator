import 'package:flutter/widgets.dart';

final class TranslatorWorkspaceController {
  VoidCallback? _openAccessKeyDialog;

  void openAccessKeyDialog() {
    _openAccessKeyDialog?.call();
  }

  void attachAccessKeyDialog(VoidCallback callback) {
    _openAccessKeyDialog = callback;
  }

  void detachAccessKeyDialog() {
    _openAccessKeyDialog = null;
  }
}
