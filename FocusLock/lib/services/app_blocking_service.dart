import 'dart:async';
import 'package:flutter/services.dart';
import '../models/app_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AppBlockingService {
  static final AppBlockingService _instance = AppBlockingService._internal();
  factory AppBlockingService() => _instance;
  AppBlockingService._internal();

  static const MethodChannel _channel = MethodChannel('focuslock/app_blocking');
  
  List<AppInfo> _blockedApps = [];
  bool _isActive = false;
  Timer? _checkTimer;

  // Initialize the service
  Future<void> init() async {
    try {
      await _channel.invokeMethod('init');
    } catch (e) {
      print('Failed to initialize app blocking service: $e');
    }
  }

  // Start app blocking
  Future<void> startBlocking(List<AppInfo> blockedApps) async {
    _blockedApps = blockedApps.where((app) => app.isBlocked).toList();
    _isActive = true;

    print('AppBlockingService: Starting blocking for ${_blockedApps.length} apps');
    print('AppBlockingService: Blocked apps: ${_blockedApps.map((app) => '${app.appName} (${app.packageName})').join(', ')}');

    try {
      await _channel.invokeMethod('startBlocking', {
        'blockedApps': _blockedApps.map((app) => app.packageName).toList(),
      });

      // Start periodic check for blocked apps
      _startPeriodicCheck();
      print('AppBlockingService: App blocking started successfully');
    } catch (e) {
      print('Failed to start app blocking: $e');
    }
  }

  // Stop app blocking
  Future<void> stopBlocking() async {
    _isActive = false;
    _checkTimer?.cancel();
    _checkTimer = null;

    try {
      await _channel.invokeMethod('stopBlocking');
    } catch (e) {
      print('Failed to stop app blocking: $e');
    }
  }

  // Check if an app is currently blocked
  bool isAppBlocked(String packageName) {
    if (!_isActive) return false;
    
    return _blockedApps.any((app) => 
      app.packageName == packageName && app.isBlocked
    );
  }

  // Get blocked app info
  AppInfo? getBlockedAppInfo(String packageName) {
    return _blockedApps.firstWhere(
      (app) => app.packageName == packageName,
      orElse: () => AppInfo(
        packageName: packageName,
        appName: packageName,
        isBlocked: false,
      ),
    );
  }

  // Start periodic check for blocked apps
  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!_isActive) {
        timer.cancel();
        return;
      }

      try {
        final currentApp = await _channel.invokeMethod('getCurrentApp');
        if (currentApp != null) {
          print('AppBlockingService: Current app: $currentApp');
          if (isAppBlocked(currentApp)) {
            print('AppBlockingService: Blocked app detected: $currentApp');
            await _showBlockedAppDialog(currentApp);
          }
        }
      } catch (e) {
        print('Error checking current app: $e');
      }
    });
  }

  // Show dialog when blocked app is detected
  Future<void> _showBlockedAppDialog(String packageName) async {
    final appInfo = getBlockedAppInfo(packageName);
    if (appInfo == null) return;

    try {
      await _channel.invokeMethod('showBlockedAppDialog', {
        'appName': appInfo.appName,
        'packageName': packageName,
      });
    } catch (e) {
      print('Failed to show blocked app dialog: $e');
    }
  }

  // Request necessary permissions
  Future<bool> requestPermissions() async {
    try {
      // Request usage access permission
      final usageResult = await _channel.invokeMethod('requestPermissions');
      
      // Request accessibility permission
      final accessibilityResult = await _channel.invokeMethod('requestAccessibilityPermission');
      
      return (usageResult ?? false) || (accessibilityResult ?? false);
    } catch (e) {
      print('Failed to request permissions: $e');
      return false;
    }
  }

  // Check if permissions are granted
  Future<bool> checkPermissions() async {
    try {
      final result = await _channel.invokeMethod('checkPermissions');
      return result ?? false;
    } catch (e) {
      print('Failed to check permissions: $e');
      return false;
    }
  }

  // Kiểm tra quyền Usage Access
  Future<bool> checkUsageAccessPermission() async {
    try {
      final result = await _channel.invokeMethod('checkUsageAccessPermission');
      return result ?? false;
    } catch (e) {
      print('Failed to check usage access permission: $e');
      return false;
    }
  }

  // Kiểm tra quyền Overlay
  Future<bool> checkOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod('checkOverlayPermission');
      return result ?? false;
    } catch (e) {
      print('Failed to check overlay permission: $e');
      return false;
    }
  }

  // Kiểm tra quyền Accessibility
  Future<bool> checkAccessibilityPermission() async {
    try {
      final result = await _channel.invokeMethod('checkAccessibilityPermission');
      return result ?? false;
    } catch (e) {
      print('Failed to check accessibility permission: $e');
      return false;
    }
  }

  // Xin quyền Accessibility
  Future<bool> requestAccessibilityPermission() async {
    try {
      final result = await _channel.invokeMethod('requestAccessibilityPermission');
      return result ?? false;
    } catch (e) {
      print('Failed to request accessibility permission: $e');
      return false;
    }
  }

  // Xin quyền Usage Access
  Future<bool> requestUsageAccessPermission() async {
    try {
      final result = await _channel.invokeMethod('requestUsageAccessPermission');
      return result ?? false;
    } catch (e) {
      print('Failed to request usage access permission: $e');
      return false;
    }
  }

  // Xin quyền Overlay
  Future<bool> requestOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod('requestPermissions');
      return result ?? false;
    } catch (e) {
      print('Failed to request overlay permission: $e');
      return false;
    }
  }

  // Get list of installed apps
  Future<List<AppInfo>> getInstalledApps() async {
  try {
    final result = await _channel.invokeMethod('getInstalledApps');
    if (result is List) {
      // Sửa đoạn này:
      return result
          .map((app) => AppInfo.fromJson(Map<String, dynamic>.from(app)))
          .toList();
    }
    return [];
  } catch (e) {
    print('Failed to get installed apps: $e');
    return [];
  }
}

  // Get current app (for debug purposes)
  Future<String?> getCurrentApp() async {
    try {
      final result = await _channel.invokeMethod('getCurrentApp');
      return result;
    } catch (e) {
      print('Failed to get current app: $e');
      return null;
    }
  }

  // Debug current app and blocking status
  Future<Map<String, dynamic>> debugCurrentApp() async {
    try {
      final result = await _channel.invokeMethod('debugCurrentApp');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      print('Failed to debug current app: $e');
      return {};
    }
  }

  // Dispose
  void dispose() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  // Get blocking statistics for a specific period
  Future<Map<String, dynamic>> getBlockingStatsForPeriod(String period) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Mock data for demonstration - in real app, this would come from actual blocking logs
    final mockBlockingData = {
      'today': {
        'blockedApps': 5,
        'totalBlockTime': const Duration(hours: 2, minutes: 30),
        'blockAttempts': 12,
        'successfulBlocks': 10,
        'blockedAppsList': [
          'com.facebook.katana',
          'com.instagram.android',
          'com.google.android.youtube',
          'com.zhiliaoapp.musically',
          'com.whatsapp',
        ],
      },
      'week': {
        'blockedApps': 8,
        'totalBlockTime': const Duration(hours: 15, minutes: 45),
        'blockAttempts': 45,
        'successfulBlocks': 38,
        'blockedAppsList': [
          'com.facebook.katana',
          'com.instagram.android',
          'com.google.android.youtube',
          'com.zhiliaoapp.musically',
          'com.whatsapp',
          'com.spotify.music',
          'com.netflix.mediaclient',
          'com.discord',
        ],
      },
      'month': {
        'blockedApps': 12,
        'totalBlockTime': const Duration(hours: 45, minutes: 20),
        'blockAttempts': 180,
        'successfulBlocks': 156,
        'blockedAppsList': [
          'com.facebook.katana',
          'com.instagram.android',
          'com.google.android.youtube',
          'com.zhiliaoapp.musically',
          'com.whatsapp',
          'com.spotify.music',
          'com.netflix.mediaclient',
          'com.discord',
          'com.reddit.frontpage',
          'com.pinterest',
          'com.snapchat.android',
          'com.twitter.android',
        ],
      },
    };

    return Map<String, dynamic>.from(mockBlockingData[period] ?? {});
  }

  // Get blocking efficiency (successful blocks / total attempts)
  Future<double> getBlockingEfficiency(String period) async {
    final stats = await getBlockingStatsForPeriod(period);
    final attempts = stats['blockAttempts'] ?? 0;
    final successful = stats['successfulBlocks'] ?? 0;
    
    if (attempts == 0) return 0.0;
    return (successful / attempts) * 100;
  }

  // Get most blocked apps for a period
  Future<List<String>> getMostBlockedApps(String period) async {
    final stats = await getBlockingStatsForPeriod(period);
    final blockedAppsList = List<String>.from(stats['blockedAppsList'] ?? []);
    return blockedAppsList;
  }

  // Save blocking event (for future implementation)
  Future<void> saveBlockingEvent(String packageName, bool wasSuccessful) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = 'blocking_event_${today}_$packageName';
    
    // Get existing events for today
    final existingEvents = prefs.getStringList(key) ?? [];
    existingEvents.add('${DateTime.now().millisecondsSinceEpoch}_${wasSuccessful ? 'success' : 'failed'}');
    
    // Keep only last 100 events to avoid memory issues
    if (existingEvents.length > 100) {
      existingEvents.removeRange(0, existingEvents.length - 100);
    }
    
    await prefs.setStringList(key, existingEvents);
  }

  // Get blocking events for a specific app and date
  Future<List<Map<String, dynamic>>> getBlockingEvents(String packageName, String date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'blocking_event_${date}_$packageName';
    final events = prefs.getStringList(key) ?? [];
    
    return events.map((event) {
      final parts = event.split('_');
      if (parts.length == 2) {
        return {
          'timestamp': int.parse(parts[0]),
          'successful': parts[1] == 'success',
        };
      }
      return null;
    }).where((event) => event != null).cast<Map<String, dynamic>>().toList();
  }

  // Get total blocking time for a period
  Future<Duration> getTotalBlockingTime(String period) async {
    final stats = await getBlockingStatsForPeriod(period);
    return stats['totalBlockTime'] ?? Duration.zero;
  }

  // Get blocking attempts count for a period
  Future<int> getBlockingAttempts(String period) async {
    final stats = await getBlockingStatsForPeriod(period);
    return stats['blockAttempts'] ?? 0;
  }

  // Get successful blocks count for a period
  Future<int> getSuccessfulBlocks(String period) async {
    final stats = await getBlockingStatsForPeriod(period);
    return stats['successfulBlocks'] ?? 0;
  }
} 