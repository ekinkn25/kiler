import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';

/// Giris ekrani. NEDEN BASIT: bu gorevin odagi oturum/token altyapisi -
/// gorsel tasarim ayri bir mobil gorevde genisletilir.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final hata = authState.hasError ? authState.error.toString() : null;
    final yukleniyor = authState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Giriş')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-posta'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Şifre'),
              obscureText: true,
            ),
            if (hata != null) ...[
              const SizedBox(height: 12),
              Text(hata, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            AppButton(
              label: 'Giriş Yap',
              loading: yukleniyor,
              onPressed: () => ref.read(authProvider.notifier).login(
                email: _emailController.text.trim(),
                password: _passwordController.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}