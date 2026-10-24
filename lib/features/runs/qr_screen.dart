import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/providers/providers.dart';

class QrScreen extends ConsumerStatefulWidget {
  const QrScreen({required this.runId, super.key});
  final String runId;
  @override
  ConsumerState<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends ConsumerState<QrScreen> {
  Timer? timer;
  String? token;
  String? error;

  @override
  void initState() {
    super.initState();
    refresh();
    timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  Future<void> refresh() async {
    try {
      final value = await ref.read(repositoryProvider).getQrToken(widget.runId);
      if (mounted) {
        setState(() {
          token = value;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'QR kod yenilenemedi. Koşunun açık ve internet bağlantının aktif olduğundan emin ol.',
        );
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Katılım QR kodu')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (token != null)
              QrImageView(
                data: token!,
                size: 290,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(18),
              )
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              error ?? 'Kod her 30 saniyede otomatik yenilenir.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Şimdi yenile'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                await ref
                    .read(repositoryProvider)
                    .setRunStatus(widget.runId, 'closed');
                ref.invalidate(runsProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Koşuyu kapat'),
            ),
          ],
        ),
      ),
    ),
  );
}
