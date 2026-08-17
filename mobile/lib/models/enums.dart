library;

enum MealType { kahvalti, ogle, aksam, atistirma }

MealType mealTypeFromJson(String value) => switch(value){
  'kahvalti' => MealType.kahvalti,
  'ogle' => MealType.ogle,
  'aksam' => MealType.aksam,
  'atistirma' => MealType.atistirma,
  _ => throw ArgumentError('bilinmeyen meal_typeÇ $value'),
};

String mealTypeToJson(MealType value) => switch (value){
  MealType.kahvalti => 'kahvaltı',
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

enum PantrySource { barkod, foto, tarif, sistem }

PantrySource pantrySourceFromJson(String value) => switch (value) {
  'barkod' => PantrySource.barkod,
  'foto' => PantrySource.foto,
  'tarif' => PantrySource.tarif,
  'sistem' => PantrySource.sistem,
  _ => throw ArgumentError('Bilinmeyen pantry source: $value'),
};

String pantrySourceToJson(PantrySource value) => switch (value) {
  PantrySource.barkod => 'barkod',
  PantrySource.foto => 'foto',
  PantrySource.tarif => 'tarif',
  PantrySource.sistem => 'sistem',
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
  'yapti' => FeedbackAction.yapti,
  _ => throw ArgumentError('Bilinmeyen feedback action: $value'),
};

String feedbackActionToJson(FeedbackAction value) => switch (value) {
  FeedbackAction.gordu => 'gordu',
  FeedbackAction.begendim => 'begendim',
  FeedbackAction.begenmedim => 'begenmedim',
  FeedbackAction.yapacagim => 'yapacagim',
  FeedbackAction.kaydetti => 'kaydetti',
  FeedbackAction.yapti => 'yapti',
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