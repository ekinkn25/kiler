import 'package:dio/dio.dart';
//dosya yükleme indirme işlemlerini kolaylaştırır, istekleri iptal etme özellikleri, form verilerini (FormData) rahatça gönderir, Interceptor mantığını destekler, uygulama <-> backend arası iletişimi sağlar

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

//backende giden tüm isteklerin tek çıkış noktası

final dioProvider = Provider<Dio>((ref){
  //riverpod state management(durum kütüphanesi) kullanılarak mimari karar verildi: 
  //Singleton pattern = her sayfada dio objesi kurmaktansa Provider kurarız uygulama ömrü boyunca sadece tek bir dio nesnesi yarat her sayfa aynı nesneyi kullansın
  final dio = Dio(
    BaseOptions(
      //backende atılacak tüm isteklerin ortak kuralları
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.requestTimeout, //int yavaş / sunucu çökmüş
      receiveTimeout: AppConfig.requestTimeout, //bağlantı kuruldu fakat data inerken belirli sürede inmez ise işlemi iptal etmek için
    ),
  );

  final storage = ref.watch(secureStorageProvider);
  dio.interceptors.add(
    AuthInterceptor(storage: storage, baseUrl: AppConfig.apiBaseUrl),
  );
  dio.interceptors.add(ErrorInterceptor());

  if (AppConfig.debugLogging){
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
      //istek backende gitmeden hemen önce veya backendden cevap cihaza dönmeden hemen önce araya girip işlem yapmanı sağlar
      //backendde hangi json verisi gönderdiğimi ve backendden hangi json cevabı döndiğini console'a yazdırır
    );
  }
  
  // Auth başlığını ekleyen interceptor, secyre_storagedan toke nokuyacak şekilde auth ekranı görevinde buraya eklenecek
  return dio;
});