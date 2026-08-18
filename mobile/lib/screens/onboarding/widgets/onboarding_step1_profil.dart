import 'package:flutter/material.dart';

import '../../../models/enums.dart';

typedef Step1Degisti = void Function({
  int? dogumYili, Gender? cinsiyet, double? boyCm, double? kiloKg, ActivityLevel? aktivite,
});

class OnboardingStep1Profil extends StatelessWidget {
  const OnboardingStep1Profil({
    required this.dogumYili, required this.cinsiyet, required this.boyCm,
    required this.kiloKg, required this.aktivite, required this.onChanged, super.key,
  });

  final int? dogumYili;
  final Gender? cinsiyet;
  final double? boyCm;
  final double? kiloKg;
  final ActivityLevel aktivite;
  final Step1Degisti onChanged;

  static const _aktiviteEtiketleri = {
    ActivityLevel.sedanter: 'Sedanter',
    ActivityLevel.hafif: 'Hafif',
    ActivityLevel.orta: 'Orta',
    ActivityLevel.yuksek: 'Yüksek',
    ActivityLevel.cokYuksek: 'Çok Yüksek',
  };

  static const _cinsiyetEtiketleri = {
    Gender.kadin: 'Kadın',
    Gender.erkek: 'Erkek',
    Gender.belirtilmedi: 'Belirtmek istemiyorum',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Seni biraz tanıyalım', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: dogumYili?.toString(),
            decoration: const InputDecoration(labelText: 'Doğum yılı'),
            keyboardType: TextInputType.number,
            onChanged: (v) => onChanged(dogumYili: int.tryParse(v)),
          ),
          const SizedBox(height: 16),
          Text('Cinsiyet', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: Gender.values.map((g) => ChoiceChip(
              label: Text(_cinsiyetEtiketleri[g]!),
              selected: cinsiyet == g,
              onSelected: (_) => onChanged(cinsiyet: g),
            )).toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: boyCm?.toString(),
            decoration: const InputDecoration(labelText: 'Boy (cm)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => onChanged(boyCm: double.tryParse(v)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: kiloKg?.toString(),
            decoration: const InputDecoration(labelText: 'Kilo (kg)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => onChanged(kiloKg: double.tryParse(v)),
          ),
          const SizedBox(height: 16),
          Text('Aktivite seviyesi', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ActivityLevel.values.map((a) => ChoiceChip(
              label: Text(_aktiviteEtiketleri[a]!),
              selected: aktivite == a,
              onSelected: (_) => onChanged(aktivite: a),
            )).toList(),
          ),
        ],
      ),
    );
  }
}