import 'package:dio/dio.dart';

//backendin {code, message, detail?} gövdesini temsil eden
//dio ters giden her şeyi flutterda exception olarak yapsın diye 
//hem sunucudan gelen hatalarda hem de hiç sunucuya ulaşmayan duurmlar aynı kutuya giriyor

class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.detail,
  });

  //backendin hata kodu sunucuya hiç ulaşmadıysa yerel bir kod kullanılır
  final String code;
  final String message; //kullanıcıya gösterilebilir türkçe metin
  final int? statusCode;
  final Object? detail;

  @override
  String toString() => 'ApiException($code): $message';
}

extension DioExceptionApiError on DioException{
  ApiException get apiException {
    final err = error;
    if (err is ApiException) return err;
    return ApiException(
      code: "unknown_eror", 
      message: message ?? "Beklenmeyen bir hata oluştu.",
    );
  }
}

String friendlyErrorMessage(Object? error) {
  if (error is DioException) return error.apiException.message;
  if (error is ApiException) return error.message;
  return 'Beklenmeyen bir hata oluştur';
}