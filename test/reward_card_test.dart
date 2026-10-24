import 'package:efeler_running_club/core/models/models.dart';
import 'package:efeler_running_club/core/providers/providers.dart';
import 'package:efeler_running_club/core/theme/app_theme.dart';
import 'package:efeler_running_club/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const longName =
      'Efeler Running Club Resmî Yarış Tişörtü Sınırlı Sayıda Üretim Serisi';
  const longDescription =
      'Nefes alan teknik kumaş, yansıtıcı baskı ve kulüp logosu. '
      'Bedenler S, M, L ve XL olarak kulüpten teslim edilir.';

  for (final scale in [1.0, 2.0]) {
    testWidgets('reward card lays text out horizontally at scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rewardsProvider.overrideWith(
              (ref) async => const [
                Reward(
                  id: 'r1',
                  name: longName,
                  description: longDescription,
                  pointsCost: 20000,
                  stock: 3,
                  imagePath: null,
                ),
              ],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const Scaffold(body: RewardsTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final name = tester.getSize(find.text(longName));
      final description = tester.getSize(find.text(longDescription));
      final pill = tester.getSize(
        find.widgetWithText(FilledButton, '20000 puan'),
      );
      expect(name.width, greaterThan(200));
      expect(description.width, greaterThan(200));
      expect(pill.width, lessThan(390 / 2 * scale));
    });
  }
}
