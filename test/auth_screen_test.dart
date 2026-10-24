import 'package:efeler_running_club/features/auth/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

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
