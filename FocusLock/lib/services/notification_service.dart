import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    // Focus Channel
    const focusChannel = AndroidNotificationChannel(
      AppConstants.focusChannelId,
      'Focus Sessions',
      description: 'Thông báo về phiên tập trung',
    );

    // App Blocked Channel
    const appBlockedChannel = AndroidNotificationChannel(
      AppConstants.appBlockedChannelId,
      'App Blocked',
      description: 'Thông báo khi ứng dụng bị chặn',
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(focusChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(appBlockedChannel);
  }

  Future<void> showFocusStartNotification({
    required int durationMinutes,
    String? goal,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.focusChannelId,
      'Focus Sessions',
      channelDescription: 'Thông báo về phiên tập trung',
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      AppConstants.focusStartNotificationId,
      'Phiên tập trung đã bắt đầu!',
      goal != null 
          ? 'Mục tiêu: $goal\nThời gian: $durationMinutes phút'
          : 'Thời gian: $durationMinutes phút',
      details,
    );
  }

  Future<void> showFocusEndNotification({
    required int durationMinutes,
    required bool completed,
    String? goal,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.focusChannelId,
      'Focus Sessions',
      channelDescription: 'Thông báo về phiên tập trung',
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = completed 
        ? '🎉 Hoàn thành phiên tập trung!'
        : '⏸️ Phiên tập trung đã tạm dừng';
    
    final body = goal != null 
        ? 'Mục tiêu: $goal\nThời gian: $durationMinutes phút'
        : 'Thời gian: $durationMinutes phút';

    await _notifications.show(
      AppConstants.focusEndNotificationId,
      title,
      body,
      details,
    );
  }

  Future<void> showAppBlockedNotification({
    required String appName,
    required int remainingMinutes,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.appBlockedChannelId,
      'App Blocked',
      channelDescription: 'Thông báo khi ứng dụng bị chặn',
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      AppConstants.appBlockedNotificationId,
      '🚫 Ứng dụng bị chặn',
      '$appName đã bị chặn trong thời gian tập trung\nCòn lại: $remainingMinutes phút',
      details,
    );
  }

  Future<void> showMotivationalNotification({
    required double completionPercentage,
    required int remainingMinutes,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.focusChannelId,
      'Focus Sessions',
      channelDescription: 'Thông báo về phiên tập trung',
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final emoji = _getMotivationalEmoji(completionPercentage);
    final message = _getMotivationalMessage(completionPercentage);

    await _notifications.show(
      AppConstants.focusStartNotificationId + 1,
      '$emoji $message',
      'Còn lại: $remainingMinutes phút',
      details,
    );
  }

  String _getMotivationalEmoji(double percentage) {
    if (percentage < 25) return '🚀';
    if (percentage < 50) return '💪';
    if (percentage < 75) return '🔥';
    if (percentage < 100) return '🎯';
    return '🎉';
  }

  String _getMotivationalMessage(double percentage) {
    if (percentage < 25) return 'Bắt đầu là bước quan trọng nhất!';
    if (percentage < 50) return 'Bạn đang làm rất tốt! Hãy tiếp tục!';
    if (percentage < 75) return 'Đã được một nửa rồi! Cố gắng lên!';
    if (percentage < 100) return 'Gần hoàn thành rồi! Đừng bỏ cuộc!';
    return 'Tuyệt vời! Bạn đã hoàn thành!';
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
} 