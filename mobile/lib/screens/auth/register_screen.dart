import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';
import '../../models/app_user.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _emailController = TextEditingController();
  final _sifreController = TextEditingController();
  final _sifreTekrarController = TextEditingController();

  final _emailFocus = FocusNode();
  final _sifreFocus = FocusNode();
  final _sifreTekrarFocus = FocusNode();

  bool _sifreGorunur = false;
  bool _sifreTekrarGorunur = false;
  String _sifreDegeri = '';

  @override
  void dispose() {
    _adController.dispose();
    _emailController.dispose();
    _sifreController.dispose();
    _sifreTekrarController.dispose();
    _emailFocus.dispose();
    _sifreFocus.dispose();
    _sifreTekrarFocus.dispose();
    super.dispose();
  }

  void _kayitOl() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(authProvider.notifier).register(
      email: _emailController.text.trim(),
      password: _sifreController.text,
      fullName: _adController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppUser?>>(authProvider, (onceki, sonraki) {
      if (sonraki.valueOrNull != null) {
        context.go('/sohbet');
      }
    });
    final authState = ref.watch(authProvider);
    final hata = authState.hasError ? friendlyErrorMessage(authState.error) : null;
    final yukleniyor = authState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _adController,
                decoration: const InputDecoration(labelText: 'Ad Soyad (opsiyonel)'),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                validator: fullNameValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                decoration: const InputDecoration(labelText: 'E-posta'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _sifreFocus.requestFocus(),
                validator: emailValidator,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sifreController,
                focusNode: _sifreFocus,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  suffixIcon: IconButton(
                    icon: Icon(_sifreGorunur ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _sifreGorunur = !_sifreGorunur),
                  ),
                ),
                obscureText: !_sifreGorunur,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _sifreTekrarFocus.requestFocus(),
                onChanged: (v) => setState(() => _sifreDegeri = v),
                validator: passwordValidator,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              PasswordStrengthIndicator(password: _sifreDegeri),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sifreTekrarController,
                focusNode: _sifreTekrarFocus,
                decoration: InputDecoration(
                  labelText: 'Şifre (Tekrar)',
                  suffixIcon: IconButton(
                    icon: Icon(_sifreTekrarGorunur ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _sifreTekrarGorunur = !_sifreTekrarGorunur),
                  ),
                ),
                obscureText: !_sifreTekrarGorunur,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _kayitOl(),
                validator: (v) => v != _sifreController.text ? 'Şifreler eşleşmiyor.' : null,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              if (hata != null) ...[
                const SizedBox(height: 12),
                Text(hata, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              AppButton(label: 'Kayıt Ol', loading: yukleniyor, onPressed: _kayitOl),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Zaten hesabın var mı? Giriş yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}