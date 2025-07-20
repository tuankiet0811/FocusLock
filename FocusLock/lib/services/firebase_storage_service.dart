import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/focus_session.dart';
import '../models/app_info.dart';
import '../models/session_history.dart';
import '../models/session_status.dart';
import '../utils/constants.dart';

class FirebaseStorageService {
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Initialize service
  Future<void> init() async {
    print('FirebaseStorageService: Initializing...');
    if (!isLoggedIn) {
      print('FirebaseStorageService: User not logged in');
      return;
    }
    print('FirebaseStorageService: User logged in - ${currentUserId}');
  }

  // Focus Sessions
  Future<void> saveFocusSession(FocusSession session) async {
    if (!isLoggedIn) {
      print('FirebaseStorageService: Cannot save - user not logged in');
      return;
    }

    try {
      print('FirebaseStorageService: Saving session ${session.id}');
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('sessions')
          .doc(session.id)
          .set(session.toJson());
      print('FirebaseStorageService: Session saved successfully');
    } catch (e) {
      print('FirebaseStorageService: Error saving session: $e');
      throw Exception('Lỗi khi lưu session: $e');
    }
  }

  Future<List<FocusSession>> getFocusSessions() async {
    if (!isLoggedIn) {
      print('FirebaseStorageService: Cannot get sessions - user not logged in');
      return [];
    }

    try {
      print('FirebaseStorageService: Getting sessions for user ${currentUserId}');
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('sessions')
          .orderBy('startTime', descending: true)
          .get();

      final sessions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure ID is set
        return FocusSession.fromJson(data);
      }).toList();

      print('FirebaseStorageService: Loaded ${sessions.length} sessions');
      return sessions;
    } catch (e) {
      print('FirebaseStorageService: Error getting sessions: $e');
      return [];
    }
  }

  Future<void> updateFocusSession(FocusSession session) async {
    await saveFocusSession(session);
  }

  Future<void> removeFocusSession(String sessionId) async {
    if (!isLoggedIn) {
      print('FirebaseStorageService: Cannot remove session - user not logged in');
      return;
    }

    try {
      print('FirebaseStorageService: Removing session $sessionId');
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('sessions')
          .doc(sessionId)
          .delete();
      print('FirebaseStorageService: Session removed successfully');
    } catch (e) {
      print('FirebaseStorageService: Error removing session: $e');
    }
  }

  // Blocked Apps
  Future<void> saveBlockedApps(List<AppInfo> apps) async {
    if (!isLoggedIn) {
      print('FirebaseStorageService: Cannot save blocked apps - user not logged in');
      return;
    }

    try {
      print('FirebaseStorageService: Saving ${apps.length} blocked apps');
      final appsJson = apps.map((app) => app.toJson()).toList();
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('settings')
          .doc('blockedApps')
          .set({'blockedApps': appsJson}, SetOptions(merge: true));
      print('FirebaseStorageService: Blocked apps saved successfully');
    } catch (e) {
      print('FirebaseStorageService: Error saving blocked apps: $e');
    }
  }

  Future<List<AppInfo>> getBlockedApps() async {
    if (!isLoggedIn) {
      print('FirebaseStorageService: Cannot get blocked apps - user not logged in');
      return AppConstants.defaultBlockedApps
          .map((app) => AppInfo(
                packageName: app['packageName']!,
                appName: app['appName']!,
                isBlocked: true,
              ))
          .toList();
    }

    try {
      print('FirebaseStorageService: Getting blocked apps for user ${currentUserId}');
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('settings')
          .doc('blockedApps')
          .get();

      if (doc.exists && doc.data()!.containsKey('blockedApps')) {
        final appsJson = doc.data()!['blockedApps'] as List;
        final apps = appsJson.map((json) => AppInfo.fromJson(json)).toList();
        print('FirebaseStorageService: Loaded ${apps.length} blocked apps');
        return apps;
      } else {
        print('FirebaseStorageService: No blocked apps found, using defaults');
        return AppConstants.defaultBlockedApps
            .map((app) => AppInfo(
                  packageName: app['packageName']!,
                  appName: app['appName']!,
                  isBlocked: true,
                ))
            .toList();
      }
    } catch (e) {
      print('FirebaseStorageService: Error getting blocked apps: $e');
      return AppConstants.defaultBlockedApps
          .map((app) => AppInfo(
                packageName: app['packageName']!,
                appName: app['appName']!,
                isBlocked: true,
              ))
          .toList();
    }
  }

  // Session History
  Future<void> saveSessionHistory(List<SessionHistory> history) async {
    if (!isLoggedIn) {
      print('FirebaseStorageService: Cannot save history - user not logged in');
      return;
    }

    try {
      print('FirebaseStorageService: Saving ${history.length} history entries');
      final batch = _firestore.batch();
      
      for (final entry in history) {
        final docRef = _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('history')
            .doc(entry.id);
        batch.set(docRef, entry.toJson());
      }
      
      await batch.commit();
      print('FirebaseStorageService: History saved successfully');
    } catch (e) {
      print('FirebaseStorageService: Error saving history: $e');
    }
  }

  Future<List<SessionHistory>> getSessionHistory() async {
    if (!isLoggedIn) {
      print('FirebaseStorageService: Cannot get history - user not logged in');
      return [];
    }

    try {
      print('FirebaseStorageService: Getting history for user ${currentUserId}');
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get();

      final history = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure ID is set
        return SessionHistory.fromJson(data);
      }).toList();

      print('FirebaseStorageService: Loaded ${history.length} history entries');
      return history;
    } catch (e) {
      print('FirebaseStorageService: Error getting history: $e');
      return [];
    }
  }

  Future<void> addSessionHistory(SessionHistory entry) async {
    if (!isLoggedIn) {
      print('FirebaseStorageService: Cannot add history - user not logged in');
      return;
    }

    try {
      print('FirebaseStorageService: Adding history entry ${entry.id}');
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('history')
          .doc(entry.id)
          .set(entry.toJson());
      print('FirebaseStorageService: History entry added successfully');
    } catch (e) {
      print('FirebaseStorageService: Error adding history: $e');
    }
  }

  // Statistics
  Future<void> saveStatistics(SessionStatistics statistics) async {
    if (!isLoggedIn) {
      print('FirebaseStorageService: Cannot save statistics - user not logged in');
      return;
    }

    try {
      print('FirebaseStorageService: Saving statistics');
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('statistics')
          .doc('user_stats')
          .set(statistics.toJson());
      print('FirebaseStorageService: Statistics saved successfully');
    } catch (e) {
      print('FirebaseStorageService: Error saving statistics: $e');
    }
  }

  Future<SessionStatistics?> getStatistics() async {
    if (!isLoggedIn) {
      print('FirebaseStorageService: Cannot get statistics - user not logged in');
      return null;
    }

    try {
      print('FirebaseStorageService: Getting statistics for user ${currentUserId}');
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('statistics')
          .doc('user_stats')
          .get();

      if (doc.exists) {
        final statistics = SessionStatistics.fromJson(doc.data()!);
        print('FirebaseStorageService: Statistics loaded successfully');
        return statistics;
      } else {
        print('FirebaseStorageService: No statistics found');
        return null;
      }
    } catch (e) {
      print('FirebaseStorageService: Error getting statistics: $e');
      return null;
    }
  }

  // Settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    if (!isLoggedIn) {
      print('FirebaseStorageService: Cannot save settings - user not logged in');
      return;
    }

    try {
      print('FirebaseStorageService: Saving settings');
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('settings')
          .doc('user_settings')
          .set(settings, SetOptions(merge: true));
      print('FirebaseStorageService: Settings saved successfully');
    } catch (e) {
      print('FirebaseStorageService: Error saving settings: $e');
    }
  }

  Future<Map<String, dynamic>> getSettings() async {
    if (!isLoggedIn) {
      print('FirebaseStorageService: Cannot get settings - user not logged in');
      return {
        'notifications_enabled': true,
        'sound_enabled': true,
        'vibration_enabled': true,
        'auto_start_focus': false,
        'focus_goal_reminder': true,
      };
    }

    try {
      print('FirebaseStorageService: Getting settings for user ${currentUserId}');
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('settings')
          .doc('user_settings')
          .get();

      if (doc.exists) {
        final settings = Map<String, dynamic>.from(doc.data()!);
        print('FirebaseStorageService: Settings loaded successfully');
        return settings;
      } else {
        print('FirebaseStorageService: No settings found, using defaults');
        return {
          'notifications_enabled': true,
          'sound_enabled': true,
          'vibration_enabled': true,
          'auto_start_focus': false,
          'focus_goal_reminder': true,
        };
      }
    } catch (e) {
      print('FirebaseStorageService: Error getting settings: $e');
      return {
        'notifications_enabled': true,
        'sound_enabled': true,
        'vibration_enabled': true,
        'auto_start_focus': false,
        'focus_goal_reminder': true,
      };
    }
  }

  // Clear all data for current user
  Future<void> clearAllData() async {
    if (!isLoggedIn) {
      print('FirebaseStorageService: Cannot clear data - user not logged in');
      return;
    }

    try {
      print('FirebaseStorageService: Clearing all data for user ${currentUserId}');
      
      // Delete sessions
      final sessionsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('sessions')
          .get();
      
      final batch1 = _firestore.batch();
      for (final doc in sessionsSnapshot.docs) {
        batch1.delete(doc.reference);
      }
      await batch1.commit();

      // Delete history
      final historySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('history')
          .get();
      
      final batch2 = _firestore.batch();
      for (final doc in historySnapshot.docs) {
        batch2.delete(doc.reference);
      }
      await batch2.commit();

      // Delete settings and statistics
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .delete();

      print('FirebaseStorageService: All data cleared successfully');
    } catch (e) {
      print('FirebaseStorageService: Error clearing data: $e');
    }
  }

  // Sync data from local to Firebase
  Future<void> syncFromLocal(List<FocusSession> localSessions, List<SessionHistory> localHistory) async {
    if (!isLoggedIn) {
      print('FirebaseStorageService: Cannot sync - user not logged in');
      return;
    }

    try {
      print('FirebaseStorageService: Syncing ${localSessions.length} sessions and ${localHistory.length} history entries');
      
      // Sync sessions
      for (final session in localSessions) {
        await saveFocusSession(session);
      }
      
      // Sync history
      for (final entry in localHistory) {
        await addSessionHistory(entry);
      }
      
      print('FirebaseStorageService: Sync completed successfully');
    } catch (e) {
      print('FirebaseStorageService: Error syncing data: $e');
    }
  }
} 