import 'package:efeler_running_club/core/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('planned run response includes coach and reservation details', () {
    final run = ClubRun.fromJson({
      'id': 'run-1',
      'title': 'Tekstil Park Koşusu',
      'starts_at': '2026-10-29T05:30:00+00:00',
      'location': 'Tekstil Park',
      'status': 'scheduled',
      'points': 15,
      'capacity': 30,
      'reserved_count': 0,
      'is_reserved': false,
      'coach_name': 'Mustafa Eraslan',
      'coach_bio': 'Koşu antrenörü',
    });

    expect(run.title, 'Tekstil Park Koşusu');
    expect(run.coachName, 'Mustafa Eraslan');
    expect(run.availableSpots, 30);
  });
}
