import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../models/enums.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/widgets.dart';
import 'widgets/onboarding_step1_profil.dart';
import 'widgets/onboarding_step2_hedef.dart';
import 'widgets/onboarding_step3_diyet.dart';
import 'widgets/onboarding_step4_tarifler.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  static const _toplamAdim = 4;
  int _adim = 0;

  int? _dogumYili;
  Gender? _cinsiyet;
  double? _boyCm;
  double? _kiloKg;
  ActivityLevel _aktivite = ActivityLevel.orta;

  Goal _hedef = Goal.koruma;
  int _haneBuyuklugu = 1;

  final Set<String> _diyetKodlari = {};
  final Set<String> _alerjenKodlari = {};
  final Set<String> _begenilenTarifIdleri = {};
  static const _maxBegeni = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _sonrakiAdim() {
    if (_adim == _toplamAdim - 1) {
      _gonder();
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Future<void> _gonder() async {
    await ref.read(onboardingProvider.notifier).submit(
      birthYear: _dogumYili,
      gender: _cinsiyet == null ? null : genderToJson(_cinsiyet!),
      heightCm: _boyCm,
      weightKg: _kiloKg,
      activityLevel: activityLevelToJson(_aktivite),
      goal: goalToJson(_hedef),
      householdSize: _haneBuyuklugu,
      dietTagCodes: _diyetKodlari.toList(),
      allergenCodes: _alerjenKodlari.toList(),
      likedRecipeIds: _begenilenTarifIdleri.toList(),
    );
    if (!mounted) return;
    if (!ref.read(onboardingProvider).hasError) context.go('/sohbet');
  }

  @override
  Widget build(BuildContext context) {
    final durum = ref.watch(onboardingProvider);
    final hata = durum.hasError ? friendlyErrorMessage(durum.error) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tanıma Anketi  ${_adim + 1}/$_toplamAdim'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: durum.isLoading ? null : _gonder,
            child: const Text('Atla'),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_adim + 1) / _toplamAdim),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _adim = i),
              children: [
                OnboardingStep1Profil(
                  dogumYili: _dogumYili, cinsiyet: _cinsiyet, boyCm: _boyCm,
                  kiloKg: _kiloKg, aktivite: _aktivite,
                  onChanged: ({dogumYili, cinsiyet, boyCm, kiloKg, aktivite}) => setState(() {
                    if (dogumYili != null) _dogumYili = dogumYili;
                    if (cinsiyet != null) _cinsiyet = cinsiyet;
                    if (boyCm != null) _boyCm = boyCm;
                    if (kiloKg != null) _kiloKg = kiloKg;
                    if (aktivite != null) _aktivite = aktivite;
                  }),
                ),
                OnboardingStep2Hedef(
                  hedef: _hedef, haneBuyuklugu: _haneBuyuklugu,
                  onHedefChanged: (v) => setState(() => _hedef = v),
                  onHaneBuyuklugu: (v) => setState(() => _haneBuyuklugu = v),
                ),
                OnboardingStep3Diyet(
                  seciliDiyetKodlari: _diyetKodlari,
                  seciliAlerjenKodlari: _alerjenKodlari,
                  onDiyetToggle: (kod) => setState(() =>
                      _diyetKodlari.contains(kod) ? _diyetKodlari.remove(kod) : _diyetKodlari.add(kod)),
                  onAlerjenToggle: (kod) => setState(() =>
                      _alerjenKodlari.contains(kod) ? _alerjenKodlari.remove(kod) : _alerjenKodlari.add(kod)),
                ),
                OnboardingStep4Tarifler(
                  seciliTarifIdleri: _begenilenTarifIdleri,
                  maxSecim: _maxBegeni,
                  onToggle: (id) => setState(() {
                    if (_begenilenTarifIdleri.contains(id)) {
                      _begenilenTarifIdleri.remove(id);
                    } else if (_begenilenTarifIdleri.length < _maxBegeni) {
                      _begenilenTarifIdleri.add(id);
                    }
                  }),
                ),
              ],
            ),
          ),
          if (hata != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(hata, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: AppButton(
              label: _adim == _toplamAdim - 1 ? 'Anketi Tamamla' : 'Devam Et',
              loading: durum.isLoading,
              onPressed: _sonrakiAdim,
            ),
          ),
        ],
      ),
    );
  }
}