import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/providers.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kulüp Yetkileri')),
      body: members.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Üyeler yüklenemedi.')),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(membersProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Yeni kayıt olan herkes Atlet olarak başlar. Güvendiğin bir atleti Antrenör yaparak koşu planlama ve QR oluşturma yetkisi verebilirsin.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...items.map((member) => _MemberTile(member: member)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({required this.member});
  final ClubMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        child: Text(
          member.fullName.isEmpty ? '?' : member.fullName[0].toUpperCase(),
        ),
      ),
      title: Text(member.fullName),
      subtitle: Text(
        member.role == 'member'
            ? 'Atlet'
            : member.role == 'coach'
            ? 'Antrenör'
            : 'Yönetici',
      ),
      trailing: member.role == 'member'
          ? FilledButton.tonal(
              onPressed: () => _promote(context, ref),
              child: const Text('Antrenör Yap'),
            )
          : const Icon(Icons.verified, color: Color(0xFFCCFF00)),
    ),
  );

  Future<void> _promote(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Antrenör yetkisi ver'),
        content: Text(
          '${member.fullName} koşu planlayabilecek ve katılım QR kodu oluşturabilecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yetki ver'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(repositoryProvider).promoteToCoach(member.id);
      ref.invalidate(membersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.fullName} artık antrenör.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Yetki verilemedi.')));
      }
    }
  }
}
