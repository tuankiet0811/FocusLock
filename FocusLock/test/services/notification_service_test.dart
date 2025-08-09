import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/services/notification_service.dart';
import '../mocks/mock_services.dart';

void main() {
  group('NotificationService Tests', () {
    late ExtendedMockNotificationService notificationService;

    setUp(() {
      notificationService = ExtendedMockNotificationService();
    });

    group('Session Notifications', () {
      test('should show session start notification', () async {
        await notificationService.showFocusStartNotification(
          durationMinutes: 25,
          goal: 'Test goal',
        );
        
        expect(notificationService.lastNotificationId, greaterThan(0));
      });

      test('should show session complete notification', () async {
        await notificationService.showFocusEndNotification(
          durationMinutes: 25,
          completed: true,
          goal: 'Test goal',
        );
        
        expect(notificationService.lastNotificationId, greaterThan(0));
      });

      test('should show session paused notification', () async {
        await notificationService.showFocusPausedNotification();
        
        expect(notificationService.lastNotificationId, greaterThan(0));
      });

      test('should show session resumed notification', () async {
        await notificationService.showFocusResumedNotification();
        
        expect(notificationService.lastNotificationId, greaterThan(0));
      });

      test('should show session progress notification', () async {
        await notificationService.showFocusProgressNotification(
          remainingMinutes: 20,
          remainingSeconds: 30,
          completionPercentage: 75.0,
          goal: 'Test goal',
        );
        
        expect(notificationService.lastNotificationId, greaterThan(0));
      });
    });
  });
}