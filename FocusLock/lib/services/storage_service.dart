import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/focus_session.dart';
import '../models/app_info.dart';
import '../utils/constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Focus Sessions
  Future<void> saveFocusSessions(List<FocusSession> sessions) async {
    final sessionsJson = sessions.map((session) => session.toJson()).toList();
    await _prefs.setString(AppConstants.focusSessionsKey, jsonEncode(sessionsJson));
  }

  Future<List<FocusSession>> getFocusSessions() async {
    final sessionsString = _prefs.getString(AppConstants.focusSessionsKey);
    if (sessionsString == null) return [];

    final sessionsJson = jsonDecode(sessionsString) as List;
    return sessionsJson.map((json) => FocusSession.fromJson(json)).toList();
  }

  Future<void> addFocusSession(FocusSession session) async {
    final sessions = await getFocusSessions();
    sessions.add(session);
    await saveFocusSessions(sessions);
  }

  Future<void> updateFocusSession(FocusSession updatedSession) async {
    final sessions = await getFocusSessions();
    final index = sessions.indexWhere((session) => session.id == updatedSession.id);
    if (index != -1) {
      sessions[index] = updatedSession;
      await saveFocusSessions(sessions);
    }
  }

  // Blocked Apps
  Future<void> saveBlockedApps(List<AppInfo> apps) async {
    final appsJson = apps.map((app) => app.toJson()).toList();
    await _prefs.setString(AppConstants.blockedAppsKey, jsonEncode(appsJson));
  }

  Future<List<AppInfo>> getBlockedApps() async {
    final appsString = _prefs.getString(AppConstants.blockedAppsKey);
    if (appsString == null) {
      // Return default blocked apps if none saved
      return AppConstants.defaultBlockedApps
          .map((app) => AppInfo(
                packageName: app['packageName']!,
                appName: app['appName']!,
                isBlocked: true,
              ))
          .toList();
    }

    final appsJson = jsonDecode(appsString) as List;
    return appsJson.map((json) => AppInfo.fromJson(json)).toList();
  }

  Future<void> updateBlockedApp(AppInfo app) async {
    final apps = await getBlockedApps();
    final index = apps.indexWhere((a) => a.packageName == app.packageName);
    if (index != -1) {
      apps[index] = app;
    } else {
      apps.add(app);
    }
    await saveBlockedApps(apps);
  }

  // Settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _prefs.setString(AppConstants.settingsKey, jsonEncode(settings));
  }

  Future<Map<String, dynamic>> getSettings() async {
    final settingsString = _prefs.getString(AppConstants.settingsKey);
    if (settingsString == null) {
      return {
        'notifications_enabled': true,
        'sound_enabled': true,
        'vibration_enabled': true,
        'auto_start_focus': false,
        'focus_goal_reminder': true,
      };
    }
    return Map<String, dynamic>.from(jsonDecode(settingsString));
  }

  // Statistics
  Future<void> saveStatistics(Map<String, dynamic> statistics) async {
    await _prefs.setString(AppConstants.statisticsKey, jsonEncode(statistics));
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final statisticsString = _prefs.getString(AppConstants.statisticsKey);
    if (statisticsString == null) {
      return {
        'total_focus_time': 0,
        'total_sessions': 0,
        'completed_sessions': 0,
        'current_streak': 0,
        'longest_streak': 0,
        'last_session_date': null,
      };
    }
    return Map<String, dynamic>.from(jsonDecode(statisticsString));
  }

  Future<void> updateStatistics({
    int? totalFocusTime,
    int? totalSessions,
    int? completedSessions,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastSessionDate,
  }) async {
    final statistics = await getStatistics();
    
    if (totalFocusTime != null) statistics['total_focus_time'] = totalFocusTime;
    if (totalSessions != null) statistics['total_sessions'] = totalSessions;
    if (completedSessions != null) statistics['completed_sessions'] = completedSessions;
    if (currentStreak != null) statistics['current_streak'] = currentStreak;
    if (longestStreak != null) statistics['longest_streak'] = longestStreak;
    if (lastSessionDate != null) statistics['last_session_date'] = lastSessionDate.toIso8601String();
    
    await saveStatistics(statistics);
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _prefs.clear();
  }
} 