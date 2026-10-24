import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/club_repository.dart';
import '../models/models.dart';

final repositoryProvider = Provider(
  (_) => ClubRepository(Supabase.instance.client),
);
final profileProvider = FutureProvider<Profile>(
  (ref) => ref.watch(repositoryProvider).getProfile(),
);
final runsProvider = FutureProvider<List<ClubRun>>(
  (ref) => ref.watch(repositoryProvider).getRuns(),
);
final membersProvider = FutureProvider<List<ClubMember>>(
  (ref) => ref.watch(repositoryProvider).getMembers(),
);
final rewardsProvider = FutureProvider<List<Reward>>(
  (ref) => ref.watch(repositoryProvider).getRewards(),
);
final balanceProvider = FutureProvider<int>(
  (ref) => ref.watch(repositoryProvider).getBalance(),
);
final ledgerProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(repositoryProvider).getLedger(),
);
final requestsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(repositoryProvider).getRequests(),
);
