import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/providers.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../core/widgets/confirm_dialog.dart';

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
                    AvatarWidget(
                      radius: 36,
                      url: p.avatarUrl,
                      initials: _initials(p.fullName),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p.fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(p.levelLabel),
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
                subtitle: const Text('Atlet ve antrenör seviyelerini yönet'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/team'),
              ),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.add_a_photo_outlined),
            title: const Text('Profil fotoğrafı'),
            subtitle: const Text('Galeriden seç veya fotoğraf çek'),
            onTap: () => _pickAvatarSheet(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Profilimi düzenle'),
            subtitle: const Text('Adını ve kısa antrenör bilgini güncelle'),
            onTap: profile.asData == null
                ? null
                : () => context.push('/profile/edit'),
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

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Bottom sheet: pick from gallery or take a photo.
  Future<void> _pickAvatarSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Profil fotoğrafı',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden seç'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar(context, ref, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Fotoğraf çek'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar(context, ref, ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    try {
      // image_picker resizes to ≤512×512 at ~80% quality; exact square crop
      // would need the `image` package — omitted per minimal-diff rule.
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      if (file == null) return; // user cancelled
      if (!context.mounted) return;
      await ref
          .read(repositoryProvider)
          .uploadProfileAvatar(await file.readAsBytes());
      ref.invalidate(profileProvider);
      ref.invalidate(runsProvider); // coach avatars on run cards
      ref.invalidate(membersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil fotoğrafın güncellendi.')),
        );
      }
    } on Exception catch (e) {
      if (!context.mounted) return;
      final msg = e.toString();
      if (msg.contains('photo_access_denied') ||
          msg.contains('authorization_restricted')) {
        _showPermissionDenied(
          context,
          'Fotoğraf arşivine erişim izni verilmedi.',
        );
      } else if (msg.contains('camera_access_denied')) {
        _showPermissionDenied(context, 'Kamera erişim izni verilmedi.');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fotoğraf yüklenemedi.')));
      }
    }
  }

  void _showPermissionDenied(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Ayarlar',
          onPressed: () => launchUrl(Uri.parse('app-settings:')),
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hesabı sil',
      message:
          'Bu işlem geri alınamaz. Katılım, puan ve ödül talebi geçmişin silinecek.',
      confirmLabel: 'Hesabımı sil',
    );
    if (!confirmed) return;
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
