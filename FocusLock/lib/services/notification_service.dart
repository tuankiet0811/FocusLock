import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thêm import này
import '../utils/constants.dart';
import '../utils/helpers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Thêm các biến instance bị thiếu
  bool _isProgressNotificationShown = false;
  int? _lastProgressPercentage;

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
  
    await _notifications.initialize(initSettings);
    await _requestNotificationPermission();
    await _createNotificationChannels();
  }

  Future<void> _requestNotificationPermission() async {
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      // Xóa print statement để tránh warning
      if (granted != null && granted) {
        // Permission granted
      }
    }
  }

  Future<void> _createNotificationChannels() async {
    const focusChannel = AndroidNotificationChannel(
      AppConstants.focusChannelId,
      'Focus Sessions',
      description: 'Thông báo về phiên tập trung',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
  
    const appBlockedChannel = AndroidNotificationChannel(
      AppConstants.appBlockedChannelId,
      'App Blocked',
      description: 'Thông báo khi ứng dụng bị chặn',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
  
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(focusChannel);
      await androidImplementation.createNotificationChannel(appBlockedChannel);
    }
  }

  // Thêm method kiểm tra settings
  Future<bool> _shouldShowNotification() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }
  
  Future<bool> _shouldPlaySound() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    final soundEnabled = prefs.getBool('sound_enabled') ?? true;
    return notificationsEnabled && soundEnabled;
  }
  
  Future<bool> _shouldVibrate() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    final vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    return notificationsEnabled && vibrationEnabled;
  }
  
  // Cập nhật method showFocusStartNotification
  Future<void> showFocusStartNotification({
    required int durationMinutes,
    String? goal,
  }) async {
    // Kiểm tra xem có nên hiển thị thông báo không
    if (!await _shouldShowNotification()) {
      return; // Không hiển thị thông báo nếu đã tắt
    }
    
    final shouldPlaySound = await _shouldPlaySound();
    final shouldVibrate = await _shouldVibrate();
    
    final androidDetails = AndroidNotificationDetails(
      AppConstants.focusChannelId,
      'Focus Sessions',
      channelDescription: 'Thông báo về phiên tập trung',
      showWhen: true,
      playSound: shouldPlaySound,
      enableVibration: shouldVibrate,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: shouldPlaySound,
    );

    final details = NotificationDetails(
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
  
  // Cập nhật method showFocusEndNotification
  Future<void> showFocusEndNotification({
    required int durationMinutes,
    required bool completed,
    String? goal,
  }) async {
    if (!await _shouldShowNotification()) {
      return;
    }
    
    final shouldPlaySound = await _shouldPlaySound();
    final shouldVibrate = await _shouldVibrate();
    
    final androidDetails = AndroidNotificationDetails(
      AppConstants.focusChannelId,
      'Focus Sessions',
      channelDescription: 'Thông báo về phiên tập trung',
      showWhen: true,
      playSound: shouldPlaySound,
      enableVibration: shouldVibrate,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: shouldPlaySound,
    );

    final details = NotificationDetails(
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
  
  // Cập nhật method showAppBlockedNotification
  Future<void> showAppBlockedNotification({
    required String appName,
    required int remainingMinutes,
  }) async {
    if (!await _shouldShowNotification()) {
      return;
    }
    
    final shouldPlaySound = await _shouldPlaySound();
    final shouldVibrate = await _shouldVibrate();
    
    final androidDetails = AndroidNotificationDetails(
      AppConstants.appBlockedChannelId,
      'App Blocked',
      channelDescription: 'Thông báo khi ứng dụng bị chặn',
      showWhen: true,
      playSound: shouldPlaySound,
      enableVibration: shouldVibrate,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: shouldPlaySound,
    );

    final details = NotificationDetails(
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
  
  // Thêm method này để settings_screen.dart có thể gọi
  Future<void> updateNotificationSettings() async {
    // Method này có thể để trống hoặc thực hiện logic cập nhật nếu cần
    // Hiện tại logic kiểm tra settings đã được tích hợp vào từng method riêng
  }

  Future<void> showMotivationalNotification({
    required double completionPercentage,
    required int remainingMinutes,
  }) async {
    // Kiểm tra xem có nên hiển thị thông báo không
    if (!await _shouldShowNotification()) {
      return;
    }
    
    final shouldPlaySound = await _shouldPlaySound();
    final shouldVibrate = await _shouldVibrate();
    
    final androidDetails = AndroidNotificationDetails(
      AppConstants.focusChannelId,
      'Focus Sessions',
      channelDescription: 'Thông báo về phiên tập trung',
      showWhen: true,
      playSound: shouldPlaySound,
      enableVibration: shouldVibrate,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: shouldPlaySound,
    );

    final details = NotificationDetails(
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

  Future<void> showFocusProgressNotification({
    required int remainingMinutes,
    required int remainingSeconds,
    required double completionPercentage,
    String? goal,
  }) async {
    // Kiểm tra xem có nên hiển thị thông báo không
    if (!await _shouldShowNotification()) {
      return;
    }
    
    final currentPercentage = completionPercentage.round();
    
    // Chỉ hiển thị thông báo khi:
    // 1. Lần đầu tiên (_isProgressNotificationShown = false)
    // 2. Hoặc khi % thay đổi đáng kể (mỗi 10%)
    if (!_isProgressNotificationShown || 
        (_lastProgressPercentage != null && 
         (currentPercentage - _lastProgressPercentage!).abs() >= 10)) {
      
      final shouldPlaySound = await _shouldPlaySound();
      final shouldVibrate = await _shouldVibrate();
      
      final progressValue = completionPercentage.round();
      
      final androidDetails = AndroidNotificationDetails(
        AppConstants.focusChannelId,
        'Focus Sessions',
        channelDescription: 'Thông báo về phiên tập trung',
        showWhen: false,
        ongoing: true,
        autoCancel: false,
        priority: Priority.low,
        importance: Importance.low,
        showProgress: true,
        maxProgress: 100,
        progress: progressValue,
        onlyAlertOnce: true,
        playSound: shouldPlaySound,
        enableVibration: shouldVibrate,
      );
    
      final iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: shouldPlaySound,
      );
    
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
    
      final timeText = remainingMinutes > 0 
          ? '${remainingMinutes}:${(remainingSeconds % 60).toString().padLeft(2, '0')}'
          : '${remainingSeconds}s';
      
      final title = goal != null 
          ? '🎯 $goal'
          : '⏰ Đang tập trung';
      
      final body = 'Còn lại: $timeText • ${completionPercentage.round()}% hoàn thành';

      await _notifications.show(
        AppConstants.focusProgressNotificationId,
        title,
        body,
        details,
      );
      
      // Cập nhật flag và percentage
      _isProgressNotificationShown = true;
      _lastProgressPercentage = currentPercentage;
    }
  }

  // Method để reset flag khi bắt đầu session mới
  Future<void> startNewFocusSession() async {
    _isProgressNotificationShown = false;
    _lastProgressPercentage = null;
  }

  // Method hủy thông báo
  Future<void> cancelFocusProgressNotification() async {
    await _notifications.cancel(AppConstants.focusProgressNotificationId);
    _isProgressNotificationShown = false;
    _lastProgressPercentage = null;
  }
}