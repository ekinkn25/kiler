import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../providers/barcode_provider.dart';
import 'package:go_router/go_router.dart';

/// GECICI: W1-T14'te alt bar navigasyonu gelince SILINECEK.
class DevHomeScreen extends ConsumerStatefulWidget {
  const DevHomeScreen({super.key});

  @override
  ConsumerState<DevHomeScreen> createState() => _DevHomeScreenState();
}

class _DevHomeScreenState extends ConsumerState<DevHomeScreen> {
  String _barkodSonuc = '—';
  String _backendSonuc = '—';
  bool _yukleniyor = false;

  Future<void> _barkodTara() async {
    final tarayici = ref.read(barcodeScannerProvider);
    final sonuc = await tarayici.scan(context);
    if (!mounted) return;
    setState(() => _barkodSonuc = sonuc ?? 'iptal edildi');
  }

  Future<void> _backendKontrol() async {
    setState(() {
      _yukleniyor = true;
      _backendSonuc = 'bağlanılıyor...';
    });
    try {
      // /health ucu /api/v1 disindadir, bu yuzden son bolumu kirpiyoruz.
      final kok = AppConfig.apiBaseUrl.replaceAll('/api/v1', '');
      final dio = Dio(BaseOptions(connectTimeout: AppConfig.requestTimeout));
      final yanit = await dio.get<Map<String, dynamic>>('$kok/health');
      if (!mounted) return;
      setState(() => _backendSonuc = 'OK — ${yanit.data}');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _backendSonuc = 'HATA — ${e.type.name}: ${e.message}');
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tarayici = ref.watch(barcodeScannerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kurulum Doğrulama')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.tonalIcon(
            onPressed: () => context.push('/dev/widgets'),
            icon: const Icon(Icons.palette_outlined),
            label: const Text('Tasarım Sistemi Vitrini'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yapılandırma',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _satir('API adresi', AppConfig.apiBaseUrl),
                  _satir('Sahte tarayıcı',
                      AppConfig.useFakeScanner ? 'AÇIK' : 'kapalı'),
                  _satir('Aktif tarayıcı', tarayici.name),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _barkodTara,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Barkod Tara'),
          ),
          const SizedBox(height: 8),
          Text('Sonuç: $_barkodSonuc'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _yukleniyor ? null : _backendKontrol,
            icon: const Icon(Icons.cloud_sync),
            label: const Text("Backend'e Bağlan (/health)"),
          ),
          const SizedBox(height: 8),
          Text('Sonuç: $_backendSonuc'),
        ],
      ),
    );
  }

  Widget _satir(String etiket, String deger) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: Text('$etiket:')),
            Expanded(
              child: Text(deger,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}