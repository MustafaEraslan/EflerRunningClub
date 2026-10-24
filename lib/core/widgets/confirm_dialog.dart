import 'package:flutter/material.dart';

/// Secondary (cancel) variant of the app's FilledButton: same size, shape and
/// text style as the primary button, only the colours differ.
final secondaryFilledButtonStyle = FilledButton.styleFrom(
  backgroundColor: const Color(0xFF343036),
  foregroundColor: Colors.white,
);

/// Confirmation dialog with equal-width "Vazgeç" / confirm buttons side by side.
///
/// The app theme gives FilledButton an infinite minimum width, so buttons must
/// be laid out in Expanded slots instead of the default OverflowBar.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Vazgeç',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        Row(
          children: [
            Expanded(
              child: FilledButton(
                style: secondaryFilledButtonStyle,
                onPressed: () => Navigator.pop(context, false),
                child: Text(cancelLabel, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return confirmed == true;
}
