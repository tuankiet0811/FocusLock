import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/utils/helpers.dart';

void main() {
  group('Helpers Tests', () {
    // Test 1: formatDuration dưới 60 phút -> "x phút"
    test('formatDuration should format minutes under 60 as "x phút"', () {
      expect(Helpers.formatDuration(45), '45 phút');
    });

    // Test 2: formatDuration đúng 60 phút -> "1 giờ"
    test('formatDuration should format 60 minutes as "1 giờ"', () {
      expect(Helpers.formatDuration(60), '1 giờ');
    });

    // Test 3: formatDuration trên 60 phút -> "h giờ m phút"
    test('formatDuration should format over 60 minutes as "h giờ m phút"', () {
      expect(Helpers.formatDuration(150), '2 giờ 30 phút');
    });

    // Test 4: formatTimeRemaining dưới 1 giờ -> "mm:ss"
    test('formatTimeRemaining should format duration < 1h as mm:ss', () {
      expect(
        Helpers.formatTimeRemaining(const Duration(minutes: 5, seconds: 30)),
        '05:30',
      );
    });

    // Test 5: formatTimeRemaining trên 1 giờ -> "HH:MM:SS"
    test('formatTimeRemaining should format duration >= 1h as HH:MM:SS', () {
      expect(
        Helpers.formatTimeRemaining(const Duration(hours: 1, minutes: 5, seconds: 9)),
        '01:05:09',
      );
    });

    // Test 6: formatDate theo định dạng dd/MM/yyyy
    test('formatDate should format to dd/MM/yyyy', () {
      final date = DateTime(2023, 2, 1);
      expect(Helpers.formatDate(date), '01/02/2023');
    });

    // Test 7: formatDateTime theo định dạng dd/MM/yyyy HH:mm
    test('formatDateTime should format to dd/MM/yyyy HH:mm', () {
      final date = DateTime(2023, 2, 1, 14, 30);
      expect(Helpers.formatDateTime(date), '01/02/2023 14:30');
    });

    // Test 8: getCompletionPercentage khi currentTime trước startTime -> 0%
    test('getCompletionPercentage returns 0 when current is before start', () {
      final start = DateTime(2023, 1, 1, 10, 0, 0);
      final end = DateTime(2023, 1, 1, 11, 0, 0);
      final current = DateTime(2023, 1, 1, 9, 59, 59);
      expect(Helpers.getCompletionPercentage(start, end, current), 0.0);
    });

    // Test 9: getCompletionPercentage khi currentTime sau endTime -> 100%
    test('getCompletionPercentage returns 100 when current is after end', () {
      final start = DateTime(2023, 1, 1, 10, 0, 0);
      final end = DateTime(2023, 1, 1, 11, 0, 0);
      final current = DateTime(2023, 1, 1, 12, 0, 0);
      expect(Helpers.getCompletionPercentage(start, end, current), 100.0);
    });

    // Test 10: getCompletionPercentage giữa khoảng -> 50%
    test('getCompletionPercentage returns 50 at the midpoint', () {
      final start = DateTime(2023, 1, 1, 10, 0, 0);
      final end = DateTime(2023, 1, 1, 11, 0, 0);
      final current = DateTime(2023, 1, 1, 10, 30, 0);
      expect(Helpers.getCompletionPercentage(start, end, current).round(), 50);
    });

    // Test 11: getMotivationalMessage < 25%
    test('getMotivationalMessage under 25% encourages starting', () {
      expect(Helpers.getMotivationalMessage(10).contains('Bắt đầu'), true);
    });

    // Test 12: getMotivationalMessage < 50%
    test('getMotivationalMessage under 50% motivates to continue', () {
      expect(Helpers.getMotivationalMessage(40).contains('Bạn đang'), true);
    });

    // Test 13: getMotivationalMessage < 75%
    test('getMotivationalMessage under 75% indicates halfway there', () {
      expect(Helpers.getMotivationalMessage(60).contains('Đã được một nửa'), true);
    });

    // Test 14: getMotivationalMessage < 100%
    test('getMotivationalMessage under 100% says almost done', () {
      expect(Helpers.getMotivationalMessage(90).contains('Gần hoàn thành'), true);
    });

    // Test 15: getMotivationalMessage >= 100%
    test('getMotivationalMessage at 100% congratulates completion', () {
      expect(Helpers.getMotivationalMessage(100).contains('Tuyệt vời'), true);
    });

    // Test 16: getMotivationalEmoji < 25%
    test('getMotivationalEmoji under 25% is rocket', () {
      expect(Helpers.getMotivationalEmoji(10), '🚀');
    });

    // Test 17: getMotivationalEmoji < 50%
    test('getMotivationalEmoji under 50% is flex', () {
      expect(Helpers.getMotivationalEmoji(40), '💪');
    });

    // Test 18: getMotivationalEmoji < 75%
    test('getMotivationalEmoji under 75% is fire', () {
      expect(Helpers.getMotivationalEmoji(60), '🔥');
    });

    // Test 19: getMotivationalEmoji < 100%
    test('getMotivationalEmoji under 100% is target', () {
      expect(Helpers.getMotivationalEmoji(90), '🎯');
    });

    // Test 20: getMotivationalEmoji >= 100%
    test('getMotivationalEmoji at 100% is party', () {
      expect(Helpers.getMotivationalEmoji(100), '🎉');
    });

    // Test 21: calculateTotalFocusTime dùng actualFocusMinutes nếu có, fallback durationMinutes
    test('calculateTotalFocusTime uses actualFocusMinutes if present, else durationMinutes', () {
      final sessions = [
        {
          'durationMinutes': 30,
          'actualFocusMinutes': 20,
        },
        {
          'durationMinutes': 30,
          // actualFocusMinutes không có -> dùng durationMinutes
        },
      ];
      expect(Helpers.calculateTotalFocusTime(sessions), 50);
    });
  });
}

