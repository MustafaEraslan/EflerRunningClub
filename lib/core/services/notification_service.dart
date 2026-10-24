import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles FCM token registration and foreground message display.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  bool _initialised = false;

  /// Call once after the user signs in and the home screen is mounted.
  Future<void> init(BuildContext context) async {
    if (_initialised) return;
    _initialised = true;

    // Request permission (iOS shows a system dialog on first call).
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Save or refresh the device FCM token.
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(token);
    _messaging.onTokenRefresh.listen(_saveToken);

    // Show a SnackBar when a notification arrives while the app is open.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notification.body ?? notification.title ?? ''),
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  Future<void> _saveToken(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.rpc(
        'efeler_save_device_token',
        params: {'p_token': token},
      );
    } catch (_) {
      // Token save is best-effort; don't crash the app.
    }
  }
}
