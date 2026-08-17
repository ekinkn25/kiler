import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Dio'nun ham hatalarini {code, message, detail} bicimindeki
/// [ApiException]'a cevirir.
///
/// NEDEN: backend HER hatada {code, message} govdesi doner
/// (app/core/exceptions.py::_error_response). Bu interceptor olmasaydi
/// her ekran kendi try/catch'inde DioException govdesini elle
/// ayristirirdi - tekrar eden, hataya acik kod.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err.copyWith(error: _toApiException(err)));
  }

  ApiException _toApiException(DioException err) {
    final statusCode = err.response?.statusCode;
    final body = err.response?.data;

    if (body is Map<String, dynamic> && body['message'] is String) {
      return ApiException(
        code: (body['code'] as String?) ?? 'unknown_error',
        message: body['message'] as String,
        statusCode: statusCode,
        detail: body['detail'],
      );
    }

    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const ApiException(
          code: 'timeout',
          message: 'Sunucuya ulaşılamadı, bağlantını kontrol et.',
        ),
      DioExceptionType.connectionError => const ApiException(
        code: 'network_error',
        message: 'İnternet bağlantısı yok görünüyor.',
      ),
      _ => ApiException(
        code: 'unknown_error',
        message: 'Beklenmeyen bir hata oluştu.',
        statusCode: statusCode,
      ),
    };
  }
}