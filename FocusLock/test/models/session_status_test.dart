import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/models/session_status.dart';

void main() {
  group('SessionStatus Enum Tests', () {
    group('Enum Values', () {
      test('should have all expected values', () {
        expect(SessionStatus.values.length, 4);
        expect(SessionStatus.values, contains(SessionStatus.running));
        expect(SessionStatus.values, contains(SessionStatus.paused));
        expect(SessionStatus.values, contains(SessionStatus.completed));
        expect(SessionStatus.values, contains(SessionStatus.cancelled));
      });

      test('should have correct string representations', () {
        expect(SessionStatus.running.name, 'running');
        expect(SessionStatus.paused.name, 'paused');
        expect(SessionStatus.completed.name, 'completed');
        expect(SessionStatus.cancelled.name, 'cancelled');
      });
    });

    group('Enum Comparison', () {
      test('should compare correctly', () {
        expect(SessionStatus.running == SessionStatus.running, true);
        expect(SessionStatus.running == SessionStatus.paused, false);
        expect(SessionStatus.completed != SessionStatus.cancelled, true);
      });

      test('should work in switch statements', () {
        String getStatusDescription(SessionStatus status) {
          switch (status) {
            case SessionStatus.running:
              return 'Session is running';
            case SessionStatus.paused:
              return 'Session is paused';
            case SessionStatus.completed:
              return 'Session completed';
            case SessionStatus.cancelled:
              return 'Session cancelled';
          }
        }

        expect(getStatusDescription(SessionStatus.running), 'Session is running');
        expect(getStatusDescription(SessionStatus.paused), 'Session is paused');
        expect(getStatusDescription(SessionStatus.completed), 'Session completed');
        expect(getStatusDescription(SessionStatus.cancelled), 'Session cancelled');
      });
    });

    group('Enum Serialization', () {
      test('should serialize to string correctly', () {
        expect(SessionStatus.running.toString(), 'SessionStatus.running');
        expect(SessionStatus.paused.toString(), 'SessionStatus.paused');
        expect(SessionStatus.completed.toString(), 'SessionStatus.completed');
        expect(SessionStatus.cancelled.toString(), 'SessionStatus.cancelled');
      });

      test('should find enum by name', () {
        expect(
          SessionStatus.values.firstWhere((e) => e.name == 'running'),
          SessionStatus.running,
        );
        expect(
          SessionStatus.values.firstWhere((e) => e.name == 'paused'),
          SessionStatus.paused,
        );
        expect(
          SessionStatus.values.firstWhere((e) => e.name == 'completed'),
          SessionStatus.completed,
        );
        expect(
          SessionStatus.values.firstWhere((e) => e.name == 'cancelled'),
          SessionStatus.cancelled,
        );
      });
    });

    group('Enum Collections', () {
      test('should work in lists', () {
        final activeStatuses = [SessionStatus.running, SessionStatus.paused];
        final inactiveStatuses = [SessionStatus.completed, SessionStatus.cancelled];

        expect(activeStatuses.contains(SessionStatus.running), true);
        expect(activeStatuses.contains(SessionStatus.completed), false);
        expect(inactiveStatuses.contains(SessionStatus.cancelled), true);
        expect(inactiveStatuses.contains(SessionStatus.running), false);
      });

      test('should work in sets', () {
        final statusSet = {SessionStatus.running, SessionStatus.paused, SessionStatus.running};
        
        expect(statusSet.length, 2); // Duplicates removed
        expect(statusSet.contains(SessionStatus.running), true);
        expect(statusSet.contains(SessionStatus.paused), true);
        expect(statusSet.contains(SessionStatus.completed), false);
      });

      test('should work in maps', () {
        final statusDescriptions = {
          SessionStatus.running: 'Đang chạy',
          SessionStatus.paused: 'Đã tạm dừng',
          SessionStatus.completed: 'Đã hoàn thành',
          SessionStatus.cancelled: 'Đã hủy',
        };

        expect(statusDescriptions[SessionStatus.running], 'Đang chạy');
        expect(statusDescriptions[SessionStatus.completed], 'Đã hoàn thành');
      });
    });
  });
}