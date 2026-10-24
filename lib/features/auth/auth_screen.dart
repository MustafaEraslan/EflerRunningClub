import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/providers/providers.dart';

enum AuthMode { login, register, forgot }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({required this.mode, super.key});
  final AuthMode mode;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final fullName = TextEditingController();
  bool consent = false;
  bool loading = false;
  String? error;
  StreamSubscription<AuthState>? authSubscription;

  @override
  void initState() {
    super.initState();
    authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      state,
    ) async {
      if (!mounted) return;
      if (state.event == AuthChangeEvent.passwordRecovery) {
        context.go('/reset-password');
        return;
      }
      if (state.event != AuthChangeEvent.signedIn) return;
      try {
        await ref.read(repositoryProvider).ensureSocialProfile();
        ref.invalidate(profileProvider);
        if (mounted) context.go('/home');
      } catch (_) {
        if (mounted) {
          setState(() => error = 'Kulüp profili oluşturulamadı. Tekrar dene.');
        }
      }
    });
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    fullName.dispose();
    authSubscription?.cancel();
    super.dispose();
  }

  Future<void> socialSignIn(OAuthProvider provider) async {
    if (!consent) {
      setState(() => error = 'Devam etmek için KVKK metnini onaylamalısın.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await ref.read(repositoryProvider).signInWithSocialProvider(provider);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Sosyal giriş başlatılamadı. Sağlayıcı ayarlarını kontrol et.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> appleSignIn() async {
    if (!consent) {
      setState(() => error = 'Devam etmek için KVKK metnini onaylamalısın.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await ref.read(repositoryProvider).signInWithApple();
    } on SignInWithAppleAuthorizationException catch (exception) {
      if (mounted && exception.code != AuthorizationErrorCode.canceled) {
        setState(() => error = 'Apple ile giriş tamamlanamadı. Tekrar dene.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Apple ile giriş tamamlanamadı. Tekrar dene.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> submit() async {
    if (widget.mode == AuthMode.register && !consent) {
      setState(() => error = 'Devam etmek için KVKK metnini onaylamalısın.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final repo = ref.read(repositoryProvider);
      if (widget.mode == AuthMode.login) {
        await repo.signIn(email.text, password.text);
        if (mounted) context.go('/home');
      } else if (widget.mode == AuthMode.register) {
        await repo.signUp(
          email: email.text,
          password: password.text,
          fullName: fullName.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Kayıt tamamlandı. E-posta doğrulama bağlantını kontrol et.',
              ),
            ),
          );
          context.go('/login');
        }
      } else {
        await repo.resetPassword(email.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Şifre yenileme bağlantısı gönderildi.'),
            ),
          );
        }
      }
    } catch (_) {
      setState(
        () => error =
            'İşlem tamamlanamadı. Bilgilerini ve internet bağlantını kontrol et.',
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.mode) {
      AuthMode.login => 'Tekrar hoş geldin',
      AuthMode.register => 'Kulübe katıl',
      AuthMode.forgot => 'Şifreni yenile',
    };
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-.8, -1),
            radius: 1.4,
            colors: [Color(0xFF412039), Color(0xFF0D0D0F)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset('assets/icon/icon.png', height: 112),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Koş. Biriktir. Kazan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: .65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 26),
                    if (widget.mode == AuthMode.register) ...[
                      TextField(
                        controller: fullName,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Ad soyad',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'E-posta'),
                    ),
                    if (widget.mode != AuthMode.forgot) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: password,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Şifre'),
                      ),
                    ],
                    if (widget.mode == AuthMode.register) ...[
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: consent,
                        onChanged: (value) =>
                            setState(() => consent = value ?? false),
                        title: const Text(
                          'KVKK Aydınlatma Metni’ni okudum ve kabul ediyorum.',
                        ),
                        subtitle: const Text(
                          'Metin bağlantısı yayın öncesi eklenecek.',
                        ),
                      ),
                    ],
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    FilledButton(
                      onPressed: loading ? null : submit,
                      child: Text(
                        loading
                            ? 'Lütfen bekle…'
                            : widget.mode == AuthMode.login
                            ? 'Giriş yap'
                            : widget.mode == AuthMode.register
                            ? 'Kayıt ol'
                            : 'Bağlantı gönder',
                      ),
                    ),
                    if (widget.mode == AuthMode.login) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('veya'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: consent,
                        onChanged: loading
                            ? null
                            : (value) =>
                                  setState(() => consent = value ?? false),
                        title: const Text(
                          'KVKK Aydınlatma Metni’ni okudum ve kabul ediyorum.',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: loading || !AppConfig.googleSignInEnabled
                            ? null
                            : () => socialSignIn(OAuthProvider.google),
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: Text(
                          AppConfig.googleSignInEnabled
                              ? 'Google ile devam et'
                              : 'Google ile devam et (kurulum gerekli)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: loading || !AppConfig.appleSignInEnabled
                            ? null
                            : appleSignIn,
                        icon: const Icon(Icons.apple),
                        label: Text(
                          AppConfig.appleSignInEnabled
                              ? 'Apple ile devam et'
                              : 'Apple ile devam et (üyelik gerekli)',
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/forgot'),
                        child: const Text('Şifremi unuttum'),
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: const Text('Hesabın yok mu? Kayıt ol'),
                      ),
                    ] else
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Giriş ekranına dön'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
