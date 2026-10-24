import 'package:efeler_running_club/core/errors/result_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('check-in result messages', () {
    test('maps known server codes to Turkish', () {
      expect(checkInMessage('expired_token'), contains('süresi doldu'));
      expect(checkInMessage('already_checked_in'), contains('daha önce'));
      expect(checkInMessage('run_closed'), contains('kapalı'));
    });

    test('has a safe fallback', () {
      expect(checkInMessage('new_server_code'), contains('tamamlanamadı'));
    });
  });

  test('maps reward failures', () {
    expect(redeemMessage('no_stock'), contains('stokta yok'));
    expect(redeemMessage('not_enough_points'), contains('yeterli puanın yok'));
  });
}
