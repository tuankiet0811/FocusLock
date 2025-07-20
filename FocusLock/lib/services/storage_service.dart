import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/focus_session.dart';
import '../models/app_info.dart';
import '../models/session_history.dart';
import '../models/session_status.dart';
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
    print('StorageService: saveFocusSessions - saving ${sessions.length} sessions');
    final sessionsJson = sessions.map((session) => session.toJson()).toList();
    final jsonString = jsonEncode(sessionsJson);
    print('StorageService: saveFocusSessions - json length: ${jsonString.length} chars');
    await _prefs.setString(AppConstants.focusSessionsKey, jsonString);
    print('StorageService: saveFocusSessions - completed');
  }

  Future<List<FocusSession>> getFocusSessions() async {
    final sessionsString = _prefs.getString(AppConstants.focusSessionsKey);
    print('StorageService: getFocusSessions - sessionsString: ${sessionsString != null ? sessionsString.length : 0} chars');
    if (sessionsString == null) {
      print('StorageService: getFocusSessions - no data found, returning empty list');
      return [];
    }

    try {
      final sessionsJson = jsonDecode(sessionsString) as List;
      final sessions = sessionsJson.map((json) => FocusSession.fromJson(json)).toList();
      print('StorageService: getFocusSessions - loaded ${sessions.length} sessions');
      return sessions;
    } catch (e) {
      print('StorageService: getFocusSessions - error parsing data: $e');
      return [];
    }
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

  Future<void> removeFocusSession(String sessionId) async {
    final sessions = await getFocusSessions();
    sessions.removeWhere((session) => session.id == sessionId);
    await saveFocusSessions(sessions);
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

  // Session History
  Future<void> saveSessionHistory(List<SessionHistory> history) async {
    final historyJson = history.map((entry) => entry.toJson()).toList();
    await _prefs.setString(AppConstants.sessionHistoryKey, jsonEncode(historyJson));
  }

  Future<List<SessionHistory>> getSessionHistory() async {
    final historyString = _prefs.getString(AppConstants.sessionHistoryKey);
    if (historyString == null) return [];

    final historyJson = jsonDecode(historyString) as List;
    return historyJson.map((json) => SessionHistory.fromJson(json)).toList();
  }

  Future<void> addSessionHistory(SessionHistory entry) async {
    final history = await getSessionHistory();
    history.add(entry);
    await saveSessionHistory(history);
  }

  // Statistics
  Future<void> saveStatistics(SessionStatistics statistics) async {
    await _prefs.setString(AppConstants.statisticsKey, jsonEncode(statistics.toJson()));
  }

  Future<SessionStatistics?> getStatistics() async {
    final statisticsString = _prefs.getString(AppConstants.statisticsKey);
    if (statisticsString == null) return null;
    
    try {
      final statisticsJson = jsonDecode(statisticsString);
      return SessionStatistics.fromJson(statisticsJson);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateStatistics({
    int? totalFocusMinutes,
    int? totalSessions,
    int? completedSessions,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastSessionDate,
  }) async {
    final statistics = await getStatistics();
    if (statistics == null) return;
    
    final updatedStatistics = statistics.copyWith(
      totalFocusMinutes: totalFocusMinutes,
      totalSessions: totalSessions,
      completedSessions: completedSessions,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastSessionDate: lastSessionDate,
    );
    
    await saveStatistics(updatedStatistics);
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _prefs.clear();
  }
} 