import 'dart:async';
import 'dart:convert';
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
  final Map<String, DateTime> _blockStartTimes = {};

  
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

  // Cập nhật method showBlockingOverlay
  Future<void> showBlockingOverlay(String packageName) async {
    try {
      final startTime = DateTime.now();
      
      await _channel.invokeMethod('showBlockingOverlay', {
        'packageName': packageName,
      });
      
      // Ghi lại thời điểm bắt đầu
      _blockStartTimes[packageName] = startTime;
      
    } catch (e) {
      print('Failed to show blocking overlay: $e');
      // Ghi lại attempt thất bại
      await recordBlockingAttempt(packageName, false, Duration.zero);
    }
  }

  // Method removeBlockingOverlay
  Future<void> removeBlockingOverlay() async {
    try {
      await _channel.invokeMethod('removeBlockingOverlay');
      
      // Tính thời gian chặn và ghi nhận
      final now = DateTime.now();
      for (final entry in _blockStartTimes.entries) {
        final packageName = entry.key;
        final startTime = entry.value;
        final blockDuration = now.difference(startTime);
        
        // Ghi nhận với thời gian thực tế
        await recordBlockingAttempt(packageName, true, blockDuration);
      }
      
      _blockStartTimes.clear();
    } catch (e) {
      print('Failed to remove blocking overlay: $e');
    }
  }

  // Record blocking attempt
  Future<void> recordBlockingAttempt(String packageName, bool wasBlocked, Duration blockDuration) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Lưu thống kê chặn ứng dụng
      final key = 'blocking_stats_$today';
      final existingData = prefs.getString(key);
      Map<String, dynamic> stats = {};
      
      if (existingData != null) {
        stats = Map<String, dynamic>.from(jsonDecode(existingData));
      }
      
      if (!stats.containsKey(packageName)) {
        stats[packageName] = {
          'attempts': 0,
          'blocked': 0,
          'totalBlockTime': 0,
        };
      }
      
      stats[packageName]['attempts'] += 1;
      if (wasBlocked) {
        stats[packageName]['blocked'] += 1;
        stats[packageName]['totalBlockTime'] += blockDuration.inSeconds;
      }
      
      await prefs.setString(key, jsonEncode(stats));
    } catch (e) {
      print('Failed to record blocking attempt: $e');
    }
  }

  // Get blocking stats for period
  Future<Map<String, dynamic>> getBlockingStatsForPeriod(String period) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      List<DateTime> dates = [];
      
      switch (period) {
        case 'today':
          dates = [now];
          break;
        case 'week':
          for (int i = 0; i < 7; i++) {
            dates.add(now.subtract(Duration(days: i)));
          }
          break;
        case 'month':
          for (int i = 0; i < 30; i++) {
            dates.add(now.subtract(Duration(days: i)));
          }
          break;
      }
      
      int totalAttempts = 0;
      int totalBlocked = 0;
      int totalBlockTime = 0;
      Map<String, int> appAttempts = {};
      
      for (final date in dates) {
        final key = 'blocking_stats_${DateFormat('yyyy-MM-dd').format(date)}';
        final data = prefs.getString(key);
        
        if (data != null) {
          final stats = Map<String, dynamic>.from(jsonDecode(data));
          
          for (final entry in stats.entries) {
            final packageName = entry.key;
            final appStats = entry.value;
            
            totalAttempts += (appStats['attempts'] as int? ?? 0);
            totalBlocked += (appStats['blocked'] as int? ?? 0);
            totalBlockTime += (appStats['totalBlockTime'] as int? ?? 0);
            
            appAttempts[packageName] = (appAttempts[packageName] ?? 0) + (appStats['attempts'] as int? ?? 0);
          }
        }
      }
      
      return {
        'attempts': totalAttempts,
        'blocked': totalBlocked,
        'totalBlockTime': totalBlockTime,
        'appAttempts': appAttempts,
      };
    } catch (e) {
      print('Failed to get blocking stats: $e');
      return {
        'attempts': 0,
        'blocked': 0,
        'totalBlockTime': 0,
        'appAttempts': <String, int>{},
      };
    }
  }
 
  // Dispose
  void dispose() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }
}