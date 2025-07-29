import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // Thêm import này
import '../utils/constants.dart';
import '../utils/helpers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Thêm MethodChannel để giao tiếp với native Android
  static const MethodChannel _channel = MethodChannel('focuslock/notifications');
  
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

  // Thêm method để tạo dynamic channel ID
  String _getFocusChannelId(bool soundEnabled, bool vibrationEnabled) {
    return 'focus_channel_s${soundEnabled ? '1' : '0'}_v${vibrationEnabled ? '1' : '0'}';
  }

  String _getAppBlockedChannelId(bool soundEnabled, bool vibrationEnabled) {
    return 'app_blocked_channel_s${soundEnabled ? '1' : '0'}_v${vibrationEnabled ? '1' : '0'}';
  }
  
  // Cập nhật _createNotificationChannels
  Future<void> _createNotificationChannels() async {
    final prefs = await SharedPreferences.getInstance();
    final vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    final soundEnabled = prefs.getBool('sound_enabled') ?? true;
    
    final focusChannelId = _getFocusChannelId(soundEnabled, vibrationEnabled);
    final appBlockedChannelId = _getAppBlockedChannelId(soundEnabled, vibrationEnabled);
    
    final focusChannel = AndroidNotificationChannel(
      focusChannelId,
      'Focus Sessions',
      description: 'Thông báo về phiên tập trung',
      importance: Importance.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
    );
  
    final appBlockedChannel = AndroidNotificationChannel(
      appBlockedChannelId,
      'App Blocked', 
      description: 'Thông báo khi ứng dụng bị chặn',
      importance: Importance.max,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
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
    
    // Sử dụng dynamic channel ID
    final channelId = _getFocusChannelId(shouldPlaySound, shouldVibrate);
    
    final androidDetails = AndroidNotificationDetails(
      channelId, // ✅ Sử dụng dynamic channel ID
      'Focus Sessions',
      channelDescription: 'Thông báo về phiên tập trung',
      showWhen: true,
      // Không cần set playSound và enableVibration ở đây nữa
      // vì đã được set trong channel
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
  // Cập nhật showFocusEndNotification
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
    
    // ✅ Sử dụng dynamic channel ID
    final channelId = _getFocusChannelId(shouldPlaySound, shouldVibrate);
    
    final androidDetails = AndroidNotificationDetails(
      channelId, // ✅ Dynamic channel ID
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
    
    // ✅ Sử dụng dynamic channel ID
    final channelId = _getAppBlockedChannelId(shouldPlaySound, shouldVibrate);
    
    final androidDetails = AndroidNotificationDetails(
      channelId, // ✅ Dynamic channel ID
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
  // Sửa method updateNotificationSettings
Future<void> updateNotificationSettings() async {
// Không thể xóa channels trên Android 8.0+, thay vào đó tạo channels mới với ID khác
// hoặc sử dụng cách tiếp cận khác
// Cách 1: Tạo lại channels (Android sẽ bỏ qua nếu đã tồn tại)
await _createNotificationChannels();
// Cách 2: Sử dụng channel ID động dựa trên settings
// Điều này sẽ tạo channel mới mỗi khi settings thay đổi
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
    
    // ✅ Sử dụng dynamic channel ID
    final channelId = _getFocusChannelId(shouldPlaySound, shouldVibrate);
    
    final androidDetails = AndroidNotificationDetails(
      channelId, // ✅ Dynamic channel ID
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
      
      // ✅ Sử dụng dynamic channel ID
      final channelId = _getFocusChannelId(shouldPlaySound, shouldVibrate);
      
      final androidDetails = AndroidNotificationDetails(
        channelId, // ✅ Dynamic channel ID
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
  
  // Thêm method kiểm tra notification permission từ hệ thống
  Future<bool> areNotificationsEnabled() async {
    try {
      // Kiểm tra từ native Android
      final result = await _channel.invokeMethod('checkNotificationPermission');
      return result ?? false;
    } catch (e) {
      print('Error checking notification permission: $e');
      
      // Fallback: kiểm tra bằng flutter_local_notifications
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final bool? enabled = await androidImplementation.areNotificationsEnabled();
        return enabled ?? false;
      }
      return false;
    }
  }
  
  // Method để đồng bộ và thông báo cho người dùng
  // Cập nhật method syncWithSystemSettings
Future<void> syncWithSystemSettings({bool showUserNotification = false}) async {
  final systemNotificationsEnabled = await areNotificationsEnabled();
  final prefs = await SharedPreferences.getInstance();
  final currentAppSetting = prefs.getBool('notifications_enabled') ?? true;
  
  // Chỉ cập nhật nếu:
  // 1. System notifications bị tắt (ưu tiên system setting)
  // 2. Hoặc nếu system bật nhưng app setting chưa được set (lần đầu)
  bool shouldUpdate = false;
  bool newValue = currentAppSetting;
  
  if (!systemNotificationsEnabled) {
    // Nếu system tắt, buộc phải tắt app setting
    shouldUpdate = currentAppSetting != false;
    newValue = false;
  }
  // Không tự động bật lại nếu user đã tắt trong app
  
  if (shouldUpdate) {
    await prefs.setBool('notifications_enabled', newValue);
    
    // Tạo lại notification channels với cài đặt mới
    await updateNotificationSettings();
    
    // Thông báo cho người dùng nếu cần
    if (showUserNotification) {
      final message = newValue 
          ? 'Thông báo đã được bật từ cài đặt hệ thống'
          : 'Thông báo đã được tắt do cài đặt hệ thống';
      print('Notification setting changed: $message');
    }
  }
}
}