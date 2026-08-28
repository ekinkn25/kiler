import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hata/guvenli.dart';
import '../../core/validators.dart';
import '../../models/kilo_kaydi.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/hata_gorunumu.dart';
import '../../widgets/kilo_grafigi.dart';
import '../../widgets/profil_parcalari.dart';

/// Kilo gecmisi: ozet + grafik + kayit listesi.
///
/// NEDEN AYRI EKRAN: profil ekrani "su an neredeyim"i anlatiyor, burasi
/// "nereden geldim"i. Ikisi ayni sayfada olsaydi profil ekrani kaydirma
/// gerektiren bir rapora donerdi.
class KiloGecmisiScreen extends ConsumerWidget {
  const KiloGecmisiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gecmis = ref.watch(kiloGecmisiProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kilo Geçmişi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(_kiloEkleAc(context, ref)),
        icon: const Icon(Icons.add),
        label: const Text('Kilo ekle'),
      ),
      body: gecmis.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (hata, _) => HataDurumu(
          hata: hata,
          baslik: 'Kilo geçmişi yüklenemedi',
          onTekrar: () =>
              unawaited(ref.read(kiloGecmisiProvider.notifier).yenile()),
        ),
        data: (kayitlar) => kayitlar.isEmpty
            ? Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: _AralikSecici(),
                  ),
                  Expanded(
                    child: EmptyState(
                      icon: Icons.monitor_weight_outlined,
                      title: 'Bu aralıkta kayıt yok',
                      message:
                          'Kilonu girdikçe burada değişim grafiğin oluşur.',
                      actionLabel: 'Kilo ekle',
                      actionIcon: Icons.add,
                      onAction: () => unawaited(_kiloEkleAc(context, ref)),
                    ),
                  ),
                ],
              )
            : _Govde(kayitlar: kayitlar),
      ),
    );
  }
}

class _Govde extends ConsumerWidget {
  const _Govde({required this.kayitlar});

  final List<KiloKaydi> kayitlar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme renkler = Theme.of(context).colorScheme;

    final ilk = kayitlar.first.kiloKg;
    final son = kayitlar.last.kiloKg;
    final fark = son - ilk;

    return ListView(
      // Alt bosluk FAB'in listenin son satirini ortmemesi icin.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        const _AralikSecici(),
        const SizedBox(height: 12),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${son.toStringAsFixed(1)} kg',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _FarkRozeti(fark: fark),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${kayitlar.length} kayıt · en son ${tarihMetni(kayitlar.last.gun)}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: renkler.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              KiloGrafigi(kayitlar: kayitlar),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Kayıtlar',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        // Liste YENIDEN ESKIYE: kullanici son girdigi kaydi en ustte arar.
        // Grafik ise eskiden yeniye - orada zaman soldan saga akar.
        for (var i = kayitlar.length - 1; i >= 0; i--)
          _KayitSatiri(
            kayit: kayitlar[i],
            // Bir onceki (daha ESKI) kayda gore fark; ilk kayitta yok.
            oncekiKilo: i == 0 ? null : kayitlar[i - 1].kiloKg,
          ),
      ],
    );
  }
}

/// 30 / 90 / 365 gun.
class _AralikSecici extends ConsumerWidget {
  const _AralikSecici();

  static const _secenekler = {30: '30 gün', 90: '3 ay', 365: '1 yıl'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secili = ref.watch(kiloAraligiProvider);
    return SegmentedButton<int>(
      segments: [
        for (final giris in _secenekler.entries)
          ButtonSegment(value: giris.key, label: Text(giris.value)),
      ],
      selected: {secili},
      showSelectedIcon: false,
      onSelectionChanged: (secim) =>
          ref.read(kiloAraligiProvider.notifier).state = secim.first,
    );
  }
}

/// '-2.4 kg' / '+1.1 kg' rozeti.
///
/// NEDEN YESIL/KIRMIZI DEGIL: kilo vermek herkes icin 'iyi' degil - kilo
/// almayi hedefleyen kullanicida yesil dusus yaniltici olurdu. Yon notr
/// bir okla anlatiliyor, deger yorumlanmiyor.
class _FarkRozeti extends StatelessWidget {
  const _FarkRozeti({required this.fark});

  final double fark;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    final durgun = fark.abs() < 0.05;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: renkler.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            durgun
                ? Icons.trending_flat
                : (fark < 0 ? Icons.south_east : Icons.north_east),
            size: 14,
            color: renkler.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            durgun
                ? 'değişim yok'
                : '${fark > 0 ? '+' : ''}${fark.toStringAsFixed(1)} kg',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: renkler.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _KayitSatiri extends ConsumerWidget {
  const _KayitSatiri({required this.kayit, this.oncekiKilo});

  final KiloKaydi kayit;
  final double? oncekiKilo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    final delta = oncekiKilo == null ? null : kayit.kiloKg - oncekiKilo!;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text('${kayit.kiloKg.toStringAsFixed(1)} kg'),
      subtitle: Text(tarihMetni(kayit.gun)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (delta != null && delta.abs() >= 0.05)
            Text(
              '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: renkler.onSurfaceVariant),
            ),
          IconButton(
            tooltip: 'Sil',
            icon: Icon(Icons.delete_outline, color: renkler.outline),
            onPressed: () => unawaited(_sil(context, ref)),
          ),
        ],
      ),
    );
  }

  Future<void> _sil(BuildContext context, WidgetRef ref) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kayıt silinsin mi?'),
        content: Text(
          '${tarihMetni(kayit.gun)} · ${kayit.kiloKg.toStringAsFixed(1)} kg\n\n'
          'Profildeki güncel kilon değişmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (onay != true || !context.mounted) return;

    await guvenliCalistir(
      () => ref.read(kiloGecmisiProvider.notifier).sil(kayit.id),
      etiket: 'kilo.sil',
      context: context,
      onEk: 'Silinemedi:',
    );
  }
}

// ====================================================================
// Kilo ekleme kagidi
// ====================================================================
Future<void> _kiloEkleAc(BuildContext context, WidgetRef ref) async {
  // Varsayilan olarak profildeki guncel kilo yaziliyor: kullanicinin
  // gireceği deger neredeyse her zaman ona YAKIN bir sayi.
  final mevcut = ref.read(authProvider).valueOrNull?.profile?.weightKg;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _KiloEkleSheet(baslangic: mevcut),
  );
}

class _KiloEkleSheet extends ConsumerStatefulWidget {
  const _KiloEkleSheet({this.baslangic});

  final double? baslangic;

  @override
  ConsumerState<_KiloEkleSheet> createState() => _KiloEkleSheetState();
}

class _KiloEkleSheetState extends ConsumerState<_KiloEkleSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kilo = TextEditingController(
    text: widget.baslangic?.toStringAsFixed(1) ?? '',
  );
  DateTime _gun = DateTime.now();
  bool _kaydediliyor = false;

  @override
  void dispose() {
    _kilo.dispose();
    super.dispose();
  }

  Future<void> _tarihSec() async {
    final bugun = DateTime.now();
    final secilen = await showDatePicker(
      context: context,
      initialDate: _gun,
      firstDate: bugun.subtract(const Duration(days: 730)),
      // GELECEGE kayit yok: henuz olmamis bir gunun kilosu girilemez.
      lastDate: bugun,
    );
    if (secilen != null) setState(() => _gun = secilen);
  }

  Future<void> _kaydet() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _kaydediliyor = true);
    final sonuc = await guvenliCalistir(
      () => ref.read(kiloGecmisiProvider.notifier).ekle(
        kiloKg: ondalikCoz(_kilo.text)!,
        gun: _gun,
      ),
      etiket: 'kilo.ekle',
      context: context,
      onEk: 'Kaydedilemedi:',
    );

    if (!mounted) return;
    if (sonuc == null) {
      setState(() => _kaydediliyor = false);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bugunMu = _ayniGun(_gun, DateTime.now());

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kilo ekle',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _kilo,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Kilo',
                suffixText: 'kg',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: kiloValidator,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _kaydediliyor ? null : () => unawaited(_tarihSec()),
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(bugunMu ? 'Bugün' : tarihMetni(_gun)),
            ),
            const SizedBox(height: 8),
            Text(
              bugunMu
                  ? 'Profilindeki kilo ve kalori hedefin de güncellenir.'
                  : 'Geçmiş bir gün: profilindeki güncel kilo değişmez.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _kaydediliyor ? null : _kaydet,
              child: _kaydediliyor
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

bool _ayniGun(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
