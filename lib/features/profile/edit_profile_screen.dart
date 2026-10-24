import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/providers.dart';
import '../../core/widgets/avatar_widget.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  bool _initialized = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _init(String fullName, String bio) {
    if (_initialized) return;
    _name = TextEditingController(text: fullName);
    _bio = TextEditingController(text: bio);
    _initialized = true;
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> _pickAvatarSheet() async {
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
                _pickAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Fotoğraf çek'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      if (file == null || !mounted) return;
      await ref
          .read(repositoryProvider)
          .uploadProfileAvatar(await file.readAsBytes());
      ref.invalidate(profileProvider);
      ref.invalidate(runsProvider);
      ref.invalidate(membersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil fotoğrafın güncellendi.')),
        );
      }
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('photo_access_denied') ||
          msg.contains('authorization_restricted')) {
        _showPermissionDenied('Fotoğraf arşivine erişim izni verilmedi.');
      } else if (msg.contains('camera_access_denied')) {
        _showPermissionDenied('Kamera erişim izni verilmedi.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf yüklenemedi.')),
        );
      }
    }
  }

  void _showPermissionDenied(String message) {
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

  Future<void> _save() async {
    final nameText = _name.text.trim();
    if (nameText.length < 2) {
      setState(() => _error = 'Ad soyad en az 2 karakter olmalı.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(repositoryProvider)
          .updateProfile(nameText, _bio.text.trim());
      ref.invalidate(profileProvider);
      ref.invalidate(runsProvider);
      ref.invalidate(membersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profilin güncellendi.')),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Profil güncellenemedi. Lütfen tekrar dene.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    return profile.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Profili düzenle')),
        body: const Center(child: Text('Profil yüklenemedi.')),
      ),
      data: (p) {
        _init(p.fullName, p.bio);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profili düzenle'),
            actions: [
              TextButton(
                onPressed: _saving ? null : _save,
                child: Text(
                  'Kaydet',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickAvatarSheet,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      AvatarWidget(
                        radius: 44,
                        url: p.avatarUrl,
                        initials: _initials(p.fullName),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF5ABB),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _pickAvatarSheet,
                  child: const Text('Fotoğrafı değiştir'),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Ad soyad'),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _bio,
                maxLength: 280,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Kısa bilgi',
                  hintText: 'Koşu deneyimin, uzmanlığın…',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
              ),
            ],
          ),
        );
      },
    );
  }
}
