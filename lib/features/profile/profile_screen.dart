import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: profile.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Text('Profil yüklenemedi.'),
                data: (p) => Column(
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      child: Icon(Icons.person, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p.fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      p.role == 'admin'
                          ? 'Yönetici'
                          : p.role == 'coach'
                          ? 'Antrenör'
                          : 'Atlet',
                    ),
                  ],
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Çıkış yap'),
            onTap: () async {
              await ref.read(repositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Hesabımı sil',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: const Text('Efeler verilerin kalıcı olarak silinir.'),
            onTap: () => _delete(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı sil'),
        content: const Text(
          'Bu işlem geri alınamaz. Katılım, puan ve ödül talebi geçmişin silinecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hesabımı sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(repositoryProvider).deleteAccount();
      if (context.mounted) context.go('/login');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hesap silinemedi. Lütfen tekrar dene.'),
          ),
        );
      }
    }
  }
}
