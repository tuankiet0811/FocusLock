import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/models/focus_session.dart';
import 'package:focuslock/models/session_status.dart';
import '../mocks/test_data.dart';

void main() {
  group('FocusSession Model Tests', () {
    late FocusSession session;

    setUp(() {
      session = TestData.sampleSession;
    });

    group('Constructor and Properties', () {
      test('should create session with required properties', () {
        expect(session.id, 'test-session-1');
        expect(session.durationMinutes, 30);
        expect(session.durationSeconds, 1800);
        expect(session.isActive, false);
        expect(session.status, SessionStatus.completed);
      });

      test('should have correct computed properties', () {
        expect(session.isCompleted, true);
        expect(session.isPaused, false);
        expect(session.isRunning, false);
      });

      test('should handle null values correctly', () {
        final sessionWithNulls = FocusSession(
          id: 'test',
          startTime: DateTime.now(),
          durationMinutes: 30,
          durationSeconds: 1800,
          isActive: false,
          blockedApps: [],
        );

        expect(sessionWithNulls.endTime, isNull);
        expect(sessionWithNulls.goal, isNull);
        expect(sessionWithNulls.pausedTime, isNull);
        expect(sessionWithNulls.actualFocusMinutes, isNull);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final json = session.toJson();

        expect(json['id'], session.id);
        expect(json['durationMinutes'], session.durationMinutes);
        expect(json['isActive'], session.isActive);
        expect(json['status'], session.status.name);
        expect(json['blockedApps'], session.blockedApps);
      });

      test('should deserialize from JSON correctly', () {
        final json = session.toJson();
        final deserializedSession = FocusSession.fromJson(json);

        expect(deserializedSession.id, session.id);
        expect(deserializedSession.durationMinutes, session.durationMinutes);
        expect(deserializedSession.isActive, session.isActive);
        expect(deserializedSession.status, session.status);
        expect(deserializedSession.blockedApps, session.blockedApps);
      });

      test('should handle missing optional fields in JSON', () {
        final minimalJson = {
          'id': 'test',
          'startTime': DateTime.now().toIso8601String(),
          'durationMinutes': 30,
          'isActive': false,
          'blockedApps': <String>[],
          'durationSeconds': 1800,
        };

        final session = FocusSession.fromJson(minimalJson);
        expect(session.endTime, isNull);
        expect(session.goal, isNull);
        expect(session.status, SessionStatus.running); // default
      });
    });

    group('CopyWith Method', () {
      test('should copy with new values', () {
        final newSession = session.copyWith(
          goal: 'New goal',
          isActive: true,
          status: SessionStatus.running,
        );

        expect(newSession.goal, 'New goal');
        expect(newSession.isActive, true);
        expect(newSession.status, SessionStatus.running);
        // Original values should remain
        expect(newSession.id, session.id);
        expect(newSession.durationMinutes, session.durationMinutes);
      });

      test('should keep original values when not specified', () {
        final newSession = session.copyWith();

        expect(newSession.id, session.id);
        expect(newSession.goal, session.goal);
        expect(newSession.isActive, session.isActive);
        expect(newSession.status, session.status);
      });
    });

    group('Status-based Computed Properties', () {
      test('should correctly identify running session', () {
        final runningSession = TestData.createSessionWithStatus(SessionStatus.running);
        expect(runningSession.isRunning, true);
        expect(runningSession.isPaused, false);
        expect(runningSession.isCompleted, false);
      });

      test('should correctly identify paused session', () {
        final pausedSession = TestData.createSessionWithStatus(SessionStatus.paused);
        expect(pausedSession.isRunning, false);
        expect(pausedSession.isPaused, true);
        expect(pausedSession.isCompleted, false);
      });

      test('should correctly identify completed session', () {
        final completedSession = TestData.createSessionWithStatus(SessionStatus.completed);
        expect(completedSession.isRunning, false);
        expect(completedSession.isPaused, false);
        expect(completedSession.isCompleted, true);
      });

      test('should correctly identify cancelled session', () {
        final cancelledSession = TestData.createSessionWithStatus(SessionStatus.cancelled);
        expect(cancelledSession.isRunning, false);
        expect(cancelledSession.isPaused, false);
        expect(cancelledSession.isCompleted, false);
      });
    });

    group('Edge Cases', () {
      test('should handle very long duration', () {
        final longSession = FocusSession(
          id: 'long-session',
          startTime: DateTime.now(),
          durationMinutes: 480, // 8 hours
          durationSeconds: 28800,
          isActive: true,
          blockedApps: [],
        );

        expect(longSession.durationMinutes, 480);
        expect(longSession.durationSeconds, 28800);
      });

      test('should handle zero duration', () {
        final zeroSession = FocusSession(
          id: 'zero-session',
          startTime: DateTime.now(),
          durationMinutes: 0,
          durationSeconds: 0,
          isActive: false,
          blockedApps: [],
        );

        expect(zeroSession.durationMinutes, 0);
        expect(zeroSession.durationSeconds, 0);
      });

      test('should handle empty blocked apps list', () {
        final emptyAppsSession = FocusSession(
          id: 'empty-apps',
          startTime: DateTime.now(),
          durationMinutes: 30,
          durationSeconds: 1800,
          isActive: true,
          blockedApps: [],
        );

        expect(emptyAppsSession.blockedApps, isEmpty);
      });

      test('should handle large blocked apps list', () {
        final manyApps = List.generate(100, (i) => 'com.app$i');
        final manyAppsSession = FocusSession(
          id: 'many-apps',
          startTime: DateTime.now(),
          durationMinutes: 30,
          durationSeconds: 1800,
          isActive: true,
          blockedApps: manyApps,
        );

        expect(manyAppsSession.blockedApps.length, 100);
        expect(manyAppsSession.blockedApps.first, 'com.app0');
        expect(manyAppsSession.blockedApps.last, 'com.app99');
      });
    });
  });
}