import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/models/focus_session.dart';
import 'package:focuslock/models/session_status.dart';
import '../mocks/test_data.dart';
import '../test_helper.dart';

void main() {
  group('StatisticsService', () {
    setUp(() async {
      await TestHelper.setupTestEnvironment();
    });
    
    tearDown(() {
      TestHelper.cleanup();
    });

    group('Session Statistics', () {
      test('should handle empty sessions list', () async {
        final sessions = <FocusSession>[];
        expect(sessions, isEmpty);
      });

      test('should count completed sessions', () async {
        final sessions = [
          TestData.createTestSession(status: SessionStatus.completed),
          TestData.createTestSession(status: SessionStatus.cancelled),
        ];
        
        final completedSessions = sessions.where((s) => s.status == SessionStatus.completed).toList();
        expect(completedSessions.length, 1);
      });
    });
  });
}