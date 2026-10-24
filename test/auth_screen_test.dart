import 'package:efeler_running_club/features/auth/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('registration requires KVKK consent', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: AuthScreen(mode: AuthMode.register)),
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Kayıt ol'));
    await tester.pump();
    expect(find.textContaining('KVKK metnini onaylamalısın'), findsOneWidget);
  });
}
