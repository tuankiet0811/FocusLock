import 'package:focuslock/models/app_info.dart';
import 'package:focuslock/models/focus_session.dart';
import 'package:focuslock/models/session_history.dart';
import 'package:focuslock/models/session_status.dart';
import 'mock_services.dart';

class TestData {
  /// Create a test user
  static MockUser createTestUser() {
    return MockUser(
      uid: 'test_uid_123',
      email: 'test@example.com',
      displayName: 'Test User',
      emailVerified: true,
    );
  }
  
  /// Sample session getter for tests
  static FocusSession get sampleSession {
    return createTestSession(
      id: 'test-session-1',
      durationMinutes: 30,
      status: SessionStatus.completed,
      goal: 'Sample test session',
    );
  }
  
  /// Create session with specific status
  static FocusSession createSessionWithStatus(SessionStatus status) {
    return createTestSession(
      status: status,
      durationMinutes: 25,
      goal: 'Test session with ${status.name} status',
    );
  }
  
  /// Create test app info list
  static List<AppInfo> createTestApps() {
    return [
      AppInfo(
        packageName: 'com.facebook.katana',
        appName: 'Facebook',
        isBlocked: true,
        iconPath: '/path/to/facebook_icon.png',
        usageTimeMinutes: 120,
        category: 'Social',
      ),
      AppInfo(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        isBlocked: true,
        iconPath: '/path/to/instagram_icon.png',
        usageTimeMinutes: 90,
        category: 'Social',
      ),
      AppInfo(
        packageName: 'com.twitter.android',
        appName: 'Twitter',
        isBlocked: false,
        iconPath: '/path/to/twitter_icon.png',
        usageTimeMinutes: 45,
        category: 'Social',
      ),
      AppInfo(
        packageName: 'com.youtube.android',
        appName: 'YouTube',
        isBlocked: true,
        iconPath: '/path/to/youtube_icon.png',
        usageTimeMinutes: 180,
        category: 'Entertainment',
      ),
      AppInfo(
        packageName: 'com.spotify.music',
        appName: 'Spotify',
        isBlocked: false,
        iconPath: '/path/to/spotify_icon.png',
        usageTimeMinutes: 60,
        category: 'Music',
      ),
    ];
  }
  
  /// Create a test focus session
  static FocusSession createTestSession({
    String? id,
    DateTime? startTime,
    int durationMinutes = 25,
    SessionStatus status = SessionStatus.completed,
    String? goal,
    List<String>? blockedApps,
  }) {
    final now = DateTime.now();
    final sessionId = id ?? 'test_session_${now.millisecondsSinceEpoch}';
    final sessionStart = startTime ?? now.subtract(Duration(minutes: durationMinutes));
    
    return FocusSession(
      id: sessionId,
      startTime: sessionStart,
      endTime: status == SessionStatus.running ? null : sessionStart.add(Duration(minutes: durationMinutes)),
      durationMinutes: durationMinutes,
      durationSeconds: durationMinutes * 60,
      remainingSeconds: status == SessionStatus.running ? (durationMinutes * 60) ~/ 2 : 0,
      isActive: status == SessionStatus.running,
      blockedApps: blockedApps ?? ['com.facebook.katana', 'com.instagram.android'],
      goal: goal ?? 'Test focus session',
      pausedTime: null,
      status: status,
      lastActivityTime: now,
      // Loại bỏ actualFocusMinutes vì không tồn tại trong constructor
    );
  }
  
  /// Create multiple test sessions
  static List<FocusSession> createTestSessions({int count = 5}) {
    final sessions = <FocusSession>[];
    final now = DateTime.now();
    
    for (int i = 0; i < count; i++) {
      final startTime = now.subtract(Duration(days: i, hours: i * 2));
      final status = i % 3 == 0 ? SessionStatus.completed : 
                    i % 3 == 1 ? SessionStatus.cancelled : SessionStatus.running;
      
      sessions.add(createTestSession(
        id: 'test_session_$i',
        startTime: startTime,
        durationMinutes: 25 + (i * 5),
        status: status,
        goal: 'Test goal $i',
      ));
    }
    
    return sessions;
  }
  
  /// Create test session history
  static List<SessionHistory> createTestHistory({int count = 10}) {
    final history = <SessionHistory>[];
    final now = DateTime.now();
    final actions = SessionAction.values;
    
    for (int i = 0; i < count; i++) {
      history.add(SessionHistory(
        id: 'history_$i',
        sessionId: 'test_session_${i % 3}',
        action: actions[i % actions.length],
        timestamp: now.subtract(Duration(hours: i)),
        data: {
          'testData': 'value_$i',
          'index': i,
        },
        note: 'Test history entry $i',
      ));
    }
    
    return history;
  }
  
  /// Create test statistics
  static Map<String, dynamic> createTestStatistics() {
    return {
      'totalSessions': 15,
      'completedSessions': 10,
      'cancelledSessions': 3,
      'totalFocusTime': 375, // minutes
      'averageSessionLength': 25.0,
      'completionRate': 0.67,
      'currentStreak': 3,
      'longestStreak': 7,
      'mostProductiveDay': 'Monday',
      'mostProductiveHour': 14,
      'weeklyProgress': {
        'Monday': 60,
        'Tuesday': 45,
        'Wednesday': 75,
        'Thursday': 30,
        'Friday': 90,
        'Saturday': 25,
        'Sunday': 50,
      },
      'appBlockingStats': {
        'com.facebook.katana': 25,
        'com.instagram.android': 18,
        'com.youtube.android': 12,
        'com.twitter.android': 8,
      },
    };
  }
  
  /// Create test settings
  static Map<String, dynamic> createTestSettings() {
    return {
      'notificationsEnabled': true,
      'soundEnabled': true,
      'vibrationEnabled': true,
      'autoStartBlocking': true,
      'showProgressNotification': true,
      'defaultSessionDuration': 25,
      'breakDuration': 5,
      'longBreakDuration': 15,
      'sessionsUntilLongBreak': 4,
      'theme': 'light',
      'language': 'en',
      'motivationalQuotes': true,
      'weeklyGoal': 300, // minutes
      'dailyGoal': 120, // minutes
    };
  }
  
  /// Create test blocked apps list
  static List<String> createTestBlockedAppsList() {
    return [
      'com.facebook.katana',
      'com.instagram.android',
      'com.youtube.android',
      'com.tiktok.android',
      'com.twitter.android',
    ];
  }
  
  /// Create test notification history
  static List<String> createTestNotificationHistory() {
    return [
      'Focus session started: 25 minutes',
      'App blocked: Facebook',
      'Focus session completed successfully',
      'Break time started: 5 minutes',
      'Focus session paused',
      'Focus session resumed',
      'Daily goal achieved: 120 minutes',
    ];
  }
  
  /// Create test productivity insights
  static Map<String, dynamic> createTestProductivityInsights() {
    return {
      'todayFocusTime': 90,
      'weekFocusTime': 420,
      'monthFocusTime': 1680,
      'todayGoalProgress': 0.75,
      'weekGoalProgress': 0.84,
      'monthGoalProgress': 0.67,
      'streakDays': 5,
      'bestStreak': 12,
      'averageDailyFocus': 60,
      'mostProductiveTimeSlot': '14:00-16:00',
      'leastProductiveTimeSlot': '20:00-22:00',
      'topBlockedApps': [
        {'name': 'Facebook', 'blocks': 25},
        {'name': 'Instagram', 'blocks': 18},
        {'name': 'YouTube', 'blocks': 12},
      ],
      'weeklyTrend': 'increasing',
      'monthlyTrend': 'stable',
    };
  }
}