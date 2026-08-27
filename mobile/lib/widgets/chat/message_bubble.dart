import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../providers/chat_provider.dart';
import 'recipe_mini_card.dart';
import '../../core/network/api_exception.dart';
import 'dart:io';

/// Tek mesaj baloncugu.
///
/// Kullanici SAGDA ve dolu renkli, asistan SOLDA ve yuzey renginde.
/// Baloncuklarin ic kosesi (kullanicida sag ust, asistanda sol ust)
/// kirpilir - konusma yonunu renkten bagimsiz olarak da belli eder,
/// renk koru kullanicilar icin onemli (W4-T09).
class MessageBubble extends ConsumerWidget {
  const MessageBubble({required this.entry, this.onDetectedTap, super.key});

  final ChatEntry entry;

  /// 'Kilerine ekle' butonuna dokununca cagirilir. Onay alt sayfasini
  /// EKRAN acar; baloncuk navigasyon bilmez.
  final ValueChanged<ChatEntry>? onDetectedTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    final bool kullanici = entry.role == ChatRole.user;
    final double enFazlaGenislik = MediaQuery.of(context).size.width * 0.78;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            kullanici ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: enFazlaGenislik),
            child: Opacity(
              // Gonderilirken soluk: 'gitti mi gitmedi mi' belirsizligini
              // ayri bir gosterge koymadan cozer.
              opacity: entry.status == ChatStatus.gonderiliyor ? 0.55 : 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: kullanici
                      ? renkler.primary
                      : renkler.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(kullanici ? 16 : 4),
                    topRight: Radius.circular(kullanici ? 4 : 16),
                    bottomLeft: const Radius.circular(16),
                    bottomRight: const Radius.circular(16),
                  ),
                ),
                                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gonderilen fotografin onizlemesi. Kullanici neyi
                    // yolladigini gormeli - 'gitti mi' belirsizligi kalkar.
                    if (entry.imagePath != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(entry.imagePath!),
                          width: 180,
                          height: 135,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Container(
                            width: 180,
                            height: 135,
                            color: renkler.surfaceContainerHighest,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: renkler.outline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SelectableText(
                      entry.text,
                      style: TextStyle(
                        color:
                            kullanici ? renkler.onPrimary : renkler.onSurface,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // W4-T15: yanit LLM'den degil kural tabanli motordan geldi.
          // NOTR dil: 'asistan coktu' DEMIYORUZ - kullanici onerisini aldi,
          // altyapi arizasi onun sorunu degil. Yalnizca onerinin NEYE gore
          // secildigini soyluyoruz ki beklentisi dogru olsun.
          if (entry.degraded)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    size: 14,
                    color: renkler.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Kilerine göre seçildi',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: renkler.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // Onerilen tarifler: yalnizca asistan yanitinda.
          if (entry.recipeIds.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: enFazlaGenislik + 40),
              child: _MiniKartlar(recipeIds: entry.recipeIds),
            ),

                    // Fotograftan malzeme cikmissa onay yolu (W3-T13).
          if (entry.detected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: () => onDetectedTap?.call(entry),
                icon: const Icon(Icons.kitchen_outlined, size: 18),
                label: Text('${entry.detected.length} malzeme · Kilerine ekle'),
              ),
            ),

          if (entry.status == ChatStatus.hatali)
            _HataSatiri(
              mesaj: entry.hata ?? 'Gönderilemedi.',
              onRetry: () => ref.read(chatProvider.notifier).tekrarDene(entry.id),
            ),
        ],
      ),
    );
  }
}

class _MiniKartlar extends ConsumerWidget {
  const _MiniKartlar({required this.recipeIds});

  final List<String> recipeIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kartlar = ref.watch(recipeCardsProvider(recipeIds.join(',')));

    return kartlar.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 8),
        child: SizedBox(
          height: 2,
          child: LinearProgressIndicator(minHeight: 2),
        ),
      ),
      // Kart verisi cekilemezse METIN yaniti yine duruyor; ekrana hata
      // basmak sohbeti gereksiz kirletirdi.
            // Kart verisi cekilemezse metin yaniti yine duruyor, ama SESSIZ
      // kalmak yanlis: kullanici 'tarif buldum' yazisini gorup kart
      // gormeyince uygulamanin bozuk oldugunu dusunuyor. Kucuk ama
      // GORUNUR bir uyari + yeniden deneme.
      error: (error, _) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 14,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Öneriler yüklenemedi: ${friendlyErrorMessage(error)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
      data: (liste) => liste.isEmpty
          // Sohbet 'tarif buldum' dedi ama kart gelmedi: sessiz kalmak
          // yerine sebebi soyle.
          ? Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Önerilen tarifler bulunamadı.',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final tarif in liste) RecipeMiniCard(recipe: tarif),
              ],
            ),
    );
  }
}

class _HataSatiri extends StatelessWidget {
  const _HataSatiri({required this.mesaj, required this.onRetry});

  final String mesaj;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 16, color: renkler.error),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              mesaj,
              style: TextStyle(fontSize: 12, color: renkler.error),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Yeniden dene'),
          ),
        ],
      ),
    );
  }
}