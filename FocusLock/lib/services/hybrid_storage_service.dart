import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thêm dòng này
import 'storage_service.dart';
import 'firebase_storage_service.dart';
import '../models/focus_session.dart';
import '../models/app_info.dart';
import '../models/session_history.dart';
import '../models/session_status.dart';

class HybridStorageService {
  static final HybridStorageService _instance = HybridStorageService._internal();
  factory HybridStorageService() => _instance;
  HybridStorageService._internal();

  final StorageService _localStorage = StorageService();
  final FirebaseStorageService _firebaseStorage = FirebaseStorageService();

  // Check if user is logged in
  bool get isLoggedIn => _firebaseStorage.isLoggedIn;

  // Initialize service
  Future<void> init() async {
    print('HybridStorageService: Initializing...');
    await _localStorage.init();
    await _firebaseStorage.init();
    print('HybridStorageService: Initialized successfully');
  }

  // Focus Sessions
  Future<void> saveFocusSession(FocusSession session) async {
    print('HybridStorageService: Saving session ${session.id}');
    
    // Always save to local first
    await _localStorage.updateFocusSession(session);
    
    // Save to Firebase if logged in
    if (isLoggedIn) {
      await _firebaseStorage.saveFocusSession(session);
    }
  }

  Future<List<FocusSession>> getFocusSessions() async {
    print('HybridStorageService: Getting sessions');
    
    if (isLoggedIn) {
      // Try Firebase first
      try {
        final firebaseSessions = await _firebaseStorage.getFocusSessions();
        if (firebaseSessions.isNotEmpty) {
          print('HybridStorageService: Loaded ${firebaseSessions.length} sessions from Firebase');
          // Sync to local
          for (final session in firebaseSessions) {
            await _localStorage.updateFocusSession(session);
          }
          return firebaseSessions;
        }
      } catch (e) {
        print('HybridStorageService: Error getting from Firebase: $e');
      }
    }
    
    // Fallback to local
    final localSessions = await _localStorage.getFocusSessions();
    print('HybridStorageService: Loaded ${localSessions.length} sessions from local');
    return localSessions;
  }

  Future<void> addFocusSession(FocusSession session) async {
    print('HybridStorageService: Adding session ${session.id}');
    
    // Add to local first
    await _localStorage.addFocusSession(session);
    
    // Add to Firebase if logged in
    if (isLoggedIn) {
      await _firebaseStorage.saveFocusSession(session);
    }
  }

  Future<void> updateFocusSession(FocusSession session) async {
    await saveFocusSession(session);
  }

  Future<void> removeFocusSession(String sessionId) async {
    print('HybridStorageService: Removing session $sessionId');
    
    // Remove from local
    await _localStorage.removeFocusSession(sessionId);
    
    // Remove from Firebase if logged in
    if (isLoggedIn) {
      await _firebaseStorage.removeFocusSession(sessionId);
    }
  }

  // Blocked Apps
  Future<void> saveBlockedApps(List<AppInfo> apps) async {
    print('HybridStorageService: Saving ${apps.length} blocked apps');
    
    // Save to local
    await _localStorage.saveBlockedApps(apps);
    
    // Save to Firebase if logged in
    if (isLoggedIn) {
      await _firebaseStorage.saveBlockedApps(apps);
    }
  }

  Future<List<AppInfo>> getBlockedApps() async {
    print('HybridStorageService: Getting blocked apps');
    
    if (isLoggedIn) {
      // Try Firebase first
      try {
        final firebaseApps = await _firebaseStorage.getBlockedApps();
        print('HybridStorageService: Loaded ${firebaseApps.length} apps from Firebase');
        // Sync to local
        await _localStorage.saveBlockedApps(firebaseApps);
        return firebaseApps;
      } catch (e) {
        print('HybridStorageService: Error getting from Firebase: $e');
      }
    }
    
    // Fallback to local
    final localApps = await _localStorage.getBlockedApps();
    print('HybridStorageService: Loaded ${localApps.length} apps from local');
    return localApps;
  }

  // Session History
  Future<void> saveSessionHistory(List<SessionHistory> history) async {
    print('HybridStorageService: Saving ${history.length} history entries');
    
    // Save to local
    await _localStorage.saveSessionHistory(history);
    
    // Save to Firebase if logged in
    if (isLoggedIn) {
      await _firebaseStorage.saveSessionHistory(history);
    }
  }

  Future<List<SessionHistory>> getSessionHistory() async {
    print('HybridStorageService: Getting session history');
    
    if (isLoggedIn) {
      // Try Firebase first
      try {
        final firebaseHistory = await _firebaseStorage.getSessionHistory();
        if (firebaseHistory.isNotEmpty) {
          print('HybridStorageService: Loaded ${firebaseHistory.length} history entries from Firebase');
          // Sync to local
          await _localStorage.saveSessionHistory(firebaseHistory);
          return firebaseHistory;
        }
      } catch (e) {
        print('HybridStorageService: Error getting from Firebase: $e');
      }
    }
    
    // Fallback to local
    final localHistory = await _localStorage.getSessionHistory();
    print('HybridStorageService: Loaded ${localHistory.length} history entries from local');
    return localHistory;
  }

  Future<void> addSessionHistory(SessionHistory entry) async {
    print('HybridStorageService: Adding history entry ${entry.id}');
    
    // Add to local
    await _localStorage.addSessionHistory(entry);
    
    // Add to Firebase if logged in
    if (isLoggedIn) {
      await _firebaseStorage.addSessionHistory(entry);
    }
  }

  // Statistics
  Future<void> saveStatistics(SessionStatistics statistics) async {
    print('HybridStorageService: Saving statistics');
    
    // Save to local
    await _localStorage.saveStatistics(statistics);
    
    // Save to Firebase if logged in
    if (isLoggedIn) {
      await _firebaseStorage.saveStatistics(statistics);
    }
  }

  Future<SessionStatistics?> getStatistics() async {
    print('HybridStorageService: Getting statistics');
    
    if (isLoggedIn) {
      // Try Firebase first
      try {
        final firebaseStats = await _firebaseStorage.getStatistics();
        if (firebaseStats != null) {
          print('HybridStorageService: Loaded statistics from Firebase');
          // Sync to local
          await _localStorage.saveStatistics(firebaseStats);
          return firebaseStats;
        }
      } catch (e) {
        print('HybridStorageService: Error getting from Firebase: $e');
      }
    }
    
    // Fallback to local
    final localStats = await _localStorage.getStatistics();
    print('HybridStorageService: Loaded statistics from local');
    return localStats;
  }

  // Settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    print('HybridStorageService: Saving settings');
    
    // Save to local
    await _localStorage.saveSettings(settings);
    
    // Save to Firebase if logged in
    if (isLoggedIn) {
      await _firebaseStorage.saveSettings(settings);
    }
  }

  Future<Map<String, dynamic>> getSettings() async {
    print('HybridStorageService: Getting settings');
    
    if (isLoggedIn) {
      // Try Firebase first
      try {
        final firebaseSettings = await _firebaseStorage.getSettings();
        print('HybridStorageService: Loaded settings from Firebase');
        // Sync to local
        await _localStorage.saveSettings(firebaseSettings);
        return firebaseSettings;
      } catch (e) {
        print('HybridStorageService: Error getting from Firebase: $e');
      }
    }
    
    // Fallback to local
    final localSettings = await _localStorage.getSettings();
    print('HybridStorageService: Loaded settings from local');
    return localSettings;
  }

  // Sync local data to Firebase
  Future<void> syncToFirebase() async {
    if (!isLoggedIn) {
      print('HybridStorageService: Cannot sync - user not logged in');
      return;
    }

    try {
      print('HybridStorageService: Syncing local data to Firebase');
      
      // Get local data
      final localSessions = await _localStorage.getFocusSessions();
      final localHistory = await _localStorage.getSessionHistory();
      
      // Sync to Firebase
      await _firebaseStorage.syncFromLocal(localSessions, localHistory);
      
      print('HybridStorageService: Sync completed successfully');
    } catch (e) {
      print('HybridStorageService: Error syncing to Firebase: $e');
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    print('HybridStorageService: Clearing all data except avatar');
    
    // Lưu avatar trước khi clear
    final prefs = await SharedPreferences.getInstance();
    final avatarKeys = prefs.getKeys().where((key) => key.startsWith('user_avatar_id_')).toList();
    final avatarData = <String, String>{};
    
    for (final key in avatarKeys) {
      final value = prefs.getString(key);
      if (value != null) {
        avatarData[key] = value;
      }
    }
    
    // Clear local data
    await _localStorage.clearAllData();
    
    // Khôi phục avatar
    for (final entry in avatarData.entries) {
      await prefs.setString(entry.key, entry.value);
    }
    
    // Clear Firebase if logged in
    if (isLoggedIn) {
      await _firebaseStorage.clearAllData();
    }
    
    print('HybridStorageService: Data cleared, avatar preserved');
  }

  // Get storage info
  Future<Map<String, dynamic>> getStorageInfo() async {
    final localSessions = await _localStorage.getFocusSessions();
    final localHistory = await _localStorage.getSessionHistory();
    
    final info = {
      'isLoggedIn': isLoggedIn,
      'localSessions': localSessions.length,
      'localHistory': localHistory.length,
    };
    
    if (isLoggedIn) {
      try {
        final firebaseSessions = await _firebaseStorage.getFocusSessions();
        final firebaseHistory = await _firebaseStorage.getSessionHistory();
        info['firebaseSessions'] = firebaseSessions.length;
        info['firebaseHistory'] = firebaseHistory.length;
      } catch (e) {
        info['firebaseError'] = e.toString();
      }
    }
    
    return info;
  }
}