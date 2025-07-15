import '../models/app_info.dart';
import '../utils/constants.dart';

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
} 