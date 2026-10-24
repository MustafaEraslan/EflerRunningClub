import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

  Future<void> resetPassword(String email) => client.auth
      .resetPasswordForEmail(
        email.trim(),
        redirectTo: 'com.efelerrunningclub.app://reset-password',
      )
      .then((_) {});

  Future<void> updatePassword(String password) =>
      client.auth.updateUser(UserAttributes(password: password)).then((_) {});

  Future<void> signOut() => client.auth.signOut();

  Future<void> signInWithSocialProvider(OAuthProvider provider) => client.auth
      .signInWithOAuth(
        provider,
        redirectTo: 'com.efelerrunningclub.app://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      )
      .then((_) {});

  Future<void> signInWithApple() async {
    final rawNonce = client.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException('Apple kimlik bilgisi alınamadı.');
    }
    await client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
    final appleName = [
      credential.givenName,
      credential.familyName,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
    if (appleName.isNotEmpty) {
      await client.auth.updateUser(
        UserAttributes(data: {'full_name': appleName}),
      );
    }
  }

  Future<void> ensureSocialProfile() =>
      client.rpc('efeler_ensure_profile').then((_) {});

  Future<Profile> getProfile() async {
    final data = await client
        .from('efeler_profiles')
        .select()
        .eq('app_id', AppConfig.appId)
        .eq('id', user!.id)
        .single();
    final profile = Profile.fromJson(data);
    final url = await resolveAvatarUrl(profile.avatarPath);
    return profile.copyWith(avatarUrl: url);
  }

  Future<void> updateProfile(String fullName, String bio) => client
      .rpc(
        'efeler_update_profile',
        params: {'p_full_name': fullName.trim(), 'p_bio': bio.trim()},
      )
      .then((_) {});

  /// Public URL for objects in the public efeler-media bucket (reward images, etc.)
  String mediaUrl(String path) =>
      client.storage.from('efeler-media').getPublicUrl(path);

  /// Resolves an avatar storage path to a displayable URL.
  ///
  /// Legacy paths (avatars/{id}.jpg) live in the public efeler-media bucket.
  /// New paths ({id}/avatar.jpg) live in the private efeler-avatars bucket and
  /// require a signed URL (1-week expiry; refreshed on every profile/member/run fetch).
  Future<String?> resolveAvatarUrl(String? path) async {
    if (path == null) return null;
    if (path.startsWith('avatars/')) {
      // Legacy: public bucket – return synchronously.
      return client.storage.from('efeler-media').getPublicUrl(path);
    }
    try {
      return await client.storage
          .from('efeler-avatars')
          .createSignedUrl(path, 604800); // 1 week
    } catch (_) {
      return null;
    }
  }

  /// Upload the user's avatar to efeler-avatars, then update their profile path.
  /// [bytes] should be a JPEG, ≤512×512 px, ~80 % quality.
  Future<void> uploadProfileAvatar(Uint8List bytes) async {
    final path = '${user!.id}/avatar.jpg';
    await client.storage
        .from('efeler-avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
            cacheControl: '1',  // 1 second – forces re-fetch after re-upload
          ),
        );
    final profile = await getProfile();
    await client.rpc(
      'efeler_update_profile',
      params: {
        'p_full_name': profile.fullName,
        'p_bio': profile.bio,
        'p_avatar_path': path,
      },
    );
  }

  Future<List<ClubMember>> getMembers() async {
    final data = await client.rpc('efeler_list_members');
    final rows = List<Map<String, dynamic>>.from(data as List);
    final members = rows.map(ClubMember.fromJson).toList(growable: false);
    final urls = await Future.wait(
      members.map((m) => resolveAvatarUrl(m.avatarPath)),
    );
    return [for (var i = 0; i < members.length; i++) members[i].withAvatarUrl(urls[i])];
  }

  Future<void> promoteToCoach(String memberId) => client
      .rpc('efeler_promote_to_coach', params: {'p_member_id': memberId})
      .then((_) {});

  Future<void> setCoachLevel(String coachId, int level) => client
      .rpc(
        'efeler_set_coach_level',
        params: {'p_coach_id': coachId, 'p_level': level},
      )
      .then((_) {});

  Future<void> changeRunnerLevel(String memberId, int direction) => client
      .rpc(
        'efeler_change_runner_level',
        params: {'p_member_id': memberId, 'p_direction': direction},
      )
      .then((_) {});

  Future<List<ClubRun>> getRuns() async {
    final data = await client.rpc('efeler_list_runs');
    final rows = List<Map<String, dynamic>>.from(data as List);
    final runs = rows.map(ClubRun.fromJson).toList(growable: false);
    final urls = await Future.wait(
      runs.map((r) => resolveAvatarUrl(r.coachAvatarPath)),
    );
    return [for (var i = 0; i < runs.length; i++) runs[i].withCoachAvatarUrl(urls[i])];
  }

  Future<List<Reward>> getRewards() async {
    final data = await client
        .from('efeler_rewards')
        .select()
        .eq('app_id', AppConfig.appId)
        .eq('active', true)
        .order('points_cost');
    final rows = List<Map<String, dynamic>>.from(data);
    return rows.map(Reward.fromJson).toList(growable: false);
  }

  Future<String> createReward({
    required String name,
    required String description,
    required int pointsCost,
    required int stock,
  }) async {
    final data = await client.rpc(
      'efeler_create_reward',
      params: {
        'p_name': name.trim(),
        'p_description': description.trim(),
        'p_points_cost': pointsCost,
        'p_stock': stock,
      },
    );
    return data as String;
  }

  Future<void> uploadRewardImage(String rewardId, Uint8List bytes) async {
    final path = 'rewards/$rewardId.jpg';
    await client.storage
        .from('efeler-media')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
            cacheControl: '3600',
          ),
        );
    await client.rpc(
      'efeler_set_reward_image',
      params: {'p_reward_id': rewardId, 'p_image_path': path},
    );
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

  Future<void> createRun({
    required String title,
    required DateTime startsAt,
    required String location,
    required int points,
    required int capacity,
  }) => client
      .rpc(
        'efeler_create_run',
        params: {
          'p_title': title.trim(),
          'p_starts_at': startsAt.toUtc().toIso8601String(),
          'p_location': location.trim(),
          'p_points': points,
          'p_capacity': capacity,
        },
      )
      .then((_) {});

  Future<void> updateRun({
    required String runId,
    required String title,
    required DateTime startsAt,
    required String location,
    required int points,
    required int capacity,
  }) => client
      .rpc(
        'efeler_update_run',
        params: {
          'p_run_id': runId,
          'p_title': title.trim(),
          'p_starts_at': startsAt.toUtc().toIso8601String(),
          'p_location': location.trim(),
          'p_points': points,
          'p_capacity': capacity,
        },
      )
      .then((_) {});

  Future<void> updateReward({
    required String rewardId,
    required String name,
    required String description,
    required int pointsCost,
    required int stock,
  }) => client
      .rpc(
        'efeler_update_reward',
        params: {
          'p_reward_id': rewardId,
          'p_name': name.trim(),
          'p_description': description.trim(),
          'p_points_cost': pointsCost,
          'p_stock': stock,
        },
      )
      .then((_) {});

  Future<void> deleteReward(String rewardId) => client
      .rpc('efeler_delete_reward', params: {'p_reward_id': rewardId})
      .then((_) {});

  Future<String> reserveRun(String runId) async {
    final data = await client.rpc(
      'efeler_reserve_run',
      params: {'p_run_id': runId},
    );
    return _code(data);
  }

  Future<String> cancelReservation(String runId) async {
    final data = await client.rpc(
      'efeler_cancel_reservation',
      params: {'p_run_id': runId},
    );
    return _code(data);
  }

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
