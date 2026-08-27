// / POST /chat yanitinin ekranin kullandigi kismi (backend: RagChatResponse).
// /
// / DIKKAT 1: bu uc TURKCE alan adlari donuyor (mesaj`,
// / onerilen_tarif_idleri`) - modeldeki adlandirma ona uyar.
// /
// / DIKKAT 2: projedeki freezed ChatMessage modeli ChatMessageRead`
// / semasini yansitiyor ve o semayi HICBIR UC donmuyor. Sohbet ekrani
// / bu modeli kullanir, onu degil.

import 'detected_ingredient.dart';

class ChatReply {
  const ChatReply({
    required this.conversationId,
    required this.mesaj,
    this.onerilenTarifIdleri = const [],
    this.uygulananFiltreler = const [],
    this.detectedIngredients = const [],
    this.fromCache = false,
    this.degraded = false,
  });

  factory ChatReply.fromJson(Map<String, dynamic> json) => ChatReply(
    conversationId: (json['conversation_id'] as num).toInt(),
    mesaj: json['mesaj'] as String? ?? '',
    onerilenTarifIdleri:
        ((json['onerilen_tarif_idleri'] as List<dynamic>?) ?? const [])
            .cast<String>(),
    uygulananFiltreler:
        ((json['uygulanan_filtreler'] as List<dynamic>?) ?? const [])
            .cast<String>(),
    // Foto eklendiyse gorme modelinin bulduklari. ONAY BEKLER,
    // dogrudan kilere YAZILMAZ (W2-T10 kurali).
    detectedIngredients:
        ((json['detected_ingredients'] as List<dynamic>?) ?? const [])
            .map((e) => DetectedIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
    fromCache: json['from_cache'] as bool? ?? false,
    degraded: json['degraded'] as bool? ?? false
  );

  final int conversationId;
  final String mesaj;
  final List<String> onerilenTarifIdleri;
  final List<String> uygulananFiltreler;
  final List<DetectedIngredient> detectedIngredients;
  final bool fromCache;
  final bool degraded;
}