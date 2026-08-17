import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

/// Fotograf yukleme uclarina (vision/ingredients, vision/meal, chat)
/// dosya eklerken TEKRAR TEKRAR ayni MultipartFile/FormData kurulumunu
/// yazmamak icin tek yardimci.
///
/// NEDEN content-type ELLE VERILIYOR: backend yalnizca image/jpeg,
/// image/png, image/webp kabul ediyor (ALLOWED_IMAGE_TYPES,
/// app/services/vision/base.py). dio content-type'i dosya uzantisindan
/// OTOMATIK CIKARMAZ - yanlis/eksik content-type backend'den 415 doner.
abstract final class MultipartHelper {
  /// Bir fotograf dosyasini [fieldName] adiyla MultipartFile'a cevirir.
  static Future<MultipartFile> imageFile(
    File file, {
    String fieldName = 'file',
  }) async {
    return MultipartFile.fromFile(
      file.path,
      filename: _fileName(file.path),
      contentType: _mediaTypeFor(file.path),
    );
  }

  /// Sadece foto goturen uclar icin (POST /vision/ingredients, /vision/meal).
  static Future<FormData> singleImageForm(File file) async {
    return FormData.fromMap({'file': await imageFile(file)});
  }

  /// Metin + opsiyonel foto goturen sohbet ucu icin (POST /chat).
  static Future<FormData> chatForm({
    required String message,
    int? conversationId,
    File? file,
  }) async {
    return FormData.fromMap({
      'message': message,
      'conversation_id': ?conversationId,
      if (file != null) 'file': await imageFile(file),
    });
  }

  static String _fileName(String path) {
    final normalized = path.replaceAll(r'\', '/');
    return normalized.split('/').last;
  }

  static MediaType _mediaTypeFor(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      _ => MediaType('image', 'jpeg'), // jpg/jpeg varsayilan
    };
  }
}