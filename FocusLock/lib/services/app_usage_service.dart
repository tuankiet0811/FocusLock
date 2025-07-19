import '../models/app_info.dart';
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AppUsageService {
  static final AppUsageService _instance = AppUsageService._internal();
  factory AppUsageService() => _instance;
  AppUsageService._internal();

  // Get default blocked apps
  Future<List<AppInfo>> getDefaultBlockedApps() async {
    return AppConstants.defaultBlockedApps
        .map((app) => AppInfo(
              packageName: app['packageName']!,
              appName: app['appName']!,
              isBlocked: true,
              usageTimeMinutes: 0,
            ))
        .toList();
  }

  // Get all available apps (default + common apps)
  Future<List<AppInfo>> getAllApps() async {
    final defaultApps = await getDefaultBlockedApps();
    
    // Add common apps that users might want to block
    final commonApps = [
      AppInfo(
        packageName: 'com.google.android.youtube',
        appName: 'YouTube',
        isBlocked: false,
        usageTimeMinutes: 0,
      ),
      AppInfo(
        packageName: 'com.spotify.music',
        appName: 'Spotify',
        isBlocked: false,
        usageTimeMinutes: 0,
      ),
      AppInfo(
        packageName: 'com.netflix.mediaclient',
        appName: 'Netflix',
        isBlocked: false,
        usageTimeMinutes: 0,
      ),
      AppInfo(
        packageName: 'com.discord',
        appName: 'Discord',
        isBlocked: false,
        usageTimeMinutes: 0,
      ),
      AppInfo(
        packageName: 'com.reddit.frontpage',
        appName: 'Reddit',
        isBlocked: false,
        usageTimeMinutes: 0,
      ),
      AppInfo(
        packageName: 'com.google.android.gm',
        appName: 'Gmail',
        isBlocked: false,
        usageTimeMinutes: 0,
      ),
      AppInfo(
        packageName: 'com.google.android.apps.maps',
        appName: 'Google Maps',
        isBlocked: false,
        usageTimeMinutes: 0,
      ),
      AppInfo(
        packageName: 'com.google.android.apps.photos',
        appName: 'Google Photos',
        isBlocked: false,
        usageTimeMinutes: 0,
      ),
    ];

    return [...defaultApps, ...commonApps];
  }

  // Get apps by category
  Future<List<AppInfo>> getAppsByCategory(String category) async {
    final allApps = await getAllApps();
    
    switch (category.toLowerCase()) {
      case 'social':
        return allApps.where((app) => _isSocialMediaApp(app.packageName)).toList();
      case 'entertainment':
        return allApps.where((app) => _isEntertainmentApp(app.packageName)).toList();
      case 'productivity':
        return allApps.where((app) => _isProductivityApp(app.packageName)).toList();
      default:
        return allApps;
    }
  }

  // Check if app is social media
  bool _isSocialMediaApp(String packageName) {
    final socialMediaPackages = [
      'com.facebook.katana',
      'com.instagram.android',
      'com.zhiliaoapp.musically',
      'com.twitter.android',
      'com.threads.android',
      'com.snapchat.android',
      'com.whatsapp',
      'com.telegram.messenger',
      'com.discord',
      'com.reddit.frontpage',
      'com.pinterest',
      'com.linkedin.android',
    ];
    return socialMediaPackages.contains(packageName);
  }

  // Check if app is entertainment
  bool _isEntertainmentApp(String packageName) {
    final entertainmentPackages = [
      'com.spotify.music',
      'com.netflix.mediaclient',
      'com.google.android.youtube',
      'com.amazon.avod.thirdpartyclient',
      'com.hulu.plus',
      'com.disney.disneyplus',
    ];
    return entertainmentPackages.contains(packageName);
  }

  // Check if app is productivity
  bool _isProductivityApp(String packageName) {
    final productivityPackages = [
      'com.microsoft.office.word',
      'com.microsoft.office.excel',
      'com.microsoft.office.powerpoint',
      'com.google.android.apps.docs.editors.docs',
      'com.google.android.apps.docs.editors.sheets',
      'com.google.android.apps.docs.editors.slides',
      'com.notion.id',
      'com.trello',
      'com.asana.app',
      'com.google.android.gm',
    ];
    return productivityPackages.contains(packageName);
  }

  // Get app icon data (returns null for now, can be extended later)
  Future<String?> getAppIconPath(String packageName) async {
    // For now, return null as we don't have direct access to app icons
    // This can be extended later with native Android implementation
    return null;
  }

  // Check if app is installed (simplified check)
  Future<bool> isAppInstalled(String packageName) async {
    // For now, assume all apps in our list are installed
    // This can be extended later with native Android implementation
    final allApps = await getAllApps();
    return allApps.any((app) => app.packageName == packageName);
  }

  // Get app usage statistics for a specific period
  Future<Map<String, Duration>> getAppUsageForPeriod(String period) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Mock data for demonstration - in real app, this would come from system usage stats
    final mockUsageData = {
      'today': {
        'Facebook': const Duration(minutes: 45),
        'Instagram': const Duration(minutes: 30),
        'YouTube': const Duration(minutes: 60),
        'TikTok': const Duration(minutes: 25),
        'WhatsApp': const Duration(minutes: 20),
        'Gmail': const Duration(minutes: 15),
      },
      'week': {
        'Facebook': const Duration(hours: 3, minutes: 30),
        'Instagram': const Duration(hours: 2, minutes: 15),
        'YouTube': const Duration(hours: 4, minutes: 45),
        'TikTok': const Duration(hours: 1, minutes: 50),
        'WhatsApp': const Duration(hours: 1, minutes: 30),
        'Gmail': const Duration(minutes: 45),
        'Spotify': const Duration(hours: 2, minutes: 20),
        'Netflix': const Duration(hours: 1, minutes: 15),
      },
      'month': {
        'Facebook': const Duration(hours: 12, minutes: 30),
        'Instagram': const Duration(hours: 8, minutes: 45),
        'YouTube': const Duration(hours: 15, minutes: 20),
        'TikTok': const Duration(hours: 6, minutes: 15),
        'WhatsApp': const Duration(hours: 5, minutes: 30),
        'Gmail': const Duration(hours: 2, minutes: 15),
        'Spotify': const Duration(hours: 8, minutes: 45),
        'Netflix': const Duration(hours: 4, minutes: 30),
        'Discord': const Duration(hours: 3, minutes: 20),
        'Reddit': const Duration(hours: 2, minutes: 15),
      },
    };

    return Map<String, Duration>.from(mockUsageData[period] ?? {});
  }

  // Get app usage by category for a period
  Future<Map<String, Duration>> getAppUsageByCategory(String period, String category) async {
    final allUsage = await getAppUsageForPeriod(period);
    final Map<String, Duration> categoryUsage = {};

    for (final entry in allUsage.entries) {
      final packageName = entry.key;
      final duration = entry.value;

      bool isInCategory = false;
      switch (category.toLowerCase()) {
        case 'social':
          isInCategory = _isSocialMediaApp(packageName);
          break;
        case 'entertainment':
          isInCategory = _isEntertainmentApp(packageName);
          break;
        case 'productivity':
          isInCategory = _isProductivityApp(packageName);
          break;
      }

      if (isInCategory) {
        categoryUsage[packageName] = duration;
      }
    }

    return categoryUsage;
  }

  // Get total usage time for a period
  Future<Duration> getTotalUsageTime(String period) async {
    final usage = await getAppUsageForPeriod(period);
    return usage.values.fold<Duration>(
      Duration.zero,
      (total, duration) => total + duration,
    );
  }

  // Get most used apps for a period
  Future<List<MapEntry<String, Duration>>> getMostUsedApps(String period, {int limit = 5}) async {
    final usage = await getAppUsageForPeriod(period);
    final sortedEntries = usage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.take(limit).toList();
  }

  // Save app usage data (for future implementation)
  Future<void> saveAppUsageData(String packageName, Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = 'app_usage_${today}_$packageName';
    
    // Convert duration to minutes for storage
    final minutes = duration.inMinutes;
    await prefs.setInt(key, minutes);
  }

  // Load app usage data (for future implementation)
  Future<Duration?> loadAppUsageData(String packageName, String date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'app_usage_${date}_$packageName';
    final minutes = prefs.getInt(key);
    
    if (minutes != null) {
      return Duration(minutes: minutes);
    }
    return null;
  }
} 