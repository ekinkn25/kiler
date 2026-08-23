/// POST /chat yanitinin ekranin kullandigi kismi (backend: RagChatResponse).
///
/// DIKKAT 1: bu uc TURKCE alan adlari donuyor (`mesaj`,
/// `onerilen_tarif_idleri`) - modeldeki adlandirma ona uyar.
///
/// DIKKAT 2: projedeki freezed ChatMessage modeli `ChatMessageRead`
/// semasini yansitiyor ve o semayi HICBIR UC donmuyor. Sohbet ekrani
/// bu modeli kullanir, onu degil.
class ChatReply {
  const ChatReply({
    required this.conversationId,
    required this.mesaj,
    this.onerilenTarifIdleri = const [],
    this.uygulananFiltreler = const [],
    this.fromCache = false,
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
    fromCache: json['from_cache'] as bool? ?? false,
  );

  final int conversationId;
  final String mesaj;

  /// Mini kart olarak render edilecek tarifler. Yalnizca KIMLIK gelir;
  /// kart verisi GET /recipes/cards ile cekilir.
  final List<String> onerilenTarifIdleri;

  final List<String> uygulananFiltreler;
  final bool fromCache;
}