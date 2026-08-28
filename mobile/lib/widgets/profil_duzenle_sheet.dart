import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/hata/guvenli.dart';
import '../core/validators.dart';
import '../models/app_user.dart';
import '../models/enums.dart';
import '../providers/auth_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/profile_provider.dart';

/// Profil duzenleme kagidini acar. Kaydedildiyse true doner.
///
/// NEDEN TAM EKRAN DEGIL: kullanicinin buraya gelme sebebi neredeyse her
/// zaman TEK bir sayi - kilosu. Tam ekran bir form icin rota tanimlamak,
/// geri tusu davranisini dusunmek ve ekrani terk ettirmek fazla agirdi.
Future<bool> profilDuzenleAc(BuildContext context, UserProfile mevcut) async {
  final sonuc = await showModalBottomSheet<bool>(
    context: context,
    // isScrollControlled: klavye acilinca kagit yukari kayar ve alanlar
    // gorunur kalir. Olmadan kilo alani klavyenin altinda kalirdi.
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => ProfilDuzenleSheet(mevcut: mevcut),
  );
  return sonuc ?? false;
}

class ProfilDuzenleSheet extends ConsumerStatefulWidget {
  const ProfilDuzenleSheet({required this.mevcut, super.key});

  final UserProfile mevcut;

  @override
  ConsumerState<ProfilDuzenleSheet> createState() => _ProfilDuzenleSheetState();
}

class _ProfilDuzenleSheetState extends ConsumerState<ProfilDuzenleSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kilo;
  late final TextEditingController _boy;

  late ActivityLevel _aktivite = widget.mevcut.activityLevel;
  late Goal _hedef = widget.mevcut.goal;
  late int _hane = widget.mevcut.householdSize;

  bool _kaydediliyor = false;

  @override
  void initState() {
    super.initState();
    _kilo = TextEditingController(
      text: widget.mevcut.weightKg?.toStringAsFixed(1) ?? '',
    );
    _boy = TextEditingController(
      text: widget.mevcut.heightCm?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _kilo.dispose();
    _boy.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final yeniKilo = ondalikCoz(_kilo.text);
    final yeniBoy = ondalikCoz(_boy.text);

    // YALNIZCA DEGISENI GONDER: PATCH'in amaci bu. Hepsini gondermek
    // sunucuda gereksiz yeniden hesap ve her kaydetmede yeni bir kilo
    // gunlugu satiri demek olurdu.
    final kiloDegisti = yeniKilo != null && yeniKilo != widget.mevcut.weightKg;
    final boyDegisti = yeniBoy != null && yeniBoy != widget.mevcut.heightCm;
    final aktiviteDegisti = _aktivite != widget.mevcut.activityLevel;
    final hedefDegisti = _hedef != widget.mevcut.goal;
    final haneDegisti = _hane != widget.mevcut.householdSize;

    final degisiklikVar = kiloDegisti || boyDegisti || aktiviteDegisti ||
        hedefDegisti || haneDegisti;
    if (!degisiklikVar) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _kaydediliyor = true);

    final profil = await guvenliCalistir(
      () => ref.read(profilServisiProvider).guncelle(
        kiloKg: kiloDegisti ? yeniKilo : null,
        boyCm: boyDegisti ? yeniBoy : null,
        aktivite: aktiviteDegisti ? _aktivite : null,
        hedef: hedefDegisti ? _hedef : null,
        haneBuyuklugu: haneDegisti ? _hane : null,
      ),
      etiket: 'profil.guncelle',
      context: context,
      onEk: 'Kaydedilemedi:',
    );

    if (!mounted) return;
    if (profil == null) {
      // guvenliCalistir kullaniciya mesaji ZATEN gosterdi; kagit acik
      // kalsin ki girilen degerler kaybolmasin.
      setState(() => _kaydediliyor = false);
      return;
    }

    ref.read(authProvider.notifier).profiliDegistir(profil);
    // Kalori ekrani hedefi sunucudan aliyor; hedef degistiyse halka eski
    // sayiyi gostermeye devam etmesin.
    ref.invalidate(dailySummaryProvider);
    if (kiloDegisti) ref.invalidate(kiloGecmisiProvider);

    // Messenger pop'tan ONCE alinir: pop sonrasi bu kagidin context'i
    // agactan dusuyor ve ScaffoldMessenger.of(context) patlardi.
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(true);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
          'Güncellendi · günlük hedefin '
          '${profil.dailyCalorieTarget.toStringAsFixed(0)} kcal',
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;

    return Padding(
      // viewInsets: klavyenin kapladigi yukseklik. Kagidin ic bosluguna
      // eklenmezse 'Kaydet' butonu klavyenin altinda kalir.
      padding: EdgeInsets.fromLTRB(
        20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ölçülerini güncelle',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Kalori ve makro hedeflerin bu değerlere göre yeniden hesaplanır.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: renkler.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _kilo,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Kilo',
                        suffixText: 'kg',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      validator: kiloValidator,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _boy,
                      decoration: const InputDecoration(
                        labelText: 'Boy',
                        suffixText: 'cm',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: boyValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const _Etiket('Hedefin'),
              Wrap(
                spacing: 8,
                children: [
                  for (final h in Goal.values)
                    ChoiceChip(
                      avatar: Icon(h.ikon, size: 18),
                      label: Text(h.etiket),
                      selected: _hedef == h,
                      onSelected: (_) => setState(() => _hedef = h),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              const _Etiket('Aktivite seviyen'),
              Wrap(
                spacing: 8,
                children: [
                  for (final a in ActivityLevel.values)
                    ChoiceChip(
                      label: Text(a.etiket),
                      selected: _aktivite == a,
                      onSelected: (_) => setState(() => _aktivite = a),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              const _Etiket('Hane büyüklüğü'),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _hane > 1
                        ? () => setState(() => _hane -= 1)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Text(
                      '$_hane kişi',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton.filledTonal(
                    // Backend ust siniri 20; burada da ayni.
                    onPressed: _hane < 20
                        ? () => setState(() => _hane += 1)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 24),

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
              const SizedBox(height: 8),
              TextButton(
                onPressed: _kaydediliyor
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: const Text('Vazgeç'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Etiket extends StatelessWidget {
  const _Etiket(this.metin);

  final String metin;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(metin, style: Theme.of(context).textTheme.labelLarge),
  );
}
