import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_exception.dart';
import '../../providers/chat_provider.dart';
import '../../providers/pantry_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../widgets/chat/detected_ingredients_sheet.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/suggestion_chips.dart';
import '../../widgets/chat/typing_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/chat/shot_guide.dart';

/// SOHBET sekmesi (W3-T10 + T11 + T12 + T13).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _giris = TextEditingController();
  final ImagePicker _secici = ImagePicker();

  @override
  void dispose() {
    _giris.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Gonderim
  // ---------------------------------------------------------------

  void _gonder({File? dosya}) {
    final metin = _giris.text;
    if (metin.trim().isEmpty && dosya == null) return;
    _giris.clear();
    unawaited(ref.read(chatProvider.notifier).gonder(metin, dosya: dosya));
  }

  /// Hazir cip: KLAVYE ACILMADAN mesaj gonderir (W3-T11 kabul kriteri).
  ///
  /// unfocus() sart: kullanici daha once metin kutusuna dokunmussa klavye
  /// aciktir ve cipe basinca acik kalirdi - 'klavyesiz yol' bozulurdu.
  void _cipSecildi(String soru) {
    FocusScope.of(context).unfocus();
    unawaited(ref.read(chatProvider.notifier).gonder(soru));
  }

  // ---------------------------------------------------------------
  // Fotograf (W3-T12)
  // ---------------------------------------------------------------

  Future<void> _fotoSec() async {
    // Klavye aciksa alt sayfayi ortuyor.
    FocusScope.of(context).unfocus();

    final kaynak = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cekim rehberi: 'malzemeleri tezgaha yay, ustten cek'.
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 4),
              child: ShotGuide(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                'Malzemeleri tezgaha yay, üstten çek',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden seç'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (kaynak == null) return;

    try {
      // SIKISTIRMA BURADA: ayri bir paket (flutter_image_compress)
      // gerekmiyor. maxWidth 1600 + kalite %80, 3 MB'lik bir fotografi
      // tipik olarak 500 KB altina indirir - yukleme suresi ve gorme
      // modeli maliyeti bu iki parametreye bagli.
      final XFile? secilen = await _secici.pickImage(
        source: kaynak,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (secilen == null || !mounted) return;

      _gonder(dosya: File(secilen.path));
    } catch (hata) {
      if (!mounted) return;
      _bilgi('Fotoğraf alınamadı: ${friendlyErrorMessage(hata)}');
    }
  }

  // ---------------------------------------------------------------
  // Malzeme onayi (W3-T13)
  // ---------------------------------------------------------------

  Future<void> _malzemeleriOnayla(ChatEntry girdi) async {
    final secilenler = await showDetectedIngredientsSheet(
      context,
      tespitler: girdi.detected,
    );
    if (secilenler == null || secilenler.isEmpty || !mounted) return;

    try {
      final adet = await ref
          .read(pantryConfirmServiceProvider)
          .kilereEkle(secilenler);
      if (!mounted) return;

      // Kiler sekmesi tazelensin.
      ref.invalidate(pantryProvider);
      // Kesfet YENIDEN skorlansin: kiler degisti, eski oneriler bayat.
      // Yeni oturum ayni zamanda daha once gorulen tarifleri de geri
      // getirir - kullanici 'oneriler degisti' etkisini burada gorur.
      unawaited(ref.read(swipeDeckProvider.notifier).oturumuSifirla());

      _bilgi('$adet malzeme kilerine eklendi.');
    } catch (hata) {
      if (!mounted) return;
      _bilgi('Kilere eklenemedi: ${friendlyErrorMessage(hata)}');
    }
  }

  void _bilgi(String mesaj) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mesaj), duration: const Duration(seconds: 3)),
      );
  }

  // ---------------------------------------------------------------
  // Gorunum
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final durum = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sohbet'), centerTitle: false),
      body: Column(
        children: [
          Expanded(
            child: durum.entries.isEmpty && !durum.yaziyor
                ? EmptyState(
                    icon: Icons.chat_bubble_outline,
                    illustrated: true,
                    title: 'Bugün ne yesen?',
                    message: 'Kilerine göre tarif önerebilirim.',
                    footer: SuggestionChips(onSecildi: _cipSecildi),
                  )
                : _mesajListesi(durum),
          ),
          if (durum.yuklemeOrani != null)
            LinearProgressIndicator(value: durum.yuklemeOrani, minHeight: 3),
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
  /// zamanlamasi yuzunden kirilgandir.
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
        return MessageBubble(
          entry: durum.entries[gercekIndex],
          onDetectedTap: (girdi) => unawaited(_malzemeleriOnayla(girdi)),
        );
      },
    );
  }

  Widget _girisCubugu(ChatState durum) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              // Dokunma alani 48dp'nin altina dusmesin (W4-T09).
              onPressed: durum.yaziyor ? null : () => unawaited(_fotoSec()),
              icon: const Icon(Icons.photo_camera_outlined),
              tooltip: 'Fotoğraf ekle',
            ),
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
              onPressed: durum.yaziyor ? null : () => _gonder(),
              icon: const Icon(Icons.send),
              tooltip: 'Gönder',
            ),
          ],
        ),
      ),
    );
  }
}