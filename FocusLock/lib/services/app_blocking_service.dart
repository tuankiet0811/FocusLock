import 'dart:async';
import 'package:flutter/services.dart';
import '../models/app_info.dart';

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
} 