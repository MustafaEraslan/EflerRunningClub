import 'package:efeler_running_club/core/theme/app_theme.dart';
import 'package:efeler_running_club/core/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('confirm dialog buttons share size and sit side by side', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showConfirmDialog(
              context,
              title: 'Ödülü talep et',
              message: 'Tişört için 200 puan kullanılsın mı?',
              confirmLabel: 'Onayla',
            ),
            child: const Text('aç'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    final cancel = tester.getRect(find.widgetWithText(FilledButton, 'Vazgeç'));
    final confirm = tester.getRect(find.widgetWithText(FilledButton, 'Onayla'));
    expect(cancel.size, confirm.size);
    expect(cancel.top, confirm.top);
    expect(cancel.right, lessThan(confirm.left));

    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
