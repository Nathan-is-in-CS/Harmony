import 'package:flutter_test/flutter_test.dart';
import 'package:harmony/screens/player_screen.dart';

void main() {
  group('PlayerScreen progression guards', () {
    test('returns zero progress when duration is unknown or zero', () {
      expect(PlayerScreen.sliderValueFor(Duration.zero, Duration.zero), 0.0);
      expect(PlayerScreen.sliderValueFor(const Duration(seconds: 3), Duration.zero), 0.0);
    });

    test('clamps progress to the valid millisecond range', () {
      expect(PlayerScreen.sliderValueFor(const Duration(seconds: 8), const Duration(seconds: 4)), 4000.0);
      expect(PlayerScreen.sliderValueFor(const Duration(seconds: -1), const Duration(seconds: 4)), 0.0);
    });

    test('computes the raw position in milliseconds for a valid duration', () {
      expect(PlayerScreen.sliderValueFor(const Duration(seconds: 2), const Duration(seconds: 4)), closeTo(2000.0, 0.0001));
    });
  });
}
