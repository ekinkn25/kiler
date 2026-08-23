import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_provider.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/typing_indicator.dart';
import '../../widgets/empty_state.dart';

/// SOHBET sekmesi (W3-T10).
///
/// Hazir soru cipleri W3-T11'de, fotograf ekleme W3-T12'de, malzeme
/// onayi W3-T13'te eklenecek.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _giris = TextEditingController();

  @override
  void dispose() {
    _giris.dispose();
    super.dispose();
  }

  void _gonder() {
    final metin = _giris.text;
    if (metin.trim().isEmpty) return;
    _giris.clear();
    unawaited(ref.read(chatProvider.notifier).gonder(metin));
  }

  @override
  Widget build(BuildContext context) {
    final durum = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sohbet'), centerTitle: false),
      body: Column(
        children: [
          Expanded(
            child: durum.entries.isEmpty && !durum.yaziyor
                ? const EmptyState(
                    icon: Icons.chat_bubble_outline,
                    illustrated: true,
                    title: 'Bugün ne yesen?',
                    message:
                        'Kilerine göre tarif önerebilirim. "Hafif bir şey öner" '
                        'ya da "30 dakikada ne yaparım?" diye sorabilirsin.',
                  )
                : _mesajListesi(durum),
          ),
          _girisCubugu(durum),
        ],
      ),
    );
  }

  /// TERS liste (reverse: true).
  ///
  /// NEDEN ScrollController + animateTo DEGIL: ters listede en yeni mesaj
  /// zaten en altta olur ve liste orada durur. Kaydirma denetleyicisiyle
  /// yapilan cozum klavye acilmasi, gorsel yuklenmesi ve yerlesim
  /// zamanlamasi yuzunden kirilgandir - bir kare gec kalirsa kullanici
  /// yeni mesaji goremez. Ters liste bu hata sinifinin tamamini yok eder.
  Widget _mesajListesi(ChatState durum) {
    final int toplam = durum.entries.length + (durum.yaziyor ? 1 : 0);

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      itemCount: toplam,
      itemBuilder: (context, i) {
        // reverse: true -> index 0 EN ALTTAKI ogedir.
        if (durum.yaziyor && i == 0) return const TypingIndicator();

        final int kaydirma = durum.yaziyor ? 1 : 0;
        final int gercekIndex = durum.entries.length - 1 - (i - kaydirma);
        return MessageBubble(entry: durum.entries[gercekIndex]);
      },
    );
  }

  Widget _girisCubugu(ChatState durum) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _giris,
                // Yanit beklenirken yeni mesaj alinmaz: backend konusma
                // sirasini koruyamaz, notifier zaten reddediyor.
                enabled: !durum.yaziyor,
                minLines: 1,
                maxLines: 4,
                // Backend siniri: message max_length=500.
                maxLength: 500,
                buildCounter: (
                  context, {
                  required int currentLength,
                  required bool isFocused,
                  int? maxLength,
                }) => null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _gonder(),
                decoration: const InputDecoration(
                  hintText: 'Bir şey sor...',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: durum.yaziyor ? null : _gonder,
              icon: const Icon(Icons.send),
              tooltip: 'Gönder',
            ),
          ],
        ),
      ),
    );
  }
}