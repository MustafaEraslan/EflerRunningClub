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
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        actions: [
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
              onPressed: () => context.push('/scanner'),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('QR Tara'),
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
      itemBuilder: (run) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(child: Text('${run.points}')),
          title: Text(run.title),
          subtitle: Text(
            '${DateFormat('dd.MM.yyyy • HH:mm').format(run.startsAt)}\n${run.location}',
          ),
          isThreeLine: true,
          trailing: profile?.canManageRuns == true
              ? IconButton(
                  tooltip: run.status == 'open'
                      ? 'QR kodu göster'
                      : 'Koşuyu aç',
                  icon: Icon(
                    run.status == 'open' ? Icons.qr_code_2 : Icons.lock_open,
                  ),
                  onPressed: () async {
                    if (run.status != 'open') {
                      await ref
                          .read(repositoryProvider)
                          .setRunStatus(run.id, 'open');
                      ref.invalidate(runsProvider);
                    }
                    if (context.mounted) context.push('/qr/${run.id}');
                  },
                )
              : Chip(label: Text(_status(run.status))),
        ),
      ),
    );
  }

  String _status(String value) => switch (value) {
    'open' => 'Açık',
    'closed' => 'Tamamlandı',
    _ => 'Planlandı',
  };
}

class RewardsTab extends ConsumerWidget {
  const RewardsTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => _AsyncList<Reward>(
    value: ref.watch(rewardsProvider),
    empty: 'Şu anda aktif ödül yok.',
    onRefresh: () => ref.refresh(rewardsProvider.future),
    itemBuilder: (reward) => Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(child: Icon(Icons.checkroom)),
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
    error: (_, _) => const Center(
      child: Text('Veriler yüklenemedi. İnternet bağlantını kontrol et.'),
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
