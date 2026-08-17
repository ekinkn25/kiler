import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/multipart_helper.dart';
import '../../core/storage/secure_storage.dart';
import '../../providers/barcode_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/me_provider.dart';

/// GECICI: alt bar navigasyonu geldi (W2-T15), bu ekran artik '/dev'
/// rotasinda - gercek Ayarlar ekrani gelince kaldirilabilir.
class DevHomeScreen extends ConsumerStatefulWidget {
  const DevHomeScreen({super.key});

  @override
  ConsumerState<DevHomeScreen> createState() => _DevHomeScreenState();
}

class _DevHomeScreenState extends ConsumerState<DevHomeScreen> {
  final _emailController = TextEditingController(text: 'test@example.com');
  final _passwordController = TextEditingController(text: 'Test1234!');

  String _barkodSonuc = '—';
  String _girisSonuc = '—';
  String _fotoSonuc = '—';
  bool _girisYukleniyor = false;
  bool _fotoYukleniyor = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _barkodTara() async {
    final tarayici = ref.read(barcodeScannerProvider);
    final sonuc = await tarayici.scan(context);
    if (!mounted) return;
    setState(() => _barkodSonuc = sonuc ?? 'iptal edildi');
  }

  Future<void> _girisYap() async {
    setState(() {
      _girisYukleniyor = true;
      _girisSonuc = 'giriş yapılıyor...';
    });
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );
      final data = response.data!;
      await ref.read(secureStorageProvider).saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      if (!mounted) return;
      setState(() => _girisSonuc = 'giriş başarılı, token kaydedildi');
      ref.invalidate(meProvider);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _girisSonuc = 'HATA — ${e.apiException.message}');
    } finally {
      if (mounted) setState(() => _girisYukleniyor = false);
    }
  }

  Future<void> _cikisYap() async {
    await ref.read(secureStorageProvider).clear();
    ref.invalidate(meProvider);
    setState(() => _girisSonuc = 'çıkış yapıldı');
  }

  Future<void> _fotoYukle() async {
    final secilen = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (secilen == null) return;

    setState(() {
      _fotoYukleniyor = true;
      _fotoSonuc = 'yükleniyor...';
    });
    try {
      final dio = ref.read(dioProvider);
      final form = await MultipartHelper.singleImageForm(File(secilen.path));
      final response = await dio.post<List<dynamic>>('/vision/ingredients', data: form);
      if (!mounted) return;
      setState(() => _fotoSonuc = '${response.data?.length ?? 0} malzeme döndü');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _fotoSonuc = 'HATA — ${e.apiException.message}');
    } finally {
      if (mounted) setState(() => _fotoYukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tarayici = ref.watch(barcodeScannerProvider);
    final saglikDurumu = ref.watch(healthProvider);
    final kullaniciDurumu = ref.watch(meProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kurulum Doğrulama')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yapılandırma', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _satir('API adresi', AppConfig.apiBaseUrl),
                  _satir('Sahte tarayıcı', AppConfig.useFakeScanner ? 'AÇIK' : 'kapalı'),
                  _satir('Aktif tarayıcı', tarayici.name),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => context.push('/dev/widgets'),
            icon: const Icon(Icons.palette_outlined),
            label: const Text('Tasarım Sistemi Vitrini'),
          ),
          const SizedBox(height: 24),

          _baslik(context, 'GET /health (AsyncNotifier)'),
          saglikDurumu.when(
            loading: () => const LinearProgressIndicator(),
            error: (err, _) =>
                Text('HATA — ${err is DioException ? err.apiException.message : err}'),
            data: (veri) => Text('OK — $veri'),
          ),
          TextButton(
            onPressed: () => ref.read(healthProvider.notifier).refresh(),
            child: const Text('Tekrar dene'),
          ),
          const SizedBox(height: 24),

          _baslik(context, 'Barkod Tarama'),
          FilledButton.icon(
            onPressed: _barkodTara,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Barkod Tara'),
          ),
          const SizedBox(height: 8),
          Text('Sonuç: $_barkodSonuc'),
          const SizedBox(height: 24),

          _baslik(context, 'Test Girişi (dev)'),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'E-posta'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Şifre'),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _girisYukleniyor ? null : _girisYap,
                  child: const Text('Giriş Yap'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _cikisYap, child: const Text('Çıkış')),
            ],
          ),
          const SizedBox(height: 8),
          Text('Sonuç: $_girisSonuc'),
          const SizedBox(height: 24),

          _baslik(context, 'GET /auth/me (AsyncNotifier + Bearer token)'),
          kullaniciDurumu.when(
            loading: () => const LinearProgressIndicator(),
            error: (err, _) =>
                Text('HATA — ${err is DioException ? err.apiException.message : err}'),
            data: (veri) => Text('OK — ${veri.email} (id: ${veri.id})'),
          ),
          TextButton(
            onPressed: () => ref.read(meProvider.notifier).refresh(),
            child: const Text('Tekrar dene'),
          ),
          const SizedBox(height: 24),

          _baslik(context, 'Fotoğraf Yükleme (MultipartFile)'),
          FilledButton.icon(
            onPressed: _fotoYukleniyor ? null : _fotoYukle,
            icon: const Icon(Icons.photo_camera_back_outlined),
            label: const Text('Galeriden Seç ve Yükle'),
          ),
          const SizedBox(height: 8),
          Text('Sonuç: $_fotoSonuc'),
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
        Expanded(child: Text(deger, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    ),
  );

  Widget _baslik(BuildContext context, String metin) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      metin,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    ),
  );
}