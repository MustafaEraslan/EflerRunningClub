import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/providers.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool loading = false;
  String? error;

  @override
  void dispose() {
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (password.text.length < 8) {
      setState(() => error = 'Şifren en az 8 karakter olmalı.');
      return;
    }
    if (password.text != confirmation.text) {
      setState(() => error = 'Şifreler birbiriyle eşleşmiyor.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final repo = ref.read(repositoryProvider);
      await repo.updatePassword(password.text);
      await repo.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifren yenilendi. Şimdi giriş yapabilirsin.'),
          ),
        );
        context.go('/login');
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Şifre yenilenemedi. Bağlantıyı yeniden aç.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Yeni şifre')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.lock_reset, size: 72, color: Color(0xFFCCFF00)),
        const SizedBox(height: 24),
        Text(
          'Yeni şifreni belirle',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Yeni şifre'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: confirmation,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Yeni şifre tekrar'),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: loading ? null : submit,
          child: Text(loading ? 'Kaydediliyor…' : 'ŞİFREYİ YENİLE'),
        ),
      ],
    ),
  );
}
