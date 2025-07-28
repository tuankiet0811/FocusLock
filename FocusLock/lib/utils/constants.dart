class AppConstants {
  // App Info
  static const String appName = 'FocusLock';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String focusSessionsKey = 'focus_sessions';
  static const String blockedAppsKey = 'blocked_apps';
  static const String settingsKey = 'app_settings';
  static const String statisticsKey = 'statistics';
  static const String sessionHistoryKey = 'session_history';
  
  // Default Focus Durations (in minutes)
  static const List<int> defaultDurations = [5, 15, 25, 45, 60, 90, 120];
  
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
  
  // Modern Color Palette
  static const int primaryColor = 0xFF6366F1; // Indigo-500
  static const int primaryLightColor = 0xFF818CF8; // Indigo-400
  static const int primaryDarkColor = 0xFF4F46E5; // Indigo-600
  static const int accentColor = 0xFF10B981; // Emerald-500
  static const int successColor = 0xFF059669; // Emerald-600
  static const int warningColor = 0xFFF59E0B; // Amber-500
  static const int errorColor = 0xFFEF4444; // Red-500
  static const int surfaceColor = 0xFFF8FAFC; // Slate-50
  static const int backgroundColor = 0xFFFFFFFF; // White
  static const int cardColor = 0xFFFFFFFF; // White
  
  // Text Colors
  static const int textPrimaryColor = 0xFF1E293B; // Slate-800
  static const int textSecondaryColor = 0xFF64748B; // Slate-500
  static const int textTertiaryColor = 0xFF94A3B8; // Slate-400
  
  // Notification IDs
  static const int focusStartNotificationId = 1001;
  static const int focusEndNotificationId = 1002;
  static const int appBlockedNotificationId = 1003;
  static const int focusProgressNotificationId = 1004;
  
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
  
  // Icon mappings for better UX
  static const Map<String, int> categoryIcons = {
    'all': 0xe047, // Icons.apps
    'social': 0xe7ef, // Icons.people
    'entertainment': 0xe40f, // Icons.movie
    'gaming': 0xe021, // Icons.games
    'productivity': 0xe8f9, // Icons.work
    'education': 0xe80c, // Icons.school
    'health': 0xe3ab, // Icons.favorite
    'finance': 0xe227, // Icons.account_balance_wallet
  };
}