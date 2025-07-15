class AppConstants {
  // App Info
  static const String appName = 'FocusLock';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String focusSessionsKey = 'focus_sessions';
  static const String blockedAppsKey = 'blocked_apps';
  static const String settingsKey = 'app_settings';
  static const String statisticsKey = 'statistics';
  
  // Default Focus Durations (in minutes)
  static const List<int> defaultDurations = [15, 25, 45, 60, 90, 120];
  
  // Default Blocked Apps (Social Media)
  static const List<Map<String, String>> defaultBlockedApps = [
    {'packageName': 'com.facebook.katana', 'appName': 'Facebook'},
    {'packageName': 'com.instagram.android', 'appName': 'Instagram'},
    {'packageName': 'com.zhiliaoapp.musically', 'appName': 'TikTok'},
    {'packageName': 'com.twitter.android', 'appName': 'Twitter/X'},
    {'packageName': 'com.threads.android', 'appName': 'Threads'},
    {'packageName': 'com.snapchat.android', 'appName': 'Snapchat'},
    {'packageName': 'com.whatsapp', 'appName': 'WhatsApp'},
    {'packageName': 'com.telegram.messenger', 'appName': 'Telegram'},
    {'packageName': 'com.discord', 'appName': 'Discord'},
    {'packageName': 'com.reddit.frontpage', 'appName': 'Reddit'},
    {'packageName': 'com.pinterest', 'appName': 'Pinterest'},
    {'packageName': 'com.linkedin.android', 'appName': 'LinkedIn'},
    {'packageName': 'com.spotify.music', 'appName': 'Spotify'},
    {'packageName': 'com.netflix.mediaclient', 'appName': 'Netflix'},
    {'packageName': 'com.google.android.youtube', 'appName': 'YouTube'},
  ];
  
  // Colors
  static const int primaryColor = 0xFF2196F3;
  static const int accentColor = 0xFFFF5722;
  static const int successColor = 0xFF4CAF50;
  static const int warningColor = 0xFFFF9800;
  static const int errorColor = 0xFFF44336;
  
  // Notification IDs
  static const int focusStartNotificationId = 1001;
  static const int focusEndNotificationId = 1002;
  static const int appBlockedNotificationId = 1003;
  
  // Channel IDs
  static const String focusChannelId = 'focus_channel';
  static const String appBlockedChannelId = 'app_blocked_channel';
  
  // Messages
  static const String focusStartMessage = 'Phiên tập trung đã bắt đầu!';
  static const String focusEndMessage = 'Phiên tập trung đã kết thúc. Chúc mừng bạn!';
  static const String appBlockedMessage = 'Ứng dụng này đã bị chặn trong thời gian tập trung';
  
  // Permissions
  static const List<String> requiredPermissions = [
    'android.permission.PACKAGE_USAGE_STATS',
    'android.permission.SYSTEM_ALERT_WINDOW',
    'android.permission.FOREGROUND_SERVICE',
  ];
} 