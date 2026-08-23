import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../core/network/multipart_helper.dart';
import '../models/chat_reply.dart';
import '../models/enums.dart';
import '../models/recipe_mini.dart';

/// Bir mesajin gonderim durumu.
enum ChatStatus { gonderiliyor, tamam, hatali }

/// Ekranda gorunen tek mesaj.
@immutable
class ChatEntry {
  const ChatEntry({
    required this.id,
    required this.role,
    required this.text,
    this.recipeIds = const [],
    this.status = ChatStatus.tamam,
    this.hata,
  });

  /// YEREL kimlik. Backend basarisiz istekte hicbir kimlik donmez; ama
  /// 'Yeniden dene' hangi mesaji tekrar gonderecegini bilmek ZORUNDA.
  final String id;

  final ChatRole role;
  final String text;

  /// Asistan yanitindaki onerilen tarifler (mini kart olarak cizilir).
  final List<String> recipeIds;

  final ChatStatus status;
  final String? hata;

  /// Durum degistirir. copyWith YERINE bu var: standart copyWith'te
  /// `hata: null` 'degistirme' anlamina gelir, bizim ise hatayi
  /// TEMIZLEMEMIZ gerekiyor (yeniden denerken).
  ChatEntry durumla(ChatStatus yeniDurum, {String? hata}) => ChatEntry(
    id: id,
    role: role,
    text: text,
    recipeIds: recipeIds,
    status: yeniDurum,
    hata: hata,
  );
}

@immutable
class ChatState {
  const ChatState({
    this.entries = const [],
    this.yaziyor = false,
    this.conversationId,
  });

  final List<ChatEntry> entries;

  /// Asistan yaniti bekleniyor -> 'yaziyor...' gostergesi.
  final bool yaziyor;

  /// Ilk yanitla gelir, sonraki her istekte gonderilir ki backend AYNI
  /// konusmaya yazsin. Gonderilmezse her mesaj yeni sohbet acar ve
  /// baglam kaybolur.
  final int? conversationId;

  ChatState copyWith({
    List<ChatEntry>? entries,
    bool? yaziyor,
    int? conversationId,
  }) => ChatState(
    entries: entries ?? this.entries,
    yaziyor: yaziyor ?? this.yaziyor,
    // conversationId yalnizca SET edilir, hic temizlenmez.
    conversationId: conversationId ?? this.conversationId,
  );
}

/// Sohbet durumu.
///
/// autoDispose DEGIL: kullanici Kesfet'e gecip Sohbet'e dondugunde
/// konusma kaybolmamali. Backend'de sohbet gecmisi okuma ucu YOK, yani
/// state kaybolursa konusma geri getirilemez.
class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  Future<void> gonder(String metin) async {
    final temiz = metin.trim();
    // Yanit beklenirken ikinci mesaj gonderilirse konusma sirasi bozulur.
    if (temiz.isEmpty || state.yaziyor) return;

    final girdi = ChatEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: ChatRole.user,
      text: temiz,
      status: ChatStatus.gonderiliyor,
    );
    state = state.copyWith(entries: [...state.entries, girdi], yaziyor: true);
    await _istekAt(girdi);
  }

  /// Basarisiz bir mesaji AYNI kimlikle yeniden gonderir; listede
  /// kopyasi olusmaz.
  Future<void> tekrarDene(String entryId) async {
    if (state.yaziyor) return;

    final girdi = state.entries.where((e) => e.id == entryId).firstOrNull;
    if (girdi == null) return;

    _durumYaz(entryId, ChatStatus.gonderiliyor);
    state = state.copyWith(yaziyor: true);
    await _istekAt(girdi);
  }

  Future<void> _istekAt(ChatEntry girdi) async {
    try {
      final dio = ref.read(dioProvider);
      // Uc JSON DEGIL multipart/form-data bekliyor (Form alanlari).
      // Duz JSON gonderilirse 422 doner.
      final form = await MultipartHelper.chatForm(
        message: girdi.text,
        conversationId: state.conversationId,
      );
      final response = await dio.post<Map<String, dynamic>>('/chat', data: form);
      final yanit = ChatReply.fromJson(response.data!);

      state = state.copyWith(
        entries: [
          for (final e in state.entries)
            if (e.id == girdi.id) e.durumla(ChatStatus.tamam) else e,
          ChatEntry(
            id: '${girdi.id}-yanit',
            role: ChatRole.assistant,
            text: yanit.mesaj,
            recipeIds: yanit.onerilenTarifIdleri,
          ),
        ],
        yaziyor: false,
        conversationId: yanit.conversationId,
      );
    } catch (hata) {
      // Mesaj listede KALIR ve 'hatali' isaretlenir; kullanici metni
      // yeniden yazmak zorunda kalmasin diye silmiyoruz.
      _durumYaz(girdi.id, ChatStatus.hatali, hata: friendlyErrorMessage(hata));
      state = state.copyWith(yaziyor: false);
    }
  }

  void _durumYaz(String id, ChatStatus durum, {String? hata}) {
    state = state.copyWith(
      entries: [
        for (final e in state.entries)
          if (e.id == id) e.durumla(durum, hata: hata) else e,
      ],
    );
  }
}

final chatProvider =
    NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

/// Kimlik listesi -> mini kart verisi.
///
/// family anahtari VIRGULLE BIRLESTIRILMIS METIN: List String anahtar
/// olamaz, cunku Riverpod family degerlerini == ile karsilastirir; iki
/// ayri liste asla esit sayilmaz ve her build yeni istek atardi.
final recipeCardsProvider =
    FutureProvider.autoDispose.family<List<RecipeMini>, String>((ref, ids) async {
  if (ids.isEmpty) return const [];

  // Baloncuk ekrandan cikip geri gelince (uzun sohbette kaydirma)
  // ayni kartlar tekrar cekilmesin.
  ref.keepAlive();

  final dio = ref.read(dioProvider);
  final response = await dio.get<List<dynamic>>(
    '/recipes/cards',
    queryParameters: {'ids': ids},
  );
  return response.data!
      .map((e) => RecipeMini.fromJson(e as Map<String, dynamic>))
      .toList();
});