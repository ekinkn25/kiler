import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';
import '../../models/app_user.dart';

/// Giris ekrani.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _sifreGorunur = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _girisYap() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(authProvider.notifier).login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppUser?>>(authProvider, (onceki, sonraki) {
      if (sonraki.valueOrNull != null) {
        context.go('/kesfet');
      }
    });
    final authState = ref.watch(authProvider);
    final hata = authState.hasError ? friendlyErrorMessage(authState.error) : null;
    final yukleniyor = authState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Giriş')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-posta'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                validator: emailValidator,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  suffixIcon: IconButton(
                    icon: Icon(_sifreGorunur ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _sifreGorunur = !_sifreGorunur),
                  ),
                ),
                obscureText: !_sifreGorunur,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _girisYap(),
                validator: loginPasswordValidator,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              if (hata != null) ...[
                const SizedBox(height: 12),
                Text(hata, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              AppButton(label: 'Giriş Yap', loading: yukleniyor, onPressed: _girisYap),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/kayit'),
                child: const Text('Hesabın yok mu? Kayıt ol'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}