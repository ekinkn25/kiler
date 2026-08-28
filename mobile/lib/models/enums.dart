library;

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
enum MealType { kahvalti, ogle, aksam, atistirma }

MealType mealTypeFromJson(String value) => switch(value){
  'kahvalti' => MealType.kahvalti,
  'ogle' => MealType.ogle,
  'aksam' => MealType.aksam,
  'atistirma' => MealType.atistirma,
  _ => throw ArgumentError('bilinmeyen meal_typeÇ $value'),
};

String mealTypeToJson(MealType value) => switch (value){
  MealType.kahvalti => 'kahvalti',
  MealType.ogle => 'ogle',
  MealType.aksam => 'aksam',
  MealType.atistirma => 'atistirma',
};

enum LogSource { manuel, barkod, tarif, foto }

LogSource logSourceFromJson(String value) => switch (value) {
  'manuel' => LogSource.manuel,
  'barkod' => LogSource.barkod,
  'tarif' => LogSource.tarif,
  'foto' => LogSource.foto,
  _ => throw ArgumentError('Bilinmeyen source: $value'),
};

String logSourceToJson(LogSource value) => switch (value) {
  LogSource.manuel => 'manuel',
  LogSource.barkod => 'barkod',
  LogSource.tarif => 'tarif',
  LogSource.foto => 'foto',
};

/// Kilerdeki bir malzemenin bulunma durumuna dair INANC seviyesi.
/// 'var' Dart'ta ayrilmis kelime oldugu icin 'available' adlandirildi.
enum Availability { available, unknown, finished }

Availability availabilityFromJson(String value) => switch (value) {
  'var' => Availability.available,
  'bilinmiyor' => Availability.unknown,
  'bitti' => Availability.finished,
  _ => throw ArgumentError('Bilinmeyen availability: $value'),
};

String availabilityToJson(Availability value) => switch (value) {
  Availability.available => 'var',
  Availability.unknown => 'bilinmiyor',
  Availability.finished => 'bitti',
};

enum PantrySource { barkod, foto, tarif, sistem, manuel}

PantrySource pantrySourceFromJson(String value) => switch (value) {
  'barkod' => PantrySource.barkod,
  'foto' => PantrySource.foto,
  'tarif' => PantrySource.tarif,
  'sistem' => PantrySource.sistem,
  'manuel' => PantrySource.manuel,
  _ => throw ArgumentError('Bilinmeyen pantry source: $value'),
};

String pantrySourceToJson(PantrySource value) => switch (value) {
  PantrySource.barkod => 'barkod',
  PantrySource.foto => 'foto',
  PantrySource.tarif => 'tarif',
  PantrySource.sistem => 'sistem',
  PantrySource.manuel => 'manuel',
};

enum ChatRole { user, assistant }

ChatRole chatRoleFromJson(String value) => switch (value) {
  'user' => ChatRole.user,
  'assistant' => ChatRole.assistant,
  _ => throw ArgumentError('Bilinmeyen chat role: $value'),
};

String chatRoleToJson(ChatRole value) => switch (value) {
  ChatRole.user => 'user',
  ChatRole.assistant => 'assistant',
};

/// Swipe kartinda kullanicinin verdigi geri bildirim eylemi.
enum FeedbackAction { gordu, begendim, begenmedim, yapacagim, kaydetti, yapti }

FeedbackAction feedbackActionFromJson(String value) => switch (value) {
  'gordu' => FeedbackAction.gordu,
  'begendim' => FeedbackAction.begendim,
  'begenmedim' => FeedbackAction.begenmedim,
  'yapacagim' => FeedbackAction.yapacagim,
  'kaydetti' => FeedbackAction.kaydetti,
  'yaptim' => FeedbackAction.yapti,
  _ => throw ArgumentError('Bilinmeyen feedback action: $value'),
};

String feedbackActionToJson(FeedbackAction value) => switch (value) {
  FeedbackAction.gordu => 'gordu',
  FeedbackAction.begendim => 'begendim',
  FeedbackAction.begenmedim => 'begenmedim',
  FeedbackAction.yapacagim => 'yapacagim',
  FeedbackAction.kaydetti => 'kaydetti',
  FeedbackAction.yapti => 'yaptim',
};

/// 'begenmedim' eyleminin sebebi. Diger eylemlerde null.
enum FeedbackReason { sevmedim, cokUzun, malzemeYok }

FeedbackReason feedbackReasonFromJson(String value) => switch (value) {
  'sevmedim' => FeedbackReason.sevmedim,
  'cok_uzun' => FeedbackReason.cokUzun,
  'malzeme_yok' => FeedbackReason.malzemeYok,
  _ => throw ArgumentError('Bilinmeyen feedback reason: $value'),
};

String feedbackReasonToJson(FeedbackReason value) => switch (value) {
  FeedbackReason.sevmedim => 'sevmedim',
  FeedbackReason.cokUzun => 'cok_uzun',
  FeedbackReason.malzemeYok => 'malzeme_yok',
};

/// Malzeme/urun miktar birimleri.
enum UnitCode {
  g, kg, ml, l, adet, paket,
  yemekKasigi, tatliKasigi, cayKasigi, suBardagi, demet, dilim,
}

UnitCode unitCodeFromJson(String value) => switch (value) {
  'g' => UnitCode.g,
  'kg' => UnitCode.kg,
  'ml' => UnitCode.ml,
  'l' => UnitCode.l,
  'adet' => UnitCode.adet,
  'paket' => UnitCode.paket,
  'yemek_kasigi' => UnitCode.yemekKasigi,
  'tatli_kasigi' => UnitCode.tatliKasigi,
  'cay_kasigi' => UnitCode.cayKasigi,
  'su_bardagi' => UnitCode.suBardagi,
  'demet' => UnitCode.demet,
  'dilim' => UnitCode.dilim,
  _ => throw ArgumentError('Bilinmeyen unit code: $value'),
};

String unitCodeToJson(UnitCode value) => switch (value) {
  UnitCode.g => 'g',
  UnitCode.kg => 'kg',
  UnitCode.ml => 'ml',
  UnitCode.l => 'l',
  UnitCode.adet => 'adet',
  UnitCode.paket => 'paket',
  UnitCode.yemekKasigi => 'yemek_kasigi',
  UnitCode.tatliKasigi => 'tatli_kasigi',
  UnitCode.cayKasigi => 'cay_kasigi',
  UnitCode.suBardagi => 'su_bardagi',
  UnitCode.demet => 'demet',
  UnitCode.dilim => 'dilim',
};

// ==================================================================
// Profil enum'lari (backend: app/models/enums.py)
// ==================================================================
//
// @JsonValue NEDEN GEREKLI: bu enum'lar artik IKI yerde kullaniliyor -
// onboarding gonderirken asagidaki elle yazilmis *ToJson fonksiyonlariyla,
// AppUser.profile okunurken json_serializable tarafindan. Annotasyon
// olmadan json_serializable enum'u ADIYLA kodlar ('cokYuksek'), oysa
// backend 'cok_yuksek' bekler. Elle yazilmis fonksiyonlar bundan
// ETKILENMEZ; ikisi yan yana calisir.

enum Gender {
  @JsonValue('erkek') erkek,
  @JsonValue('kadin') kadin,
  @JsonValue('belirtilmedi') belirtilmedi,
}

String genderToJson(Gender value) => switch (value) {
  Gender.erkek => 'erkek',
  Gender.kadin => 'kadin',
  Gender.belirtilmedi => 'belirtilmedi',
};

/// AppUser.profile.gender NULLABLE oldugu icin ayri sarmalayici.
///
/// json_serializable nullable bir alanda toJson fonksiyonunun da null
/// kabul etmesini bekliyor. Yukaridaki genderToJson non-nullable ve
/// onboarding onu kullaniyor - imzasini DEGISTIRMIYORUZ, sariyoruz.
String? genderToJsonNullable(Gender? value) =>
    value == null ? null : genderToJson(value);

/// Bilinmeyen deger veya null -> null. COKMEZ.
///
/// NEDEN: /auth/me uygulama her acilista cagriliyor
/// (auth_provider._restoreSession). ArgumentError firlatan bir cozumde,
/// backend'e yarin yeni bir cinsiyet degeri eklenirse eski surumdeki
/// uygulama splash ekraninda kilitlenirdi.
Gender? genderFromJson(Object? value) => switch (value) {
  'erkek' => Gender.erkek,
  'kadin' => Gender.kadin,
  'belirtilmedi' => Gender.belirtilmedi,
  _ => null,
};

enum ActivityLevel {
  @JsonValue('sedanter') sedanter,
  @JsonValue('hafif') hafif,
  @JsonValue('orta') orta,
  @JsonValue('yuksek') yuksek,
  @JsonValue('cok_yuksek') cokYuksek,
}

String activityLevelToJson(ActivityLevel value) => switch (value) {
  ActivityLevel.sedanter => 'sedanter',
  ActivityLevel.hafif => 'hafif',
  ActivityLevel.orta => 'orta',
  ActivityLevel.yuksek => 'yuksek',
  ActivityLevel.cokYuksek => 'cok_yuksek',
};

enum Goal {
  @JsonValue('kilo_verme') kiloVerme,
  @JsonValue('koruma') koruma,
  @JsonValue('kilo_alma') kiloAlma,
}

String goalToJson(Goal value) => switch (value) {
  Goal.kiloVerme => 'kilo_verme',
  Goal.koruma => 'koruma',
  Goal.kiloAlma => 'kilo_alma',
};

// ---------------------------------------------------------------- gosterim
extension GenderGosterim on Gender {
  String get etiket => switch (this) {
    Gender.erkek => 'Erkek',
    Gender.kadin => 'Kadın',
    Gender.belirtilmedi => 'Belirtilmedi',
  };
}

extension ActivityLevelGosterim on ActivityLevel {
  String get etiket => switch (this) {
    ActivityLevel.sedanter => 'Hareketsiz',
    ActivityLevel.hafif => 'Hafif aktif',
    ActivityLevel.orta => 'Orta aktif',
    ActivityLevel.yuksek => 'Çok aktif',
    ActivityLevel.cokYuksek => 'Aşırı aktif',
  };
}

extension GoalGosterim on Goal {
  String get etiket => switch (this) {
    Goal.kiloVerme => 'Kilo verme',
    Goal.koruma => 'Kiloyu koruma',
    Goal.kiloAlma => 'Kilo alma',
  };

  IconData get ikon => switch (this) {
    Goal.kiloVerme => Icons.trending_down,
    Goal.koruma => Icons.trending_flat,
    Goal.kiloAlma => Icons.trending_up,
  };
}