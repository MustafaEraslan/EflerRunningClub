import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/result_messages.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    const titles = ['Koşular', 'Ödüller', 'Puanlarım', 'Taleplerim'];
    final pages = [
      const RunsTab(),
      const RewardsTab(),
      const PointsTab(),
      const RequestsTab(),
    ];
    final canManageRuns =
        ref.watch(profileProvider).asData?.value.canManageRuns == true;
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        actions: [
          if (index == 0 && canManageRuns)
            IconButton(
              onPressed: () => context.push('/runs/new'),
              icon: const Icon(Icons.event_available),
              tooltip: 'Koşu planla',
            ),
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profil',
          ),
        ],
      ),
      body: pages[index],
      floatingActionButton: index == 0
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.push(canManageRuns ? '/runs/new' : '/scanner'),
              icon: Icon(
                canManageRuns ? Icons.add_road : Icons.qr_code_scanner,
              ),
              label: Text(canManageRuns ? 'KOŞU PLANLA' : 'QR TARA'),
            )
          : index == 1 && canManageRuns
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/rewards/new'),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('ÖDÜL EKLE'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.directions_run),
            label: 'Koşular',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard),
            label: 'Ödüller',
          ),
          NavigationDestination(
            icon: Icon(Icons.stars_outlined),
            label: 'Puanlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Talepler',
          ),
        ],
      ),
    );
  }
}

class RunsTab extends ConsumerWidget {
  const RunsTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    return _AsyncList<ClubRun>(
      value: ref.watch(runsProvider),
      empty: 'Henüz planlanmış koşu yok.',
      onRefresh: () => ref.refresh(runsProvider.future),
      itemBuilder: (run) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF242126), Color(0xFF151517)],
          ),
          border: Border.all(color: const Color(0xFF343036)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5ABB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      DateFormat('dd.MM • HH:mm').format(run.startsAt),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Chip(label: Text('${run.points} PUAN')),
                ],
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _showCoach(context, ref, run),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: Color(0xFFCCFF00),
                        foregroundColor: Colors.black,
                        backgroundImage: run.coachAvatarPath == null
                            ? null
                            : NetworkImage(
                                ref
                                    .read(repositoryProvider)
                                    .mediaUrl(run.coachAvatarPath!),
                              ),
                        child: run.coachAvatarPath == null
                            ? const Icon(Icons.sports, size: 18)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KOŞUYU PLANLAYAN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFCCFF00),
                              ),
                            ),
                            Text(
                              run.coachName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                run.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(run.location)),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    '${run.reservedCount}/${run.capacity} kişi',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    run.availableSpots > 0
                        ? '${run.availableSpots} boş yer'
                        : 'Kontenjan dolu',
                    style: const TextStyle(color: Color(0xFFCCFF00)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: run.capacity == 0 ? 0 : run.reservedCount / run.capacity,
                minHeight: 7,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: const Color(0xFF343036),
                color: const Color(0xFFCCFF00),
              ),
              const SizedBox(height: 18),
              if (profile?.canManageRuns == true)
                FilledButton.icon(
                  icon: const Icon(Icons.qr_code_2),
                  label: Text(
                    run.status == 'open'
                        ? 'QR KODU GÖSTER'
                        : 'KOŞUYU AÇ & QR OLUŞTUR',
                  ),
                  onPressed: run.status == 'closed'
                      ? null
                      : () => _showQr(context, ref, run),
                )
              else
                FilledButton(
                  onPressed:
                      run.status == 'closed' ||
                          (!run.isReserved && run.availableSpots <= 0)
                      ? null
                      : () => _toggleReservation(context, ref, run),
                  style: run.isReserved
                      ? FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF343036),
                          foregroundColor: Colors.white,
                        )
                      : null,
                  child: Text(
                    run.isReserved ? 'REZERVASYONU İPTAL ET' : 'YERİNİ AYIRT',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCoach(BuildContext context, WidgetRef ref, ClubRun run) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundImage: run.coachAvatarPath == null
                  ? null
                  : NetworkImage(
                      ref
                          .read(repositoryProvider)
                          .mediaUrl(run.coachAvatarPath!),
                    ),
              child: run.coachAvatarPath == null
                  ? const Icon(Icons.sports, size: 34)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(run.coachName, style: Theme.of(context).textTheme.titleLarge),
            const Text(
              'Antrenör',
              style: TextStyle(
                color: Color(0xFFCCFF00),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              run.coachBio.isEmpty
                  ? 'Antrenör henüz kısa bir tanıtım eklemedi.'
                  : run.coachBio,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showQr(BuildContext context, WidgetRef ref, ClubRun run) async {
    if (run.status != 'open') {
      await ref.read(repositoryProvider).setRunStatus(run.id, 'open');
      ref.invalidate(runsProvider);
    }
    if (context.mounted) context.push('/qr/${run.id}');
  }

  Future<void> _toggleReservation(
    BuildContext context,
    WidgetRef ref,
    ClubRun run,
  ) async {
    final repo = ref.read(repositoryProvider);
    final code = run.isReserved
        ? await repo.cancelReservation(run.id)
        : await repo.reserveRun(run.id);
    ref.invalidate(runsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(reservationMessage(code))));
    }
  }
}

class RewardsTab extends ConsumerWidget {
  const RewardsTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => _AsyncList<Reward>(
    value: ref.watch(rewardsProvider),
    empty: 'Şu anda aktif ödül yok.',
    onRefresh: () => ref.refresh(rewardsProvider.future),
    itemBuilder: (reward) => Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (reward.imagePath != null)
            Image.network(
              ref.read(repositoryProvider).mediaUrl(reward.imagePath!),
              height: 170,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: reward.imagePath == null
                ? const CircleAvatar(child: Icon(Icons.checkroom))
                : null,
            title: Text(reward.name),
            subtitle: Text(
              '${reward.description}\n${reward.stock > 0 ? '${reward.stock} adet kaldı' : 'Stokta yok'}',
            ),
            isThreeLine: true,
            trailing: FilledButton.tonal(
              onPressed: reward.stock < 1
                  ? null
                  : () => _redeem(context, ref, reward),
              child: Text('${reward.pointsCost} puan'),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _redeem(
    BuildContext context,
    WidgetRef ref,
    Reward reward,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödülü talep et'),
        content: Text(
          '${reward.name} için ${reward.pointsCost} puan kullanılsın mı?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final code = await ref.read(repositoryProvider).redeem(reward.id);
    ref.invalidate(balanceProvider);
    ref.invalidate(rewardsProvider);
    ref.invalidate(requestsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(redeemMessage(code))));
    }
  }
}

class PointsTab extends ConsumerWidget {
  const PointsTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(balanceProvider);
    final ledger = ref.watch(ledgerProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(balanceProvider);
        ref.invalidate(ledgerProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('Kullanılabilir puanın'),
                  const SizedBox(height: 8),
                  Text(
                    balance.asData?.value.toString() ?? '—',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Puan hareketleri',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ...?ledger.asData?.value.map(
            (row) => ListTile(
              leading: Icon(
                (row['delta'] as int) > 0
                    ? Icons.add_circle
                    : Icons.remove_circle,
              ),
              title: Text(_reason(row['reason'] as String)),
              subtitle: Text(
                DateFormat(
                  'dd.MM.yyyy HH:mm',
                ).format(DateTime.parse(row['created_at'] as String).toLocal()),
              ),
              trailing: Text(
                '${(row['delta'] as int) > 0 ? '+' : ''}${row['delta']}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _reason(String value) => switch (value) {
    'checkin' => 'Koşu katılımı',
    'redeem' => 'Ödül talebi',
    'refund' => 'Puan iadesi',
    _ => 'Puan düzenlemesi',
  };
}

class RequestsTab extends ConsumerWidget {
  const RequestsTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(requestsProvider);
    if (rows.isLoading) return const Center(child: CircularProgressIndicator());
    if (rows.hasError) {
      return const Center(child: Text('Talepler yüklenemedi.'));
    }
    if (rows.value!.isEmpty) {
      return const Center(child: Text('Henüz ödül talebin yok.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: rows.value!.map((row) {
        final reward = row['efeler_rewards'] as Map<String, dynamic>?;
        return Card(
          child: ListTile(
            title: Text(reward?['name'] as String? ?? 'Ödül'),
            subtitle: Text('${row['points_spent']} puan'),
            trailing: Chip(label: Text(_label(row['status'] as String))),
          ),
        );
      }).toList(),
    );
  }

  String _label(String value) => switch (value) {
    'delivered' => 'Teslim edildi',
    'cancelled' => 'İptal',
    _ => 'Hazırlanıyor',
  };
}

class _AsyncList<T> extends StatelessWidget {
  const _AsyncList({
    required this.value,
    required this.itemBuilder,
    required this.empty,
    required this.onRefresh,
  });
  final AsyncValue<List<T>> value;
  final Widget Function(T) itemBuilder;
  final String empty;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) => value.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, _) => RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * .25),
          const Icon(Icons.sync_problem, size: 46),
          const SizedBox(height: 12),
          const Center(child: Text('Veriler şu anda yüklenemedi.')),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Yeniden dene'),
            ),
          ),
        ],
      ),
    ),
    data: (items) => RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          ? ListView(
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * .3),
                Center(child: Text(empty)),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: items.map(itemBuilder).toList(),
            ),
    ),
  );
}
