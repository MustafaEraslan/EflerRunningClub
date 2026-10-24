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
          if (profile.asData?.value.canManageRuns == true) ...[
            const SizedBox(height: 8),
            Card(
              color: const Color(0xFF292329),
              child: ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFFCCFF00),
                ),
                title: const Text('Kulüp yetkilerini yönet'),
                subtitle: const Text('Atletleri antrenör olarak yetkilendir'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/team'),
              ),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Profilimi düzenle'),
            subtitle: const Text('Adını ve kısa antrenör bilgini güncelle'),
            onTap: profile.asData == null
                ? null
                : () => _edit(context, ref, profile.asData!.value),
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

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    dynamic profile,
  ) async {
    final name = TextEditingController(text: profile.fullName as String);
    final bio = TextEditingController(text: profile.bio as String);
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profili düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Ad soyad'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bio,
              maxLength: 280,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Kısa bilgi',
                hintText: 'Koşu deneyimin, uzmanlığın…',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (save == true && name.text.trim().isNotEmpty) {
      await ref.read(repositoryProvider).updateProfile(name.text, bio.text);
      ref.invalidate(profileProvider);
    }
    name.dispose();
    bio.dispose();
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
