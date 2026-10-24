import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/errors/result_messages.dart';
import '../../core/providers/providers.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  bool processing = false;
  String? message;

  Future<void> detected(BarcodeCapture capture) async {
    final token = capture.barcodes.firstOrNull?.rawValue;
    if (token == null || processing) return;
    setState(() => processing = true);
    try {
      final code = await ref.read(repositoryProvider).checkIn(token);
      ref.invalidate(balanceProvider);
      ref.invalidate(ledgerProvider);
      setState(() => message = checkInMessage(code));
    } catch (_) {
      setState(
        () =>
            message = 'Katılım doğrulanamadı. İnternet bağlantını kontrol et.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Koşuya katıl')),
    body: message != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    message!.startsWith('Katılımın')
                        ? Icons.check_circle
                        : Icons.info,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tamam'),
                  ),
                ],
              ),
            ),
          )
        : Stack(
            children: [
              MobileScanner(onDetect: detected),
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 4),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Antrenörün ekranındaki QR kodu çerçeveye al.',
                      style: TextStyle(color: Colors.white, fontSize: 17),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
  );
}
