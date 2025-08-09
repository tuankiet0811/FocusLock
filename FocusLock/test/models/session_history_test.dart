import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/models/session_history.dart';

void main() {
  group('SessionHistory Model Tests', () {
    test('JSON Serialization should handle missing optional fields in JSON', () {
      // Test with all required fields
      final json = {
        'id': 'test-id',
        'sessionId': 'session-123',
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'started',
        'data': {},
        'note': null,
      };

      final sessionHistory = SessionHistory.fromJson(json);
      expect(sessionHistory.id, 'test-id');
      expect(sessionHistory.sessionId, 'session-123');
      expect(sessionHistory.action, SessionAction.started);
      
      // Test toJson doesn't include null values
      final serialized = sessionHistory.toJson();
      expect(serialized, isA<Map<String, dynamic>>());
      expect(serialized['note'], null);
    });

    test('Constructor should create SessionHistory with required parameters', () {
      final sessionHistory = SessionHistory(
        id: 'test-id',
        sessionId: 'session-123',
        timestamp: DateTime.now(),
        action: SessionAction.started,
        data: {'key': 'value'},
        note: 'Test note',
      );

      expect(sessionHistory.id, 'test-id');
      expect(sessionHistory.sessionId, 'session-123');
      expect(sessionHistory.action, SessionAction.started);
      expect(sessionHistory.data['key'], 'value');
      expect(sessionHistory.note, 'Test note');
    });
  });
}