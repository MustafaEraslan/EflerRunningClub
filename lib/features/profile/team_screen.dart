import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/confirm_dialog.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider);
    final currentProfile = ref.watch(profileProvider).asData?.value;
    return Scaffold(
      appBar: AppBar(title: const Text('Kulüp Yetkileri')),
      body: members.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Üyeler yüklenemedi.')),
        data: (items) => RefreshIndicator(
          onRefresh: () {
            ref.invalidate(profileProvider);
            return ref.refresh(membersProvider.future).then((_) {});
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const _HierarchyInfo(),
              const SizedBox(height: 14),
              ...items.map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MemberCard(
                    member: member,
                    currentProfile: currentProfile,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HierarchyInfo extends StatelessWidget {
  const _HierarchyInfo();

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF292329),
    child: const Padding(
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: Color(0xFFCCFF00)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kulüp hiyerarşisi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text('Atlet: Çaylak → Koşucu → Tempocu → Elit'),
          SizedBox(height: 6),
          Text('Antrenör: Yardımcı → Kıdemli → Baş Antrenör'),
          SizedBox(height: 10),
          Text(
            'Tüm antrenörler atlet seviyesini değiştirebilir. Yalnızca Baş Antrenör veya Yönetici yeni antrenör atayabilir ve antrenör seviyelerini düzenleyebilir.',
            style: TextStyle(color: Color(0xFFCFC5CD), height: 1.35),
          ),
        ],
      ),
    ),
  );
}

class _MemberCard extends ConsumerWidget {
  const _MemberCard({required this.member, required this.currentProfile});

  final ClubMember member;
  final Profile? currentProfile;

  bool get _canManageCoaches => currentProfile?.canManageCoaches == true;
  bool get _isSelf => currentProfile?.id == member.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(repositoryProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: member.avatarPath == null
                      ? null
                      : NetworkImage(repository.mediaUrl(member.avatarPath!)),
                  child: member.avatarPath == null
                      ? Text(
                          member.fullName.isEmpty
                              ? '?'
                              : member.fullName[0].toUpperCase(),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName.isEmpty
                            ? 'İsimsiz üye'
                            : member.fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      _LevelBadge(member: member),
                    ],
                  ),
                ),
                if (member.role != 'member') ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.verified, color: Color(0xFFCCFF00)),
                ],
              ],
            ),
            if (member.role == 'member') ...[
              const SizedBox(height: 16),
              _RunnerActions(member: member, canPromote: _canManageCoaches),
            ] else if (member.role == 'coach' &&
                _canManageCoaches &&
                !_isSelf) ...[
              const SizedBox(height: 16),
              _CoachActions(member: member),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.member});
  final ClubMember member;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: member.role == 'member'
            ? const Color(0xFF4A2840)
            : const Color(0xFF344000),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        member.levelLabel,
        style: TextStyle(
          color: member.role == 'member'
              ? const Color(0xFFFF8AD2)
              : const Color(0xFFCCFF00),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    ),
  );
}

class _RunnerActions extends ConsumerWidget {
  const _RunnerActions({required this.member, required this.canPromote});
  final ClubMember member;
  final bool canPromote;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: WrapAlignment.end,
    children: [
      IconButton.filledTonal(
        tooltip: 'Atlet seviyesini düşür',
        onPressed: member.runnerLevel > 1
            ? () => _changeLevel(context, ref, -1)
            : null,
        icon: const Icon(Icons.remove),
      ),
      IconButton.filledTonal(
        tooltip: 'Atlet seviyesini yükselt',
        onPressed: member.runnerLevel < 4
            ? () => _changeLevel(context, ref, 1)
            : null,
        icon: const Icon(Icons.add),
      ),
      if (canPromote)
        FilledButton.tonalIcon(
          onPressed: () => _promote(context, ref),
          icon: const Icon(Icons.sports),
          label: const Text('Antrenör Yap'),
        ),
    ],
  );

  Future<void> _changeLevel(
    BuildContext context,
    WidgetRef ref,
    int direction,
  ) async {
    try {
      await ref
          .read(repositoryProvider)
          .changeRunnerLevel(member.id, direction);
      ref.invalidate(membersProvider);
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'Atlet seviyesi değiştirilemedi.');
      }
    }
  }

  Future<void> _promote(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Antrenör yetkisi ver',
      message:
          '${member.fullName}, Yardımcı Antrenör olacak; koşu planlayıp katılım QR kodu oluşturabilecek.',
      confirmLabel: 'Yetki ver',
    );
    if (!confirmed) return;
    try {
      await ref.read(repositoryProvider).promoteToCoach(member.id);
      ref.invalidate(membersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.fullName} artık Yardımcı Antrenör.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) _showError(context, 'Antrenör yetkisi verilemedi.');
    }
  }
}

class _CoachActions extends ConsumerWidget {
  const _CoachActions({required this.member});
  final ClubMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      const Text('Antrenör seviyesi'),
      const Spacer(),
      IconButton.filledTonal(
        tooltip: 'Seviyeyi düşür',
        onPressed: member.coachLevel > 1
            ? () => _setLevel(context, ref, member.coachLevel - 1)
            : null,
        icon: const Icon(Icons.remove),
      ),
      const SizedBox(width: 8),
      IconButton.filledTonal(
        tooltip: 'Seviyeyi yükselt',
        onPressed: member.coachLevel < 3
            ? () => _setLevel(context, ref, member.coachLevel + 1)
            : null,
        icon: const Icon(Icons.add),
      ),
    ],
  );

  Future<void> _setLevel(BuildContext context, WidgetRef ref, int level) async {
    try {
      await ref.read(repositoryProvider).setCoachLevel(member.id, level);
      ref.invalidate(membersProvider);
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'Antrenör seviyesi değiştirilemedi.');
      }
    }
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
