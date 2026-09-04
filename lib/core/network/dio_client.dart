import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';
import '../constants/storage_keys.dart';

/// Dio setup + interceptors (auth, logging) — PROMPT_SPEC.md §2.1 & §2.2.
/// Retry policy belum diimplementasi di sini (menyusul pas integrasi backend
/// beneran, CPMK 5) — untuk sekarang interceptor cuma nyisipin Bearer token
/// dan nge-log error biar gampang di-debug.
class DioClient {
  DioClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: StorageKeys.accessToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // ignore: avoid_print
          print(
            '[DioClient] ${error.requestOptions.method} ${error.requestOptions.path} '
            '-> ${error.response?.statusCode ?? error.type}',
          );
          handler.next(error);
        },
      ),
    );
  }

  final FlutterSecureStorage _secureStorage;
  late final Dio _dio;

  Dio get dio => _dio;
}
