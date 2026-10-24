import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/models.dart';

class ClubRepository {
  ClubRepository(this.client);
  final SupabaseClient client;

  User? get user => client.auth.currentUser;

  Future<void> signIn(String email, String password) => client.auth
      .signInWithPassword(email: email.trim(), password: password)
      .then((_) {});

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) => client.auth
      .signUp(
        email: email.trim(),
        password: password,
        data: {
          'app_id': AppConfig.appId,
          'full_name': fullName.trim(),
          'consent_version': '1.0',
          'consent_accepted_at': DateTime.now().toUtc().toIso8601String(),
        },
      )
      .then((_) {});

  Future<void> resetPassword(String email) =>
      client.auth.resetPasswordForEmail(email.trim()).then((_) {});

  Future<void> signOut() => client.auth.signOut();

  Future<Profile> getProfile() async {
    final data = await client
        .from('efeler_profiles')
        .select()
        .eq('app_id', AppConfig.appId)
        .eq('id', user!.id)
        .single();
    return Profile.fromJson(data);
  }

  Future<List<ClubRun>> getRuns() async {
    final data = await client
        .from('efeler_runs')
        .select()
        .eq('app_id', AppConfig.appId)
        .order('starts_at');
    return data.map(ClubRun.fromJson).toList();
  }

  Future<List<Reward>> getRewards() async {
    final data = await client
        .from('efeler_rewards')
        .select()
        .eq('app_id', AppConfig.appId)
        .eq('active', true)
        .order('points_cost');
    return data.map(Reward.fromJson).toList();
  }

  Future<int> getBalance() async {
    final data = await client
        .from('efeler_member_balance')
        .select('balance')
        .eq('app_id', AppConfig.appId)
        .eq('member_id', user!.id)
        .maybeSingle();
    return (data?['balance'] as num?)?.toInt() ?? 0;
  }

  Future<List<Map<String, dynamic>>> getLedger() async =>
      List<Map<String, dynamic>>.from(
        await client
            .from('efeler_points_ledger')
            .select()
            .eq('app_id', AppConfig.appId)
            .eq('member_id', user!.id)
            .order('created_at', ascending: false),
      );

  Future<List<Map<String, dynamic>>> getRequests() async =>
      List<Map<String, dynamic>>.from(
        await client
            .from('efeler_reward_requests')
            .select('*, efeler_rewards(name)')
            .eq('app_id', AppConfig.appId)
            .eq('member_id', user!.id)
            .order('created_at', ascending: false),
      );

  Future<String> checkIn(String token) async {
    final data = await client.rpc(
      'efeler_check_in',
      params: {'p_token': token},
    );
    return _code(data);
  }

  Future<String> redeem(String rewardId) async {
    final data = await client.rpc(
      'efeler_redeem',
      params: {'p_reward_id': rewardId},
    );
    return _code(data);
  }

  Future<String> getQrToken(String runId) async {
    final data = await client.rpc(
      'efeler_get_qr_token',
      params: {'p_run_id': runId},
    );
    if (data is Map) return data['token'] as String;
    if (data is List && data.isNotEmpty) return data.first['token'] as String;
    throw StateError('QR kod oluşturulamadı.');
  }

  Future<void> setRunStatus(String runId, String status) => client
      .rpc(
        'efeler_set_run_status',
        params: {'p_run_id': runId, 'p_status': status},
      )
      .then((_) {});

  Future<void> deleteAccount() =>
      client.rpc('efeler_delete_account').then((_) => client.auth.signOut());

  String _code(dynamic value) {
    if (value is Map) return value['code'] as String? ?? 'unknown';
    if (value is List && value.isNotEmpty) {
      return value.first['code'] as String? ?? 'unknown';
    }
    return 'unknown';
  }
}
