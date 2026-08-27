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
  final FocusNode _girisOdak = FocusNode();

  //seçilmiş ama henüz gönderilmemiş foto
  File? _bekleyenFoto;

  @override
  void dispose() {
    _giris.dispose();
    _girisOdak.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Gonderim
  // ---------------------------------------------------------------
  /// Tek gonderim kapisi: bekleyen foto varsa ONA da ekler ve temizler.
  void _gonderMesaj(String metin) {
    final File? dosya = _bekleyenFoto;
    if (metin.trim().isEmpty && dosya == null) return;

    _giris.clear();
    // Foto gonderildi: onizleme kalkmali, yoksa ikinci mesaja da eklenir.
    if (dosya != null) setState(() => _bekleyenFoto = null);

    unawaited(ref.read(chatProvider.notifier).gonder(metin, dosya: dosya));
  }

  void _gonder() => _gonderMesaj(_giris.text);

  /// Hazir cip: KLAVYE ACILMADAN mesaj gonderir (W3-T11 kabul kriteri).
  ///
  /// unfocus() sart: kullanici daha once metin kutusuna dokunmussa klavye
  /// aciktir ve cipe basinca acik kalirdi - 'klavyesiz yol' bozulurdu.
  void _cipSecildi(String soru) {
    FocusScope.of(context).unfocus();
    // Cip de _gonderMesaj'dan geciyor: bekleyen foto varsa o da gider.
    // Ayri yol yazmak, foto eklenmisken cipe basan kullanicinin fotosunu
    // sessizce kaybetmesi demek olurdu.
    _gonderMesaj(soru);
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

      setState(() => _bekleyenFoto = File(secilen.path));
      if (mounted) FocusScope.of(context).requestFocus(_girisOdak);
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
          _bekleyenFotoOnizleme(),
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

    /// Gonderilmeyi bekleyen fotografin onizlemesi.
  ///
  /// Kullanici neyin ekli oldugunu GORMELI: aksi halde fotografin
  /// eklenip eklenmedigini ancak mesaji gonderdikten sonra anlar.
  Widget _bekleyenFotoOnizleme() {
    final File? dosya = _bekleyenFoto;
    if (dosya == null) return const SizedBox.shrink();

    final ColorScheme renkler = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              dosya,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                width: 56,
                height: 56,
                color: renkler.surfaceContainerHighest,
                child: Icon(Icons.broken_image_outlined, color: renkler.outline),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Fotoğraf eklendi — ne sormak istersin?',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: renkler.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _bekleyenFoto = null),
            icon: const Icon(Icons.close),
            tooltip: 'Fotoğrafı kaldır',
          ),
        ],
      ),
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
              onPressed: durum.yaziyor || _bekleyenFoto != null
                ? null
                : () => unawaited(_fotoSec()),
              icon: Icon(
                _bekleyenFoto == null
                    ? Icons.photo_camera_outlined
                    : Icons.check_circle_outline,
              ),
              tooltip: _bekleyenFoto == null ? 'Fotoğraf ekle' : 'Fotoğraf ekli',
            ),
            Expanded(
              child: TextField(
                controller: _giris,
                // Yanit beklenirken yeni mesaj alinmaz: backend konusma
                // sirasini koruyamaz, notifier zaten reddediyor.
                focusNode: _girisOdak,
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
                decoration: InputDecoration(
                  hintText: _bekleyenFoto == null
                    ? 'Bir şey sor...'
                    : 'Fotoğrafla ilgili bir şey sor...',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
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