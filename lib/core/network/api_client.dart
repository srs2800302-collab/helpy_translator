import 'package:dio/dio.dart';

import '../config/app_config.dart';

final class ApiClient {
  ApiClient(AppConfig config)
      : dio = Dio(
          BaseOptions(
            baseUrl: config.typhoonBaseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
            headers: <String, String>{
              'Authorization': 'Bearer ${config.typhoonApiKey}',
              'Content-Type': 'application/json',
            },
          ),
        );

  final Dio dio;
}
