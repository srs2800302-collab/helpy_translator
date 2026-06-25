import 'dart:io';

import 'package:flutter/services.dart';

import 'background_execution_controller.dart';

final class AndroidForegroundServiceController
    implements BackgroundExecutionController {
  const AndroidForegroundServiceController();

  static const MethodChannel _channel = MethodChannel(
    'helpy_translator/background_execution',
  );

  @override
  Future<void> start({
    required String title,
    required String message,
  }) async {
    if (!Platform.isAndroid) {
      return;
    }

    await _channel.invokeMethod<void>(
      'startForegroundService',
      <String, String>{
        'title': title,
        'message': message,
      },
    );
  }

  @override
  Future<void> stop() async {
    if (!Platform.isAndroid) {
      return;
    }

    await _channel.invokeMethod<void>('stopForegroundService');
  }
}
